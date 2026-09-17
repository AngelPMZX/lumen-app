import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../domain/services/motion_service.dart';
import '../../../widgets/journal/journal_style.dart';
import '../../../widgets/min_tap_target.dart';
import '../../routes/widgets/route_progress_ring.dart';

enum GardenBadge { none, seeds, harvest }

/// Encabezado del Home: avatar con anillo de nivel, saludo a mano, racha,
/// jardín y tema.
class HomeHeader extends StatelessWidget {
  final String name;
  final String greeting;
  final List<Color> avatarColors;
  final int level;
  final double levelProgress;
  final int streak;
  final GardenBadge gardenBadge;
  final bool isDark;
  final VoidCallback onGarden;
  final VoidCallback onToggleTheme;

  const HomeHeader({
    super.key,
    required this.name,
    required this.greeting,
    required this.avatarColors,
    required this.level,
    required this.levelProgress,
    required this.streak,
    required this.gardenBadge,
    required this.isDark,
    required this.onGarden,
    required this.onToggleTheme,
  });

  @override
  Widget build(BuildContext context) {
    final ink = isDark ? Colors.white : AppColors.textPrimary;
    final initial = name.isNotEmpty ? name.characters.first.toUpperCase() : 'U';

    return Row(
      children: [
        Semantics(
          label: '${'home.levelShort'.tr()} $level',
          excludeSemantics: true,
          child: RouteProgressRing(
            progress: levelProgress,
            color: avatarColors.first,
            track: avatarColors.first.withValues(alpha: isDark ? 0.2 : 0.14),
            size: 60,
            stroke: 4,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: avatarColors,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      initial,
                      style: const TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
                Positioned(
                  right: -6,
                  bottom: -4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E1D35) : Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: avatarColors.first, width: 1.5),
                    ),
                    child: Text(
                      '$level',
                      style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900, color: avatarColors.first),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  greeting,
                  maxLines: 1,
                  style: JournalStyle.hand(TextStyle(
                    fontSize: 21,
                    height: 1.05,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.primaryLight : AppColors.primary,
                  )),
                ),
              ),
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 22, height: 1.15, fontWeight: FontWeight.w900, color: ink),
              ),
            ],
          ),
        ),
        _StreakFlame(streak: streak, isDark: isDark),
        const SizedBox(width: 2),
        _RoundButton(
          isDark: isDark,
          label: 'garden.title'.tr(),
          onTap: onGarden,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              const Text('🌱', style: TextStyle(fontSize: 19)),
              if (gardenBadge != GardenBadge.none)
                Positioned(
                  top: -3,
                  right: -5,
                  child: Container(
                    width: gardenBadge == GardenBadge.harvest ? 11 : 8,
                    height: gardenBadge == GardenBadge.harvest ? 11 : 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: gardenBadge == GardenBadge.harvest ? const Color(0xFFF59E0B) : const Color(0xFF10B981),
                      border: Border.all(color: isDark ? const Color(0xFF1A1A2E) : Colors.white, width: 1.5),
                    ),
                  )
                      .animate(onPlay: MotionService.loop(context, reverse: true))
                      .scale(begin: const Offset(1, 1), end: const Offset(1.25, 1.25), duration: 800.ms),
                ),
            ],
          ),
        ),
        _RoundButton(
          isDark: isDark,
          label: isDark ? 'profileScreen.lightModeOn'.tr() : 'profileScreen.darkModeOn'.tr(),
          onTap: onToggleTheme,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 350),
            transitionBuilder: (child, anim) => RotationTransition(
              turns: Tween(begin: 0.7, end: 1.0).animate(anim),
              child: FadeTransition(opacity: anim, child: child),
            ),
            child: Icon(
              isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
              key: ValueKey(isDark),
              color: isDark ? const Color(0xFFFBBF24) : AppColors.textSecondary,
              size: 20,
            ),
          ),
        ),
      ],
    ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.15, end: 0, curve: Curves.easeOutCubic);
  }
}

class _StreakFlame extends StatelessWidget {
  final int streak;
  final bool isDark;

  const _StreakFlame({required this.streak, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final active = streak > 0;
    const orange = Color(0xFFF97316);
    return Semantics(
      label: '${'home.streak'.tr()}: $streak',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          gradient: active
              ? LinearGradient(colors: [
                  const Color(0xFFFBBF24).withValues(alpha: isDark ? 0.25 : 0.2),
                  orange.withValues(alpha: isDark ? 0.25 : 0.16),
                ])
              : null,
          color: active ? null : (isDark ? Colors.white.withValues(alpha: 0.08) : AppColors.surfaceVariant),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(active ? '🔥' : '🌑', style: const TextStyle(fontSize: 16))
                .animate(onPlay: active ? MotionService.loop(context, reverse: true) : null)
                .scale(begin: const Offset(1, 1), end: const Offset(1.15, 1.15), duration: 900.ms, curve: Curves.easeInOut),
            const SizedBox(width: 4),
            Text(
              '$streak',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w900,
                color: active ? (isDark ? const Color(0xFFFDBA74) : const Color(0xFFC2410C)) : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  final bool isDark;
  final String label;
  final VoidCallback onTap;
  final Widget child;

  const _RoundButton({required this.isDark, required this.label, required this.onTap, required this.child});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      onTap: onTap,
      excludeSemantics: true,
      child: MinTapTarget(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.white,
            shape: BoxShape.circle,
            boxShadow: isDark
                ? null
                : [BoxShadow(color: AppColors.primary.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 3))],
          ),
          child: Center(child: child),
        ),
      ),
    );
  }
}
