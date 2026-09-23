import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gimnasio_emocional/data/models/wellness_route.dart';
import 'package:gimnasio_emocional/domain/services/sound_service.dart';
import 'package:gimnasio_emocional/ui/screens/routes/lesson_palette.dart';
import 'package:gimnasio_emocional/ui/screens/routes/steps/commit_step.dart';
import 'package:gimnasio_emocional/ui/screens/routes/steps/exercise_step.dart';
import 'package:gimnasio_emocional/ui/screens/routes/steps/myth_fact_step.dart';
import 'package:gimnasio_emocional/ui/screens/routes/steps/order_step.dart';
import 'package:gimnasio_emocional/ui/screens/routes/steps/pick_step.dart';
import 'package:gimnasio_emocional/ui/screens/routes/steps/practice_step.dart';
import 'package:gimnasio_emocional/ui/screens/routes/steps/quiz_step.dart';
import 'package:gimnasio_emocional/ui/screens/routes/steps/reading_step.dart';
import 'package:gimnasio_emocional/ui/screens/routes/steps/reveal_step.dart';
import 'package:gimnasio_emocional/ui/screens/routes/steps/scenario_step.dart';
import 'package:gimnasio_emocional/ui/screens/routes/steps/slider_step.dart';
import 'package:gimnasio_emocional/ui/screens/routes/steps/sort_step.dart';
import 'package:gimnasio_emocional/ui/screens/routes/steps/step_common.dart';
import 'package:gimnasio_emocional/ui/screens/routes/steps/story_step.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Un paso de lección tiene que ocupar **todo** el ancho que le da la pantalla.
///
/// Todos son `Column(crossAxisAlignment: start)`, así que una columna más
/// estrecha que la pantalla se pega a la izquierda y **todo lo que el paso
/// centra por dentro deja de estar centrado**. Eso le pasaba a la práctica
/// guiada en cuanto arrancaba: el orbe, el contador y sus textos se iban al
/// borde izquierdo, con medio círculo fuera de la pantalla. Lo vieron los
/// testers.
///
/// Sin `EasyLocalization` los textos salen como su clave (`routes.quizLabel`),
/// que es más larga que la traducción: por eso se mide a 600 dp, para que el
/// ancho de los textos no sea lo que se está probando. Lo que se mide es que
/// la columna del paso llene el ancho que le dan, sea cual sea.
const _width = 600.0;
const _route = Color(0xFF22D3EE);

final _callbacks = StepCallbacks(
  onAnswer: (_, _, {bool sound = true}) {},
  onReflect: (_) {},
  onReady: () {},
);

