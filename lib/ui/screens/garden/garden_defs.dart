import 'package:flutter/material.dart';

import '../../../data/models/garden_item.dart';
import '../../../domain/services/sound_service.dart';
import 'garden_logic.dart';
import 'plant_metrics.dart';

// ═════════════════════════════════════════════════════════════════════════════
// Jardines: fondo ilustrado, huecos para plantas y ambiente sonoro
// ═════════════════════════════════════════════════════════════════════════════

/// Un jardín. Las coordenadas de los huecos son fracciones (0-1) de la
/// ilustración de fondo, en el centro de cada parche de tierra.
class GardenDef {
  final String id;
  final String nameKey;
  final String assetPath;
  final List<GardenSlot> slots;
  final bool isUnlocked;
  final Ambient ambient;

  /// Color del cielo de la ilustración (para velos y transiciones).
  final Color tint;

  const GardenDef({
    required this.id,
    required this.nameKey,
    required this.assetPath,
    required this.slots,
    required this.ambient,
    required this.tint,
    this.isUnlocked = false,
  });
}

class GardenSlot {
  final int slotIndex;
  final double anchorX;
  final double anchorY;
  final double plantScale;

  const GardenSlot({
    required this.slotIndex,
    required this.anchorX,
    required this.anchorY,
    this.plantScale = 1.0,
  });
}

class GardensCatalog {
  GardensCatalog._();

  static const GardenDef meadow = GardenDef(
    id: 'meadow',
    nameKey: 'garden.gardens.meadow',
    assetPath: 'assets/images/gardens/garden_meadow.webp',
    isUnlocked: true,
    ambient: Ambient.forest,
    tint: Color(0xFF8FB996),
    slots: [
      GardenSlot(slotIndex: 0, anchorX: 0.3542, anchorY: 0.2990),
      GardenSlot(slotIndex: 1, anchorX: 0.7942, anchorY: 0.3734),
      GardenSlot(slotIndex: 2, anchorX: 0.1642, anchorY: 0.4637),
      GardenSlot(slotIndex: 3, anchorX: 0.5742, anchorY: 0.5446),
      GardenSlot(slotIndex: 4, anchorX: 0.2525, anchorY: 0.6683),
      GardenSlot(slotIndex: 5, anchorX: 0.7658, anchorY: 0.7883),
    ],
  );

  static const GardenDef mountain = GardenDef(
    id: 'mountain',
    nameKey: 'garden.gardens.mountain',
    assetPath: 'assets/images/gardens/garden_mountain.webp',
    isUnlocked: true,
    ambient: Ambient.mountain,
    tint: Color(0xFF7FA7B8),
    slots: [
      GardenSlot(slotIndex: 0, anchorX: 0.3292, anchorY: 0.4023),
      GardenSlot(slotIndex: 1, anchorX: 0.7275, anchorY: 0.4190),
      GardenSlot(slotIndex: 2, anchorX: 0.2942, anchorY: 0.5204),
      GardenSlot(slotIndex: 3, anchorX: 0.7042, anchorY: 0.5772),
      GardenSlot(slotIndex: 4, anchorX: 0.7208, anchorY: 0.7055),
      GardenSlot(slotIndex: 5, anchorX: 0.2875, anchorY: 0.7539),
    ],
  );

  // Jardines futuros — bloqueados
  static const GardenDef forest = GardenDef(
    id: 'forest',
    nameKey: 'garden.gardens.forest',
    assetPath: 'assets/images/gardens/garden_forest.webp',
    ambient: Ambient.forest,
    tint: Color(0xFF5E8C61),
    slots: [],
  );

  static const GardenDef lake = GardenDef(
    id: 'lake',
    nameKey: 'garden.gardens.lake',
    assetPath: 'assets/images/gardens/garden_lake.webp',
    ambient: Ambient.stream,
    tint: Color(0xFF6BA3BE),
    slots: [],
  );

  static const GardenDef greenhouse = GardenDef(
    id: 'greenhouse',
    nameKey: 'garden.gardens.greenhouse',
    assetPath: 'assets/images/gardens/garden_greenhouse.webp',
    ambient: Ambient.rain,
    tint: Color(0xFF9CC5A1),
    slots: [],
  );

