import '../../data/models/achievement.dart';
import '../../data/models/user_progress.dart';

/// Tipos de eventos celebrables
enum CelebrationEventType {
  achievement,
  levelUp,
  streakMilestone,
}

/// Un evento que merece celebración (dialog con confetti)
class CelebrationEvent {
  final CelebrationEventType type;
  final String? achievementId; // solo para achievements
  final int? newLevel; // solo para level up
  final int? streakDays; // solo para streak milestone

  const CelebrationEvent({
    required this.type,
    this.achievementId,
    this.newLevel,
    this.streakDays,
  });
}

/// Servicio que detecta logros nuevos comparando estado antes/después
class AchievementService {
  /// Milestones de racha que celebramos
  static const streakMilestones = [7, 14, 30, 50, 100];

  /// Compara el estado antes y después de una acción y retorna
  /// los eventos que merecen celebración
  static List<CelebrationEvent> checkForCelebrations({
    required UserProgress? progressBefore,
    required UserProgress progressAfter,
    required int diaryEntries,
    required int habitsCompleted,
    required int moodCheckIns,
  }) {
    final events = <CelebrationEvent>[];

    // 1. Verificar subida de nivel
    final levelBefore = progressBefore?.level ?? 1;
    final levelAfter = progressAfter.level;
    if (levelAfter > levelBefore) {
      events.add(CelebrationEvent(
        type: CelebrationEventType.levelUp,
        newLevel: levelAfter,
      ));
    }

    // 2. Verificar streak milestones
    final streakBefore = progressBefore?.currentStreak ?? 0;
    final streakAfter = progressAfter.currentStreak;
    for (final milestone in streakMilestones) {
      if (streakAfter >= milestone && streakBefore < milestone) {
        events.add(CelebrationEvent(
          type: CelebrationEventType.streakMilestone,
          streakDays: milestone,
        ));
        break; // Solo un milestone a la vez
      }
    }

    // 3. Verificar achievements nuevos
    final allAchievements = Achievement.all;

    for (final achievement in allAchievements) {
      final wasUnlockedBefore = progressBefore != null &&
          achievement.isUnlocked(
            currentStreak: progressBefore.currentStreak,
            longestStreak: progressBefore.longestStreak,
            totalXp: progressBefore.totalXp,
            level: progressBefore.level,
            diaryEntries: diaryEntries > 0 ? diaryEntries - 1 : 0,
            habitsCompleted: habitsCompleted > 0 ? habitsCompleted - 1 : 0,
            moodCheckIns: moodCheckIns > 0 ? moodCheckIns - 1 : 0,
          );

      final isUnlockedNow = achievement.isUnlocked(
        currentStreak: progressAfter.currentStreak,
        longestStreak: progressAfter.longestStreak,
        totalXp: progressAfter.totalXp,
        level: progressAfter.level,
        diaryEntries: diaryEntries,
        habitsCompleted: habitsCompleted,
        moodCheckIns: moodCheckIns,
      );

      if (isUnlockedNow && !wasUnlockedBefore) {
        events.add(CelebrationEvent(
          type: CelebrationEventType.achievement,
          achievementId: achievement.id,
        ));
      }
    }

    return events;
  }
}