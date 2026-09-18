import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gimnasio_emocional/data/models/wellness_route.dart';
import 'package:gimnasio_emocional/domain/services/sound_service.dart';
import 'package:gimnasio_emocional/ui/screens/reminders/widgets/habit_color_picker.dart';
import 'package:gimnasio_emocional/ui/screens/routes/steps/commit_step.dart';
import 'package:gimnasio_emocional/ui/screens/routes/steps/step_common.dart';
import 'package:gimnasio_emocional/ui/widgets/journal/journal_style.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Nada se desborda en una pantalla estrecha ni con la letra grande.
///
/// Flutter avisa de un desbordamiento con una excepción, así que basta con
/// dibujar el widget apretado: si algo no cabe, la prueba falla sola. Los dos
/// casos de aquí salieron de pruebas reales en el teléfono, con la franja
/// negra y amarilla de "RIGHT OVERFLOWED BY 26 PIXELS".
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    // ignore: invalid_use_of_visible_for_testing_member
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
    await SoundService.instance.setEffectsEnabled(false);
    // Sin esto, google_fonts intenta bajar las tipografías y la pantalla ni
    // se dibuja.
    // ignore: invalid_use_of_visible_for_testing_member
    JournalStyle.useSystemFonts = true;
  });

  /// 320 dp de ancho es un teléfono pequeño de verdad (iPhone SE 1.ª gen).
  /// Con `textScale` se simula la letra grande del sistema.
  Future<void> pumpNarrow(
    WidgetTester tester,
    Widget child, {
    double width = 320,
    double textScale = 1.0,
    String locale = 'es',
    bool needsText = true,
  }) async {
    await tester.binding.setSurfaceSize(Size(width, 720));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      EasyLocalization(
        supportedLocales: const [Locale('es'), Locale('en')],
        path: 'assets/translations',
        startLocale: Locale(locale),
        fallbackLocale: const Locale('es'),
        child: Builder(
          builder: (context) => MaterialApp(
            localizationsDelegates: context.localizationDelegates,
            supportedLocales: context.supportedLocales,
            locale: context.locale,
            home: Builder(
              builder: (context) => MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(textScaler: TextScaler.linear(textScale)),
                child: Scaffold(
                  body: SingleChildScrollView(child: child),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    // Las traducciones cargan de verdad (leen un asset), así que hace falta
    // tiempo real: sin esto no se dibuja nada y la prueba mediría el vacío.
    await tester.runAsync(
        () => Future.delayed(const Duration(milliseconds: 300)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    // Si no se dibujó nada, no hay nada que comprobar.
    if (needsText) {
      expect(find.byType(Text), findsWidgets,
          reason: 'la pantalla no llegó a dibujarse');
    }
  }

  group('El reto de una lección', () {
    const step = LessonStep.commit(
      title: 'Tu reto de hoy',
      content: 'Elige uno y mantenlo presionado.',
      options: ['Escribir tres cosas buenas', 'Salir a caminar diez minutos'],
    );

    Widget commit() => CommitStep(
          step: step,
          routeColor: Colors.teal,
          callbacks: StepCallbacks(
            onAnswer: (_, _, {bool sound = true}) {},
            onReflect: (_) {},
            onReady: () {},
          ),
          onCommitted: (_) {},
        );

    /// El botón solo dice "Mantén presionado para comprometerte" —el texto
    /// largo, el que se desbordaba— **después** de elegir un reto.
    Future<void> chooseOption(WidgetTester tester) async {
      await tester.tap(find.text('Salir a caminar diez minutos'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
    }

    testWidgets('cabe en una pantalla estrecha', (tester) async {
      await pumpNarrow(tester, commit());
      await chooseOption(tester);
      expect(tester.takeException(), isNull);
    });

    testWidgets('cabe también en inglés y con la letra grande', (tester) async {
      await pumpNarrow(tester, commit(), locale: 'en', textScale: 1.3);
      await chooseOption(tester);
      expect(tester.takeException(), isNull);
    });
  });

  group('Crear un hábito', () {
    testWidgets('los ocho colores caben en una pantalla estrecha',
        (tester) async {
      // Ocho círculos en una sola fila no entraban: ahora bajan de línea.
      var chosen = const Color(0xFF6366F1);
      await pumpNarrow(
        tester,
        HabitColorPicker(
          colors: const [
            Color(0xFF6366F1), Color(0xFFEF4444), Color(0xFF3B82F6),
            Color(0xFF10B981), Color(0xFFF59E0B), Color(0xFFF97316),
            Color(0xFF8B5CF6), Color(0xFFEC4899),
          ],
          selected: chosen,
          onSelected: (c) => chosen = c,
        ),
        needsText: false,
      );
      expect(tester.takeException(), isNull);
    });
  });
}
