import 'package:flutter_test/flutter_test.dart';
import 'package:gimnasio_emocional/data/models/password_strength.dart';

void main() {
  group('Reglas obligatorias', () {
    test('una contraseña vacía no cumple nada', () {
      final s = PasswordStrength.check('');
      expect(s.level, PasswordLevel.empty);
      expect(s.isValid, isFalse);
      expect(s.score, 0);
    });

    test('pide al menos 8 caracteres', () {
      expect(PasswordStrength.check('abc123').has(PasswordRule.length), isFalse);
      expect(PasswordStrength.check('abcd1234').has(PasswordRule.length), isTrue);
    });

    test('pide letras y números', () {
      final onlyLetters = PasswordStrength.check('abcdefghij');
      expect(onlyLetters.has(PasswordRule.letters), isTrue);
      expect(onlyLetters.has(PasswordRule.numbers), isFalse);
      final onlyDigits = PasswordStrength.check('9481726354');
      expect(onlyDigits.has(PasswordRule.numbers), isTrue);
      expect(onlyDigits.has(PasswordRule.letters), isFalse);
      // Solo dígitos tampoco pasa el filtro de "muy común"
      expect(onlyDigits.has(PasswordRule.notCommon), isFalse);
    });

    test('rechaza las contraseñas más usadas', () {
      for (final p in ['password123', 'Contraseña1', 'qwertyuiop', 'iloveyou', 'lumen123']) {
        expect(PasswordStrength.check(p).has(PasswordRule.notCommon), isFalse, reason: p);
      }
    });

    test('rechaza repeticiones y series seguidas', () {
      expect(PasswordStrength.check('aaaaaaaa').has(PasswordRule.notCommon), isFalse);
      expect(PasswordStrength.check('abcdefgh').has(PasswordRule.notCommon), isFalse);
      expect(PasswordStrength.check('87654321').has(PasswordRule.notCommon), isFalse);
      expect(PasswordStrength.check('abcd3fgh').has(PasswordRule.notCommon), isTrue);
    });

    test('no deja usar el correo ni el nombre', () {
      const personal = ['angel@correo.com', 'Ángel Pérez'];
      expect(PasswordStrength.check('angel2026', personal: personal).has(PasswordRule.notPersonal), isFalse);
      expect(PasswordStrength.check('miAngel99', personal: personal).has(PasswordRule.notPersonal), isFalse);
      expect(PasswordStrength.check('jardin7lumen', personal: personal).has(PasswordRule.notPersonal), isTrue);
    });

    test('ignora datos personales demasiado cortos', () {
      expect(PasswordStrength.check('lunaverde42', personal: ['a', 'me']).has(PasswordRule.notPersonal), isTrue);
    });
  });

  group('Nivel de fuerza', () {
    test('sube conforme cumple más', () {
      expect(PasswordStrength.check('abc').level, PasswordLevel.weak);
      // Cumple todo menos el largo
      expect(PasswordStrength.check('sol7ab').level, PasswordLevel.fair);
      expect(PasswordStrength.check('jardin7luz').level, PasswordLevel.good);
      expect(PasswordStrength.check('Jardin7Luz!x').level, PasswordLevel.strong);
    });

    test('solo es válida cuando cumple las cinco reglas', () {
      final ok = PasswordStrength.check('lumen7jardin');
      expect(ok.isValid, isTrue);
      expect(ok.passed.length, PasswordStrength.required.length);
      expect(PasswordStrength.check('password123').isValid, isFalse);
      expect(PasswordStrength.check('corto1').isValid, isFalse);
    });

    test('el puntaje va de 0 a 4', () {
      for (final p in ['', 'a', 'sol7ab', 'jardin7luz', 'Jardin7Luz!x']) {
        final s = PasswordStrength.check(p);
        expect(s.score, inInclusiveRange(0, 4), reason: p);
      }
    });
  });

  test('las claves de traducción siguen el patrón esperado', () {
    expect(PasswordStrength.check('abcd1234').levelKey, startsWith('validation.strength.'));
    for (final r in PasswordRule.values) {
      expect(PasswordStrength.ruleKey(r), 'validation.passwordRules.${r.name}');
    }
  });
}
