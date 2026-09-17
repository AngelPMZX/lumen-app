import 'package:flutter_test/flutter_test.dart';
import 'package:gimnasio_emocional/data/models/weekly_missions.dart';

void main() {
  group('semana', () {
    test('la clave es el lunes de la semana', () {
      expect(WeeklyMissions.weekKey(DateTime(2026, 9, 16)), '2026-09-14'); // miércoles
      expect(WeeklyMissions.weekKey(DateTime(2026, 9, 14)), '2026-09-14'); // lunes
      expect(WeeklyMissions.weekKey(DateTime(2026, 9, 20)), '2026-09-14'); // domingo
      expect(WeeklyMissions.weekKey(DateTime(2026, 9, 21)), '2026-09-21');
    });

    test('cruza meses', () {
      expect(WeeklyMissions.weekKey(DateTime(2026, 10, 2)), '2026-09-28');
    });

    test('días restantes', () {
      expect(WeeklyMissions.daysLeft(DateTime(2026, 9, 14)), 7);
      expect(WeeklyMissions.daysLeft(DateTime(2026, 9, 20)), 1);
    });
  });

  group('pick', () {
    test('3 misiones, siempre incluye check-in y sin repetir', () {
      final types = WeeklyMissions.pick(weekKey: '2026-09-14', uid: 'u1', hasHabits: true, reviewAvailable: true);
      expect(types.length, 3);
      expect(types.first, MissionType.checkIns);
      expect(types.toSet().length, 3);
    });

    test('es estable durante la semana', () {
      List<MissionType> p() => WeeklyMissions.pick(weekKey: '2026-09-14', uid: 'u1', hasHabits: true, reviewAvailable: true);
      expect(p(), p());
    });

    test('no propone hábitos ni repaso si no aplican', () {
      for (int w = 0; w < 30; w++) {
        final types = WeeklyMissions.pick(
          weekKey: 'week$w',
          uid: 'u1',
          hasHabits: false,
          reviewAvailable: false,
        );
        expect(types, isNot(contains(MissionType.habits)));
        expect(types, isNot(contains(MissionType.review)));
      }
    });

    test('varía entre semanas', () {
      final combos = {
        for (int w = 0; w < 20; w++)
          WeeklyMissions.pick(weekKey: 'week$w', uid: 'u1', hasHabits: true, reviewAvailable: true).join(','),
      };
      expect(combos.length, greaterThan(3));
    });
  });

  test('avance, completado y reclamado', () {
    final missions = WeeklyMissions.build(
      types: [MissionType.checkIns, MissionType.lessons, MissionType.diary],
      activity: const WeekActivity(checkInDays: 5, lessons: 1, diary: 4),
      claimed: {'diary'},
    );
    expect(missions[0].claimable, isTrue);
    expect(missions[1].completed, isFalse);
    expect(missions[1].fraction, closeTo(1 / 3, 0.001));
    expect(missions[2].completed, isTrue);
    expect(missions[2].claimable, isFalse);
    expect(missions[2].fraction, 1.0);
  });
}
