import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../data/models/routes_overview.dart';
import '../../../../domain/services/motion_service.dart';
import '../route_theme.dart';
import 'route_progress_ring.dart';

/// Tarjeta de una ruta en el menú: medallón con anillo de progreso, estado,
/// lecciones y XP, y los emojis de la ruta flotando al fondo.
class RouteCard extends StatelessWidget {
  final RouteProgress progress;
  final bool isDark;
  final VoidCallback onTap;

  const RouteCard({
    super.key,
    required this.progress,
    required this.isDark,
    required this.onTap,
  });

  static const _gold = Color(0xFFF59E0B);

  @override
  Widget build(BuildContext context) {
    final route = progress.route;
    final color = route.color;
    final status = progress.status;
    final deco = RouteTheme.decorations(route.id);
    final ink = isDark ? Colors.white : AppColors.textPrimary;
    // El color de la ruta como texto: en claro un poco más oscuro para leerse.
    final colorText = isDark ? Color.lerp(color, Colors.white, 0.25)! : route.colorDark;

    return Semantics(
      button: true,
      label: 'routes.routeCardA11y'.tr(namedArgs: {
        'title': route.title,
        'completed': '${progress.completed}',
        'total': '${progress.total}',
      }),
      hint: route.description,
      onTap: onTap,
      excludeSemantics: true,
      child: _PressScale(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [
                      Color.lerp(const Color(0xFF1A1B2E), color, 0.24)!,
                      Color.lerp(const Color(0xFF131427), route.colorDark, 0.08)!,
                    ]
                  : [Color.lerp(Colors.white, color, 0.14)!, Colors.white],
            ),
            border: Border.all(
              color: status == RouteStatus.completed
                  ? _gold.withValues(alpha: 0.55)
                  : color.withValues(alpha: isDark ? 0.28 : 0.18),
              width: status == RouteStatus.completed ? 1.6 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: isDark ? 0.12 : 0.1),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(26),
            child: Stack(
              children: [
                // Emojis de la ruta al fondo, muy tenues
                Positioned(
                  right: -16,
                  top: -22,
                  child: _FloatingEmoji(emoji: deco[0], size: 64, opacity: isDark ? 0.16 : 0.2, turns: 0.04),
                ),
                Positioned(
                  right: 58,
                  bottom: -16,
                  child: _FloatingEmoji(emoji: deco[1], size: 36, opacity: isDark ? 0.12 : 0.16, turns: -0.05, delayMs: 700),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 16, 14, 16),
                  child: Row(
                    children: [
                      _Medallion(progress: progress, isDark: isDark),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Text(
                                    route.title,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 16.5,
                                      height: 1.2,
                                      fontWeight: FontWeight.w800,
                                      color: ink,
                                    ),
                                  ),
                                ),
                                if (status != RouteStatus.notStarted) ...[
                                  const SizedBox(width: 6),
                                  _StatusPill(progress: progress, colorText: colorText, isDark: isDark),
                                ],
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              route.description,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13,
                                height: 1.35,
                                color: isDark ? Colors.white60 : AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: [
                                _MetaChip(
                                  icon: Icons.menu_book_rounded,
                                  text: 'routes.lessonsShort'.tr(namedArgs: {'n': '${progress.total}'}),
                                  color: colorText,
                                  isDark: isDark,
                                ),
                                _MetaChip(
                                  icon: Icons.bolt_rounded,
                                  text: 'routes.xpShort'.tr(namedArgs: {'n': '${progress.xpTotal}'}),
                                  color: isDark ? const Color(0xFFFBBF24) : const Color(0xFFB45309),
                                  isDark: isDark,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: color.withValues(alpha: isDark ? 0.2 : 0.12),
                        ),
                        child: Icon(Icons.chevron_right_rounded, size: 20, color: colorText),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Medallion extends StatelessWidget {
  final RouteProgress progress;
  final bool isDark;

  const _Medallion({required this.progress, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final route = progress.route;
    final done = progress.status == RouteStatus.completed;
    return SizedBox(
      width: 80,
      height: 80,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          RouteProgressRing(
            progress: progress.fraction,
            color: done ? RouteCard._gold : route.color,
            track: route.color.withValues(alpha: isDark ? 0.18 : 0.14),
            size: 80,
            stroke: 5,
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color.lerp(route.color, Colors.white, 0.15)!, route.colorDark],
                ),
                boxShadow: [
                  BoxShadow(
                    color: route.color.withValues(alpha: 0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Brillo
                  Positioned(
                    top: 8,
                    left: 12,
                    child: Container(
                      width: 16,
                      height: 8,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  Text(route.emoji, style: const TextStyle(fontSize: 28)),
                ],
              ),
            ),
          ),
          if (done)
            Positioned(
              right: -2,
              bottom: 2,
              child: Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(colors: [Color(0xFFFDE68A), RouteCard._gold]),
                  border: Border.all(
                    color: isDark ? const Color(0xFF1A1B2E) : Colors.white,
                    width: 2.5,
                  ),
                ),
                child: const Icon(Icons.emoji_events_rounded, size: 14, color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final RouteProgress progress;
  final Color colorText;
  final bool isDark;

  const _StatusPill({
    required this.progress,
    required this.colorText,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final done = progress.status == RouteStatus.completed;
    if (done) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFFFBBF24), Color(0xFFF59E0B)]),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          'routes.statusDone'.tr(),
          style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900, color: Colors.white),
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: progress.route.color.withValues(alpha: isDark ? 0.22 : 0.14),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '${(progress.fraction * 100).round()}%',
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: colorText),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;
  final bool isDark;

  const _MetaChip({
    required this.icon,
    required this.text,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.07) : Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12.5, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color),
          ),
        ],
      ),
    );
  }
}

class _FloatingEmoji extends StatelessWidget {
  final String emoji;
  final double size;
  final double opacity;
  final double turns;
  final int delayMs;

  const _FloatingEmoji({
    required this.emoji,
    required this.size,
    required this.opacity,
    required this.turns,
    this.delayMs = 0,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Opacity(
        opacity: opacity,
        child: Transform.rotate(
          angle: turns * 6.283,
          child: Text(emoji, style: TextStyle(fontSize: size)),
        ),
      )
          .animate(delay: delayMs.ms, onPlay: MotionService.loop(context, reverse: true))
          .moveY(begin: -3, end: 3, duration: 2600.ms, curve: Curves.easeInOut),
    );
  }
}

/// Se hunde un poco al tocar, como un botón físico.
class _PressScale extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const _PressScale({required this.child, required this.onTap});

  @override
  State<_PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<_PressScale> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _down = true),
      onTapUp: (_) => setState(() => _down = false),
      onTapCancel: () => setState(() => _down = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _down ? 0.97 : 1,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}
