/// Lumi: la pequeña luz que acompaña al usuario en Lumen.
///
/// Personalidad: cálida, curiosa y un poco juguetona. Nunca juzga, nunca
/// regaña y habla con lenguaje neutro en género.
enum LumiMood { happy, excited, calm, sleepy, proud, caring, curious }

/// Lo que Lumi dice: clave de traducción, argumentos y expresión.
class LumiLine {
  final String key;
  final Map<String, String> args;
  final LumiMood mood;

  const LumiLine(this.key, this.mood, [this.args = const {}]);
}

/// Datos del día que Lumi usa para decidir qué decir en el Home.
class LumiContext {
  final String name;
  final int hour;
  final bool introSeen;

  /// null si todavía no hizo check-in hoy; si no, la categoría del ánimo
  /// (`positive`, `neutral`, `negative`).
  final String? todayMoodCategory;
  final int streak;
  final bool streakBroken;
  final bool hasPendingCommitment;
  final bool lessonDoneToday;
  final String? nextLessonTitle;
  final bool reviewAvailable;
  final bool reviewDoneToday;

  const LumiContext({
    required this.name,
    required this.hour,
    required this.introSeen,
    required this.todayMoodCategory,
    required this.streak,
    required this.streakBroken,
    required this.hasPendingCommitment,
    required this.lessonDoneToday,
    required this.nextLessonTitle,
    required this.reviewAvailable,
    required this.reviewDoneToday,
  });
}

class LumiDialog {
  /// Frases al tocar a Lumi (claves `lumi.tap.0` … `lumi.tap.N`).
  static const tapLineCount = 12;

  /// Qué dice Lumi al abrir el Home. El orden es la prioridad: primero lo que
  /// más cuida al usuario (presentarse, la noche, volver tras perder la racha,
  /// un día difícil) y después lo que lo invita a seguir.
  static LumiLine forHome(LumiContext c) {
    final name = {'name': c.name};

    if (!c.introSeen) return LumiLine('lumi.intro', LumiMood.excited, name);

    if (c.hour >= 23 || c.hour < 5) return LumiLine('lumi.night', LumiMood.sleepy, name);

    if (c.streakBroken && c.todayMoodCategory == null) {
      return LumiLine('lumi.welcomeBack', LumiMood.caring, name);
    }

    if (c.todayMoodCategory == null) {
      final key = c.hour < 12 ? 'lumi.askMoodMorning' : 'lumi.askMood';
      return LumiLine(key, LumiMood.curious, name);
    }

    if (c.todayMoodCategory == 'negative') return LumiLine('lumi.hardDay', LumiMood.caring, name);

    if (c.hasPendingCommitment) return const LumiLine('lumi.commitment', LumiMood.curious);

    if (c.streak >= 3 && _isStreakMilestone(c.streak)) {
      return LumiLine('lumi.streak', LumiMood.proud, {'n': '${c.streak}'});
    }

    if (!c.lessonDoneToday && c.nextLessonTitle != null) {
      return LumiLine('lumi.nextLesson', LumiMood.excited, {'lesson': c.nextLessonTitle!});
    }

    if (c.reviewAvailable && !c.reviewDoneToday) return const LumiLine('lumi.review', LumiMood.happy);

    if (c.lessonDoneToday) return LumiLine('lumi.allDone', LumiMood.proud, name);

    if (c.todayMoodCategory == 'positive') return LumiLine('lumi.goodMood', LumiMood.happy, name);

    return LumiLine('lumi.default', LumiMood.calm, name);
  }

  /// La racha se celebra en 3, 5, 7 y después cada 7 días, para que no
  /// pierda valor si Lumi la repite todos los días.
  static bool _isStreakMilestone(int streak) =>
      streak == 3 || streak == 5 || (streak >= 7 && streak % 7 == 0);

  /// Frase al tocar a Lumi, rotando sin repetir la anterior.
  static LumiLine tap(int count) {
    final index = count % tapLineCount;
    const moods = [
      LumiMood.happy,
      LumiMood.excited,
      LumiMood.curious,
      LumiMood.calm,
      LumiMood.proud,
      LumiMood.caring,
    ];
    return LumiLine('lumi.tap.$index', moods[index % moods.length]);
  }
}
