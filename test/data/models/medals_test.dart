import 'package:flutter_test/flutter_test.dart';
import 'package:gimnasio_emocional/data/models/achievement.dart';
import 'package:gimnasio_emocional/data/models/lumi.dart';
import 'package:gimnasio_emocional/data/models/medals.dart';

MedalStatus _find(List<MedalStatus> list, String id) => list.firstWhere((m) => m.id == id);

void main() {
  group('Medals.tiers', () {
    final tiers = Medals.tiers(Achievement.all);

    test('dentro de un tipo: bronce, plata y oro por dificultad', () {
      expect(tiers['xp_100'], MedalTier.bronze);
      expect(tiers['xp_500'], MedalTier.silver);
      expect(tiers['xp_1000'], MedalTier.gold);
      expect(tiers['streak_3'], MedalTier.bronze);
      expect(tiers['streak_30'], MedalTier.gold);
    });

    test('con dos medallas del tipo, la segunda es oro; con una, bronce', () {
      expect(tiers['mood_1'], MedalTier.bronze);
      expect(tiers['mood_30'], MedalTier.gold);
      expect(tiers['garden_first_deco'], MedalTier.bronze);
    });

    test('todas las medallas tienen metal', () {
      expect(tiers.length, Achievement.all.length);
    });
  });

  group('Medals.evaluate', () {
    test('usa el dato de cada tipo, incluidos hábitos, ánimo y jardín', () {
      final medals = Medals.evaluate(const AchievementStats(
        habitsCompleted: 6,
        moodCheckIns: 31,
        plantsInGarden: 5,
        adultPlants: 1,
        decorationsPlaced: 1,
        seenIds: {'habits_5', 'mood_1', 'mood_30', 'garden_first_plant', 'garden_full', 'garden_first_adult', 'garden_first_deco'},
      ));
      for (final id in ['habits_5', 'mood_1', 'mood_30', 'garden_first_plant', 'garden_full', 'garden_first_adult', 'garden_first_deco']) {
        expect(_find(medals, id).unlocked, isTrue, reason: id);
      }
      expect(_find(medals, 'habits_50').unlocked, isFalse);
      expect(_find(medals, 'garden_3_adults').current, 1);
    });

    test('la racha cuenta la mejor, no la actual', () {
      final medals = Medals.evaluate(const AchievementStats(currentStreak: 0, longestStreak: 8));
      expect(_find(medals, 'streak_7').unlocked, isTrue);
      expect(_find(medals, 'streak_14').current, 8);
    });

    test('una medalla nueva es la ganada que no se había visto', () {
      final medals = Medals.evaluate(const AchievementStats(diaryEntries: 1, totalXp: 120, seenIds: {'xp_100'}));
      expect(_find(medals, 'diary_1').isNew, isTrue);
      expect(_find(medals, 'xp_100').isNew, isFalse);
      expect(_find(medals, 'xp_100').unlocked, isTrue);
    });

    test('una medalla ya vista sigue ganada aunque el dato baje', () {
      final medals = Medals.evaluate(const AchievementStats(plantsInGarden: 0, seenIds: {'garden_full'}));
      final full = _find(medals, 'garden_full');
      expect(full.unlocked, isTrue);
      expect(full.isNew, isFalse);
      expect(full.progress, 1);
    });

    test('avance y lo que falta', () {
      final m = _find(Medals.evaluate(const AchievementStats(longestStreak: 5)), 'streak_7');
      expect(m.progress, closeTo(5 / 7, 1e-9));
      expect(m.remaining, 2);
    });
  });

  group('Medals.nextUp y showcase', () {
    test('la próxima es la de más avance; a igual avance, la que menos falta', () {
      final medals = Medals.evaluate(const AchievementStats(longestStreak: 5, totalXp: 90, level: 1, diaryEntries: 0));
      // xp_100 va al 90 % y streak_7 al 71 %
      expect(Medals.nextUp(medals)!.id, 'xp_100');
    });

    test('sin bloqueadas no hay próxima', () {
      final all = {for (final a in Achievement.all) a.id};
      expect(Medals.nextUp(Medals.evaluate(AchievementStats(seenIds: all))), isNull);
    });

    test('la vitrina pone primero las nuevas y luego el mejor metal', () {
      final medals = Medals.evaluate(const AchievementStats(
        totalXp: 1000,
        diaryEntries: 1,
        seenIds: {'xp_100', 'xp_500', 'xp_1000'},
      ));
      final show = Medals.showcase(medals, count: 3);
      expect(show.first.id, 'diary_1');
      expect(show[1].tier, MedalTier.gold);
    });

    test('cuenta medallas por metal', () {
      final medals = Medals.evaluate(const AchievementStats(totalXp: 600));
      final counts = Medals.tierCounts(medals);
      expect(counts[MedalTier.bronze], 1);
      expect(counts[MedalTier.silver], 1);
      expect(counts[MedalTier.gold], 0);
    });
  });

  group('ProfileLumi.lineFor', () {
    test('celebra medallas nuevas primero', () {
      const stats = AchievementStats(diaryEntries: 1, currentStreak: 10);
      final line = ProfileLumi.lineFor(stats, Medals.evaluate(stats));
      expect(line.key, 'profileScreen.lumi.newMedal');
      expect(line.mood, LumiMood.excited);
    });

    test('anima cuando falta poco para la próxima', () {
      const stats = AchievementStats(longestStreak: 2, seenIds: {});
      final line = ProfileLumi.lineFor(stats, Medals.evaluate(stats));
      expect(line.key, 'profileScreen.lumi.almost');
      expect(line.args['count'], '1');
    });

    test('sin actividad invita a empezar', () {
      const stats = AchievementStats(level: 1);
      expect(ProfileLumi.lineFor(stats, Medals.evaluate(stats)).key, 'profileScreen.lumi.start');
    });
  });
}
