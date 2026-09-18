import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gimnasio_emocional/data/models/archetype.dart';
import 'package:gimnasio_emocional/data/models/routes_overview.dart';
import 'package:gimnasio_emocional/data/models/wellness_route.dart';

WellnessRoute _route(String id, int lessons, {int xp = 20}) => WellnessRoute(
      id: id,
      title: id,
      description: '',
      emoji: '⭐',
      color: Colors.teal,
      colorDark: Colors.teal,
      lessons: [
        for (int i = 1; i <= lessons; i++)
          Lesson(id: '${id}_$i', title: 'L$i', subtitle: '', xpReward: xp, steps: const []),
      ],
    );

void main() {
  final routes = [_route('a', 4), _route('b', 2, xp: 30), _route('c', 3)];

  test('sin progreso sugiere la primera ruta desde su primera lección', () {
    final o = RoutesOverview.compute(routes, {});
    expect(o.suggested!.route.id, 'a');
    expect(o.suggested!.nextLesson!.id, 'a_1');
    expect(o.lessonsCompleted, 0);
    expect(o.lessonsTotal, 9);
    expect(o.count(RouteFilter.notStarted), 3);
  });

  group('el arquetipo decide por dónde empezar', () {
    // Mente Serena empieza por mindfulness; Fuerza Resiliente, por resiliencia.
    final catalogue = [
      _route('emociones', 3),
      _route('resiliencia', 3),
      _route('mindfulness', 3),
    ];

    test('sin nada empezado propone la ruta de su arquetipo', () {
      final sabio = RoutesOverview.compute(catalogue, {}, archetypeId: 'sabio');
      expect(sabio.suggested!.route.id, 'mindfulness');

      final guerrero =
          RoutesOverview.compute(catalogue, {}, archetypeId: 'guerrero');
      expect(guerrero.suggested!.route.id, 'resiliencia');
    });

    test('en cuanto empieza una ruta, manda su progreso', () {
      final o = RoutesOverview.compute(
        catalogue,
        {'emociones_1'},
        archetypeId: 'sabio',
      );
      expect(o.suggested!.route.id, 'emociones');
    });

    test('si ya terminó la suya, sigue por la primera sin empezar', () {
      final o = RoutesOverview.compute(
        catalogue,
        {'mindfulness_1', 'mindfulness_2', 'mindfulness_3'},
        archetypeId: 'sabio',
      );
      expect(o.suggested!.route.id, 'emociones');
      expect(o.firstForArchetype, isNull);
    });

    test('sin arquetipo, o con uno desconocido, es como antes', () {
      expect(RoutesOverview.compute(catalogue, {}).suggested!.route.id,
          'emociones');
      expect(
        RoutesOverview.compute(catalogue, {}, archetypeId: 'no-existe')
            .suggested!
            .route
            .id,
        'emociones',
      );
    });

    test('si su ruta no está en el catálogo no pasa nada', () {
      // `WellnessRoute.all` (el respaldo viejo) no trae todas las rutas.
      final short = [_route('emociones', 2)];
      final o = RoutesOverview.compute(short, {}, archetypeId: 'sabio');
      expect(o.suggested!.route.id, 'emociones');
    });

    test('Archetype se expone para que la pantalla pueda contarlo', () {
      final o = RoutesOverview.compute(catalogue, {}, archetypeId: 'social');
      expect(o.archetype, Archetype.social);
    });
  });

  test('sugiere la ruta empezada más avanzada, no la primera', () {
    final o = RoutesOverview.compute(routes, {'a_1', 'c_1', 'c_2'});
    expect(o.suggested!.route.id, 'c');
    expect(o.suggested!.nextLesson!.id, 'c_3');
    expect(o.suggested!.nextIndex, 2);
  });

  test('las rutas completadas no se sugieren y cuentan en los totales', () {
    final o = RoutesOverview.compute(routes, {'b_1', 'b_2', 'a_1'});
    expect(o.routesCompleted, 1);
    expect(o.suggested!.route.id, 'a');
    expect(o.xpEarned, 30 * 2 + 20);
    expect(o.filtered(RouteFilter.completed).single.route.id, 'b');
    expect(o.filtered(RouteFilter.inProgress).single.route.id, 'a');
    expect(o.filtered(RouteFilter.notStarted).single.route.id, 'c');
  });

  test('con todo completado no hay sugerencia', () {
    final all = {for (final r in routes) ...r.lessons.map((l) => l.id)};
    final o = RoutesOverview.compute(routes, all);
    expect(o.allDone, isTrue);
    expect(o.suggested, isNull);
    expect(o.routes.every((r) => r.fraction == 1), isTrue);
  });

  test('la siguiente lección es la primera sin completar aunque haya saltos', () {
    final p = RouteProgress.compute(routes.first, {'a_1', 'a_3'});
    expect(p.nextLesson!.id, 'a_2');
    expect(p.status, RouteStatus.inProgress);
  });
}
