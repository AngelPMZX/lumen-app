import 'dart:math';
import 'garden_item.dart';

// ─── Tipos de recompensa ──────────────────────────────────────────────────────

enum RewardSource {
  dailyChallenge,
  lessonCompleted,
  moodCheckIn,
  streakMilestone,
  breathing,
  diaryEntry,
}

/// El resultado de una recompensa
class RewardResult {
  final RewardType type;
  final int seeds;           // si type == seeds
  final GardenItem? item;   // si type == item
  final String titleKey;    // clave i18n para el título del popup
  final String messageKey;  // clave i18n para el mensaje

  const RewardResult({
    required this.type,
    this.seeds = 0,
    this.item,
    required this.titleKey,
    required this.messageKey,
  });

  /// ¿Es una recompensa de item (booster)?
  bool get isItem => type == RewardType.item && item != null;

  /// ¿Es semillas?
  bool get isSeeds => type == RewardType.seeds;

  String get emoji {
    if (isItem) return item!.emoji;
    return '✨';
  }
}

enum RewardType { seeds, item }

// ─── Configuración de recompensas por fuente ──────────────────────────────────

class _SourceConfig {
  final int minSeeds;
  final int maxSeeds;
  final int itemChancePercent; // % de probabilidad de dar item en lugar de semillas

  const _SourceConfig({
    required this.minSeeds,
    required this.maxSeeds,
    required this.itemChancePercent,
  });
}

// ─── RewardService ────────────────────────────────────────────────────────────

class RewardService {
  RewardService._();

  static final _rng = Random();

  /// Configuración por fuente de recompensa
  static const Map<RewardSource, _SourceConfig> _configs = {
    RewardSource.dailyChallenge: _SourceConfig(
      minSeeds: 3,
      maxSeeds: 8,
      itemChancePercent: 30, // 30% de dar booster
    ),
    RewardSource.lessonCompleted: _SourceConfig(
      minSeeds: 2,
      maxSeeds: 5,
      itemChancePercent: 15,
    ),
    RewardSource.moodCheckIn: _SourceConfig(
      minSeeds: 1,
      maxSeeds: 2,
      itemChancePercent: 5,
    ),
    RewardSource.streakMilestone: _SourceConfig(
      minSeeds: 10,
      maxSeeds: 20,
      itemChancePercent: 50,
    ),
    RewardSource.breathing: _SourceConfig(
      minSeeds: 2,
      maxSeeds: 4,
      itemChancePercent: 20,
    ),
    RewardSource.diaryEntry: _SourceConfig(
      minSeeds: 2,
      maxSeeds: 4,
      itemChancePercent: 10,
    ),
  };

  /// Pool de boosters con sus pesos (suman 100)
  static const List<_BoosterWeight> _boosterPool = [
    _BoosterWeight(itemId: 'boost_water',        weight: 65), // común
    _BoosterWeight(itemId: 'boost_sun',          weight: 30), // raro
    _BoosterWeight(itemId: 'boost_fertilizer',   weight: 5),  // épico
    // elixir_zen NUNCA se da gratis — solo premium
  ];

  // ── API principal ──────────────────────────────────────────────────────────

  /// Genera una recompensa aleatoria según la fuente
  static RewardResult generate(RewardSource source) {
    final config = _configs[source]!;

    // ¿Da item o semillas?
    final roll = _rng.nextInt(100);
    if (roll < config.itemChancePercent) {
      final item = _pickBooster();
      if (item != null) {
        return RewardResult(
          type: RewardType.item,
          item: item,
          titleKey: 'garden.reward.itemTitle',
          messageKey: 'garden.reward.itemMessage',
        );
      }
    }

    // Dar semillas
    final seeds = config.minSeeds +
        _rng.nextInt(config.maxSeeds - config.minSeeds + 1);

    return RewardResult(
      type: RewardType.seeds,
      seeds: seeds,
      titleKey: 'garden.reward.seedsTitle',
      messageKey: 'garden.reward.seedsMessage',
    );
  }

  /// Genera recompensa específica para streak milestone
  static RewardResult generateStreakReward(int streakDays) {
    int bonus = 10;
    if (streakDays >= 30) bonus = 50;
    else if (streakDays >= 14) bonus = 30;
    else if (streakDays >= 7) bonus = 15;

    return RewardResult(
      type: RewardType.seeds,
      seeds: bonus,
      titleKey: 'garden.reward.streakTitle',
      messageKey: 'garden.reward.streakMessage',
    );
  }

  // ── Interno ───────────────────────────────────────────────────────────────

  static GardenItem? _pickBooster() {
    final total = _boosterPool.fold(0, (sum, b) => sum + b.weight);
    int roll = _rng.nextInt(total);

    for (final entry in _boosterPool) {
      roll -= entry.weight;
      if (roll < 0) {
        return GardenCatalog.findById(entry.itemId);
      }
    }
    return null;
  }
}

class _BoosterWeight {
  final String itemId;
  final int weight;
  const _BoosterWeight({required this.itemId, required this.weight});
}