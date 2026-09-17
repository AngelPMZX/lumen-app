import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gimnasio_emocional/data/models/review_deck.dart';
import 'package:gimnasio_emocional/data/models/wellness_route.dart';

WellnessRoute _route() {
  Lesson lesson(String id) => Lesson(
        id: id,
        title: 'Lesson $id',
        subtitle: '',
        xpReward: 20,
        steps: [
          const LessonStep.reading(title: 'r', content: 'c'),
          const LessonStep.mythFact(
            title: 'm',
            statements: ['s0', 's1', 's2'],
            truths: [true, false, true],
            feedbacks: ['f0', 'f1', 'f2'],
          ),
          const LessonStep.sort(
            title: 'sort',
            instruction: 'i',
            categories: ['A', 'B'],
            items: ['x', 'y'],
            itemCategory: [0, 1],
            explanation: 'e',
          ),
          const LessonStep.quiz(
            question: 'q?',
            options: ['a', 'b', 'c'],
            correctIndex: 2,
            explanation: 'why',
          ),
        ],
      );
  return WellnessRoute(
    id: 'emociones',
    title: 'E',
    description: '',
    emoji: '🎭',
    color: const Color(0xFF6366F1),
    colorDark: const Color(0xFF4338CA),
    lessons: [lesson('emo_1'), lesson('emo_2'), lesson('emo_3')],
  );
}

void main() {
  final routes = [_route()];

  test('solo usa lecciones completadas y los tipos repasables', () {
    final pool = ReviewDeck.pool(routes, {'emo_1'});
    // 3 afirmaciones + 2 items de sort + 1 quiz
    expect(pool.length, 6);
    expect(pool.every((c) => c.lessonId == 'emo_1'), isTrue);
    expect(pool.where((c) => c.kind == ReviewKind.mythFact).length, 3);
  });

  test('traduce respuestas correctamente', () {
    final pool = ReviewDeck.pool(routes, {'emo_1'});
    final myth = pool.firstWhere((c) => c.id == 'emo_1:1:1');
    expect(myth.correctIndex, 0); // falso = mito
    final sortCard = pool.firstWhere((c) => c.id == 'emo_1:2:1');
    expect(sortCard.options, ['A', 'B']);
    expect(sortCard.correctIndex, 1);
    final quiz = pool.firstWhere((c) => c.kind == ReviewKind.quiz);
    expect(quiz.correctIndex, 2);
  });

  test('sin lecciones completadas no hay repaso', () {
    final pool = ReviewDeck.pool(routes, {});
    expect(ReviewDeck.build(pool: pool, missedIds: {}, dayKey: '2026-09-16'), isEmpty);
  });

  test('arma 5 tarjetas y es igual durante el mismo día', () {
    final pool = ReviewDeck.pool(routes, {'emo_1', 'emo_2', 'emo_3'});
    final a = ReviewDeck.build(pool: pool, missedIds: {}, dayKey: '2026-09-16');
    final b = ReviewDeck.build(pool: pool, missedIds: {}, dayKey: '2026-09-16');
    expect(a.length, ReviewDeck.cardsPerReview);
    expect(a.map((c) => c.id), b.map((c) => c.id));
  });

  test('reparte entre lecciones distintas', () {
    final pool = ReviewDeck.pool(routes, {'emo_1', 'emo_2', 'emo_3'});
    final deck = ReviewDeck.build(pool: pool, missedIds: {}, dayKey: '2026-09-17');
    expect(deck.map((c) => c.lessonId).toSet().length, 3);
  });

  test('incluye tarjetas falladas, como máximo 2', () {
    final pool = ReviewDeck.pool(routes, {'emo_1', 'emo_2', 'emo_3'});
    final missed = {'emo_1:1:0', 'emo_2:3:0', 'emo_3:2:1'};
    final deck = ReviewDeck.build(pool: pool, missedIds: missed, dayKey: '2026-09-16');
    expect(deck.where((c) => missed.contains(c.id)).length, greaterThanOrEqualTo(2));
    expect(deck.length, 5);
  });

  test('estrellas', () {
    expect(ReviewDeck.stars(5, 5), 3);
    expect(ReviewDeck.stars(3, 5), 2);
    expect(ReviewDeck.stars(1, 5), 1);
    expect(ReviewDeck.stars(0, 5), 0);
  });
}
