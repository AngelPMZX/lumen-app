import '../../../widgets/clip_sideways.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/utils/image_sizing.dart';
import '../../../../data/models/garden_item.dart';
import '../../../../data/models/garden_mechanics.dart';
import '../../../../data/models/garden_state.dart';
import '../../../../domain/services/motion_service.dart';
import '../../../widgets/min_tap_target.dart';
import '../../../widgets/seed_icon.dart';
import '../garden_defs.dart';
import 'garden_common.dart';
import 'garden_plant_slot.dart';

/// Panel de la planta seleccionada: etapas con sus ilustraciones, tiempo,
/// boosters para usar ahí mismo, cosecha y retirar.
class PlantInfoPanel extends StatelessWidget {
  final PlantedItem planted;
  final GardenItem item;
  final GardenState state;
  final VoidCallback onClose;
  final VoidCallback onHarvest;
  final ValueChanged<String> onBooster;
  final VoidCallback onRemove;
  final VoidCallback onShop;

  const PlantInfoPanel({
    super.key,
    required this.planted,
    required this.item,
    required this.state,
    required this.onClose,
    required this.onHarvest,
    required this.onBooster,
    required this.onRemove,
    required this.onShop,
  });

  @override
  Widget build(BuildContext context) {
    final stage = planted.currentStage(item);
    final adult = planted.isAdult(item);
    final ready = planted.hasPendingHarvestFor(item);
    final mech = mechanicsFor(item.id);
    final left = planted.timeRemaining(item) ?? Duration.zero;

    return GlassPanel(
      padding: const EdgeInsets.fromLTRB(14, 12, 6, 14),
      radius: 24,
      opacity: 0.8,
      borderColor: item.auraColor.withValues(alpha: 0.45),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              GardenItemImage(item: item, size: 52, stage: stage),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.nameKey.tr(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        RarityChip(rarity: item.rarity, small: true),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            adult ? 'garden.stage.adult'.tr() : 'garden.readyIn'.tr(namedArgs: {'time': gardenTimeShort(left)}),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: adult ? const Color(0xFF6EE7B7) : Colors.white70,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Semantics(
                button: true,
                label: 'common.close'.tr(),
                onTap: onClose,
                excludeSemantics: true,
                child: MinTapTarget(
                  onTap: onClose,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.1), shape: BoxShape.circle),
                    child: const Icon(Icons.close_rounded, color: Colors.white70, size: 18),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _StageTimeline(planted: planted, item: item),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: adult
                ? _HarvestArea(ready: ready, mech: mech, onHarvest: onHarvest)
                : _BoosterRow(state: state, onBooster: onBooster, onShop: onShop),
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: onRemove,
              style: TextButton.styleFrom(
                foregroundColor: Colors.white60,
                textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                minimumSize: const Size(48, 40),
              ),
              icon: const Icon(Icons.inventory_2_outlined, size: 16),
              label: Text('garden.returnToInventory'.tr()),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 220.ms).slideY(begin: -0.08, end: 0, curve: Curves.easeOutCubic);
  }
}

/// Las cuatro etapas con su ilustración, unidas por una línea que se llena.
class _StageTimeline extends StatelessWidget {
  final PlantedItem planted;
  final GardenItem item;

  const _StageTimeline({required this.planted, required this.item});