Widget _buildStep(String name) => switch (name) {
      'reading' => ReadingStep(
          step: const LessonStep.reading(title: 'Leer', content: 'Un texto corto.'),
          routeColor: _route,
        ),
      'quiz' => QuizStep(
          step: const LessonStep.quiz(
            question: '¿Cuál?',
            options: ['Una', 'Otra'],
            correctIndex: 0,
            explanation: 'Porque sí.',
          ),
          routeColor: _route,
          callbacks: _callbacks,
        ),
      'exercise' => ExerciseStep(
          step: const LessonStep.exercise(title: 'Escribe', instruction: 'Lo que sientas.'),
          routeColor: _route,
          onDraftChanged: (_, _) {},
        ),
      'scenario' => ScenarioStep(
          step: const LessonStep.scenario(
            title: 'Situación',
            situation: 'Pasa algo.',
            options: ['A', 'B'],
            outcomes: ['Sale así', 'Sale asá'],
          ),
          routeColor: _route,
          callbacks: _callbacks,
        ),
      'reveal' => RevealStep(
          step: const LessonStep.reveal(question: '¿Por qué?', answer: 'Porque sí.'),
          routeColor: _route,
          callbacks: _callbacks,
        ),
      'slider' => SliderStep(
          step: const LessonStep.slider(
            question: '¿Cuánto?',
            minLabel: 'Nada',
            maxLabel: 'Mucho',
            responses: ['A', 'B', 'C'],
          ),
          routeColor: _route,
          callbacks: _callbacks,
        ),
      'sort' => SortStep(
          step: const LessonStep.sort(
            title: 'Clasifica',
            instruction: 'Arrastra.',
            categories: ['Una', 'Otra'],
            items: ['Cosa'],
            itemCategory: [0],
          ),
          routeColor: _route,
          callbacks: _callbacks,
        ),
      'mythFact' => MythFactStep(
          step: const LessonStep.mythFact(
            title: '¿Mito?',
            statements: ['Algo'],
            truths: [false],
            feedbacks: ['No es así.'],
          ),
          routeColor: _route,
          callbacks: _callbacks,
        ),
      'practice' => PracticeStep(
          step: const LessonStep.practice(
            title: 'Practica',
            intro: 'Vamos.',
            prompts: ['Inhala', 'Exhala'],
            durations: [4, 6],
            motions: ['in', 'out'],
          ),
          routeColor: _route,
          callbacks: _callbacks,
        ),
      'order' => OrderStep(
          step: const LessonStep.order(
            title: 'Ordena',
            instruction: 'Toca.',
            items: ['Uno', 'Dos'],
          ),
          routeColor: _route,
          callbacks: _callbacks,
        ),
      'pick' => PickStep(
          step: const LessonStep.pick(question: '¿Cuáles?', options: ['A', 'B']),
          routeColor: _route,
          callbacks: _callbacks,
        ),
      'story' => StoryStep(
          step: const LessonStep.story(title: 'Charla', lines: ['Hola', '> Hola']),
          routeColor: _route,
          fallbackSpeaker: '🌱',
          callbacks: _callbacks,
        ),
      'commit' => CommitStep(
          step: const LessonStep.commit(
            title: 'Reto',
            content: 'Elige uno.',
            options: ['Caminar', 'Escribir'],
          ),
          routeColor: _route,
          callbacks: _callbacks,
          onCommitted: (_) {},
        ),
      _ => throw ArgumentError('paso desconocido: $name'),
    };

Widget _harness(Widget body) => MaterialApp(
      home: Scaffold(
        body: LessonPaletteScope(
          palette: const LessonPalette(isDark: true, route: _route),
          child: Center(
            child: SizedBox(
              width: _width,
              child: SingleChildScrollView(child: body),
            ),
          ),
        ),
      ),
    );

Future<void> _settle(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 600));
  expect(find.byType(Text), findsWidgets, reason: 'el paso no llegó a dibujarse');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    // ignore: invalid_use_of_visible_for_testing_member
    SharedPreferences.setMockInitialValues({});
    await SoundService.instance.setEffectsEnabled(false);
  });

  testWidgets('cada paso ocupa todo el ancho de la pantalla', (tester) async {
    for (final name in const [
      'reading',
      'quiz',
      'exercise',
      'scenario',
      'reveal',
      'slider',
      'sort',
      'mythFact',
      'practice',
      'order',
      'pick',
      'story',
      'commit',
    ]) {
      final step = _buildStep(name);
      await tester.pumpWidget(_harness(step));
      await _settle(tester);
      expect(
        tester.getSize(find.byWidget(step)).width,
        _width,
        reason: 'el paso $name se queda corto y su contenido centrado se va al borde',
      );
    }
  });

  testWidgets('la práctica guiada sigue centrada al correr y al terminar', (tester) async {
    final step = _buildStep('practice');
    await tester.pumpWidget(_harness(step));
    await _settle(tester);

    final centerX = tester.getCenter(find.byWidget(step)).dx;

    await tester.tap(find.byIcon(Icons.play_arrow_rounded));
    await tester.pump(const Duration(milliseconds: 500));
    expect(tester.getSize(find.byWidget(step)).width, _width, reason: 'con el orbe corriendo');
    expect(tester.getCenter(find.text('Inhala')).dx, moreOrLessEquals(centerX, epsilon: 1));

    await tester.tap(find.byType(TextButton));
    await tester.pumpAndSettle();
    expect(tester.getSize(find.byWidget(step)).width, _width, reason: 'al terminar');
    expect(tester.getCenter(find.text('👍')).dx, moreOrLessEquals(centerX, epsilon: 1));
  });
}
