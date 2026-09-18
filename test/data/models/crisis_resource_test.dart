import 'dart:convert';
import 'dart:io';
import 'dart:ui' show Locale;

import 'package:flutter_test/flutter_test.dart';
import 'package:gimnasio_emocional/data/models/crisis_resource.dart';

/// Lee una clave anidada ("crisis.countries.mx") del archivo de traducciones.
Object? _lookup(Map<String, dynamic> json, String key) {
  Object? node = json;
  for (final part in key.split('.')) {
    if (node is! Map) return null;
    node = node[part];
  }
  return node;
}

void main() {
  final translations = {
    for (final locale in ['es', 'en'])
      locale: jsonDecode(
        File('assets/translations/$locale.json').readAsStringSync(),
      ) as Map<String, dynamic>,
  };

  group('Detectar el país', () {
    test('lo saca de la región del teléfono', () {
      expect(
        CrisisResources.detect([const Locale('es', 'MX')])?.code,
        'mx',
      );
      expect(
        CrisisResources.detect([const Locale('en', 'US')])?.code,
        'us',
      );
    });

    test('se queda con el primer idioma del que sí tenemos líneas', () {
      // En Android los idiomas vienen en el orden que puso la persona.
      final found = CrisisResources.detect([
        const Locale('qu', 'PE'),
        const Locale('es', 'AR'),
      ]);
      expect(found?.code, 'ar');
    });

    test('sin región no inventa un país', () {
      // Este es el fallo que había: el idioma de la app es solo `es` o `en`,
      // nunca trae país, así que preguntarle a él daba siempre México.
      expect(CrisisResources.detect([const Locale('es')]), isNull);
      expect(CrisisResources.detect([const Locale('en')]), isNull);
      expect(CrisisResources.detect([]), isNull);
    });

    test('de un país que no está en la lista devuelve null, no otro país', () {
      // Enseñarle a alguien de Perú los números de México como si fueran los
      // suyos sería peor que mandarlo al directorio internacional.
      expect(CrisisResources.detect([const Locale('es', 'PE')]), isNull);
      expect(CrisisResources.fromCode('pe'), isNull);
      expect(CrisisResources.fromCode(null), isNull);
      expect(CrisisResources.fromCode(''), isNull);
    });

    test('el código no distingue mayúsculas', () {
      expect(CrisisResources.fromCode('MX')?.code, 'mx');
    });
  });

  group('El catálogo está completo y traducido', () {
    test('cada país tiene su nombre en los dos idiomas', () {
      for (final country in CrisisResources.all) {
        expect(country.nameKey, 'crisis.countries.${country.code}');
        for (final locale in translations.keys) {
          final value = _lookup(translations[locale]!, country.nameKey);
          expect(value, isA<String>(),
              reason: 'falta ${country.nameKey} en $locale');
          expect(value as String, isNotEmpty);
        }
      }
    });

    test('cada línea tiene descripción (y nota) en los dos idiomas', () {
      for (final country in CrisisResources.all) {
        expect(country.lines, isNotEmpty, reason: country.code);
        for (final line in country.lines) {
          for (final key in [
            line.descriptionKey,
            if (line.noteKey != null) line.noteKey!,
            if (line.nameKey != null) line.nameKey!,
          ]) {
            for (final locale in translations.keys) {
              final value = _lookup(translations[locale]!, key);
              expect(value, isA<String>(),
                  reason: 'falta $key en $locale');
              expect(value as String, isNotEmpty);
            }
          }
        }
      }
    });

    test('los números son marcables y cada país dice de dónde salió', () {
      for (final country in CrisisResources.all) {
        expect(country.emergencyNumber, isNotEmpty);
        expect(country.sourceUrl, startsWith('https://'),
            reason: '${country.code} necesita su fuente oficial');
        expect(country.flag, isNotEmpty);
        for (final line in country.lines) {
          expect(line.display, isNotEmpty);
          // Lo que se marca de verdad: sin espacios ni guiones.
          expect(line.dial, isNotEmpty);
          expect(line.dial, isNot(contains(' ')), reason: line.name);
          expect(line.dial, isNot(contains('-')), reason: line.name);
        }
      }
    });

    test('no hay dos países con el mismo código', () {
      final codes = CrisisResources.all.map((c) => c.code).toList();
      expect(codes.toSet().length, codes.length);
    });
  });
}
