import 'garden_item.dart';

// ─── PlantedItem ──────────────────────────────────────────────────────────────

/// Una planta colocada en el jardín del usuario
class PlantedItem {
  final String instanceId;   // UUID único por instancia plantada
  final String itemId;       // referencia a GardenItem.id
  final DateTime plantedAt;
  final DateTime? boostedAt; // última vez que se aplicó booster
  final Duration totalBoosted; // tiempo total acortado por boosters
  final int gridX;           // posición en el grid (0-5)
  final int gridY;           // posición en el grid (0-3)

  const PlantedItem({
    required this.instanceId,
    required this.itemId,
    required this.plantedAt,
    this.boostedAt,
    this.totalBoosted = Duration.zero,
    required this.gridX,
    required this.gridY,
  });

  /// Tiempo efectivo transcurrido (real + boost aplicado)
  Duration get effectiveAge {
    final realAge = DateTime.now().difference(plantedAt);
    return realAge + totalBoosted;
  }

  /// Etapa actual de crecimiento
  PlantStage currentStage(GardenItem item) {
    if (item.stageThresholds == null || item.growthTime == null) {
      return PlantStage.adult;
    }
    final age = effectiveAge;
    final thresholds = item.stageThresholds!;
    if (age >= thresholds[2]) return PlantStage.adult;
    if (age >= thresholds[1]) return PlantStage.young;
    if (age >= thresholds[0]) return PlantStage.sprout;
    return PlantStage.seed;
  }

  /// ¿Ya está completamente crecida?
  bool isAdult(GardenItem item) => currentStage(item) == PlantStage.adult;

  /// Progreso 0.0 - 1.0 hacia el siguiente stage
  double growthProgress(GardenItem item) {
    if (item.stageThresholds == null || item.growthTime == null) return 1.0;
    final age = effectiveAge;
    final total = item.growthTime!;
    return (age.inSeconds / total.inSeconds).clamp(0.0, 1.0);
  }

  /// Tiempo restante para completar crecimiento
  Duration? timeRemaining(GardenItem item) {
    if (item.growthTime == null) return null;
    final remaining = item.growthTime! - effectiveAge;
    return remaining.isNegative ? Duration.zero : remaining;
  }

  /// Emoji actual según etapa
  String currentEmoji(GardenItem item) {
    if (item.stageEmojis == null) return item.emoji;
    final stage = currentStage(item);
    return item.stageEmojis![stage] ?? item.emoji;
  }

  // ── Serialización ─────────────────────────────────────────────────────────

  Map<String, dynamic> toMap() => {
    'instanceId': instanceId,
    'itemId': itemId,
    'plantedAt': plantedAt.toIso8601String(),
    'boostedAt': boostedAt?.toIso8601String(),
    'totalBoostedMs': totalBoosted.inMilliseconds,
    'gridX': gridX,
    'gridY': gridY,
  };

  factory PlantedItem.fromMap(Map<String, dynamic> map) => PlantedItem(
    instanceId: map['instanceId'] as String,
    itemId: map['itemId'] as String,
    plantedAt: DateTime.parse(map['plantedAt'] as String),
    boostedAt: map['boostedAt'] != null
        ? DateTime.parse(map['boostedAt'] as String)
        : null,
    totalBoosted: Duration(milliseconds: (map['totalBoostedMs'] as int?) ?? 0),
    gridX: (map['gridX'] as int?) ?? 0,
    gridY: (map['gridY'] as int?) ?? 0,
  );

  PlantedItem copyWith({
    Duration? totalBoosted,
    DateTime? boostedAt,
  }) => PlantedItem(
    instanceId: instanceId,
    itemId: itemId,
    plantedAt: plantedAt,
    boostedAt: boostedAt ?? this.boostedAt,
    totalBoosted: totalBoosted ?? this.totalBoosted,
    gridX: gridX,
    gridY: gridY,
  );
}

// ─── InventoryItem ────────────────────────────────────────────────────────────

/// Un item en el inventario del usuario (sin colocar aún)
class InventoryItem {
  final String itemId;
  final int quantity;

  const InventoryItem({
    required this.itemId,
    required this.quantity,
  });

  Map<String, dynamic> toMap() => {
    'itemId': itemId,
    'quantity': quantity,
  };

  factory InventoryItem.fromMap(Map<String, dynamic> map) => InventoryItem(
    itemId: map['itemId'] as String,
    quantity: (map['quantity'] as int?) ?? 1,
  );

  InventoryItem copyWith({int? quantity}) => InventoryItem(
    itemId: itemId,
    quantity: quantity ?? this.quantity,
  );
}

