// ═════════════════════════════════════════════════════════════════════════════
// GARDEN MECHANICS — Cosecha, Comodín de Racha y Multiplicador XP
// ═════════════════════════════════════════════════════════════════════════════

/// Resultado de la cosecha diaria
class HarvestResult {
  final int seedsEarned;
  final bool gotXpMultiplier;
  final double xpMultiplier;     // 1.5, 2.0, 2.5
  final int multiplierMinutes;   // cuántos minutos dura
  final bool gotStreakShield;    // solo Cerezo/Loto
  final String? shieldFromPlant; // nombre de la planta que lo dio

  const HarvestResult({
    required this.seedsEarned,
    this.gotXpMultiplier = false,
    this.xpMultiplier = 1.0,
    this.multiplierMinutes = 0,
    this.gotStreakShield = false,
    this.shieldFromPlant,
  });

  bool get hasAnything =>
      seedsEarned > 0 || gotXpMultiplier || gotStreakShield;
}

/// Estado del multiplicador de XP activo
class XpMultiplierState {
  final double multiplier;
  final DateTime expiresAt;

  const XpMultiplierState({
    required this.multiplier,
    required this.expiresAt,
  });

  bool get isActive => DateTime.now().isBefore(expiresAt);

  Duration get timeRemaining {
    final remaining = expiresAt.difference(DateTime.now());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  Map<String, dynamic> toMap() => {
    'multiplier': multiplier,
    'expiresAt': expiresAt.millisecondsSinceEpoch,
  };

  factory XpMultiplierState.fromMap(Map<String, dynamic> m) =>
      XpMultiplierState(
        multiplier: (m['multiplier'] as num).toDouble(),
        expiresAt: DateTime.fromMillisecondsSinceEpoch(m['expiresAt'] as int),
      );
}

/// Configuración por planta para las mecánicas
class PlantMechanics {
  /// Semillas que genera por día cuando está adulta
  final int seedsPerDay;

  /// Probabilidad (0.0–1.0) de generar multiplicador XP al cosechar
  final double xpMultiplierChance;

  /// Multiplicador de XP si cae el random
  final double xpMultiplier;

  /// Minutos que dura el multiplicador
  final int xpMultiplierMinutes;

  /// ¿Puede generar escudo de racha? Solo plantas raras+
  final bool canGiveStreakShield;

  /// Probabilidad de dar escudo en la cosecha semanal
  final double shieldChance;

  const PlantMechanics({
    required this.seedsPerDay,
    required this.xpMultiplierChance,
    required this.xpMultiplier,
    required this.xpMultiplierMinutes,
    required this.canGiveStreakShield,
    this.shieldChance = 0.0,
  });
}

/// Tabla de mecánicas por itemId de planta
const Map<String, PlantMechanics> kPlantMechanics = {
  // Trébol — común, cosecha baja, sin escudos, ~10% mult
  'plant_clover': PlantMechanics(
    seedsPerDay: 1,
    xpMultiplierChance: 0.10,
    xpMultiplier: 1.5,
    xpMultiplierMinutes: 10,
    canGiveStreakShield: false,
  ),
  // Cactus — común, ~15% mult
  'plant_cactus': PlantMechanics(
    seedsPerDay: 2,
    xpMultiplierChance: 0.15,
    xpMultiplier: 1.5,
    xpMultiplierMinutes: 10,
    canGiveStreakShield: false,
  ),
  // Bambú — común+, ~20% mult
  'plant_bamboo': PlantMechanics(
    seedsPerDay: 3,
    xpMultiplierChance: 0.20,
    xpMultiplier: 2.0,
    xpMultiplierMinutes: 10,
    canGiveStreakShield: false,
  ),
  // Cerezo — raro, ~30% mult, puede dar escudo
  'plant_cherry': PlantMechanics(
    seedsPerDay: 4,
    xpMultiplierChance: 0.30,
    xpMultiplier: 2.0,
    xpMultiplierMinutes: 10,
    canGiveStreakShield: true,
    shieldChance: 0.40, // 40% de chance al cosechar en la semana
  ),
  // Loto — épico, ~40% mult, mejor escudo
  'plant_lotus': PlantMechanics(
    seedsPerDay: 5,
    xpMultiplierChance: 0.40,
    xpMultiplier: 2.5,
    xpMultiplierMinutes: 10,
    canGiveStreakShield: true,
    shieldChance: 0.60,
  ),
};

/// Devuelve la mecánica de una planta (fallback genérico si no está en la tabla)
PlantMechanics mechanicsFor(String itemId) {
  return kPlantMechanics[itemId] ??
      const PlantMechanics(
        seedsPerDay: 1,
        xpMultiplierChance: 0.10,
        xpMultiplier: 1.5,
        xpMultiplierMinutes: 10,
        canGiveStreakShield: false,
      );
}