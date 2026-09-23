import 'package:flutter_test/flutter_test.dart';
import 'package:gimnasio_emocional/data/models/habit_xp_quota.dart';

/// El XP de los hábitos tiene tope diario: sin él se farmeaba sin límite
/// creando un hábito, marcándolo y borrándolo (cada hábito nuevo estrena id,
/// así que volvía a contar como "primera vez del día").
void main() {
  const today = '2026-9-22';

  test('sin documento previo, el cupo está entero', () {
    final quota = HabitXpQuota.fromMap(null, today: today);
    expect(quota.rewarded, 0);
    expect(quota.hasRoom, isTrue);
    expect(quota.left, HabitXpQuota.maxPerDay);
  });

  test('el cupo de ayer no cuenta hoy', () {
    final quota = HabitXpQuota.fromMap(
      const {'rewardDate': '2026-9-21', 'rewarded': 3},
      today: today,
    );
    expect(quota.day, today);
    expect(quota.rewarded, 0);
    expect(quota.hasRoom, isTrue);
  });

  test('se agota al tercer hábito del día', () {
    var quota = HabitXpQuota.fromMap(null, today: today);
    for (var i = 0; i < HabitXpQuota.maxPerDay; i++) {
      expect(quota.hasRoom, isTrue, reason: 'hábito ${i + 1}');
      quota = quota.next;
    }
    expect(quota.rewarded, HabitXpQuota.maxPerDay);
    expect(quota.hasRoom, isFalse);
    expect(quota.left, 0);
  });

  test('sin cupo, cobrar otra vez no mueve el contador', () {
    final full = HabitXpQuota.fromMap(
      const {'rewardDate': today, 'rewarded': HabitXpQuota.maxPerDay},
      today: today,
    );
    expect(full.next.rewarded, HabitXpQuota.maxPerDay);
    expect(full.next.hasRoom, isFalse);
  });

  test('un contador corrupto o más alto que el tope no abre cupo de más', () {
    final weird = HabitXpQuota.fromMap(
      const {'rewardDate': today, 'rewarded': 99},
      today: today,
    );
    expect(weird.rewarded, HabitXpQuota.maxPerDay);
    expect(weird.hasRoom, isFalse);
  });

  test('lo que se guarda se vuelve a leer igual', () {
    final quota = HabitXpQuota.fromMap(null, today: today).next;
    final again = HabitXpQuota.fromMap(quota.toMap(), today: today);
    expect(again.day, quota.day);
    expect(again.rewarded, quota.rewarded);
  });

  test('la clave del día es la fecha local, sin ceros a la izquierda', () {
    expect(HabitXpQuota.dayKey(DateTime(2026, 9, 22)), '2026-9-22');
    expect(HabitXpQuota.dayKey(DateTime(2026, 12, 1)), '2026-12-1');
  });
}