  static const List<GardenDef> all = [meadow, mountain, forest, lake, greenhouse];

  static GardenDef get defaultGarden => meadow;

  static GardenDef byId(String? id) =>
      all.firstWhere((g) => g.id == id && g.isUnlocked, orElse: () => meadow);
}

// ═════════════════════════════════════════════════════════════════════════════
// Imágenes de los items
// ═════════════════════════════════════════════════════════════════════════════

class GardenAssets {
  GardenAssets._();

  static String plant(String itemId, PlantStage stage) {
    final name = itemId.replaceFirst('plant_', '');
    return 'assets/images/plants/${name}_${stage.index + 1}_${stage.name}.webp';
  }

  static String decoration(String itemId) =>
      'assets/images/decorations/${itemId.replaceFirst('deco_', '')}.webp';

  static String booster(String itemId) =>
      'assets/images/boosters/${itemId.replaceFirst('boost_', '')}.webp';

  static const String seed = 'assets/images/currency/seed.webp';

  /// Imagen que representa al item (las plantas se muestran adultas).
  static String preview(GardenItem item, {PlantStage stage = PlantStage.adult}) => switch (item.type) {
        ItemType.plant => plant(item.id, stage),
        ItemType.decoration => decoration(item.id),
        ItemType.booster => booster(item.id),
        ItemType.theme => seed,
      };

  /// Nombre del archivo sin carpeta ni extensión (`bamboo_4_adult`), que es
  /// como [kPlantMetrics] guarda sus medidas.
  static String assetKey(String path) {
    final file = path.split('/').last;
    final dot = file.lastIndexOf('.');
    return dot < 0 ? file : file.substring(0, dot);
  }

  /// Tamaño de cada decoración en el jardín (px lógicos).
  static double decoSize(String itemId) => switch (itemId) {
        'deco_zen_stone' => 70,
        'deco_lantern' => 78,
        'deco_fountain' => 110,
        'deco_bridge' => 130,
        _ => 80,
      };
}

// ═════════════════════════════════════════════════════════════════════════════
// Rareza: color de la etiqueta (el aura de cada item vive en GardenItem)
// ═════════════════════════════════════════════════════════════════════════════

class RarityStyle {
  RarityStyle._();

  static Color color(ItemRarity rarity) => switch (rarity) {
        ItemRarity.common => const Color(0xFF10B981),
        ItemRarity.rare => const Color(0xFF3B82F6),
        ItemRarity.epic => const Color(0xFF8B5CF6),
        ItemRarity.legendary => const Color(0xFFF59E0B),
        ItemRarity.seasonal => const Color(0xFFEC4899),
      };

  static String label(ItemRarity rarity) => 'garden.rarity.${rarity.name}';

  static int shine(ItemRarity rarity) => GardenRules.shineLevel(rarity);
}

/// Colores de las hojas y paneles del jardín en claro y oscuro.
class GardenPalette {
  final bool isDark;
  const GardenPalette(this.isDark);

  static const green = Color(0xFF10B981);
  static const greenDark = Color(0xFF059669);
  static const gold = Color(0xFFF59E0B);
  static const violet = Color(0xFF8B5CF6);

  Color get sheet => isDark ? const Color(0xFF12211A) : const Color(0xFFFBF8EF);
  Color get card => isDark ? Colors.white.withValues(alpha: 0.06) : Colors.white;
  Color get cardBorder => isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE9E2CF);
  Color get ink => isDark ? Colors.white : const Color(0xFF26332B);
  Color get inkSoft => isDark ? Colors.white60 : const Color(0xFF6B7A70);
  Color get handle => isDark ? Colors.white24 : Colors.black12;

  static Color stageColor(PlantStage stage) => switch (stage) {
        PlantStage.seed => const Color(0xFFB45309),
        PlantStage.sprout => const Color(0xFF65A30D),
        PlantStage.young => const Color(0xFF16A34A),
        PlantStage.adult => green,
      };
}

// ═════════════════════════════════════════════════════════════════════════════
// Decoración colocada
// ═════════════════════════════════════════════════════════════════════════════

