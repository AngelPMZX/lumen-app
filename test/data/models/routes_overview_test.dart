import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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
