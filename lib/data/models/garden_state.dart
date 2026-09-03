import 'garden_item.dart';

// ════════════════════════════════════════════════════════════════════════════
// CAMBIOS NECESARIOS EN garden_state.dart
// Reemplaza la clase PlantedItem y los métodos relacionados en GardenState
// ════════════════════════════════════════════════════════════════════════════

// ─── PlantedItem ACTUALIZADO ──────────────────────────────────────────────────

/// Una planta colocada en el jardín del usuario.
/// Usa gardenId + slotIndex en lugar de gridX/gridY para soportar
/// múltiples jardines con layouts distintos.
class PlantedItem {
  final String instanceId;
  final String itemId;
  final DateTime plantedAt;
  final DateTime? boostedAt;
  final Duration totalBoosted;
  final String gardenId;   // 'meadow', 'mountain', etc.
  final int slotIndex;     // índice del slot dentro de ese jardín

  // NOTA: gridX y gridY se mantienen por retrocompatibilidad con Firestore
  final int gridX;
  final int gridY;

  // ── NUEVO: última cosecha individual de esta planta ──────────────────────
  final DateTime? lastHarvestedAt;

  const PlantedItem({
    required this.instanceId,
    required this.itemId,
    required this.plantedAt,
    this.boostedAt,
    this.totalBoosted = Duration.zero,
    required this.gardenId,
    required this.slotIndex,
    this.gridX = 0,
    this.gridY = 0,
    this.lastHarvestedAt,
  });

  /// ¿Esta planta tiene cosecha pendiente hoy?
  /// Verdadero si es adulta Y no ha sido cosechada hoy.
  bool hasPendingHarvestFor(GardenItem item) {
    if (!isAdult(item)) return false;
    if (lastHarvestedAt == null) return true;
    final today = DateTime.now();
    final last = lastHarvestedAt!;
    return !(last.year == today.year &&
        last.month == today.month &&
        last.day == today.day);
  }

  Duration get effectiveAge {
    final realAge = DateTime.now().difference(plantedAt);
    return realAge + totalBoosted;
  }

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

  bool isAdult(GardenItem item) => currentStage(item) == PlantStage.adult;

  double growthProgress(GardenItem item) {
    if (item.stageThresholds == null || item.growthTime == null) return 1.0;
    final age = effectiveAge;
    final total = item.growthTime!;
    return (age.inSeconds / total.inSeconds).clamp(0.0, 1.0);
  }

  Duration? timeRemaining(GardenItem item) {
    if (item.growthTime == null) return null;
    final remaining = item.growthTime! - effectiveAge;
    return remaining.isNegative ? Duration.zero : remaining;
  }

  String currentEmoji(GardenItem item) {
    if (item.stageEmojis == null) return item.emoji;
    final stage = currentStage(item);
    return item.stageEmojis![stage] ?? item.emoji;
  }

  Map<String, dynamic> toMap() => {
    'instanceId': instanceId,
    'itemId': itemId,
    'plantedAt': plantedAt.toIso8601String(),
    'boostedAt': boostedAt?.toIso8601String(),
    'totalBoostedMs': totalBoosted.inMilliseconds,
    'gardenId': gardenId,
    'slotIndex': slotIndex,
    'gridX': gridX,
    'gridY': gridY,
    // NUEVO
    'lastHarvestedAt': lastHarvestedAt?.toIso8601String(),
  };

  factory PlantedItem.fromMap(Map<String, dynamic> map) {
    final gardenId = (map['gardenId'] as String?) ?? 'meadow';
    final slotIndex = (map['slotIndex'] as int?) ??
        ((map['gridX'] as int?) ?? 0);

    return PlantedItem(
      instanceId: map['instanceId'] as String,
      itemId: map['itemId'] as String,
      plantedAt: DateTime.parse(map['plantedAt'] as String),
      boostedAt: map['boostedAt'] != null
          ? DateTime.parse(map['boostedAt'] as String)
          : null,
      totalBoosted:
          Duration(milliseconds: (map['totalBoostedMs'] as int?) ?? 0),
      gardenId: gardenId,
      slotIndex: slotIndex,
      gridX: (map['gridX'] as int?) ?? 0,
      gridY: (map['gridY'] as int?) ?? 0,
      // NUEVO — null si la planta nunca ha sido cosechada (datos existentes)
      lastHarvestedAt: map['lastHarvestedAt'] != null
          ? DateTime.parse(map['lastHarvestedAt'] as String)
          : null,
    );
  }

  PlantedItem copyWith({
    Duration? totalBoosted,
    DateTime? boostedAt,
    DateTime? lastHarvestedAt,
  }) =>
      PlantedItem(
        instanceId: instanceId,
        itemId: itemId,
        plantedAt: plantedAt,
        boostedAt: boostedAt ?? this.boostedAt,
        totalBoosted: totalBoosted ?? this.totalBoosted,
        gardenId: gardenId,
        slotIndex: slotIndex,
        gridX: gridX,
        gridY: gridY,
        lastHarvestedAt: lastHarvestedAt ?? this.lastHarvestedAt,
      );
}

// ─── InventoryItem ────────────────────────────────────────────────────────────

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

class GardenState {
  final int seeds;
  final int totalSeedsEarned;
  final List<InventoryItem> inventory;
  final List<PlantedItem> garden;
  final List<String> purchasedIds;
  final DateTime? lastDailyReward;

  const GardenState({
    this.seeds = 0,
    this.totalSeedsEarned = 0,
    this.inventory = const [],
    this.garden = const [],
    this.purchasedIds = const [],
    this.lastDailyReward,
  });

  bool hasInInventory(String itemId) =>
      inventory.any((i) => i.itemId == itemId && i.quantity > 0);

  int quantityOf(String itemId) {
    try {
      return inventory.firstWhere((i) => i.itemId == itemId).quantity;
    } catch (_) {
      return 0;
    }
  }

  bool hasPurchased(String itemId) => purchasedIds.contains(itemId);

  bool canAfford(GardenItem item) => seeds >= item.seedCost && item.seedCost > 0;

  Set<String> get occupiedPositions =>
      garden.map((p) => '${p.gridX}_${p.gridY}').toSet();

  bool isPositionFree(int x, int y) =>
      !occupiedPositions.contains('${x}_$y');

  List<PlantedItem> get growingPlants {
    return garden.where((p) {
      final item = GardenCatalog.findById(p.itemId);
      if (item == null || item.type != ItemType.plant) return false;
      return !p.isAdult(item);
    }).toList();
  }

  List<PlantedItem> get adultPlants {
    return garden.where((p) {
      final item = GardenCatalog.findById(p.itemId);
      if (item == null || item.type != ItemType.plant) return false;
      return p.isAdult(item);
    }).toList();
  }

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

  static GardenState initial() => const GardenState(
    seeds: 20,
    inventory: [
      InventoryItem(itemId: 'plant_clover', quantity: 1),
    ],
  );

  @override
  String toString() =>
      'GardenState(seeds: $seeds, plants: ${garden.length}, inventory: ${inventory.length})';
}