  @override
  Widget build(BuildContext context) {
    final current = planted.currentStage(item);
    final progress = planted.growthProgress(item);
    return Semantics(
      label: '${'garden.growthProgress'.tr()}: ${(progress * 100).round()}%. ${'garden.stage.${current.name}'.tr()}',
      excludeSemantics: true,
      child: SizedBox(
        height: 64,
        child: LayoutBuilder(
          builder: (context, c) {
            final w = c.maxWidth;
            final step = w / PlantStage.values.length;
            return Stack(
              children: [
                // línea base y progreso
                Positioned(
                  left: step / 2,
                  right: step / 2,
                  top: 20,
                  child: Container(
                    height: 4,
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                Positioned(
                  left: step / 2,
                  top: 20,
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: progress),
                    duration: MotionService.reduced(context) ? Duration.zero : const Duration(milliseconds: 900),
                    curve: Curves.easeOutCubic,
                    builder: (_, v, _) => Container(
                      width: (w - step) * v,
                      height: 4,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFFFBBF24), Color(0xFF34D399)]),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
                for (final stage in PlantStage.values)
                  Positioned(
                    left: step * stage.index,
                    width: step,
                    top: 0,
                    child: _StageDot(item: item, stage: stage, current: current),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _StageDot extends StatelessWidget {
  final GardenItem item;
  final PlantStage stage;
  final PlantStage current;

  const _StageDot({required this.item, required this.stage, required this.current});

  @override
  Widget build(BuildContext context) {
    final reached = stage.index <= current.index;
    final isCurrent = stage == current;
    final color = GardenPalette.stageColor(stage);
    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          width: isCurrent ? 42 : 34,
          height: isCurrent ? 42 : 34,
          margin: EdgeInsets.only(top: isCurrent ? 0 : 4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: reached ? Colors.white.withValues(alpha: 0.95) : Colors.white.withValues(alpha: 0.12),
            border: Border.all(color: reached ? color : Colors.white24, width: isCurrent ? 2.5 : 1.5),
          ),
          padding: const EdgeInsets.all(3),
          child: Opacity(
            opacity: reached ? 1 : 0.35,
            // El medallón es un círculo, no un suelo: aquí se centra el
            // dibujo (una semilla trae mucho aire encima y se veía caída).
            child: Transform.translate(
              offset: PlantGround.centerOffsetFor(GardenAssets.plant(item.id, stage), 36),
              child: Image.asset(
                GardenAssets.plant(item.id, stage),
                fit: BoxFit.contain,
                cacheWidth: decodePixels(context, 42),
                errorBuilder: (_, _, _) => Center(
                  child: Text(item.stageEmojis?[stage] ?? '🌱', style: const TextStyle(fontSize: 14)),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 3),
        Text(
          'garden.stage.${stage.name}'.tr(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 10,
            fontWeight: isCurrent ? FontWeight.w900 : FontWeight.w600,
            color: isCurrent ? Colors.white : Colors.white54,
          ),
        ),
      ],
    );
  }
}

class _BoosterRow extends StatelessWidget {
  final GardenState state;
  final ValueChanged<String> onBooster;
  final VoidCallback onShop;

  const _BoosterRow({required this.state, required this.onBooster, required this.onShop});

  @override
  Widget build(BuildContext context) {
    final boosters = GardenCatalog.allBoosters.where((b) => state.hasInInventory(b.id)).toList();
    if (boosters.isEmpty) {
      return Row(
        children: [
          const Text('💧', style: TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Expanded(
            child: Text('garden.boostersHint'.tr(), style: const TextStyle(fontSize: 12, color: Colors.white60)),
          ),
          TextButton(
            onPressed: onShop,
            style: TextButton.styleFrom(foregroundColor: const Color(0xFF6EE7B7), minimumSize: const Size(48, 40)),
            child: Text('garden.shop'.tr(), style: const TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('garden.useBooster'.tr(), style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: Colors.white70)),
        const SizedBox(height: 6),
        ClipSideways(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            child: Row(
              children: [
                for (final (i, b) in boosters.indexed)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GardenPressable(
                      onTap: () => onBooster(b.id),
                      semanticsLabel: '${b.nameKey.tr()}, ×${state.quantityOf(b.id)}. ${_boostLabel(b)}',
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(6, 5, 10, 5),
                        decoration: BoxDecoration(
                          color: b.auraColor.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: b.auraColor.withValues(alpha: 0.55)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            GardenItemImage(item: b, size: 30, auraScale: 0.6),
                            const SizedBox(width: 6),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(_boostLabel(b), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.white)),
                                Text('×${state.quantityOf(b.id)}', style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: Colors.white60)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ).animate().fadeIn(delay: (60 * i).ms, duration: 250.ms).slideX(begin: 0.2, end: 0, curve: Curves.easeOutCubic),
                  ),
              ],
            ),
          ),
),
      ],
    );
  }

  static String _boostLabel(GardenItem b) {
    final d = b.boostDuration;
    if (d == null || d.inDays >= 30) return 'garden.boostInstant'.tr();
    return 'garden.boostHours'.tr(namedArgs: {'hours': '${d.inHours}'});
  }
}

class _HarvestArea extends StatelessWidget {
  final bool ready;
  final PlantMechanics mech;
  final VoidCallback onHarvest;

  const _HarvestArea({required this.ready, required this.mech, required this.onHarvest});

  @override
  Widget build(BuildContext context) {
    final perks = Row(
      children: [
        _Perk(icon: const SeedIcon(size: 18, withGlow: false), text: 'garden.perSeedsDay'.tr(namedArgs: {'count': '${mech.seedsPerDay}'})),
        const SizedBox(width: 6),
        _Perk(icon: const Text('⚡', style: TextStyle(fontSize: 12)), text: '${(mech.xpMultiplierChance * 100).round()}%'),
        if (mech.canGiveStreakShield) ...[
          const SizedBox(width: 6),
          const _Perk(icon: Text('🛡️', style: TextStyle(fontSize: 12)), text: ''),
        ],
      ],
    );

    if (!ready) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          perks,
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Text('🌙', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'garden.harvestTomorrow'.tr(),
                    style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Colors.white70),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        perks,
        const SizedBox(height: 10),
        GardenPressable(
          onTap: onHarvest,
          semanticsLabel: 'garden.harvestClaim'.tr(),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFFFBBF24), Color(0xFFF59E0B)]),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: const Color(0xFFF59E0B).withValues(alpha: 0.45), blurRadius: 14, offset: const Offset(0, 4))],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SeedIcon(size: 24, withGlow: false),
                const SizedBox(width: 8),
                Text(
                  'garden.harvestClaimSeeds'.tr(namedArgs: {'count': '${mech.seedsPerDay}'}),
                  style: const TextStyle(color: Color(0xFF4A2C00), fontWeight: FontWeight.w900, fontSize: 15),
                ),
              ],
            ),
          ),
        )
            .animate(onPlay: MotionService.loop(context, reverse: true))
            .scale(begin: const Offset(1, 1), end: const Offset(1.03, 1.03), duration: 900.ms, curve: Curves.easeInOut),
      ],
    );
  }
}

class _Perk extends StatelessWidget {
  final Widget icon;
  final String text;
  const _Perk({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.09), borderRadius: BorderRadius.circular(10)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          icon,
          if (text.isNotEmpty) ...[
            const SizedBox(width: 4),
            Text(text, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white)),
          ],
        ],
      ),
    );
  }
}
