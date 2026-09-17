import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../data/models/garden_item.dart';
import '../../../../data/models/garden_mechanics.dart';
import '../../../../data/models/lumi.dart';
import '../../../../domain/services/motion_service.dart';
import '../../../widgets/journal/journal_style.dart';
import '../../../widgets/lumi/lumi_avatar.dart';
import '../../../widgets/seed_icon.dart';
import '../garden_defs.dart';
import 'garden_common.dart';

/// Celebración de la cosecha: la planta con su aura y rayos de luz, las
/// semillas que se cuentan y los regalos raros (multiplicador y escudo).
class HarvestDialog extends StatelessWidget {
  final GardenItem plant;
  final HarvestResult harvest;

  const HarvestDialog({super.key, required this.plant, required this.harvest});

  static Future<void> show(BuildContext context, {required GardenItem plant, required HarvestResult harvest}) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'common.close'.tr(),
      barrierColor: Colors.black.withValues(alpha: 0.55),
      transitionDuration: const Duration(milliseconds: 380),
      pageBuilder: (_, _, _) => HarvestDialog(plant: plant, harvest: harvest),
      transitionBuilder: (_, anim, _, child) => FadeTransition(
        opacity: anim,
        child: ScaleTransition(
          scale: Tween(begin: 0.85, end: 1.0).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final p = GardenPalette(isDark);
    final reduced = MotionService.reduced(context);
    final color = plant.auraColor;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Material(
          color: Colors.transparent,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              decoration: BoxDecoration(
                color: p.sheet,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: color.withValues(alpha: 0.4), width: 1.5),
                boxShadow: [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 30, offset: const Offset(0, 10))],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    height: 170,
                    child: Stack(
                      alignment: Alignment.center,
                      clipBehavior: Clip.none,
                      children: [
                        // rayos de luz que giran despacio
                        LightRays(color: Color.lerp(color, const Color(0xFFFBBF24), 0.4)!, size: 230),
                        GardenItemImage(item: plant, size: 120, pulse: true)
                            .animate()
                            .scale(begin: const Offset(0.5, 0.5), end: const Offset(1, 1), duration: 700.ms, curve: Curves.elasticOut),
                        if (!reduced) SparkleBurst(color: color, size: 220, seed: plant.id.hashCode),
                        Positioned(
                          right: -6,
                          top: 18,
                          child: const LumiAvatar(mood: LumiMood.proud, size: 58)
                              .animate()
                              .fadeIn(delay: 350.ms, duration: 300.ms)
                              .slideX(begin: 0.4, end: 0, curve: Curves.easeOutCubic),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    'garden.harvest.fromPlant'.tr(namedArgs: {'plant': plant.nameKey.tr()}),
                    textAlign: TextAlign.center,
                    style: JournalStyle.hand(const TextStyle(fontSize: 21, height: 1.0, color: GardenPalette.green)),
                  ),
                  const SizedBox(height: 2),
                  Semantics(
                    header: true,
                    child: Text(
                      'garden.harvest.dialogTitle'.tr(),
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: p.ink),
                    ),
                  ),
                  if (harvest.seedsEarned > 0) ...[
                    const SizedBox(height: 14),
                    Semantics(
                      label: 'garden.harvest.seedsEarned'.tr(namedArgs: {'count': '${harvest.seedsEarned}'}),
                      excludeSemantics: true,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SeedIcon(size: 44, animated: true),
                          const SizedBox(width: 6),
                          TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0, end: harvest.seedsEarned.toDouble()),
                            duration: reduced ? Duration.zero : const Duration(milliseconds: 900),
                            curve: Curves.easeOutCubic,
                            builder: (_, v, _) => Text(
                              '+${v.round()}',
                              style: const TextStyle(fontSize: 38, fontWeight: FontWeight.w900, color: Color(0xFF16A34A), height: 1),
                            ),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(delay: 200.ms, duration: 300.ms).slideY(begin: 0.3, end: 0, curve: Curves.easeOutCubic),
                  ],
                  if (harvest.gotXpMultiplier) ...[
                    const SizedBox(height: 12),
                    _GiftRow(
                      color: GardenPalette.violet,
                      icon: const Text('⚡', style: TextStyle(fontSize: 22)),
                      title: 'garden.harvest.multiplierLine'.tr(namedArgs: {
                        'mult': harvest.xpMultiplier.toStringAsFixed(1),
                        'mins': '${harvest.multiplierMinutes}',
                      }),
                      subtitle: 'garden.harvest.multiplierHint'.tr(),
                      isDark: isDark,
                    ).animate().fadeIn(delay: 450.ms, duration: 300.ms).slideX(begin: -0.1, end: 0),
                  ],
                  if (harvest.gotStreakShield) ...[
                    const SizedBox(height: 8),
                    _GiftRow(
                      color: GardenPalette.gold,
                      icon: const Text('🛡️', style: TextStyle(fontSize: 22)),
                      title: 'garden.harvest.shieldEarned'.tr(),
                      subtitle: harvest.shieldFromPlant != null
                          ? 'garden.harvest.shieldFromPlant'.tr(namedArgs: {'plant': harvest.shieldFromPlant!.tr()})
                          : null,
                      isDark: isDark,
                    ).animate().fadeIn(delay: 600.ms, duration: 300.ms).slideX(begin: -0.1, end: 0),
                  ],
                  const SizedBox(height: 18),
                  FilledButton(
                    onPressed: () => Navigator.pop(context),
                    style: FilledButton.styleFrom(
                      backgroundColor: GardenPalette.green,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: Text('challenge.awesome'.tr(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GiftRow extends StatelessWidget {
  final Color color;
  final Widget icon;
  final String title;
  final String? subtitle;
  final bool isDark;

  const _GiftRow({required this.color, required this.icon, required this.title, required this.subtitle, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.16 : 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          icon,
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(color: isDark ? Color.lerp(color, Colors.white, 0.35) : Color.lerp(color, Colors.black, 0.25), fontSize: 14, fontWeight: FontWeight.w900),
                ),
                if (subtitle != null)
                  Text(subtitle!, style: TextStyle(color: GardenPalette(isDark).inkSoft, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
