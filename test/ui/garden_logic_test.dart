import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gimnasio_emocional/data/models/garden_item.dart';
import 'package:gimnasio_emocional/data/models/lumi.dart';
import 'package:gimnasio_emocional/ui/screens/garden/garden_defs.dart';
import 'package:gimnasio_emocional/ui/screens/garden/garden_logic.dart';

void main() {
  group('GardenLayout', () {
    test('toScreen y toBackground son inversas en cualquier proporción', () {
      for (final (w, h) in const [(390.0, 844.0), (360.0, 640.0), (800.0, 1280.0), (1024.0, 600.0)]) {
        final (x, y) = GardenLayout.toScreen(0.3542, 0.299, w, h);
        final (bx, by) = GardenLayout.toBackground(x, y, w, h);
        expect(bx, closeTo(0.3542, 1e-9));
        expect(by, closeTo(0.299, 1e-9));
      }
    });

    test('con cover, el centro de la ilustración queda en el centro de la pantalla', () {
      final (x, y) = GardenLayout.toScreen(0.5, 0.5, 390, 700);
      expect(x, closeTo(195, 1e-9));
      expect(y, closeTo(350, 1e-9));
    });

    test('el área visible recorta el lado que sobra', () {
      // Pantalla más ancha que la ilustración: se recorta arriba y abajo
      final (l, t, r, b) = GardenLayout.visibleArea(600, 700);
      expect(l, closeTo(0, 1e-9));
      expect(r, closeTo(1, 1e-9));
      expect(t, greaterThan(0));
      expect(b, lessThan(1));
    });

    test('la distancia vertical pesa según la proporción del fondo', () {
      expect(GardenLayout.distance(0, 0, 0.1, 0), closeTo(0.1, 1e-9));
      expect(GardenLayout.distance(0, 0, 0, 0.1), closeTo(0.1 * GardenLayout.aspect, 1e-9));
    });
  });

  group('GardenRules.checkDecoration', () {
    const visible = (0.0, 0.0, 1.0, 1.0);
    final slots = [for (final s in GardensCatalog.meadow.slots) (s.anchorX, s.anchorY)];

    test('no deja poner una decoración encima de un hueco de planta', () {
      final s = GardensCatalog.meadow.slots.first;
      expect(
        GardenRules.checkDecoration(fx: s.anchorX + 0.02, fy: s.anchorY, slots: slots, decos: const [], visible: visible),
        DecoPlacement.nearPlant,
      );
    });

    test('no deja amontonar decoraciones', () {
      expect(
        GardenRules.checkDecoration(fx: 0.5, fy: 0.9, slots: slots, decos: const [(0.52, 0.9)], visible: visible),
        DecoPlacement.nearDeco,
      );
    });

    test('rechaza puntos fuera de la parte visible', () {
      expect(
        GardenRules.checkDecoration(fx: 0.5, fy: 0.05, slots: slots, decos: const [], visible: (0.0, 0.1, 1.0, 0.9)),
        DecoPlacement.outside,
      );
    });

    test('acepta un lugar libre', () {
      expect(
        GardenRules.checkDecoration(fx: 0.5, fy: 0.9, slots: slots, decos: const [], visible: visible),
        DecoPlacement.ok,
      );
    });
  });

  group('GardenRules', () {
    test('el brillo sube con la rareza', () {
      expect(GardenRules.shineLevel(ItemRarity.common), 0);
      expect(GardenRules.shineLevel(ItemRarity.rare), 0);
      expect(GardenRules.shineLevel(ItemRarity.epic), 1);
      expect(GardenRules.shineLevel(ItemRarity.legendary), 2);
      expect(GardenRules.shineLevel(ItemRarity.seasonal), 2);
    });

    test('el tiempo restante redondea minutos hacia arriba', () {
      expect(GardenRules.hoursMinutes(const Duration(seconds: 20)), (0, 1));
      expect(GardenRules.hoursMinutes(const Duration(hours: 2, minutes: 59, seconds: 30)), (3, 0));
      expect(GardenRules.hoursMinutes(const Duration(hours: 1, minutes: 5)), (1, 5));
    });
  });

  group('GardenLumi.lineFor', () {
    test('los modos activos van primero', () {
      expect(GardenLumi.lineFor(const GardenSnapshot(planting: true, readyToHarvest: 2)).key, 'garden.lumi.planting');
      expect(GardenLumi.lineFor(const GardenSnapshot(boosting: true)).key, 'garden.lumi.boosting');
      expect(GardenLumi.lineFor(const GardenSnapshot(draggingDeco: true)).key, 'garden.lumi.dragging');
    });

    test('avisa de la cosecha con singular o plural', () {
      final one = GardenLumi.lineFor(const GardenSnapshot(plants: 3, readyToHarvest: 1));
      expect(one.key, 'garden.lumi.harvestOne');
      expect(one.mood, LumiMood.excited);
      final many = GardenLumi.lineFor(const GardenSnapshot(plants: 3, readyToHarvest: 2));
      expect(many.key, 'garden.lumi.harvestMany');
      expect(many.args['count'], '2');
    });

    test('jardín vacío: invita a plantar o, sin semillas, a la tienda con cariño', () {
      expect(GardenLumi.lineFor(const GardenSnapshot(seedsInInventory: 1)).key, 'garden.lumi.emptyWithSeeds');
      final none = GardenLumi.lineFor(const GardenSnapshot());
      expect(none.key, 'garden.lumi.emptyNoSeeds');
      expect(none.mood, LumiMood.caring);
    });

    test('con plantas creciendo sugiere boosters, decoraciones o esperar', () {
      expect(GardenLumi.lineFor(const GardenSnapshot(plants: 2, growing: 1, boostersInInventory: 1)).key, 'garden.lumi.growingBoosters');
      expect(GardenLumi.lineFor(const GardenSnapshot(plants: 2, growing: 1, decosInInventory: 1)).key, 'garden.lumi.decoHint');
      expect(GardenLumi.lineFor(const GardenSnapshot(plants: 2, growing: 1)).key, 'garden.lumi.growing');
      expect(GardenLumi.lineFor(const GardenSnapshot(plants: 2)).key, 'garden.lumi.allHarvested');
    });
  });

  group('PlacedDeco', () {
    test('las decoraciones viejas se leen en coordenadas de pantalla', () {
      final legacy = PlacedDeco.fromMap({'instanceId': 'a', 'itemId': 'deco_lantern', 'gardenId': 'meadow', 'fx': 0.5, 'fy': 0.5});
      expect(legacy.legacy, isTrue);
      final (bx, by) = legacy.backgroundPoint(390, 700);
      expect(bx, closeTo(0.5, 1e-9));
      expect(by, closeTo(0.5, 1e-9));
      // Al moverla pasa a coordenadas de la ilustración y se guarda como v2
      final moved = legacy.movedTo(0.2, 0.8);
      expect(moved.legacy, isFalse);
      expect(moved.toMap()['v'], 2);
      expect(PlacedDeco.fromMap(moved.toMap()).legacy, isFalse);
    });

    test('sin jardín guardado usa el prado', () {
      final d = PlacedDeco.fromMap({'instanceId': 'a', 'itemId': 'deco_lantern', 'fx': 0.1, 'fy': 0.2, 'v': 2});
      expect(d.gardenId, 'meadow');
    });
  });

  test('GardensCatalog.byId cae en el prado si el jardín está bloqueado o no existe', () {
    expect(GardensCatalog.byId('mountain').id, 'mountain');
    expect(GardensCatalog.byId('forest').id, 'meadow');
    expect(GardensCatalog.byId(null).id, 'meadow');
  });

  test('cada item del catálogo tiene su ilustración en assets', () {
    for (final plant in GardenCatalog.allPlants) {
      for (final stage in PlantStage.values) {
        final path = GardenAssets.plant(plant.id, stage);
        expect(File(path).existsSync(), isTrue, reason: path);
      }
    }
    for (final item in [...GardenCatalog.allDecorations, ...GardenCatalog.allBoosters]) {
      final path = GardenAssets.preview(item);
      expect(File(path).existsSync(), isTrue, reason: path);
    }
    for (final garden in GardensCatalog.all) {
      expect(File(garden.assetPath).existsSync(), isTrue, reason: garden.assetPath);
    }
  });
}
