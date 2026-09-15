import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gimnasio_emocional/data/models/user_model.dart';

void main() {
  group('UserModel', () {
    test('toMap/fromMap round-trip keeps every field', () {
      final original = UserModel(
        uid: 'u1',
        name: 'Ana',
        username: 'ana',
        email: 'ana@test.com',
        age: 28,
        gender: 'female',
        hobbies: const ['yoga'],
        musicGenres: const ['jazz'],
        archetype: 'sabio',
        profileComplete: true,
        onboardingCompleted: true,
        createdAt: DateTime(2026, 9, 14, 10, 30),
      );

      final restored = UserModel.fromMap(original.toMap());

      expect(restored.uid, 'u1');
      expect(restored.name, 'Ana');
      expect(restored.username, 'ana');
      expect(restored.email, 'ana@test.com');
      expect(restored.age, 28);
      expect(restored.gender, 'female');
      expect(restored.hobbies, ['yoga']);
      expect(restored.musicGenres, ['jazz']);
      expect(restored.archetype, 'sabio');
      expect(restored.profileComplete, isTrue);
      expect(restored.onboardingCompleted, isTrue);
      expect(restored.createdAt, DateTime(2026, 9, 14, 10, 30));
    });

    test('fromMap applies defaults for docs created before new fields', () {
      final user = UserModel.fromMap({
        'uid': 'u2',
        'name': 'Leo',
        'email': 'leo@test.com',
      });

      expect(user.profileComplete, isFalse);
      expect(user.onboardingCompleted, isFalse);
      expect(user.hobbies, isEmpty);
      expect(user.musicGenres, isEmpty);
    });

    test('fromMap reads a Firestore Timestamp createdAt', () {
      final date = DateTime(2026, 1, 2, 3, 4, 5);

      final user = UserModel.fromMap({
        'uid': 'u3',
        'name': 'Mia',
        'email': 'mia@test.com',
        'createdAt': Timestamp.fromDate(date),
      });

      expect(user.createdAt, date);
    });

    test('copyWith marks onboarding completed and keeps the rest', () {
      final user = UserModel(
        uid: 'u4',
        name: 'Sol',
        email: 'sol@test.com',
        profileComplete: true,
        createdAt: DateTime(2026, 5, 1),
      );

      final updated = user.copyWith(onboardingCompleted: true);

      expect(updated.onboardingCompleted, isTrue);
      expect(updated.uid, 'u4');
      expect(updated.profileComplete, isTrue);
      expect(updated.createdAt, DateTime(2026, 5, 1));
    });
  });
}
