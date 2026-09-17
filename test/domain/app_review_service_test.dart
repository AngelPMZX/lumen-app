import 'package:flutter_test/flutter_test.dart';
import 'package:gimnasio_emocional/domain/services/app_review_service.dart';

void main() {
  final now = DateTime(2026, 9, 16);

  bool ask({
    DateTime? last,
    int moments = 3,
    int xp = 500,
    bool hardDay = false,
  }) =>
      AppReviewService.shouldAsk(
        now: now,
        lastRequest: last,
        happyMoments: moments,
        totalXp: xp,
        hardDayToday: hardDay,
      );

  test('pide reseña con recorrido y en un buen día', () => expect(ask(), isTrue));

  test('nunca en un día difícil', () => expect(ask(hardDay: true), isFalse));

  test('no al primer logro', () => expect(ask(moments: 1), isFalse));

  test('no a usuarios muy nuevos', () => expect(ask(xp: 40), isFalse));

  test('respeta el tiempo de espera entre pedidos', () {
    expect(ask(last: now.subtract(const Duration(days: 30))), isFalse);
    expect(ask(last: now.subtract(const Duration(days: 121))), isTrue);
  });
}
