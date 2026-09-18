import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import '../../core/utils/image_sizing.dart';
import '../../domain/providers/auth_provider.dart';
import '../../domain/providers/garden_provider.dart';
import 'seed_icon.dart';

// ═════════════════════════════════════════════════════════════════════════════
// DiscoveryDialog — "discovery moment" la primera vez que se abre una feature
// ═════════════════════════════════════════════════════════════════════════════

/// Features con discovery moment. El `name` es el id que se guarda en
/// users/{uid}/progress/discoveries y la clave de traducción `discovery.<name>`.
enum DiscoveryFeature { garden, breathing, diary, routes, reminders }

class _FeatureStyle {
  final String? image;
  final String emoji;
  final Color color;

  const _FeatureStyle({this.image, required this.emoji, required this.color});
}

const Map<DiscoveryFeature, _FeatureStyle> _styles = {
  DiscoveryFeature.garden: _FeatureStyle(
    image: 'assets/images/onboarding/slide_garden.webp',
    emoji: '🌱',
    color: Color(0xFF8B5CF6),
  ),
  DiscoveryFeature.breathing: _FeatureStyle(
    emoji: '🫁',
    color: Color(0xFF06B6D4),
  ),
  DiscoveryFeature.diary: _FeatureStyle(
    image: 'assets/images/onboarding/slide_diary.webp',
    emoji: '📖',
    color: Color(0xFF3B82F6),
  ),
  DiscoveryFeature.routes: _FeatureStyle(
    image: 'assets/images/onboarding/slide_routes.webp',
    emoji: '🧭',
    color: Color(0xFFF97316),
  ),
  DiscoveryFeature.reminders: _FeatureStyle(
    emoji: '⏰',
    color: Color(0xFF10B981),
  ),
};

class DiscoveryDialog extends StatelessWidget {
  static const int seedsReward = 5;

  final DiscoveryFeature feature;

  const DiscoveryDialog._(this.feature);

  /// Muestra el popup y da [seedsReward] semillas solo la primera vez que el
  /// usuario abre [feature]. Se puede llamar cada vez que se entra.
  static Future<void> maybeShow(
      BuildContext context, DiscoveryFeature feature) async {
    final auth = context.read<AuthProvider>();
    final garden = context.read<GardenProvider>();

    final isNew = await auth.markDiscovered(feature.name);
    if (!isNew || !context.mounted) return;

    await garden.addSeeds(seedsReward, source: 'discovery_${feature.name}');
    if (!context.mounted) return;

    HapticFeedback.mediumImpact();
    await showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (_) => DiscoveryDialog._(feature),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final style = _styles[feature]!;
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final key = 'discovery.${feature.name}';

    final card = Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: style.color.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHero(context, style),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
            child: Column(
              children: [
                Text(
                  '$key.title'.tr(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$key.message'.tr(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.5,
                    color: isDark ? Colors.white70 : Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SeedIcon(size: 28),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'discovery.seedsBonus'.tr(
                          namedArgs: {'count': '$seedsReward'},
                        ),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: style.color,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton(
                    onPressed: () => Navigator.pop(context),
                    style: FilledButton.styleFrom(
                      backgroundColor: style.color,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      'discovery.cta'.tr(),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        // Un solo momento de entrada; sin animación si el sistema la desactiva
        child: reduceMotion
            ? card
            : card
                .animate()
                .fadeIn(duration: 250.ms)
                .scale(
                  begin: const Offset(0.92, 0.92),
                  end: const Offset(1, 1),
                  duration: 450.ms,
                  curve: Curves.easeOutBack,
                ),
      ),
    );
  }

  Widget _buildHero(BuildContext context, _FeatureStyle style) {
    final fallback = Center(
      child: Text(style.emoji, style: const TextStyle(fontSize: 72)),
    );
    return Container(
      height: 170,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            style.color.withValues(alpha: 0.25),
            style.color.withValues(alpha: 0.05),
          ],
        ),
      ),
      child: style.image == null
          ? fallback
          : Image.asset(
              style.image!,
              fit: BoxFit.contain,
              cacheWidth: decodePixels(context, 340),
              errorBuilder: (_, _, _) => fallback,
            ),
    );
  }
}
