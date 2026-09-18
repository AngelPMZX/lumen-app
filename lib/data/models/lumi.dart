/// Lumi: la pequeña luz que acompaña al usuario en Lumen.
///
/// Personalidad: cálida, curiosa y un poco juguetona. Nunca juzga, nunca
/// regaña y habla con lenguaje neutro en género.
enum LumiMood { happy, excited, calm, sleepy, proud, caring, curious }

/// Lo que Lumi propone cuando su frase invita a hacer algo.
///
/// Existe porque Lumi decía "¿una respiración corta antes de dormir?" y
/// tocarla solo cambiaba la frase: proponía algo y no llevaba a ningún lado.
enum LumiAction {
  /// Respiración guiada.
  breathing,

  /// El check-in de ánimo, que está en la misma pantalla: se baja hasta él.
  checkIn,

  /// La lección de hoy.
  lesson,

  /// El repaso diario.
  review,

  /// El reto de ayer, para contarle cómo fue.
  commitment,
}

/// Lo que Lumi dice: clave de traducción, argumentos, expresión y —si su
/// frase invita a algo— qué hacer al tocarla.
class LumiLine {
  final String key;
  final Map<String, String> args;
  final LumiMood mood;

  /// Qué pasa al tocar el globo. Null = solo está acompañando.
  final LumiAction? action;

  const LumiLine(this.key, this.mood, [this.args = const {}, this.action]);

  /// Clave del botoncito del globo ("Respirar contigo", "Vamos"). Null cuando
  /// no hay nada que proponer.
  String? get actionLabelKey => switch (action) {
        LumiAction.breathing => 'lumi.go.breathing',
        LumiAction.checkIn => 'lumi.go.checkIn',
        LumiAction.lesson => 'lumi.go.lesson',
        LumiAction.review => 'lumi.go.review',
        LumiAction.commitment => 'lumi.go.commitment',
        null => null,
      };
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

    // De noche propone respirar, y tocarla lleva a la respiración.
    if (c.hour >= 23 || c.hour < 5) {
      return LumiLine('lumi.night', LumiMood.sleepy, name, LumiAction.breathing);
    }

    if (c.streakBroken && c.todayMoodCategory == null) {
      return LumiLine('lumi.welcomeBack', LumiMood.caring, name);
    }

    if (c.todayMoodCategory == null) {
      final key = c.hour < 12 ? 'lumi.askMoodMorning' : 'lumi.askMood';
      return LumiLine(key, LumiMood.curious, name, LumiAction.checkIn);
    }

    // Un día difícil: respirar es lo que de verdad ayuda ahora.
    if (c.todayMoodCategory == 'negative') {
      return LumiLine('lumi.hardDay', LumiMood.caring, name, LumiAction.breathing);
    }

    if (c.hasPendingCommitment) {
      return const LumiLine(
          'lumi.commitment', LumiMood.curious, {}, LumiAction.commitment);
    }

    if (c.streak >= 3 && _isStreakMilestone(c.streak)) {
      return LumiLine('lumi.streak', LumiMood.proud, {'n': '${c.streak}'});
    }

    if (!c.lessonDoneToday && c.nextLessonTitle != null) {
      return LumiLine('lumi.nextLesson', LumiMood.excited,
          {'lesson': c.nextLessonTitle!}, LumiAction.lesson);
    }

    if (c.reviewAvailable && !c.reviewDoneToday) {
      return const LumiLine('lumi.review', LumiMood.happy, {}, LumiAction.review);
    }

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
