import 'package:flutter/material.dart';

/// Modelo de un logro/medalla desbloqueable
class Achievement {
  final String id;
  final String title;
  final String description;
  final String? titleKey;
  final String? descriptionKey;
  final String emoji;
  final Color color;
  final AchievementType type;
  final int requirement; // Número requerido para desbloquear

  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    this.titleKey,
    this.descriptionKey,
    required this.emoji,
    required this.color,
    required this.type,
    required this.requirement,
  });

  /// Verifica si el logro está desbloqueado según el progreso
  bool isUnlocked({
    required int currentStreak,
    required int longestStreak,
    required int totalXp,
    required int level,
    required int diaryEntries,
    required int habitsCompleted,
    required int moodCheckIns,
  }) {
    switch (type) {
      case AchievementType.streak:
        return longestStreak >= requirement;
      case AchievementType.xp:
        return totalXp >= requirement;
      case AchievementType.level:
        return level >= requirement;
      case AchievementType.diary:
        return diaryEntries >= requirement;
      case AchievementType.habits:
        return habitsCompleted >= requirement;
      case AchievementType.moods:
        return moodCheckIns >= requirement;
    }
  }

  /// Calcula el progreso (0.0 - 1.0) hacia el logro
  double progress({
    required int currentStreak,
    required int longestStreak,
    required int totalXp,
    required int level,
    required int diaryEntries,
    required int habitsCompleted,
    required int moodCheckIns,
  }) {
    int current;
    switch (type) {
      case AchievementType.streak:
        current = longestStreak;
      case AchievementType.xp:
        current = totalXp;
      case AchievementType.level:
        current = level;
      case AchievementType.diary:
        current = diaryEntries;
      case AchievementType.habits:
        current = habitsCompleted;
      case AchievementType.moods:
        current = moodCheckIns;
    }
    return (current / requirement).clamp(0.0, 1.0);
  }

  /// Todos los logros disponibles
  static List<Achievement> get all => [
        const Achievement(
          id: 'streak_3',
          title: 'Constante',
          description: '3 días de racha',
          titleKey: 'achievements.streak3.title',
          descriptionKey: 'achievements.streak3.description',
          emoji: '🔥',
          color: Color(0xFFF59E0B),
          type: AchievementType.streak,
          requirement: 3,
        ),
        const Achievement(
          id: 'streak_7',
          title: 'Semana Perfecta',
          description: '7 días de racha',
          titleKey: 'achievements.streak7.title',
          descriptionKey: 'achievements.streak7.description',
          emoji: '⚡',
          color: Color(0xFFF97316),
          type: AchievementType.streak,
          requirement: 7,
        ),
        const Achievement(
          id: 'streak_14',
          title: 'Imparable',
          description: '14 días de racha',
          titleKey: 'achievements.streak14.title',
          descriptionKey: 'achievements.streak14.description',
          emoji: '💪',
          color: Color(0xFFEF4444),
          type: AchievementType.streak,
          requirement: 14,
        ),
        const Achievement(
          id: 'streak_30',
          title: 'Maestro del Hábito',
          description: '30 días de racha',
          titleKey: 'achievements.streak30.title',
          descriptionKey: 'achievements.streak30.description',
          emoji: '👑',
          color: Color(0xFFDC2626),
          type: AchievementType.streak,
          requirement: 30,
        ),
        const Achievement(
          id: 'xp_100',
          title: 'Primer Centenario',
          description: 'Alcanza 100 XP',
          titleKey: 'achievements.xp100.title',
          descriptionKey: 'achievements.xp100.description',
          emoji: '💎',
          color: Color(0xFF3B82F6),
          type: AchievementType.xp,
          requirement: 100,
        ),
        const Achievement(
          id: 'xp_500',
          title: 'Medio Millar',
          description: 'Alcanza 500 XP',
          titleKey: 'achievements.xp500.title',
          descriptionKey: 'achievements.xp500.description',
          emoji: '🏆',
          color: Color(0xFF6366F1),
          type: AchievementType.xp,
          requirement: 500,
        ),
        const Achievement(
          id: 'xp_1000',
          title: 'Leyenda',
          description: 'Alcanza 1000 XP',
          titleKey: 'achievements.xp1000.title',
          descriptionKey: 'achievements.xp1000.description',
          emoji: '🌟',
          color: Color(0xFF8B5CF6),
          type: AchievementType.xp,
          requirement: 1000,
        ),
        const Achievement(
          id: 'level_2',
          title: 'Subiendo',
          description: 'Alcanza nivel 2',
          titleKey: 'achievements.level2.title',
          descriptionKey: 'achievements.level2.description',
          emoji: '📈',
          color: Color(0xFF10B981),
          type: AchievementType.level,
          requirement: 2,
        ),
        const Achievement(
          id: 'level_5',
          title: 'Escalador',
          description: 'Alcanza nivel 5',
          titleKey: 'achievements.level5.title',
          descriptionKey: 'achievements.level5.description',
          emoji: '🧗',
          color: Color(0xFF059669),
          type: AchievementType.level,
          requirement: 5,
        ),
        const Achievement(
          id: 'level_10',
          title: 'Veterano',
          description: 'Alcanza nivel 10',
          titleKey: 'achievements.level10.title',
          descriptionKey: 'achievements.level10.description',
          emoji: '🎖️',
          color: Color(0xFF047857),
          type: AchievementType.level,
          requirement: 10,
        ),
        const Achievement(
          id: 'diary_1',
          title: 'Primera Reflexión',
          description: 'Escribe tu primera entrada',
          titleKey: 'achievements.diary1.title',
          descriptionKey: 'achievements.diary1.description',
          emoji: '📝',
          color: Color(0xFF10B981),
          type: AchievementType.diary,
          requirement: 1,
        ),
        const Achievement(
          id: 'diary_10',
          title: 'Escritor Frecuente',
          description: '10 entradas en el diario',
          titleKey: 'achievements.diary10.title',
          descriptionKey: 'achievements.diary10.description',
          emoji: '📖',
          color: Color(0xFF059669),
          type: AchievementType.diary,
          requirement: 10,
        ),
        const Achievement(
          id: 'diary_50',
          title: 'Diario Personal',
          description: '50 entradas en el diario',
          titleKey: 'achievements.diary50.title',
          descriptionKey: 'achievements.diary50.description',
          emoji: '📚',
          color: Color(0xFF047857),
          type: AchievementType.diary,
          requirement: 50,
        ),
        const Achievement(
          id: 'mood_1',
          title: 'Auto-Consciente',
          description: 'Tu primer check-in de ánimo',
          titleKey: 'achievements.mood1.title',
          descriptionKey: 'achievements.mood1.description',
          emoji: '😊',
          color: Color(0xFFEC4899),
          type: AchievementType.moods,
          requirement: 1,
        ),
        const Achievement(
          id: 'mood_30',
          title: 'Observador Emocional',
          description: '30 check-ins de ánimo',
          titleKey: 'achievements.mood30.title',
          descriptionKey: 'achievements.mood30.description',
          emoji: '🧠',
          color: Color(0xFFDB2777),
          type: AchievementType.moods,
          requirement: 30,
        ),
        const Achievement(
          id: 'habits_5',
          title: 'En Marcha',
          description: 'Completa 5 hábitos',
          titleKey: 'achievements.habits5.title',
          descriptionKey: 'achievements.habits5.description',
          emoji: '✅',
          color: Color(0xFF8B5CF6),
          type: AchievementType.habits,
          requirement: 5,
        ),
        const Achievement(
          id: 'habits_50',
          title: 'Disciplinado',
          description: 'Completa 50 hábitos',
          titleKey: 'achievements.habits50.title',
          descriptionKey: 'achievements.habits50.description',
          emoji: '🎯',
          color: Color(0xFF7C3AED),
          type: AchievementType.habits,
          requirement: 50,
        ),
      ];
}

enum AchievementType {
  streak,
  xp,
  level,
  diary,
  habits,
  moods,
}