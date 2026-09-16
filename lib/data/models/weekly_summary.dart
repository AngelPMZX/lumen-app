import 'mood_entry.dart';

/// Actividades que se cruzan con el ánimo para buscar patrones.
enum SummaryActivity { breathing, lesson, diary, habit }

/// Cómo cambió el ánimo promedio respecto a la semana anterior.
enum MoodTrend { up, same, down, unknown }

/// "Los días que hiciste X, tu ánimo fue mejor": patrón encontrado en los
/// datos del propio usuario.
class ActivityInsight {
  final SummaryActivity activity;

  /// Ánimo promedio (1 difícil · 2 neutral · 3 positivo) con y sin actividad.
  final double moodWith;
  final double moodWithout;
  final int daysWith;
  final int daysWithout;

  const ActivityInsight({
    required this.activity,
    required this.moodWith,
    required this.moodWithout,
    required this.daysWith,
    required this.daysWithout,
  });

  double get difference => moodWith - moodWithout;
}

/// Resumen de los últimos 7 días. Se calcula en el teléfono con los datos del
/// usuario: nada de esto se envía a terceros.
class WeeklySummary {
  /// Días necesarios en cada grupo (con / sin actividad) para mostrar un patrón.
  static const minDaysPerGroup = 3;

  /// Diferencia mínima de ánimo promedio para considerarla un patrón (escala 1-3).
  static const minDifference = 0.35;

  /// Días de la semana (del más antiguo a hoy), como `yyyy-MM-dd`.
  final List<String> days;

  /// Ánimo representativo de cada día (el último registrado ese día).
  final Map<String, MoodType> dayMoods;
  final Map<MoodType, int> moodCounts;
  final MoodType? dominantMood;

  /// Emoción difícil que se repitió al menos 2 días (para recomendar).
  final MoodType? recurringHardMood;
  final MoodTrend trend;
  final String? bestDay;
  final int negativeDays;

  final int lessons;
  final int breathingSessions;
  final int diaryEntries;
  final int habitsDone;
  final int commitmentsDone;

  final List<ActivityInsight> insights;

  const WeeklySummary({
    required this.days,
    required this.dayMoods,
    required this.moodCounts,
    required this.dominantMood,
    required this.recurringHardMood,
    required this.trend,
    required this.bestDay,
    required this.negativeDays,
    required this.lessons,
    required this.breathingSessions,
    required this.diaryEntries,
    required this.habitsDone,
    required this.commitmentsDone,
    required this.insights,
  });

  int get checkInDays => dayMoods.length;
  bool get hasMoodData => checkInDays >= 2;
  int get totalActivities => lessons + breathingSessions + diaryEntries + habitsDone + commitmentsDone;

  static String dayKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static int moodScore(MoodType mood) => switch (mood.category) {
        'positive' => 3,
        'negative' => 1,
        _ => 2,
      };

  /// Últimos [count] días de calendario hasta [now] incluido, del más antiguo
  /// al más reciente. `DateTime(y, m, d - i)` evita errores en cambios de horario.
  static List<String> lastDays(DateTime now, int count) => [
        for (int i = count - 1; i >= 0; i--)
          dayKey(DateTime(now.year, now.month, now.day - i)),
      ];

