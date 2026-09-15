import 'package:flutter_test/flutter_test.dart';
import 'package:gimnasio_emocional/data/models/user_progress.dart';

void main() {
  final now = DateTime(2026, 9, 14, 18);

  UserProgress lastCheckInAt(DateTime last, {int streak = 2, int longest = 5}) =>
      UserProgress(
        currentStreak: streak,
        longestStreak: longest,
        lastCheckIn: last,
      );

  group('streakAt (racha mostrada)', () {
    test('se mantiene si el último check-in fue hoy', () {
      final p = lastCheckInAt(DateTime(2026, 9, 14, 8));
      expect(p.isStreakAlive(now), isTrue);
      expect(p.streakAt(now), 2);
    });

    test('se mantiene si el último check-in fue ayer, aunque sea tarde', () {
      final p = lastCheckInAt(DateTime(2026, 9, 13, 23, 59));
      expect(p.isStreakAlive(now), isTrue);
      expect(p.streakAt(now), 2);
    });

    test('baja a 0 cuando se saltó un día sin nuevo check-in', () {
      final p = lastCheckInAt(DateTime(2026, 9, 12, 20));
      expect(p.isStreakAlive(now), isFalse);
      expect(p.streakAt(now), 0);
    });

    test('usuario nuevo no tiene racha', () {
      expect(UserProgress().streakAt(now), 0);
    });
  });

  group('calculateStreak', () {
    test('suma 1 si el último check-in fue ayer', () {
      final p = lastCheckInAt(DateTime(2026, 9, 13, 9)).calculateStreak(now);
      expect(p.currentStreak, 3);
      expect(p.longestStreak, 5);
      expect(p.lastCheckIn, now);
    });

    test('reinicia a 1 si se saltó un día', () {
      final p = lastCheckInAt(DateTime(2026, 9, 12, 9)).calculateStreak(now);
      expect(p.currentStreak, 1);
      expect(p.longestStreak, 5);
    });

    test('no cambia si ya hizo check-in hoy', () {
      final original = lastCheckInAt(DateTime(2026, 9, 14, 7));
      expect(identical(original.calculateStreak(now), original), isTrue);
    });

    test('actualiza la mejor racha cuando la supera', () {
      final p = lastCheckInAt(DateTime(2026, 9, 13), streak: 5, longest: 5)
          .calculateStreak(now);
      expect(p.currentStreak, 6);
      expect(p.longestStreak, 6);
    });

    test('cuenta días de calendario, no bloques de 24 h', () {
      // 23:30 → 00:30 del día siguiente = 1 día aunque pasó 1 hora
      final p = lastCheckInAt(DateTime(2026, 9, 13, 23, 30))
          .calculateStreak(DateTime(2026, 9, 14, 0, 30));
      expect(p.currentStreak, 3);
    });
  });

  test('hasCheckedInToday compara días de calendario', () {
    final p = lastCheckInAt(DateTime(2026, 9, 14, 0, 5));
    expect(p.hasCheckedInToday(now), isTrue);
    expect(p.hasCheckedInToday(DateTime(2026, 9, 15, 0, 1)), isFalse);
  });
}
