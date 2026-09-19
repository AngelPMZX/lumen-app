import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Ninguna lista horizontal se pinta fuera de su sitio.
///
/// Las listas que se deslizan de lado llevan `clipBehavior: Clip.none` para
/// que no se corte la sombra de la tarjeta elegida. El precio es que, al
/// deslizarlas, las tarjetas se siguen pintando **fuera de su recuadro** y
/// quedan encima del borde de lo que las contiene: eso es lo que se veía mal
/// en el check-in de ánimo, y estaba igual en otras cuatro pantallas.
///
/// La solución es envolverlas en `ClipSideways`, que recorta a los lados y
/// deja respirar arriba y abajo. Esta prueba revisa el código para que no se
/// vuelva a colar una sin envolver: es un defecto que solo se ve deslizando en
/// el teléfono, así que nadie lo encuentra hasta que un tester lo reporta.
void main() {
  test('toda lista horizontal con Clip.none va dentro de ClipSideways', () {
    final offenders = <String>[];

    for (final file in Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))) {
      final source = file.readAsStringSync();
      for (final match in RegExp(r'clipBehavior:\s*Clip\.none')
          .allMatches(source)) {
        // Lo de antes del `clipBehavior` dice de qué widget es.
        final before = source.substring(
          match.start < 260 ? 0 : match.start - 260,
          match.start,
        );
        final isScroller = before.contains('scrollDirection: Axis.horizontal');
        if (!isScroller) continue; // Un Stack con Clip.none está bien.

        // El envoltorio va justo por fuera de la lista.
        final wrapper = source.substring(
          match.start < 700 ? 0 : match.start - 700,
          match.start,
        );
        if (wrapper.contains('ClipSideways(')) continue;

        final line = '\n'.allMatches(source.substring(0, match.start)).length + 1;
        offenders.add('${file.path.replaceAll(r'\', '/')}:$line');
      }
    }

    expect(
      offenders,
      isEmpty,
      reason: 'Estas listas horizontales se pintarán fuera de su recuadro al '
          'deslizarlas. Envuélvelas en ClipSideways:\n  '
          '${offenders.join('\n  ')}',
    );
  });
}
