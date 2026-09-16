import 'package:flutter_test/flutter_test.dart';
import 'package:gimnasio_emocional/data/models/mood_entry.dart';
import 'package:gimnasio_emocional/data/models/weekly_summary.dart';

void main() {
  final now = DateTime(2026, 9, 16, 20);
  DateTime daysAgo(int n, [int hour = 10]) => DateTime(now.year, now.month, now.day - n, hour);

  WeeklySummary compute({
    List<(DateTime, MoodType)> moods = const [],
    List<DateTime> lessons = const [],
    List<DateTime> breathing = const [],
    List<DateTime> diary = const [],
    List<DateTime> habits = const [],
  }) =>
      WeeklySummary.compute(
        now: now,
        moods: moods,
        lessons: lessons,
        breathing: breathing,
        diary: diary,
        habits: habits,
        commitmentsDone: 0,
      );

  group('lastDays', () {
    test('devuelve 7 días terminando hoy, del más antiguo al más reciente', () {
      final days = WeeklySummary.lastDays(now, 7);
      expect(days.length, 7);
      expect(days.first, '2026-09-10');
      expect(days.last, '2026-09-16');
    });

    test('cruza meses correctamente', () {
      final days = WeeklySummary.lastDays(DateTime(2026, 3, 2), 3);
      expect(days, ['2026-02-28', '2026-03-01', '2026-03-02']);
    });
  });

  test('usa el último ánimo de cada día y cuenta solo la semana', () {
    final s = compute(moods: [
      (daysAgo(0, 9), MoodType.sad),
      (daysAgo(0, 21), MoodType.happy),
      (daysAgo(10), MoodType.angry), // fuera de la semana
    ]);
    expect(s.dayMoods['2026-09-16'], MoodType.happy);
    expect(s.checkInDays, 1);
    expect(s.moodCounts.containsKey(MoodType.angry), isFalse);
  });

  test('detecta la emoción difícil que se repite', () {
    final s = compute(moods: [
      (daysAgo(0), MoodType.anxious),
      (daysAgo(1), MoodType.anxious),
      (daysAgo(2), MoodType.happy),
    ]);
    expect(s.recurringHardMood, MoodType.anxious);
    expect(s.negativeDays, 2);
  });

  test('una emoción difícil de un solo día no genera recomendación', () {
    final s = compute(moods: [(daysAgo(0), MoodType.sad), (daysAgo(1), MoodType.happy)]);
    expect(s.recurringHardMood, isNull);
  });

  test('tendencia: mejora respecto a la semana anterior', () {
    final s = compute(moods: [
      for (int i = 7; i < 14; i++) (daysAgo(i), MoodType.sad),
      for (int i = 0; i < 7; i++) (daysAgo(i), MoodType.happy),
    ]);
    expect(s.trend, MoodTrend.up);
  });

  test('tendencia desconocida sin datos de la semana anterior', () {
    final s = compute(moods: [(daysAgo(0), MoodType.happy), (daysAgo(1), MoodType.happy)]);
    expect(s.trend, MoodTrend.unknown);
  });

  test('encuentra un patrón cuando los días con respiración son mejores', () {
    final moods = <(DateTime, MoodType)>[];
    final breathing = <DateTime>[];
    for (int i = 0; i < 12; i++) {
      final withBreathing = i.isEven;
      moods.add((daysAgo(i), withBreathing ? MoodType.calm : MoodType.stressed));
      if (withBreathing) breathing.add(daysAgo(i, 8));
    }
    final s = compute(moods: moods, breathing: breathing);
    expect(s.insights, isNotEmpty);
    expect(s.insights.first.activity, SummaryActivity.breathing);
    expect(s.insights.first.difference, closeTo(2, 0.001));
  });

  test('no inventa patrones con pocos días', () {
    final s = compute(
      moods: [(daysAgo(0), MoodType.happy), (daysAgo(1), MoodType.sad)],
      breathing: [daysAgo(0)],
    );
    expect(s.insights, isEmpty);
  });

  test('no muestra patrones si la diferencia es mínima', () {
    final moods = <(DateTime, MoodType)>[];
    final diary = <DateTime>[];
    for (int i = 0; i < 10; i++) {
      moods.add((daysAgo(i), MoodType.neutral));
      if (i.isEven) diary.add(daysAgo(i));
    }
    expect(compute(moods: moods, diary: diary).insights, isEmpty);
  });

  test('cuenta actividades solo dentro de la semana', () {
    final s = compute(
      lessons: [daysAgo(0), daysAgo(3), daysAgo(9)],
      breathing: [daysAgo(1), daysAgo(1, 18)],
    );
    expect(s.lessons, 2);
    expect(s.breathingSessions, 2);
  });
}
