import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gimnasio_emocional/data/models/wellness_route.dart';
import 'package:gimnasio_emocional/domain/services/sound_service.dart';
import 'package:gimnasio_emocional/ui/screens/routes/steps/sort_step.dart';
import 'package:gimnasio_emocional/ui/screens/routes/steps/step_common.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await SoundService.instance.setEffectsEnabled(false);
  });

  testWidgets('clasificar sin arrastrar: tocar la tarjeta y luego la categoría', (tester) async {
    final answers = <bool>[];
    var ready = false;
    const step = LessonStep.sort(
      title: 'Clasifica',
      instruction: 'Instrucción',
      categories: ['Recarga', 'Drena'],
      items: ['Caminar', 'Scroll'],
      itemCategory: [0, 1],
    );

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: SortStep(
            step: step,
            routeColor: Colors.teal,
            callbacks: StepCallbacks(
              onAnswer: (correct, _, {bool sound = true}) => answers.add(correct),
              onReflect: (_) {},
              onReady: () => ready = true,
            ),
          ),
        ),
      ),
    ));
    await tester.pump(const Duration(seconds: 1));

    // Sin tarjeta elegida, tocar una categoría no hace nada
    await tester.tap(find.text('Recarga'));
    await tester.pump();
    expect(answers, isEmpty);

    await tester.tap(find.text('Caminar'));
    await tester.pump();
    await tester.tap(find.text('Recarga'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(answers, [true]);

    await tester.tap(find.text('Scroll'));
    await tester.pump();
    await tester.tap(find.text('Recarga'));
    await tester.pump(const Duration(seconds: 1));
    expect(answers, [true, false]);
    expect(ready, isTrue);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 2));
  });
}
