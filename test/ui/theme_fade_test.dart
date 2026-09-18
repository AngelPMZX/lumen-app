import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gimnasio_emocional/core/theme/app_theme.dart';
import 'package:gimnasio_emocional/ui/widgets/theme_fade.dart';

void main() {
  /// Una app mínima con el atardecer dentro, como lo monta `app.dart`.
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
          child: const Scaffold(body: Center(child: Text('hola'))),
        ),
      ),
    );
  }

  /// La foto de la pantalla anterior, mientras se desvanece encima.
  Finder snapshot() => find.descendant(
        of: find.byType(ThemeFade),
        matching: find.byType(RawImage),
      );

  testWidgets('al abrir no hay nada encima', (tester) async {
    await tester.pumpWidget(app(Brightness.light));
    expect(snapshot(), findsNothing);
    await tester.pumpAndSettle();
  });

  testWidgets('al cambiar de tema se funde la pantalla anterior',
      (tester) async {
    await tester.pumpWidget(app(Brightness.light));
    await tester.pump();
    await tester.pumpWidget(app(Brightness.dark));
    await tester.pump();

    // Encima queda la foto de cómo se veía, no un color plano: por eso no hay
    // destello aunque la pantalla de abajo tenga degradados.
    expect(snapshot(), findsOneWidget);

    // Arranca tapando del todo y va bajando.
    // `.first` = el FadeTransition más cercano a la foto (arriba hay otros,
    // de las transiciones del propio MaterialApp).
    double opacity() => tester
        .widget<FadeTransition>(find
            .ancestor(of: snapshot(), matching: find.byType(FadeTransition))
            .first)
        .opacity
        .value;
    expect(opacity(), 1);

    await tester.pump(const Duration(milliseconds: 350));
    expect(opacity(), greaterThan(0));
    expect(opacity(), lessThan(1));

    // Y al terminar se quita: no deja una capa —ni varios MB de imagen— ahí.
    await tester.pumpAndSettle();
    expect(snapshot(), findsNothing);
  });

  testWidgets('funciona también al volver a claro', (tester) async {
    await tester.pumpWidget(app(Brightness.dark));
    await tester.pump();
    await tester.pumpWidget(app(Brightness.light));
    await tester.pump();

    expect(snapshot(), findsOneWidget);
    await tester.pumpAndSettle();
    expect(snapshot(), findsNothing);
  });

  testWidgets('con "reducir animaciones" el cambio es instantáneo',
      (tester) async {
    await tester.pumpWidget(app(Brightness.light, reduceMotion: true));
    await tester.pump();
    await tester.pumpWidget(app(Brightness.dark, reduceMotion: true));
    await tester.pump();

    expect(snapshot(), findsNothing);
    await tester.pumpAndSettle();
  });
}
