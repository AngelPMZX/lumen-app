import 'package:flutter/material.dart';

// ─── Enums ────────────────────────────────────────────────────────────────────

enum PlantStage { seed, sprout, young, adult }

enum ItemType { plant, decoration, booster, theme }

enum ItemRarity { common, rare, epic, legendary, seasonal }

// ─── GardenItem ───────────────────────────────────────────────────────────────

class GardenItem {
  final String id;
  final String nameKey;        // clave i18n
  final String descriptionKey; // clave i18n
  final ItemType type;
  final ItemRarity rarity;
  final String emoji;

  // Costos
  final int seedCost;          // 0 = no disponible con semillas
  final double? premiumCost;   // null = solo con semillas, valor = precio USD

  // Solo para plantas
  final Duration? growthTime;  // tiempo total hasta adulta
  final List<Duration>? stageThresholds; // [sprout, young, adult] desde plantedAt

  // Estacionalidad
  final bool isSeasonal;
  final int? availableMonth;   // 1-12, null = siempre disponible

  // Visual por etapa (solo plantas)
  final Map<PlantStage, String>? stageEmojis;

  // Para boosters: cuánto tiempo reducen
  final Duration? boostDuration;

  // Para temas: color de fondo
  final Color? themeColor;

  const GardenItem({
    required this.id,
    required this.nameKey,
    required this.descriptionKey,
    required this.type,
    required this.rarity,
    required this.emoji,
    required this.seedCost,
    this.premiumCost,
    this.growthTime,
    this.stageThresholds,
    this.isSeasonal = false,
    this.availableMonth,
    this.stageEmojis,
    this.boostDuration,
    this.themeColor,
  });

  /// ¿Está disponible este mes?
  bool get isCurrentlyAvailable {
    if (!isSeasonal) return true;
    final currentMonth = DateTime.now().month;
    return availableMonth == currentMonth;
  }

  /// ¿Es de pago?
  bool get isPremium => premiumCost != null && seedCost == 0;

  /// ¿Puede comprarse con semillas?
  bool get canBuyWithSeeds => seedCost > 0;

  // Serialización
  Map<String, dynamic> toMap() => {
    'id': id,
    'type': type.name,
    'rarity': rarity.name,
  };

  @override
  bool operator ==(Object other) => other is GardenItem && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

// ─── Catálogo completo ────────────────────────────────────────────────────────

class GardenCatalog {
  GardenCatalog._();

  // ── PLANTAS ──────────────────────────────────────────────────────────────

  static const GardenItem cloverPlant = GardenItem(
    id: 'plant_clover',
    nameKey: 'garden.plants.clover.name',
    descriptionKey: 'garden.plants.clover.description',
    type: ItemType.plant,
    rarity: ItemRarity.common,
    emoji: '🍀',
    seedCost: 15,
    growthTime: Duration(hours: 6),
    stageThresholds: [
      Duration(hours: 1),   // → sprout
      Duration(hours: 3),   // → young
      Duration(hours: 6),   // → adult
    ],
    stageEmojis: {
      PlantStage.seed:   '🟤',
      PlantStage.sprout: '🌱',
      PlantStage.young:  '🌿',
      PlantStage.adult:  '🍀',
    },
  );

  static const GardenItem cactusPlant = GardenItem(
    id: 'plant_cactus',
    nameKey: 'garden.plants.cactus.name',
    descriptionKey: 'garden.plants.cactus.description',
    type: ItemType.plant,
    rarity: ItemRarity.common,
    emoji: '🌵',
    seedCost: 25,
    growthTime: Duration(hours: 12),
    stageThresholds: [
      Duration(hours: 2),
      Duration(hours: 6),
      Duration(hours: 12),
    ],
    stageEmojis: {
      PlantStage.seed:   '🟤',
      PlantStage.sprout: '🌱',
      PlantStage.young:  '🌵',
      PlantStage.adult:  '🌵',
    },
  );

