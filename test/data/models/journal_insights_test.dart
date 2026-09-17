import 'package:flutter_test/flutter_test.dart';
import 'package:gimnasio_emocional/data/models/diary_entry.dart';
import 'package:gimnasio_emocional/data/models/journal_insights.dart';
import 'package:gimnasio_emocional/data/models/mood_entry.dart';

DiaryEntry _entry(DateTime at, [MoodType mood = MoodType.calm]) =>
    DiaryEntry(id: '${at.millisecondsSinceEpoch}', mood: mood, text: 'x', createdAt: at);

void main() {
  final now = DateTime(2026, 9, 17, 21, 30);

  group('DiaryInsights', () {
    test('racha con hoy escrito', () {
      final i = DiaryInsights([
        _entry(DateTime(2026, 9, 17, 8)),
        _entry(DateTime(2026, 9, 16, 23)),
        _entry(DateTime(2026, 9, 15, 7)),
        _entry(DateTime(2026, 9, 13, 7)),
      ], now: now);
      expect(i.wroteToday, isTrue);
      expect(i.streak, 3);
    });

    test('la racha sigue viva si hoy aún no escribe', () {
      final i = DiaryInsights([
        _entry(DateTime(2026, 9, 16, 9)),
        _entry(DateTime(2026, 9, 15, 9)),
      ], now: now);
      expect(i.wroteToday, isFalse);
      expect(i.streak, 2);
    });

    test('sin entrada ayer ni hoy la racha es 0', () {
      final i = DiaryInsights([_entry(DateTime(2026, 9, 14))], now: now);
      expect(i.streak, 0);
    });

    test('varias entradas el mismo día cuentan una vez', () {
      final i = DiaryInsights([
        _entry(DateTime(2026, 9, 17, 8)),
        _entry(DateTime(2026, 9, 17, 20)),
      ], now: now);
      expect(i.streak, 1);
      expect(i.groupedByDay.single.$2.length, 2);
      expect(i.groupedByDay.single.$2.first.createdAt.hour, 20);
    });

    test('ánimo más frecuente del último mes y entradas del mes', () {
      final i = DiaryInsights([
        _entry(DateTime(2026, 9, 17), MoodType.happy),
        _entry(DateTime(2026, 9, 10), MoodType.happy),
        _entry(DateTime(2026, 9, 2), MoodType.anxious),
        _entry(DateTime(2026, 8, 30), MoodType.anxious),
        _entry(DateTime(2026, 7, 1), MoodType.anxious),
      ], now: now);
      expect(i.topMood, MoodType.happy);
      expect(i.entriesThisMonth, 3);
    });

    test('agrupa por día del más reciente al más antiguo', () {
      final i = DiaryInsights([
        _entry(DateTime(2026, 9, 10)),
        _entry(DateTime(2026, 9, 17)),
        _entry(DateTime(2026, 9, 12)),
      ], now: now);
      expect(i.groupedByDay.map((g) => g.$1.day), [17, 12, 10]);
    });
  });

  group('HabitHistory', () {
    test('racha, hoy y última semana', () {
      final h = HabitHistory([
        DateTime(2026, 9, 17),
        DateTime(2026, 9, 16),
        DateTime(2026, 9, 14),
      ], now: now);
      expect(h.doneToday, isTrue);
      expect(h.streak, 2);
      expect(h.lastWeek.length, 7);
      expect(h.lastWeek.last.$1, DateTime(2026, 9, 17));
      expect(h.lastWeek.map((d) => d.$2), [false, false, false, true, false, true, true]);
    });

    test('parsea ids de check-in aunque el id del hábito tenga guiones bajos', () {
      final parsed = HabitHistory.parseDocId('preset_no_social_2026-09-07');
      expect(parsed!.$1, 'preset_no_social');
      expect(parsed.$2, DateTime(2026, 9, 7));
      expect(HabitHistory.parseDocId('mal'), isNull);
    });
  });
}