  /// Calcula el resumen. Cada lista trae fechas locales de los últimos 28 días
  /// (o más: lo que sobre se ignora).
  static WeeklySummary compute({
    required DateTime now,
    required List<(DateTime, MoodType)> moods,
    required List<DateTime> lessons,
    required List<DateTime> breathing,
    required List<DateTime> diary,
    required List<DateTime> habits,
    required int commitmentsDone,
  }) {
    final week = lastDays(now, 7);
    final previousWeek = lastDays(DateTime(now.year, now.month, now.day - 7), 7);
    final month = lastDays(now, 28).toSet();
    final weekSet = week.toSet();

    // Ánimo por día: el último registro del día
    final sortedMoods = [...moods]..sort((a, b) => a.$1.compareTo(b.$1));
    final moodByDay = <String, MoodType>{};
    for (final (date, mood) in sortedMoods) {
      final key = dayKey(date);
      if (month.contains(key)) moodByDay[key] = mood;
    }

    final dayMoods = {
      for (final d in week)
        if (moodByDay.containsKey(d)) d: moodByDay[d]!,
    };

    final moodCounts = <MoodType, int>{};
    for (final (date, mood) in moods) {
      if (weekSet.contains(dayKey(date))) {
        moodCounts[mood] = (moodCounts[mood] ?? 0) + 1;
      }
    }

    MoodType? dominant;
    if (moodCounts.isNotEmpty) {
      dominant = moodCounts.entries.reduce((a, b) => b.value > a.value ? b : a).key;
    }

    MoodType? recurringHard;
    final hardCounts = moodCounts.entries
        .where((e) => moodScore(e.key) == 1 || e.key == MoodType.tired || e.key == MoodType.bored)
        .where((e) => e.value >= 2)
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    if (hardCounts.isNotEmpty) recurringHard = hardCounts.first.key;

    double? average(Iterable<String> keys) {
      final scores = keys.where(moodByDay.containsKey).map((k) => moodScore(moodByDay[k]!)).toList();
      if (scores.isEmpty) return null;
      return scores.reduce((a, b) => a + b) / scores.length;
    }

    final thisAvg = average(week);
    final prevAvg = average(previousWeek);
    var trend = MoodTrend.unknown;
    if (thisAvg != null && prevAvg != null && dayMoods.length >= 2) {
      final diff = thisAvg - prevAvg;
      trend = diff >= 0.25 ? MoodTrend.up : (diff <= -0.25 ? MoodTrend.down : MoodTrend.same);
    }

    String? bestDay;
    for (final d in week) {
      final mood = dayMoods[d];
      if (mood == null) continue;
      if (bestDay == null || moodScore(mood) > moodScore(dayMoods[bestDay]!)) bestDay = d;
    }

    Set<String> keysOf(List<DateTime> dates) => dates.map(dayKey).toSet();
    int countInWeek(List<DateTime> dates) =>
        dates.where((d) => weekSet.contains(dayKey(d))).length;

    // Patrones: ánimo en días con la actividad vs. días sin ella (28 días)
    final activityDays = {
      SummaryActivity.breathing: keysOf(breathing),
      SummaryActivity.lesson: keysOf(lessons),
      SummaryActivity.diary: keysOf(diary),
      SummaryActivity.habit: keysOf(habits),
    };
    final insights = <ActivityInsight>[];
    for (final entry in activityDays.entries) {
      final withDays = moodByDay.keys.where(entry.value.contains).toList();
      final withoutDays = moodByDay.keys.where((k) => !entry.value.contains(k)).toList();
      if (withDays.length < minDaysPerGroup || withoutDays.length < minDaysPerGroup) continue;
      final insight = ActivityInsight(
        activity: entry.key,
        moodWith: average(withDays)!,
        moodWithout: average(withoutDays)!,
        daysWith: withDays.length,
        daysWithout: withoutDays.length,
      );
      if (insight.difference >= minDifference) insights.add(insight);
    }
    insights.sort((a, b) => b.difference.compareTo(a.difference));

    return WeeklySummary(
      days: week,
      dayMoods: dayMoods,
      moodCounts: moodCounts,
      dominantMood: dominant,
      recurringHardMood: recurringHard,
      trend: trend,
      bestDay: bestDay,
      negativeDays: dayMoods.values.where((m) => moodScore(m) == 1).length,
      lessons: countInWeek(lessons),
      breathingSessions: countInWeek(breathing),
      diaryEntries: countInWeek(diary),
      habitsDone: countInWeek(habits),
      commitmentsDone: commitmentsDone,
      insights: insights.take(2).toList(),
    );
  }

  /// Lecciones sugeridas según la emoción difícil que más se repitió.
  static const recommendedLessons = {
    MoodType.anxious: ['emo_9', 'mind_4', 'res_5'],
    MoodType.stressed: ['res_7', 'mind_2', 'emo_5'],
    MoodType.sad: ['emo_7', 'est_6', 'res_6'],
    MoodType.angry: ['emo_8', 'emo_5', 'rel_4'],
    MoodType.lonely: ['amor_8', 'rel_8', 'res_6'],
    MoodType.tired: ['res_8', 'auto_5'],
    MoodType.bored: ['auto_1', 'auto_10'],
  };
}
