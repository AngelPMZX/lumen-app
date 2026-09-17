import 'package:flutter_test/flutter_test.dart';
import 'package:gimnasio_emocional/data/models/lumi.dart';

LumiContext ctx({
  int hour = 10,
  bool introSeen = true,
  String? mood = 'neutral',
  int streak = 1,
  bool streakBroken = false,
  bool commitment = false,
  bool lessonDone = false,
  String? nextLesson = 'La ola emocional',
  bool reviewAvailable = true,
  bool reviewDone = false,
}) =>
    LumiContext(
      name: 'Ana',
      hour: hour,
      introSeen: introSeen,
      todayMoodCategory: mood,
      streak: streak,
      streakBroken: streakBroken,
      hasPendingCommitment: commitment,
      lessonDoneToday: lessonDone,
      nextLessonTitle: nextLesson,
      reviewAvailable: reviewAvailable,
      reviewDoneToday: reviewDone,
    );

void main() {
  test('se presenta la primera vez, antes que nada', () {
    final line = LumiDialog.forHome(ctx(introSeen: false, hour: 2, mood: 'negative'));
    expect(line.key, 'lumi.intro');
    expect(line.args['name'], 'Ana');
  });

  test('de noche tiene sueño', () {
    expect(LumiDialog.forHome(ctx(hour: 23)).mood, LumiMood.sleepy);
    expect(LumiDialog.forHome(ctx(hour: 3)).key, 'lumi.night');
  });

  test('al volver tras perder la racha, recibe con cariño y sin regaño', () {
    final line = LumiDialog.forHome(ctx(streakBroken: true, mood: null));
    expect(line.key, 'lumi.welcomeBack');
    expect(line.mood, LumiMood.caring);
  });

  test('sin check-in pregunta cómo se siente', () {
    expect(LumiDialog.forHome(ctx(mood: null, hour: 9)).key, 'lumi.askMoodMorning');
    expect(LumiDialog.forHome(ctx(mood: null, hour: 15)).key, 'lumi.askMood');
  });

  test('un día difícil tiene prioridad sobre invitar a hacer cosas', () {
    final line = LumiDialog.forHome(ctx(mood: 'negative', commitment: true, streak: 7));
    expect(line.key, 'lumi.hardDay');
  });

  test('pregunta por el reto pendiente', () {
    expect(LumiDialog.forHome(ctx(commitment: true)).key, 'lumi.commitment');
  });

  test('celebra la racha solo en hitos', () {
    expect(LumiDialog.forHome(ctx(streak: 7)).key, 'lumi.streak');
    expect(LumiDialog.forHome(ctx(streak: 14)).args['n'], '14');
    expect(LumiDialog.forHome(ctx(streak: 8)).key, isNot('lumi.streak'));
  });

  test('invita a la siguiente lección con su título', () {
    final line = LumiDialog.forHome(ctx());
    expect(line.key, 'lumi.nextLesson');
    expect(line.args['lesson'], 'La ola emocional');
  });

  test('después de la lección sugiere el repaso', () {
    expect(LumiDialog.forHome(ctx(lessonDone: true)).key, 'lumi.review');
  });

  test('con todo hecho, se enorgullece', () {
    final line = LumiDialog.forHome(ctx(lessonDone: true, reviewDone: true));
    expect(line.key, 'lumi.allDone');
    expect(line.mood, LumiMood.proud);
  });

  test('las frases al tocar rotan', () {
    expect(LumiDialog.tap(0).key, 'lumi.tap.0');
    expect(LumiDialog.tap(LumiDialog.tapLineCount).key, 'lumi.tap.0');
    expect(LumiDialog.tap(1).key, isNot(LumiDialog.tap(0).key));
  });
}