  static const GardenItem bambooPlant = GardenItem(
    id: 'plant_bamboo',
    nameKey: 'garden.plants.bamboo.name',
    descriptionKey: 'garden.plants.bamboo.description',
    type: ItemType.plant,
    rarity: ItemRarity.common,
    emoji: '🎋',
    seedCost: 40,
    growthTime: Duration(hours: 24),
    stageThresholds: [
      Duration(hours: 4),
      Duration(hours: 12),
      Duration(hours: 24),
    ],
    stageEmojis: {
      PlantStage.seed:   '🟤',
      PlantStage.sprout: '🌱',
      PlantStage.young:  '🎍',
      PlantStage.adult:  '🎋',
    },
  );

  static const GardenItem cherryPlant = GardenItem(
    id: 'plant_cherry',
    nameKey: 'garden.plants.cherry.name',
    descriptionKey: 'garden.plants.cherry.description',
    type: ItemType.plant,
    rarity: ItemRarity.rare,
    emoji: '🌸',
    seedCost: 60,
    growthTime: Duration(hours: 48),
    stageThresholds: [
      Duration(hours: 8),
      Duration(hours: 24),
      Duration(hours: 48),
    ],
    stageEmojis: {
      PlantStage.seed:   '🟤',
      PlantStage.sprout: '🌱',
      PlantStage.young:  '🌿',
      PlantStage.adult:  '🌸',
    },
  );

  static const GardenItem lotusPlant = GardenItem(
    id: 'plant_lotus',
    nameKey: 'garden.plants.lotus.name',
    descriptionKey: 'garden.plants.lotus.description',
    type: ItemType.plant,
    rarity: ItemRarity.epic,
    emoji: '🪷',
    seedCost: 100,
    growthTime: Duration(hours: 72),
    stageThresholds: [
      Duration(hours: 12),
      Duration(hours: 36),
      Duration(hours: 72),
    ],
    stageEmojis: {
      PlantStage.seed:   '🟤',
      PlantStage.sprout: '🌱',
      PlantStage.young:  '🌺',
      PlantStage.adult:  '🪷',
    },
  );

  // ── PLANTAS ESTACIONALES ──────────────────────────────────────────────────

  static const GardenItem christmasTree = GardenItem(
    id: 'plant_christmas_tree',
    nameKey: 'garden.plants.christmasTree.name',
    descriptionKey: 'garden.plants.christmasTree.description',
    type: ItemType.plant,
    rarity: ItemRarity.seasonal,
    emoji: '🎄',
    seedCost: 0,
    premiumCost: 0.99,
    isSeasonal: true,
    availableMonth: 12,
    growthTime: Duration(hours: 24),
    stageThresholds: [
      Duration(hours: 4),
      Duration(hours: 12),
      Duration(hours: 24),
    ],
    stageEmojis: {
      PlantStage.seed:   '🌲',
      PlantStage.sprout: '🌲',
      PlantStage.young:  '🎄',
      PlantStage.adult:  '🎄',
    },
  );

  static const GardenItem pumpkinPlant = GardenItem(
    id: 'plant_pumpkin',
    nameKey: 'garden.plants.pumpkin.name',
    descriptionKey: 'garden.plants.pumpkin.description',
    type: ItemType.plant,
    rarity: ItemRarity.seasonal,
    emoji: '🎃',
    seedCost: 0,
    premiumCost: 0.99,
    isSeasonal: true,
    availableMonth: 10,
    growthTime: Duration(hours: 18),
    stageThresholds: [
      Duration(hours: 3),
      Duration(hours: 9),
      Duration(hours: 18),
    ],
    stageEmojis: {
      PlantStage.seed:   '🟤',
      PlantStage.sprout: '🌱',
      PlantStage.young:  '🍊',
      PlantStage.adult:  '🎃',
    },
  );

  // ── DECORACIONES ─────────────────────────────────────────────────────────

  static const GardenItem zenStone = GardenItem(
    id: 'deco_zen_stone',
    nameKey: 'garden.decorations.zenStone.name',
    descriptionKey: 'garden.decorations.zenStone.description',
    type: ItemType.decoration,
    rarity: ItemRarity.common,
    emoji: '🪨',
    seedCost: 20,
  );

  static const GardenItem lantern = GardenItem(
    id: 'deco_lantern',
    nameKey: 'garden.decorations.lantern.name',
    descriptionKey: 'garden.decorations.lantern.description',
    type: ItemType.decoration,
    rarity: ItemRarity.rare,
    emoji: '🏮',
    seedCost: 35,
  );

