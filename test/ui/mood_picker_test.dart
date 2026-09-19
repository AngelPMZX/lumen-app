import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gimnasio_emocional/domain/services/sound_service.dart';
import 'package:gimnasio_emocional/ui/screens/home/widgets/mood_checkin_card.dart';
import 'package:gimnasio_emocional/ui/widgets/journal/journal_style.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Los emojis del check-in no se pintan fuera de su tarjeta.
///
/// Salió de una prueba en el teléfono: al deslizarlos de lado se salían del
/// recuadro y quedaban encima del borde redondeado.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    // ignore: invalid_use_of_visible_for_testing_member
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
    await SoundService.instance.setEffectsEnabled(false);
    // ignore: invalid_use_of_visible_for_testing_member
    JournalStyle.useSystemFonts = true;
  });

  testWidgets('la lista de emojis se recorta dentro de la tarjeta',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      EasyLocalization(
        supportedLocales: const [Locale('es')],
        path: 'assets/translations',
        startLocale: const Locale('es'),
        fallbackLocale: const Locale('es'),
        child: Builder(
          builder: (context) => MaterialApp(
            localizationsDelegates: context.localizationDelegates,
            supportedLocales: context.supportedLocales,
            locale: context.locale,
            home: Scaffold(
              body: Padding(
                padding: const EdgeInsets.all(20),
                child: MoodCheckInCard(
                  selected: null,
                  weeklyMoods: const {},
                  isDark: false,
                  onSelect: (_) {},
                ),
              ),
            ),
          ),
        ),
      ),
    );
    // Las traducciones cargan de un asset: hace falta tiempo real.
    await tester
        .runAsync(() => Future.delayed(const Duration(milliseconds: 300)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    // Sin esto la prueba mediría el vacío.
    expect(find.byType(MoodCheckInCard), findsOneWidget);
    expect(find.byType(ListView), findsOneWidget);

    // Lo que se rompió: `Clip.none` dejaba que los emojis se siguieran
    // pintando fuera de la lista al deslizarlos.
    final list = tester.widget<ListView>(find.byType(ListView));
    expect(list.clipBehavior, isNot(Clip.none));

    // Y hay más emojis de los que caben, así que de verdad hay que recortar.
    final viewport = tester.getSize(find.byType(ListView)).width;
    expect(viewport, lessThan(64.0 * 12), reason: 'caben todos, nada que recortar');

    await tester.drag(find.byType(ListView), const Offset(-120, 0));
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 120));
    }
    expect(tester.takeException(), isNull);
  });
}
