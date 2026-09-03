import '../../data/models/achievement.dart';
import '../../data/models/user_progress.dart';

// ─── Celebration event types ──────────────────────────────────────────────────
enum CelebrationEventType {
  achievement,
  levelUp,
  streakMilestone,
}

/// Un evento que merece celebración
class CelebrationEvent {
  final CelebrationEventType type;
  final String? achievementId;
  final int? newLevel;
  final int? streakDays;

  const CelebrationEvent({
    required this.type,
    this.achievementId,
    this.newLevel,
    this.streakDays,
  });
}

/// Servicio que detecta logros nuevos comparando estado antes/después.
class AchievementService {
  static const streakMilestones = [7, 14, 30, 50, 100];

  static List<CelebrationEvent> checkForCelebrations({
    required UserProgress? progressBefore,
    required UserProgress progressAfter,
    required int diaryEntries,
    required int habitsCompleted,
    required int moodCheckIns,
    required Set<String> celebratedAchievementIds,
    // ── Parámetros del jardín (opcionales — default 0) ──────────────────
    int plantsInGarden = 0,
    int adultPlantsInGarden = 0,
    int decorationsPlaced = 0,
  }) {
    final events = <CelebrationEvent>[];

    // ── 1. Level up ──────────────────────────────────────────────────────
    final levelBefore = progressBefore?.level ?? 1;
    final levelAfter = progressAfter.level;
    if (levelAfter > levelBefore) {
      events.add(CelebrationEvent(
        type: CelebrationEventType.levelUp,
        newLevel: levelAfter,
      ));
    }

    // ── 2. Streak milestones ─────────────────────────────────────────────
    final streakBefore = progressBefore?.currentStreak ?? 0;
    final streakAfter = progressAfter.currentStreak;
    for (final milestone in streakMilestones) {
      if (streakAfter >= milestone && streakBefore < milestone) {
        events.add(CelebrationEvent(
          type: CelebrationEventType.streakMilestone,
          streakDays: milestone,
        ));
        break;
      }
    }

    // ── 3. Achievements ──────────────────────────────────────────────────
    for (final achievement in Achievement.all) {
      if (celebratedAchievementIds.contains(achievement.id)) continue;

      final isUnlockedNow = achievement.isUnlocked(
        currentStreak: progressAfter.currentStreak,
        longestStreak: progressAfter.longestStreak,
        totalXp: progressAfter.totalXp,
        level: progressAfter.level,
        diaryEntries: diaryEntries,
        habitsCompleted: habitsCompleted,
        moodCheckIns: moodCheckIns,
        // Parámetros de jardín
        totalPlantsEver: plantsInGarden,
        adultPlants: adultPlantsInGarden,
        decorationsPlaced: decorationsPlaced,
      );

      if (isUnlockedNow) {
        events.add(CelebrationEvent(
          type: CelebrationEventType.achievement,
          achievementId: achievement.id,
        ));
      }
    }

    return events;
  }
}