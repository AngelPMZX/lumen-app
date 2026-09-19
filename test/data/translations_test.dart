import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Español e inglés van a la par.
///
/// easy_localization no avisa de una clave que falta: muestra la clave tal
/// cual, o cae al español. Así se coló toda la pantalla de verificar correo
/// escrita en español dentro del archivo inglés, y tres claves con el prefijo
/// equivocado que salían en pantalla como "auth.errors.generic".
Map<String, String> _flatten(Map<String, dynamic> json, [String prefix = '']) {
  final out = <String, String>{};
  json.forEach((key, value) {
    final path = '$prefix$key';
    if (value is Map<String, dynamic>) {
      out.addAll(_flatten(value, '$path.'));
    } else if (value is String) {
      out[path] = value;
    }
  });
  return out;
}

void main() {
  final es = _flatten(
    jsonDecode(File('assets/translations/es.json').readAsStringSync())
        as Map<String, dynamic>,
  );
  final en = _flatten(
    jsonDecode(File('assets/translations/en.json').readAsStringSync())
        as Map<String, dynamic>,
  );

  test('las dos tienen exactamente las mismas claves', () {
    expect(es.keys.toSet().difference(en.keys.toSet()), isEmpty,
        reason: 'faltan en inglés');
    expect(en.keys.toSet().difference(es.keys.toSet()), isEmpty,
        reason: 'faltan en español');
  });

  test('ninguna está vacía', () {
    for (final entry in {...es, ...en}.entries) {
      // `…words.zero` sí está vacía a propósito: con 0 palabras no se dice
      // nada en vez de "0 palabras".
      if (entry.key.endsWith('.zero')) continue;
      expect(entry.value.trim(), isNotEmpty, reason: entry.key);
    }
  });

  test('el inglés no se quedó escrito en español', () {
    // Palabras que no existen en inglés: si aparecen en `en.json` es que esa
    // frase se quedó sin traducir.
    final spanish = RegExp(
      r'(?:^|\s)(?:el|la|los|las|tu|tus|para|con|cuando|hoy|correo|'
      r'contraseña|cuenta|sesión|aquí|más|días?|semana|ánimo)(?:\s|$)',
      caseSensitive: false,
    );
    final suspects = <String>[];
    en.forEach((key, value) {
      if (value.length > 12 && spanish.hasMatch(value)) suspects.add(key);
    });
    expect(suspects, isEmpty,
        reason: 'parecen estar en español:\n  ${suspects.join('\n  ')}');
  });

  test('los marcadores {…} son los mismos en los dos idiomas', () {
    final braces = RegExp(r'\{(\w*)\}');
    for (final key in es.keys) {
      final inEs = braces.allMatches(es[key]!).map((m) => m.group(1)!).toSet();
      final inEn = braces.allMatches(en[key]!).map((m) => m.group(1)!).toSet();
      expect(inEn, inEs,
          reason: '$key: el inglés no usa los mismos datos que el español');
    }
  });
}
