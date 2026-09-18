import 'package:flutter_test/flutter_test.dart';
import 'package:gimnasio_emocional/data/models/win_back.dart';

void main() {
  group('WinBack.dateFor', () {
    test('programa a los 3 y a los 14 días, a las 7 de la noche', () {
      final now = DateTime(2026, 9, 17, 10, 30);
      final first = WinBack.dateFor(now, WinBack.firstDays);
      expect(first, DateTime(2026, 9, 20, 19));
      final second = WinBack.dateFor(now, WinBack.secondDays);
      expect(second, DateTime(2026, 10, 1, 19));
    });

    test('siempre queda en el futuro, aunque se abra de noche', () {
      final lateNight = DateTime(2026, 9, 17, 23, 50);
      final when = WinBack.dateFor(lateNight, WinBack.firstDays);
      expect(when.isAfter(lateNight), isTrue);
      expect(when.hour, WinBack.hour);
    });

    test('cruza bien el fin de mes y el fin de año', () {
      expect(WinBack.dateFor(DateTime(2026, 1, 30, 9), 3), DateTime(2026, 2, 2, 19));
      expect(WinBack.dateFor(DateTime(2026, 12, 28, 9), 14), DateTime(2027, 1, 11, 19));
    });

    test('con 0 días se corre al día siguiente si la hora ya pasó', () {
      final afterSeven = DateTime(2026, 9, 17, 20);
      expect(WinBack.dateFor(afterSeven, 0), DateTime(2026, 9, 18, 19));
    });
  });

  group('Mensajes', () {
    test('la variante cambia con el día y siempre es válida', () {
      final variants = <int>{};
      for (var d = 0; d < 9; d++) {
        final v = WinBack.variantFor(DateTime(2026, 9, 1 + d));
        expect(v, inInclusiveRange(0, WinBack.firstVariants - 1));
        variants.add(v);
      }
      expect(variants.length, WinBack.firstVariants);
    });

    test('el mismo día siempre da la misma variante', () {
      final day = DateTime(2026, 5, 12);
      expect(WinBack.variantFor(day), WinBack.variantFor(DateTime(2026, 5, 12)));
    });

    test('las claves de traducción siguen el patrón', () {
      for (var v = 0; v < WinBack.firstVariants; v++) {
        expect(WinBack.firstTitleKey(v), 'notifications.winBack.first.$v.title');
        expect(WinBack.firstBodyKey(v), 'notifications.winBack.first.$v.body');
      }
      expect(WinBack.secondTitleKey, 'notifications.winBack.second.title');
    });
  });
}