/// Decoración puesta en un jardín. `fx`/`fy` son fracciones de la ilustración.
/// Las guardadas antes de v2 eran fracciones de la pantalla (`legacy`): se
/// muestran igual que antes y pasan a coordenadas de la ilustración al moverlas.
class PlacedDeco {
  final String instanceId;
  final String itemId;
  final String gardenId;
  final double fx;
  final double fy;
  final bool legacy;

  const PlacedDeco({
    required this.instanceId,
    required this.itemId,
    required this.gardenId,
    required this.fx,
    required this.fy,
    this.legacy = false,
  });

  /// Punto de la ilustración para una pantalla de [viewW]×[viewH].
  (double, double) backgroundPoint(double viewW, double viewH) =>
      legacy ? GardenLayout.toBackground(fx * viewW, fy * viewH, viewW, viewH) : (fx, fy);

  PlacedDeco movedTo(double bx, double by) => PlacedDeco(
        instanceId: instanceId,
        itemId: itemId,
        gardenId: gardenId,
        fx: bx,
        fy: by,
      );

  Map<String, dynamic> toMap() => {
        'instanceId': instanceId,
        'itemId': itemId,
        'gardenId': gardenId,
        'fx': fx,
        'fy': fy,
        if (!legacy) 'v': 2,
      };

  factory PlacedDeco.fromMap(Map<String, dynamic> m) => PlacedDeco(
        instanceId: m['instanceId'] as String,
        itemId: m['itemId'] as String,
        gardenId: m['gardenId'] as String? ?? GardensCatalog.defaultGarden.id,
        fx: (m['fx'] as num).toDouble(),
        fy: (m['fy'] as num).toDouble(),
        legacy: m['v'] == null,
      );
}

// ═════════════════════════════════════════════════════════════════════════════
// Suelo: todas las etapas de una planta se apoyan en la misma línea
// ═════════════════════════════════════════════════════════════════════════════

/// Dónde pisa una planta dentro del cuadrado de su hueco.
///
/// Las ilustraciones traen mucho aire transparente y cada etapa lo reparte a
/// su manera: la base del dibujo cae entre el 66 % y el 96 % del alto del
/// lienzo. Pintadas todas centradas en el mismo cuadrado, la planta **saltaba
/// al crecer** y la tierra se salía del hueco (lo vieron los testers). Con
/// [kPlantMetrics] (que genera `tools/images/measure_plants.py` midiendo los
/// archivos) cada etapa se desplaza para pisar [line].
abstract final class PlantGround {
  /// Línea de tierra, en fracción del cuadrado del hueco.
  ///
  /// Es casi la base media de las plantas adultas (0.918), que es con lo que
  /// se colocaron los huecos sobre la ilustración del jardín: así las adultas
  /// se quedan donde estaban y son las etapas pequeñas —las que flotaban— las
  /// que bajan a su sitio. Un poco más arriba que esa media para que la
  /// sombra y el anillo de selección quepan dentro del cuadrado.
  static const double line = 0.88;

  static PlantMetrics? metricsFor(String assetPath) =>
      kPlantMetrics[GardenAssets.assetKey(assetPath)];

  /// Cuánto mover el dibujo dentro de un cuadrado de [size] para que se apoye
  /// en [line] y quede centrado. Sin medida (una ilustración nueva sin pasar
  /// por el script) no se mueve nada y se ve como antes.
  static Offset offsetFor(String assetPath, double size) {
    final m = metricsFor(assetPath);
    if (m == null) return Offset.zero;
    return Offset((0.5 - m.centerX) * size, (line - m.baseY) * size);
  }

  /// Cuánto mover el dibujo para centrarlo **a él**, no a su lienzo. Para
  /// medallones y vitrinas, donde no hay suelo y lo que estorba es el aire
  /// que la ilustración deja de más arriba o abajo.
  static Offset centerOffsetFor(String assetPath, double size) {
    final m = metricsFor(assetPath);
    if (m == null) return Offset.zero;
    return Offset((0.5 - m.centerX) * size, (0.5 - m.centerY) * size);
  }
}
