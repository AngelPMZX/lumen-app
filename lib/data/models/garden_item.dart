import 'package:flutter/material.dart';

// ─── Enums ────────────────────────────────────────────────────────────────────

enum PlantStage { seed, sprout, young, adult }

enum ItemType { plant, decoration, booster, theme }

enum ItemRarity { common, rare, epic, legendary, seasonal }

// ─── GardenItem ───────────────────────────────────────────────────────────────

class GardenItem {
  final String id;
  final String nameKey;
  final String descriptionKey;
  final ItemType type;
  final ItemRarity rarity;
  final String emoji;

  final int seedCost;
  final double? premiumCost;

  final Duration? growthTime;
  final List<Duration>? stageThresholds;

  final bool isSeasonal;
  final int? availableMonth;

  final Map<PlantStage, String>? stageEmojis;
  final Duration? boostDuration;
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

  bool get isCurrentlyAvailable {
    if (!isSeasonal) return true;
    final currentMonth = DateTime.now().month;
    return availableMonth == currentMonth;
  }

  bool get isPremium => premiumCost != null && seedCost == 0;
  bool get canBuyWithSeeds => seedCost > 0;

  // ─── AURA / GLOW VISUAL ─────────────────────────────────────────────────
  // Cada item tiene un color y una intensidad de glow que se aplican
  // automáticamente en la tienda, inventario y jardín.

  /// Color específico del aura del item (personalidad visual)
  Color get auraColor {
    switch (id) {
      // Boosters
      case 'boost_water':           return const Color(0xFF06B6D4); // cyan
      case 'boost_sun':             return const Color(0xFFFBBF24); // dorado
      case 'boost_fertilizer':      return const Color(0xFF10B981); // verde
      case 'boost_elixir':          return const Color(0xFFA855F7); // morado
      // Plantas
      case 'plant_clover':          return const Color(0xFF10B981); // verde
      case 'plant_cactus':          return const Color(0xFF84CC16); // lime
      case 'plant_bamboo':          return const Color(0xFF22C55E); // verde bosque
      case 'plant_cherry':          return const Color(0xFFEC4899); // rosa
      case 'plant_lotus':           return const Color(0xFFA855F7); // morado
      case 'plant_christmas_tree':  return const Color(0xFFDC2626); // rojo festivo
      case 'plant_pumpkin':         return const Color(0xFFF97316); // naranja
      // Decoraciones — usar color por rareza
      default:                      return _rarityColor(rarity);
    }
  }

  /// Blur del glow según rareza (más raro = más intenso)
  double get auraBlurRadius {
    switch (rarity) {
      case ItemRarity.common:    return 8;
      case ItemRarity.rare:      return 12;
      case ItemRarity.epic:      return 16;
      case ItemRarity.legendary: return 20;
      case ItemRarity.seasonal:  return 16;
    }
  }

  /// Opacidad del glow según rareza
  double get auraOpacity {
    switch (rarity) {
      case ItemRarity.common:    return 0.15;
      case ItemRarity.rare:      return 0.25;
      case ItemRarity.epic:      return 0.35;
      case ItemRarity.legendary: return 0.45;
      case ItemRarity.seasonal:  return 0.35;
    }
  }

  static Color _rarityColor(ItemRarity r) {
    switch (r) {
      case ItemRarity.common:    return const Color(0xFF9CA3AF);
      case ItemRarity.rare:      return const Color(0xFF3B82F6);
      case ItemRarity.epic:      return const Color(0xFFA855F7);
      case ItemRarity.legendary: return const Color(0xFFFBBF24);
      case ItemRarity.seasonal:  return const Color(0xFFDC2626);
    }
  }

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

  // ── PLANTAS ───────────────────────────────────────────────────────────────

  static const GardenItem cloverPlant = GardenItem(
    id: 'plant_clover',
    nameKey: 'garden.plants.clover.name',
    descriptionKey: 'garden.plants.clover.description',
    type: ItemType.plant,
    rarity: ItemRarity.common,
    emoji: '🍀',
    seedCost: 15,
    growthTime: Duration(hours: 24),
    stageThresholds: [
      Duration(hours: 4),
      Duration(hours: 12),
      Duration(hours: 24),
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
    growthTime: Duration(hours: 48),
    stageThresholds: [
      Duration(hours: 8),
      Duration(hours: 24),
      Duration(hours: 48),
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
    growthTime: Duration(hours: 72),
    stageThresholds: [
      Duration(hours: 12),
      Duration(hours: 36),
      Duration(hours: 72),
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
    growthTime: Duration(hours: 120),
    stageThresholds: [
      Duration(hours: 20),
      Duration(hours: 60),
      Duration(hours: 120),
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
    growthTime: Duration(hours: 168),
    stageThresholds: [
      Duration(hours: 28),
      Duration(hours: 84),
      Duration(hours: 168),
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
    growthTime: Duration(hours: 48),
    stageThresholds: [
      Duration(hours: 8),
      Duration(hours: 24),
      Duration(hours: 48),
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
    growthTime: Duration(hours: 36),
    stageThresholds: [
      Duration(hours: 6),
      Duration(hours: 18),
      Duration(hours: 36),
    ],
    stageEmojis: {
      PlantStage.seed:   '🟤',
      PlantStage.sprout: '🌱',
      PlantStage.young:  '🍊',
      PlantStage.adult:  '🎃',
    },
  );

  // ── DECORACIONES ──────────────────────────────────────────────────────────

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

  // ── BOOSTERS ──────────────────────────────────────────────────────────────
  // Ahora comprables con semillas — antes solo se ganaban como recompensa.
  // El elixir sigue siendo solo premium por ser legendary.

  static const GardenItem waterDrop = GardenItem(
    id: 'boost_water',
    nameKey: 'garden.boosters.water.name',
    descriptionKey: 'garden.boosters.water.description',
    type: ItemType.booster,
    rarity: ItemRarity.common,
    emoji: '💧',
    seedCost: 20, // era 0
    boostDuration: Duration(hours: 2),
  );

  static const GardenItem sunRay = GardenItem(
    id: 'boost_sun',
    nameKey: 'garden.boosters.sun.name',
    descriptionKey: 'garden.boosters.sun.description',
    type: ItemType.booster,
    rarity: ItemRarity.rare,
    emoji: '☀️',
    seedCost: 60, // era 0
    boostDuration: Duration(hours: 6),
  );

  static const GardenItem magicFertilizer = GardenItem(
    id: 'boost_fertilizer',
    nameKey: 'garden.boosters.fertilizer.name',
    descriptionKey: 'garden.boosters.fertilizer.description',
    type: ItemType.booster,
    rarity: ItemRarity.epic,
    emoji: '🌿',
    seedCost: 150, // era 0
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
    boostDuration: Duration(days: 999),
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

  static const List<_RewardWeight> challengeRewardPool = [
    _RewardWeight(itemId: null,               weight: 70),
    _RewardWeight(itemId: 'boost_water',      weight: 20),
    _RewardWeight(itemId: 'boost_sun',        weight: 9),
    _RewardWeight(itemId: 'boost_fertilizer', weight: 1),
  ];
}

class _RewardWeight {
  final String? itemId;
  final int weight;
  const _RewardWeight({required this.itemId, required this.weight});
}