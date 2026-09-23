import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gimnasio_emocional/domain/services/sound_service.dart';

/// Con la app minimizada no debe sonar nada: el contexto de audio es
/// `mixWithOthers`, así que el sistema no pausa por su cuenta y el ambiente de
/// una lección seguía sonando fuera de la app.
void main() {
  final sound = SoundService.instance;

  tearDown(() => sound.handleLifecycleState(AppLifecycleState.resumed));

  test('minimizar calla la app y volver la despierta', () {
    expect(sound.silenced, isFalse);

    sound.handleLifecycleState(AppLifecycleState.hidden);
    expect(sound.silenced, isTrue);
    sound.handleLifecycleState(AppLifecycleState.paused);
    expect(sound.silenced, isTrue);

    sound.handleLifecycleState(AppLifecycleState.resumed);
    expect(sound.silenced, isFalse);
  });

  test('perder el foco sin irse (cortina, diálogo del sistema) no calla nada', () {
    sound.handleLifecycleState(AppLifecycleState.inactive);
    expect(sound.silenced, isFalse);
  });

  test('un efecto con la app minimizada no suena ni revienta', () async {
    sound.handleLifecycleState(AppLifecycleState.paused);
    await sound.play(Sfx.correct);
    await sound.cue(BreathCue.inhale);
    expect(sound.silenced, isTrue);
  });
}
