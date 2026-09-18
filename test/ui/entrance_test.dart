import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gimnasio_emocional/ui/widgets/entrance.dart';

/// Reloj falso: `ListEntrance` mide tiempo de pared (cuándo apareció la lista
/// frente a cuándo se construyó el elemento), y en una prueba eso no avanza
/// solo.
late DateTime _now;

void main() {
  setUp(() {
    _now = DateTime(2026, 9, 18, 10, 0, 0);
    EntranceScope.clock = () => _now;
  });

  tearDown(() => EntranceScope.clock = DateTime.now);

  Widget scope({Object? restartOn, required List<Widget> children}) {
    return MaterialApp(
      home: EntranceScope(
        restartOn: restartOn,
        child: Column(children: children),
      ),
    );
  }

  group('ListEntrance', () {
    testWidgets('al abrir la lista, los elementos entran escalonados',
        (tester) async {
      await tester.pumpWidget(scope(children: [
        const ListEntrance(index: 0, child: Text('uno')),
        const ListEntrance(index: 3, child: Text('dos')),
      ]));

      expect(find.byType(Animate), findsNWidgets(2));
      expect(find.text('uno'), findsOneWidget);
      expect(find.text('dos'), findsOneWidget);
      await tester.pumpAndSettle();
    });

    testWidgets('lo que aparece al desplazarse no espera su turno',
        (tester) async {
      await tester.pumpWidget(scope(children: [
        const ListEntrance(index: 0, child: Text('uno')),
      ]));
      expect(find.byType(Animate), findsOneWidget);

      // El usuario baja rápido: la lista crea el elemento 30 segundos después.
      _now = _now.add(const Duration(seconds: 30));
      await tester.pumpWidget(scope(children: [
        const ListEntrance(index: 0, child: Text('uno')),
        const ListEntrance(index: 30, child: Text('tarde')),
      ]));

      // El tardío se muestra tal cual, sin animación ni espera de 1.8 s.
      expect(find.text('tarde'), findsOneWidget);
      expect(find.byType(Animate), findsNothing);
      await tester.pumpAndSettle();
    });

    testWidgets('al cambiar el filtro la lista vuelve a escalonarse',
        (tester) async {
      await tester.pumpWidget(scope(
        restartOn: 'todas',
        children: [const ListEntrance(index: 5, child: Text('uno'))],
      ));
      expect(find.byType(Animate), findsOneWidget);

      _now = _now.add(const Duration(seconds: 30));
      await tester.pumpWidget(scope(
        restartOn: 'todas',
        children: [const ListEntrance(index: 5, child: Text('dos'))],
      ));
      expect(find.byType(Animate), findsNothing);

      // Mismo instante, pero ahora el filtro cambió: la entrada se reinicia.
      await tester.pumpWidget(scope(
        restartOn: 'completadas',
        children: [const ListEntrance(index: 5, child: Text('tres'))],
      ));
      expect(find.byType(Animate), findsOneWidget);
      await tester.pumpAndSettle();
    });

    testWidgets('sin EntranceScope el retraso se topa', (tester) async {
      // Columnas cortas que se construyen enteras: se comporta como siempre,
      // pero un índice grande no puede dejar el elemento un segundo en blanco.
      Duration? delay;
      await tester.pumpWidget(MaterialApp(
        home: Builder(builder: (context) {
          delay = EntranceScope.delayFor(
            context,
            40,
            step: const Duration(milliseconds: 60),
          );
          return const SizedBox();
        }),
      ));

      expect(delay, const Duration(milliseconds: 480)); // 8 escalones, no 40
    });
  });

  group('entranceFrom', () {
    testWidgets('al abrir arranca en 0 y se llena', (tester) async {
      late double from;
      await tester.pumpWidget(MaterialApp(
        home: EntranceScope(
          child: Builder(builder: (context) {
            from = entranceFrom(context, 0.8);
            return const SizedBox();
          }),
        ),
      ));
      expect(from, 0);
    });

    testWidgets('al volver a crearse desplazándose arranca ya en su valor',
        (tester) async {
      late double from;
      Widget build() => MaterialApp(
            home: EntranceScope(
              child: Builder(builder: (context) {
                from = entranceFrom(context, 0.8);
                return const SizedBox();
              }),
            ),
          );

      await tester.pumpWidget(build());
      _now = _now.add(const Duration(seconds: 30));
      await tester.pumpWidget(build());

      // Ni contador desde 0 ni barra llenándose otra vez: eso se veía como si
      // la app estuviera recargando al subir y bajar.
      expect(from, 0.8);
    });
  });

  group('EntranceScope.fresh', () {
    testWidgets('es cierto al abrir y falso después', (tester) async {
      late BuildContext inner;
      Widget build() => MaterialApp(
            home: EntranceScope(
              child: Builder(builder: (context) {
                inner = context;
                return const SizedBox();
              }),
            ),
          );

      await tester.pumpWidget(build());
      expect(EntranceScope.fresh(inner), isTrue);

      _now = _now.add(const Duration(seconds: 5));
      expect(EntranceScope.fresh(inner), isFalse);
    });
  });
}