// ─── GardenState ──────────────────────────────────────────────────────────────

/// Estado completo del jardín del usuario
class GardenState {
  final int seeds;                      // moneda principal "Semillas de Luz"
  final int totalSeedsEarned;          // histórico para estadísticas
  final List<InventoryItem> inventory; // items sin colocar
  final List<PlantedItem> garden;      // items colocados en el grid
  final List<String> purchasedIds;     // IDs comprados (para RevenueCat/restore)
  final DateTime? lastDailyReward;     // para no dar recompensa duplicada

  const GardenState({
    this.seeds = 0,
    this.totalSeedsEarned = 0,
    this.inventory = const [],
    this.garden = const [],
    this.purchasedIds = const [],
    this.lastDailyReward,
  });

  // ── Helpers ───────────────────────────────────────────────────────────────

  /// ¿Tiene este item en inventario?
  bool hasInInventory(String itemId) {
    return inventory.any((i) => i.itemId == itemId && i.quantity > 0);
  }

  /// Cantidad de un item en inventario
  int quantityOf(String itemId) {
    try {
      return inventory.firstWhere((i) => i.itemId == itemId).quantity;
    } catch (_) {
      return 0;
    }
  }

  /// ¿Ya compró este item premium?
  bool hasPurchased(String itemId) => purchasedIds.contains(itemId);

  /// ¿Puede comprar con semillas?
  bool canAfford(GardenItem item) => seeds >= item.seedCost && item.seedCost > 0;

  /// Posiciones ocupadas en el grid
  Set<String> get occupiedPositions =>
      garden.map((p) => '${p.gridX}_${p.gridY}').toSet();

  /// ¿Posición libre en el grid?
  bool isPositionFree(int x, int y) =>
      !occupiedPositions.contains('${x}_$y');

  /// Plantas actualmente creciendo (no adultas)
  List<PlantedItem> get growingPlants {
    return garden.where((p) {
      final item = GardenCatalog.findById(p.itemId);
      if (item == null || item.type != ItemType.plant) return false;
      return !p.isAdult(item);
    }).toList();
  }

  /// Plantas completamente adultas
  List<PlantedItem> get adultPlants {
    return garden.where((p) {
      final item = GardenCatalog.findById(p.itemId);
      if (item == null || item.type != ItemType.plant) return false;
      return p.isAdult(item);
    }).toList();
  }

  // ── Serialización ─────────────────────────────────────────────────────────

  Map<String, dynamic> toMap() => {
    'seeds': seeds,
    'totalSeedsEarned': totalSeedsEarned,
    'inventory': inventory.map((i) => i.toMap()).toList(),
    'garden': garden.map((p) => p.toMap()).toList(),
    'purchasedIds': purchasedIds,
    'lastDailyReward': lastDailyReward?.toIso8601String(),
  };

  factory GardenState.fromMap(Map<String, dynamic> map) => GardenState(
    seeds: (map['seeds'] as int?) ?? 0,
    totalSeedsEarned: (map['totalSeedsEarned'] as int?) ?? 0,
    inventory: (map['inventory'] as List<dynamic>? ?? [])
        .map((i) => InventoryItem.fromMap(i as Map<String, dynamic>))
        .toList(),
    garden: (map['garden'] as List<dynamic>? ?? [])
        .map((p) => PlantedItem.fromMap(p as Map<String, dynamic>))
        .toList(),
    purchasedIds: List<String>.from(map['purchasedIds'] as List? ?? []),
    lastDailyReward: map['lastDailyReward'] != null
        ? DateTime.parse(map['lastDailyReward'] as String)
        : null,
  );

  GardenState copyWith({
    int? seeds,
    int? totalSeedsEarned,
    List<InventoryItem>? inventory,
    List<PlantedItem>? garden,
    List<String>? purchasedIds,
    DateTime? lastDailyReward,
  }) => GardenState(
    seeds: seeds ?? this.seeds,
    totalSeedsEarned: totalSeedsEarned ?? this.totalSeedsEarned,
    inventory: inventory ?? this.inventory,
    garden: garden ?? this.garden,
    purchasedIds: purchasedIds ?? this.purchasedIds,
    lastDailyReward: lastDailyReward ?? this.lastDailyReward,
  );

  /// Estado inicial para usuarios nuevos — con trébol de regalo
  static GardenState initial() => GardenState(
    seeds: 20, // semillas de bienvenida
    inventory: const [
      InventoryItem(itemId: 'plant_clover', quantity: 1), // regalo inicial
    ],
  );

  @override
  String toString() =>
      'GardenState(seeds: $seeds, plants: ${garden.length}, inventory: ${inventory.length})';
}