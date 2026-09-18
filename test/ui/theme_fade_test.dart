import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gimnasio_emocional/core/theme/app_theme.dart';
import 'package:gimnasio_emocional/ui/widgets/theme_fade.dart';

void main() {
  /// Una app mínima con el velo dentro, como lo monta `app.dart`.
  Widget app(Brightness brightness, {bool reduceMotion = false}) {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode:
          brightness == Brightness.dark ? ThemeMode.dark : ThemeMode.light,
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: reduceMotion),
        child: ThemeFade(
          brightness: brightness,
          child: const Scaffold(body: Text('hola')),
        ),
      ),
    );
  }

  /// El velo es el `ColoredBox` a pantalla completa que tapa la app mientras
  /// se desvanece.
  Color? veilColor(WidgetTester tester) {
    final boxes = tester.widgetList<ColoredBox>(find.descendant(
      of: find.byType(ThemeFade),
      matching: find.byType(ColoredBox),
    ));
    return boxes.isEmpty ? null : boxes.first.color;
  }

  testWidgets('al abrir no hay velo', (tester) async {
    await tester.pumpWidget(app(Brightness.light));
    expect(veilColor(tester), isNull);
    await tester.pumpAndSettle();
  });

  testWidgets('al pasar a oscuro se desvanece el fondo claro', (tester) async {
    await tester.pumpWidget(app(Brightness.light));
    await tester.pumpWidget(app(Brightness.dark));
    await tester.pump();

    // El velo es el fondo del tema que acaba de salir (el claro), no el nuevo:
    // así la luz baja poco a poco en vez de dar un salto.
    expect(veilColor(tester), AppTheme.lightTheme.scaffoldBackgroundColor);

    // A media animación sigue ahí, tapando en parte.
    await tester.pump(const Duration(milliseconds: 200));
    final opacity = tester
        .widget<FadeTransition>(find.descendant(
          of: find.byType(ThemeFade),
          matching: find.byType(FadeTransition),
        ))
        .opacity
        .value;
    expect(opacity, greaterThan(0));
    expect(opacity, lessThan(1));

    // Y al terminar se quita: no deja una capa de más para siempre.
    await tester.pumpAndSettle();
    expect(veilColor(tester), isNull);
  });

  testWidgets('al volver a claro se desvanece el fondo oscuro', (tester) async {
    await tester.pumpWidget(app(Brightness.dark));
    await tester.pumpWidget(app(Brightness.light));
    await tester.pump();

    expect(veilColor(tester), AppTheme.darkTheme.scaffoldBackgroundColor);
    await tester.pumpAndSettle();
  });

  testWidgets('con "reducir animaciones" el cambio es instantáneo',
      (tester) async {
    await tester.pumpWidget(app(Brightness.light, reduceMotion: true));
    await tester.pumpWidget(app(Brightness.dark, reduceMotion: true));
    await tester.pump();

    expect(veilColor(tester), isNull);
    await tester.pumpAndSettle();
  });
}
