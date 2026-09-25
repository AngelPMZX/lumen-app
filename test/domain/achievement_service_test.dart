import 'package:flutter_test/flutter_test.dart';
import 'package:gimnasio_emocional/data/models/user_progress.dart';
import 'package:gimnasio_emocional/domain/services/achievement_service.dart';

/// Qué se celebra y qué no.
///
/// Las medallas volvían a salir aunque ya hubieran salido: la lista de las ya
/// celebradas se quedaba **vacía** cuando no se podía leer, y con una lista
/// vacía todo lo ganado cuenta como nuevo. Ahora "no se pudo leer" es `null`
/// —distinto de "ninguna"— y entonces no se celebra ninguna medalla.
void main() {
  List<CelebrationEvent> check({
    required UserProgress before,
    required UserProgress after,
    required Set<String>? celebrated,
    int diaryEntries = 0,
  }) =>
      AchievementService.checkForCelebrations(
        progressBefore: before,
        progressAfter: after,
        diaryEntries: diaryEntries,
        habitsCompleted: 0,
        moodCheckIns: 0,
        celebratedAchievementIds: celebrated,
      );

  Iterable<String> medalsOf(List<CelebrationEvent> events) => events
      .where((e) => e.type == CelebrationEventType.achievement)
      .map((e) => e.achievementId!);

  group('medallas', () {
    test('una medalla nueva se celebra', () {
      final events = check(
        before: UserProgress(totalXp: 80),
        after: UserProgress(totalXp: 120),
        celebrated: {},
      );
      expect(medalsOf(events), contains('xp_100'));
    });

    test('una medalla ya celebrada no vuelve a salir', () {
      final events = check(
        before: UserProgress(totalXp: 120),
        after: UserProgress(totalXp: 140),
        celebrated: {'xp_100'},
      );
      expect(medalsOf(events), isEmpty);
    });

    test('sin saber cuáles ya salieron, no se celebra ninguna', () {
      final events = check(
        before: UserProgress(totalXp: 1000, level: 11),
        after: UserProgress(totalXp: 1020, level: 11),
        celebrated: null,
        diaryEntries: 60,
      );
      expect(medalsOf(events), isEmpty);
    });

    test('pero el nivel y la racha sí se celebran', () {
      final events = check(
        before: UserProgress(totalXp: 90, currentStreak: 6, longestStreak: 6),
        after: UserProgress(
            totalXp: 110, level: 2, currentStreak: 7, longestStreak: 7),
        celebrated: null,
      );
      expect(
        events.map((e) => e.type),
        containsAll(<CelebrationEventType>[
          CelebrationEventType.levelUp,
          CelebrationEventType.streakMilestone,
        ]),
      );
      expect(medalsOf(events), isEmpty);
    });
  });

  test('el hito de racha no se repite si la racha no cruza otro', () {
    final events = check(
      before: UserProgress(currentStreak: 8, longestStreak: 8),
      after: UserProgress(currentStreak: 9, longestStreak: 9),
      celebrated: {},
    );
    expect(
      events.where((e) => e.type == CelebrationEventType.streakMilestone),
      isEmpty,
    );
  });
}