  static const GardenItem fountain = GardenItem(
    id: 'deco_fountain',
    nameKey: 'garden.decorations.fountain.name',
    descriptionKey: 'garden.decorations.fountain.description',
    type: ItemType.decoration,
    rarity: ItemRarity.epic,
    emoji: '⛲',
    seedCost: 80,
  );

  static const GardenItem bridge = GardenItem(
    id: 'deco_bridge',
    nameKey: 'garden.decorations.bridge.name',
    descriptionKey: 'garden.decorations.bridge.description',
    type: ItemType.decoration,
    rarity: ItemRarity.rare,
    emoji: '🌉',
    seedCost: 50,
    premiumCost: 1.99,
  );

  // ── BOOSTERS ─────────────────────────────────────────────────────────────

  static const GardenItem waterDrop = GardenItem(
    id: 'boost_water',
    nameKey: 'garden.boosters.water.name',
    descriptionKey: 'garden.boosters.water.description',
    type: ItemType.booster,
    rarity: ItemRarity.common,
    emoji: '💧',
    seedCost: 0, // solo se obtiene como recompensa aleatoria
    boostDuration: Duration(hours: 2),
  );

  static const GardenItem sunRay = GardenItem(
    id: 'boost_sun',
    nameKey: 'garden.boosters.sun.name',
    descriptionKey: 'garden.boosters.sun.description',
    type: ItemType.booster,
    rarity: ItemRarity.rare,
    emoji: '☀️',
    seedCost: 0,
    boostDuration: Duration(hours: 6),
  );

  static const GardenItem magicFertilizer = GardenItem(
    id: 'boost_fertilizer',
    nameKey: 'garden.boosters.fertilizer.name',
    descriptionKey: 'garden.boosters.fertilizer.description',
    type: ItemType.booster,
    rarity: ItemRarity.epic,
    emoji: '🌿',
    seedCost: 0,
    boostDuration: Duration(hours: 12),
  );

  static const GardenItem zenElixir = GardenItem(
    id: 'boost_elixir',
    nameKey: 'garden.boosters.elixir.name',
    descriptionKey: 'garden.boosters.elixir.description',
    type: ItemType.booster,
    rarity: ItemRarity.legendary,
    emoji: '⚗️',
    seedCost: 0,
    premiumCost: 0.99,
    boostDuration: Duration(days: 999), // completa al instante
  );

  // ── LISTAS ────────────────────────────────────────────────────────────────

  static const List<GardenItem> allPlants = [
    cloverPlant,
    cactusPlant,
    bambooPlant,
    cherryPlant,
    lotusPlant,
    christmasTree,
    pumpkinPlant,
  ];

  static const List<GardenItem> allDecorations = [
    zenStone,
    lantern,
    fountain,
    bridge,
  ];

  static const List<GardenItem> allBoosters = [
    waterDrop,
    sunRay,
    magicFertilizer,
    zenElixir,
  ];

  static List<GardenItem> get all => [
    ...allPlants,
    ...allDecorations,
    ...allBoosters,
  ];

  static List<GardenItem> get availableNow =>
      all.where((item) => item.isCurrentlyAvailable).toList();

  static GardenItem? findById(String id) {
    try {
      return all.firstWhere((item) => item.id == id);
    } catch (_) {
      return null;
    }
  }

  // ── Recompensas aleatorias de retos ──────────────────────────────────────
  // Probabilidades: 70% semillas, 20% booster común, 9% booster raro, 1% booster épico

  static const List<_RewardWeight> challengeRewardPool = [
    _RewardWeight(itemId: null,              weight: 70), // semillas
    _RewardWeight(itemId: 'boost_water',     weight: 20),
    _RewardWeight(itemId: 'boost_sun',       weight: 9),
    _RewardWeight(itemId: 'boost_fertilizer',weight: 1),
  ];
}

/// Peso para el sistema de recompensas aleatorias
class _RewardWeight {
  final String? itemId; // null = semillas
  final int weight;
  const _RewardWeight({required this.itemId, required this.weight});
}