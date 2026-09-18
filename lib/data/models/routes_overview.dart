import 'archetype.dart';
import 'wellness_route.dart';

enum RouteStatus { notStarted, inProgress, completed }

enum RouteFilter { all, inProgress, notStarted, completed }

/// Progreso del usuario en una ruta.
class RouteProgress {
  final WellnessRoute route;
  final int completed;

  /// Primera lección sin completar (null si terminó la ruta).
  final Lesson? nextLesson;
  final int nextIndex;

  /// XP base de las lecciones completadas y de toda la ruta.
  final int xpEarned;
  final int xpTotal;

  const RouteProgress({
    required this.route,
    required this.completed,
    required this.nextLesson,
    required this.nextIndex,
    required this.xpEarned,
    required this.xpTotal,
  });

  int get total => route.lessons.length;

  double get fraction => total == 0 ? 0 : completed / total;

  RouteStatus get status {
    if (total > 0 && completed >= total) return RouteStatus.completed;
    if (completed > 0) return RouteStatus.inProgress;
    return RouteStatus.notStarted;
  }

  factory RouteProgress.compute(WellnessRoute route, Set<String> completedIds) {
    var completed = 0;
    var xpEarned = 0;
    var xpTotal = 0;
    Lesson? next;
    var nextIndex = -1;
    for (int i = 0; i < route.lessons.length; i++) {
      final lesson = route.lessons[i];
      xpTotal += lesson.xpReward;
      if (completedIds.contains(lesson.id)) {
        completed++;
        xpEarned += lesson.xpReward;
      } else if (next == null) {
        next = lesson;
        nextIndex = i;
      }
    }
    return RouteProgress(
      route: route,
      completed: completed,
      nextLesson: next,
      nextIndex: nextIndex,
      xpEarned: xpEarned,
      xpTotal: xpTotal,
    );
  }
}

/// Resumen del menú de rutas: totales, ruta sugerida para seguir y filtros.
/// Lógica pura (sin Flutter ni Firebase) para poder probarla.
class RoutesOverview {
  final List<RouteProgress> routes;

  /// Arquetipo de la persona, si lo tiene. Solo decide **por dónde empezar**
  /// cuando todavía no ha abierto ninguna ruta.
  final Archetype? archetype;

  const RoutesOverview(this.routes, {this.archetype});

  factory RoutesOverview.compute(
    List<WellnessRoute> routes,
    Set<String> completedIds, {
    String? archetypeId,
  }) {
    return RoutesOverview(
      [for (final r in routes) RouteProgress.compute(r, completedIds)],
      archetype: Archetype.fromId(archetypeId),
    );
  }

  int get lessonsCompleted => routes.fold(0, (sum, r) => sum + r.completed);
  int get lessonsTotal => routes.fold(0, (sum, r) => sum + r.total);
  int get routesCompleted =>
      routes.where((r) => r.status == RouteStatus.completed).length;
  int get xpEarned => routes.fold(0, (sum, r) => sum + r.xpEarned);
  bool get allDone => routes.isNotEmpty && routesCompleted == routes.length;

  /// Ruta para "Continúa donde te quedaste": la que va más avanzada entre las
  /// empezadas (a igualdad, la primera del orden).
  ///
  /// Si no hay ninguna empezada manda el **arquetipo**: se propone la que le
  /// sienta mejor a quien es (ver [Archetype.preferredRouteIds]) en vez de la
  /// primera del catálogo, que era igual para todo el mundo. En cuanto empieza
  /// cualquier ruta, manda su progreso. Null si ya terminó todas.
  RouteProgress? get suggested {
    RouteProgress? best;
    for (final r in routes) {
      if (r.status != RouteStatus.inProgress) continue;
      if (best == null || r.fraction > best.fraction) best = r;
    }
    if (best != null) return best;
    return firstForArchetype ?? _firstNotStarted;
  }

  RouteProgress? get _firstNotStarted {
    for (final r in routes) {
      if (r.status == RouteStatus.notStarted) return r;
    }
    return null;
  }

  /// La primera ruta sin empezar que le toca al arquetipo, si hay alguna.
  /// Se expone para poder decirle a la persona por dónde va a empezar al
  /// revelarle su arquetipo.
  RouteProgress? get firstForArchetype {
    for (final id in archetype?.preferredRouteIds ?? const <String>[]) {
      for (final r in routes) {
        if (r.route.id == id && r.status == RouteStatus.notStarted) return r;
      }
    }
    return null;
  }

  List<RouteProgress> filtered(RouteFilter filter) => switch (filter) {
        RouteFilter.all => routes,
        RouteFilter.inProgress =>
          routes.where((r) => r.status == RouteStatus.inProgress).toList(),
        RouteFilter.notStarted =>
          routes.where((r) => r.status == RouteStatus.notStarted).toList(),
        RouteFilter.completed =>
          routes.where((r) => r.status == RouteStatus.completed).toList(),
      };

  int count(RouteFilter filter) => filtered(filter).length;
}
