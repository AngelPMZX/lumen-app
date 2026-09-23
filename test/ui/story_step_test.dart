import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gimnasio_emocional/data/models/wellness_route.dart';
import 'package:gimnasio_emocional/domain/services/sound_service.dart';
import 'package:gimnasio_emocional/ui/screens/routes/lesson_screen.dart';
import 'package:gimnasio_emocional/ui/screens/routes/steps/step_common.dart';
import 'package:gimnasio_emocional/ui/screens/routes/steps/story_step.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// El botón "Continuar" de la lección solo aparece cuando la conversación
/// termina, así que la historia no puede avisar antes de su última línea.
void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await SoundService.instance.setEffectsEnabled(false);
  });

  test('solo la conversación esconde el botón "Continuar"', () {
    expect(LessonScreen.hidesContinue(LessonStepType.story), isTrue);
    for (final type in LessonStepType.values) {
      if (type == LessonStepType.story) continue;
      expect(
        LessonScreen.hidesContinue(type),
        isFalse,
        reason: '$type debería seguir mostrando el botón',
      );
    }
  });

  testWidgets('la historia avisa que se puede continuar en la última línea',
      (tester) async {
    var ready = false;
    const step = LessonStep.story(
      title: 'Una charla',
      speaker: '🌊',
      lines: ['Hola', '> Hola', '* Se quedan callados'],
    );

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: StoryStep(
            step: step,
            routeColor: Colors.teal,
            fallbackSpeaker: '🌱',
            callbacks: StepCallbacks(
              onAnswer: (_, _, {bool sound = true}) {},
              onReflect: (_) {},
              onReady: () => ready = true,
            ),
          ),
        ),
      ),
    ));
    await tester.pump(const Duration(milliseconds: 600));
    expect(ready, isFalse, reason: 'con la primera burbuja aún no se sigue');

    await tester.tap(find.text('Hola').first);
    await tester.pump(const Duration(milliseconds: 600));
    expect(ready, isFalse);

    await tester.tap(find.text('Hola').first);
    await tester.pump(const Duration(milliseconds: 600));
    expect(ready, isTrue);
    expect(find.text('Se quedan callados'), findsOneWidget);
    // El último acomodo del scroll llega tras hacerle sitio al botón.
    await tester.pumpAndSettle();
  });
}
