import 'achievement.dart';
import 'lumi.dart';

/// Todo lo que cuenta para las medallas y el perfil.
class AchievementStats {
  final int currentStreak;
  final int longestStreak;
  final int totalXp;
  final int level;
  final int diaryEntries;
  final int habitsCompleted;
  final int moodCheckIns;
  final int lessonsCompleted;
  final int plantsInGarden;
  final int adultPlants;
  final int decorationsPlaced;

  /// Medallas ya vistas o celebradas: siguen ganadas aunque el dato baje
  /// (p. ej. si se guarda una planta del jardín).
  final Set<String> seenIds;

  const AchievementStats({
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.totalXp = 0,
    this.level = 1,
    this.diaryEntries = 0,
    this.habitsCompleted = 0,
    this.moodCheckIns = 0,
    this.lessonsCompleted = 0,
    this.plantsInGarden = 0,
    this.adultPlants = 0,
    this.decorationsPlaced = 0,
    this.seenIds = const {},
  });

  int valueFor(AchievementType type) => switch (type) {
        AchievementType.streak => longestStreak,
        AchievementType.xp => totalXp,
        AchievementType.level => level,
        AchievementType.diary => diaryEntries,
        AchievementType.habits => habitsCompleted,
        AchievementType.moods => moodCheckIns,
        AchievementType.gardenPlants => plantsInGarden,
        AchievementType.gardenAdults => adultPlants,
        AchievementType.gardenDecorations => decorationsPlaced,
      };
}

enum MedalCategory { streak, growth, diary, mood, habits, garden }

enum MedalTier { bronze, silver, gold }

class MedalStatus {
  final Achievement achievement;
  final MedalCategory category;
  final MedalTier tier;
  final bool unlocked;

  /// Ganada por primera vez: todavía no se había visto ni celebrado.
  final bool isNew;
  final int current;

  const MedalStatus({
    required this.achievement,
    required this.category,
    required this.tier,
    required this.unlocked,
    required this.isNew,
    required this.current,
  });

  String get id => achievement.id;
  int get requirement => achievement.requirement;
  double get progress => unlocked ? 1 : (current / requirement).clamp(0.0, 1.0);
  int get remaining => unlocked ? 0 : (requirement - current).clamp(0, requirement);
}

class Medals {
  Medals._();

  static MedalCategory categoryOf(AchievementType type) => switch (type) {
        AchievementType.streak => MedalCategory.streak,
        AchievementType.xp || AchievementType.level => MedalCategory.growth,
        AchievementType.diary => MedalCategory.diary,
        AchievementType.moods => MedalCategory.mood,
        AchievementType.habits => MedalCategory.habits,
        AchievementType.gardenPlants || AchievementType.gardenAdults || AchievementType.gardenDecorations => MedalCategory.garden,
      };

  /// Metal de cada medalla según su dificultad dentro del mismo tipo: la
  /// primera es bronce, la segunda plata y desde la tercera oro. Si el tipo
  /// solo tiene dos, la segunda es oro.
  static Map<String, MedalTier> tiers(List<Achievement> all) {
    final byType = <AchievementType, List<Achievement>>{};
    for (final a in all) {
      byType.putIfAbsent(a.type, () => []).add(a);
    }
    final result = <String, MedalTier>{};
    for (final list in byType.values) {
      list.sort((a, b) => a.requirement.compareTo(b.requirement));
      for (int i = 0; i < list.length; i++) {
        final tier = i == 0
            ? MedalTier.bronze
            : (i == list.length - 1 && list.length >= 2)
                ? MedalTier.gold
                : MedalTier.silver;
        result[list[i].id] = tier;
      }
    }
    return result;
  }

  static List<MedalStatus> evaluate(AchievementStats stats, {List<Achievement>? all}) {
    final achievements = all ?? Achievement.all;
    final tierMap = tiers(achievements);
    return [
      for (final a in achievements)
        () {
          final current = stats.valueFor(a.type);
          final reached = current >= a.requirement;
          final seen = stats.seenIds.contains(a.id);
          return MedalStatus(
            achievement: a,
            category: categoryOf(a.type),
            tier: tierMap[a.id]!,
            unlocked: reached || seen,
            isNew: reached && !seen,
            current: current,
          );
        }(),
    ];
  }

  /// La medalla bloqueada más cerca de ganarse (a igual avance, la más fácil).
  static MedalStatus? nextUp(List<MedalStatus> medals) {
    final locked = medals.where((m) => !m.unlocked).toList();
    if (locked.isEmpty) return null;
    locked.sort((a, b) {
      final byProgress = b.progress.compareTo(a.progress);
      return byProgress != 0 ? byProgress : a.remaining.compareTo(b.remaining);
    });
    return locked.first;
  }

  /// Las ganadas para la vitrina: primero las nuevas, luego oro, plata, bronce.
  static List<MedalStatus> showcase(List<MedalStatus> medals, {int count = 4}) {
    final unlocked = medals.where((m) => m.unlocked).toList()
      ..sort((a, b) {
        if (a.isNew != b.isNew) return a.isNew ? -1 : 1;
        return b.tier.index.compareTo(a.tier.index);
      });
    return unlocked.take(count).toList();
  }

  static Map<MedalTier, int> tierCounts(List<MedalStatus> medals) => {
        for (final t in MedalTier.values) t: medals.where((m) => m.unlocked && m.tier == t).length,
      };
}

/// Qué dice Lumi en el perfil.
class ProfileLumi {
  ProfileLumi._();

  static LumiLine lineFor(AchievementStats stats, List<MedalStatus> medals) {
    final newOnes = medals.where((m) => m.isNew).length;
    if (newOnes > 0) {
      return LumiLine(newOnes == 1 ? 'profileScreen.lumi.newMedal' : 'profileScreen.lumi.newMedals', LumiMood.excited, {'count': '$newOnes'});
    }
    if (medals.isNotEmpty && medals.every((m) => m.unlocked)) {
      return const LumiLine('profileScreen.lumi.allMedals', LumiMood.proud);
    }
    final next = Medals.nextUp(medals);
    if (next != null && next.progress >= 0.6) {
      return LumiLine('profileScreen.lumi.almost', LumiMood.curious, {'count': '${next.remaining}'});
    }
    if (stats.currentStreak >= 3) {
      return LumiLine('profileScreen.lumi.streak', LumiMood.proud, {'days': '${stats.currentStreak}'});
    }
    if (stats.totalXp == 0 && stats.diaryEntries == 0 && stats.moodCheckIns == 0) {
      return const LumiLine('profileScreen.lumi.start', LumiMood.happy);
    }
    return const LumiLine('profileScreen.lumi.journey', LumiMood.happy);
  }
}
