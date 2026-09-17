import 'dart:math' as math;

/// Tipos de misión semanal. Todas se cuentan con datos que la app ya guarda:
/// el usuario no tiene que marcar nada.
enum MissionType { checkIns, lessons, breathing, diary, review, habits, commitment }

class MissionDef {
  final MissionType type;
  final int target;
  final int seeds;

  const MissionDef(this.type, this.target, this.seeds);
}

/// Una misión de la semana con su avance.
class Mission {
  final MissionDef def;
  final int progress;
  final bool claimed;

  const Mission({required this.def, required this.progress, required this.claimed});

  MissionType get type => def.type;
  bool get completed => progress >= def.target;
  bool get claimable => completed && !claimed;
  double get fraction => (progress / def.target).clamp(0.0, 1.0);
}

/// Actividad de la semana en curso (lunes a hoy).
class WeekActivity {
  final int checkInDays;
  final int lessons;
  final int breathing;
  final int diary;
  final int reviews;
  final int habits;
  final int commitments;

  const WeekActivity({
    this.checkInDays = 0,
    this.lessons = 0,
    this.breathing = 0,
    this.diary = 0,
    this.reviews = 0,
    this.habits = 0,
    this.commitments = 0,
  });

  int countFor(MissionType type) => switch (type) {
        MissionType.checkIns => checkInDays,
        MissionType.lessons => lessons,
        MissionType.breathing => breathing,
        MissionType.diary => diary,
        MissionType.review => reviews,
        MissionType.habits => habits,
        MissionType.commitment => commitments,
      };
}

class WeeklyMissions {
  static const missionsPerWeek = 3;

  /// Metas alcanzables en una semana normal: la idea es motivar, no agobiar.
  static const catalog = {
    MissionType.checkIns: MissionDef(MissionType.checkIns, 5, 15),
    MissionType.lessons: MissionDef(MissionType.lessons, 3, 15),
    MissionType.breathing: MissionDef(MissionType.breathing, 3, 12),
    MissionType.diary: MissionDef(MissionType.diary, 2, 12),
    MissionType.review: MissionDef(MissionType.review, 3, 12),
    MissionType.habits: MissionDef(MissionType.habits, 5, 12),
    MissionType.commitment: MissionDef(MissionType.commitment, 1, 15),
  };

  /// Lunes de la semana de [date], como `yyyy-MM-dd`: identifica la semana.
  static String weekKey(DateTime date) {
    final monday = DateTime(date.year, date.month, date.day - (date.weekday - 1));
    return '${monday.year}-${monday.month.toString().padLeft(2, '0')}-${monday.day.toString().padLeft(2, '0')}';
  }

  static DateTime weekStart(DateTime date) =>
      DateTime(date.year, date.month, date.day - (date.weekday - 1));

  /// Días que quedan incluyendo hoy (domingo = 1).
  static int daysLeft(DateTime date) => 8 - date.weekday;

  /// Elige las misiones de la semana. Determinista por semana y usuario.
  /// El check-in de ánimo siempre está (es la base de todo lo demás); las otras
  /// dos varían, sin hábitos si el usuario no tiene y sin repaso si todavía no
  /// completó lecciones.
  static List<MissionType> pick({
    required String weekKey,
    required String uid,
    required bool hasHabits,
    required bool reviewAvailable,
  }) {
    final seed = '$uid|$weekKey'.codeUnits.fold<int>(7, (h, c) => (h * 31 + c) & 0x7fffffff);
    final rng = math.Random(seed);
    final pool = [
      MissionType.lessons,
      MissionType.breathing,
      MissionType.diary,
      MissionType.commitment,
      if (reviewAvailable) MissionType.review,
      if (hasHabits) MissionType.habits,
    ]..shuffle(rng);
    return [MissionType.checkIns, ...pool.take(missionsPerWeek - 1)];
  }

  static List<Mission> build({
    required List<MissionType> types,
    required WeekActivity activity,
    required Set<String> claimed,
  }) =>
      [
        for (final t in types)
          Mission(
            def: catalog[t]!,
            progress: activity.countFor(t),
            claimed: claimed.contains(t.name),
          ),
      ];
}
