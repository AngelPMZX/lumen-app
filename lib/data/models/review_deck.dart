import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'wellness_route.dart';

/// Tipo de tarjeta del repaso diario.
enum ReviewKind {
  /// Afirmación: ¿mito o realidad? (sale de pasos `mythfact`).
  mythFact,

  /// ¿A qué categoría pertenece? (sale de pasos `sort`).
  category,

  /// Pregunta con opciones (sale de pasos `quiz`).
  quiz,
}

/// Una tarjeta del repaso, sacada de una lección que el usuario ya completó.
class ReviewCard {
  /// `lessonId:stepIndex:itemIndex`: estable mientras no cambie el contenido.
  final String id;
  final ReviewKind kind;
  final String prompt;

  /// Opciones de respuesta. En [ReviewKind.mythFact] va vacía: la pantalla
  /// muestra Mito / Realidad.
  final List<String> options;

  /// Índice correcto. En [ReviewKind.mythFact]: 1 = realidad, 0 = mito.
  final int correctIndex;
  final String? feedback;

  final String lessonId;
  final String lessonTitle;
  final String routeId;
  final String routeEmoji;
  final Color routeColor;

  const ReviewCard({
    required this.id,
    required this.kind,
    required this.prompt,
    required this.options,
    required this.correctIndex,
    required this.feedback,
    required this.lessonId,
    required this.lessonTitle,
    required this.routeId,
    required this.routeEmoji,
    required this.routeColor,
  });
}

/// Arma el mazo del día a partir de las lecciones completadas.
class ReviewDeck {
  static const cardsPerReview = 5;

  /// Menos tarjetas que esto y el repaso no se ofrece (se sentiría vacío).
  static const minCards = 3;

  /// Tarjetas falladas que vuelven como máximo en un repaso.
  static const maxMissedPerReview = 2;

  /// Todas las tarjetas posibles de las lecciones completadas.
  static List<ReviewCard> pool(List<WellnessRoute> routes, Set<String> completedLessons) {
    final cards = <ReviewCard>[];
    for (final route in routes) {
      for (final lesson in route.lessons) {
        if (!completedLessons.contains(lesson.id)) continue;
        for (int s = 0; s < lesson.steps.length; s++) {
          final step = lesson.steps[s];
          ReviewCard card(int item, ReviewKind kind, String prompt, List<String> options,
                  int correct, String? feedback) =>
              ReviewCard(
                id: '${lesson.id}:$s:$item',
                kind: kind,
                prompt: prompt,
                options: options,
                correctIndex: correct,
                feedback: feedback,
                lessonId: lesson.id,
                lessonTitle: lesson.title,
                routeId: route.id,
                routeEmoji: route.emoji,
                routeColor: route.color,
              );

          switch (step.type) {
            case LessonStepType.mythFact:
              final statements = step.statements ?? const [];
              final truths = step.truths ?? const [];
              final feedbacks = step.feedbacks ?? const [];
              for (int i = 0; i < statements.length && i < truths.length; i++) {
                cards.add(card(i, ReviewKind.mythFact, statements[i], const [],
                    truths[i] ? 1 : 0, i < feedbacks.length ? feedbacks[i] : null));
              }
            case LessonStepType.sort:
              final items = step.items ?? const [];
              final categories = step.categories ?? const [];
              final answers = step.itemCategory ?? const [];
              if (categories.length < 2) break;
              for (int i = 0; i < items.length && i < answers.length; i++) {
                if (answers[i] < 0 || answers[i] >= categories.length) continue;
                cards.add(card(i, ReviewKind.category, items[i], categories, answers[i],
                    step.explanation));
              }
            case LessonStepType.quiz:
              final options = step.options ?? const [];
              final correct = step.correctIndex ?? -1;
              if (step.question == null || correct < 0 || correct >= options.length) break;
              cards.add(card(0, ReviewKind.quiz, step.question!, options, correct, step.explanation));
            default:
              break;
          }
        }
      }
    }
    return cards;
  }

  /// Mazo del día. Determinista por [dayKey] (el mismo día, el mismo mazo):
  /// primero hasta [maxMissedPerReview] tarjetas falladas antes, después al
  /// azar procurando no repetir lección.
  static List<ReviewCard> build({
    required List<ReviewCard> pool,
    required Set<String> missedIds,
    required String dayKey,
  }) {
    if (pool.length < minCards) return const [];
    final rng = math.Random(dayKey.codeUnits.fold<int>(17, (h, c) => (h * 31 + c) & 0x7fffffff));

    final deck = <ReviewCard>[];
    final missed = pool.where((c) => missedIds.contains(c.id)).toList()..shuffle(rng);
    deck.addAll(missed.take(maxMissedPerReview));

    final rest = pool.where((c) => !deck.contains(c)).toList()..shuffle(rng);
    final usedLessons = deck.map((c) => c.lessonId).toSet();
    // Primera pasada: una tarjeta por lección; segunda: completar
    for (final c in rest) {
      if (deck.length >= cardsPerReview) break;
      if (usedLessons.add(c.lessonId)) deck.add(c);
    }
    for (final c in rest) {
      if (deck.length >= cardsPerReview) break;
      if (!deck.contains(c)) deck.add(c);
    }
    deck.shuffle(rng);
    return deck;
  }

  /// Estrellas (0-3) según aciertos.
  static int stars(int correct, int total) {
    if (total == 0) return 0;
    final ratio = correct / total;
    if (ratio >= 1) return 3;
    if (ratio >= 0.6) return 2;
    if (ratio > 0) return 1;
    return 0;
  }
}
