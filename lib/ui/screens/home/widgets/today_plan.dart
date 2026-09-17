import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../domain/services/motion_service.dart';
import '../../../widgets/journal/journal_style.dart';

/// Título de sección: una línea a mano arriba y el título en negrita.
class HomeSectionTitle extends StatelessWidget {
  final String kicker;
  final String title;
  final bool isDark;
  final Widget? trailing;

  const HomeSectionTitle({super.key, required this.kicker, required this.title, required this.isDark, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                kicker,
                style: JournalStyle.hand(TextStyle(fontSize: 18, height: 1.0, color: isDark ? AppColors.primaryLight : AppColors.primary)),
              ),
              Semantics(
                header: true,
                child: Text(
                  title,
                  style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: isDark ? Colors.white : AppColors.textPrimary),
                ),
              ),
            ],
          ),
        ),
        ?trailing,
      ],
    );
  }
}

/// La lección de hoy, grande y con el color de su ruta.
class TodayLessonCard extends StatelessWidget {
  final String? routeEmoji;
  final String? routeTitle;
  final String? lessonTitle;
  final Color color;
  final Color colorDark;
  final bool doneToday;
  final bool allComplete;
  final VoidCallback? onTap;

  const TodayLessonCard({
    super.key,
    required this.routeEmoji,
    required this.routeTitle,
    required this.lessonTitle,
    required this.color,
    required this.colorDark,
    required this.doneToday,
    required this.allComplete,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final title = allComplete ? 'home.allComplete'.tr() : (lessonTitle ?? '');
    final kicker = allComplete
        ? 'home.congratulations'.tr()
        : doneToday
            ? 'home.lessonDoneTodayKicker'.tr()
            : 'home.lessonOfDay'.tr();
    final cta = allComplete ? null : (doneToday ? 'home.anotherLesson'.tr() : 'home.startLesson'.tr());

    return _Pressable(
      onTap: onTap,
      semanticsLabel: '$kicker. $title. ${routeTitle ?? ''}',
      child: Container(
        constraints: const BoxConstraints(minHeight: 150),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color.lerp(color, Colors.white, 0.1)!, colorDark],
          ),
          boxShadow: [BoxShadow(color: color.withValues(alpha: 0.35), blurRadius: 20, offset: const Offset(0, 8))],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(26),
          child: Stack(
            children: [
              Positioned(top: -40, right: -30, child: _circle(150, 0.12)),
              Positioned(bottom: -50, left: -20, child: _circle(120, 0.08)),
              Positioned(
                right: 16,
                top: 16,
                child: Text(allComplete ? '🏆' : (routeEmoji ?? '📚'), style: const TextStyle(fontSize: 58))
                    .animate(onPlay: MotionService.loop(context, reverse: true))
                    .moveY(begin: -3, end: 3, duration: 2000.ms, curve: Curves.easeInOut)
                    .rotate(begin: -0.02, end: 0.02, duration: 2000.ms),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.22), borderRadius: BorderRadius.circular(12)),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(doneToday ? Icons.check_circle_rounded : Icons.auto_stories_rounded, size: 13, color: Colors.white),
                          const SizedBox(width: 5),
                          Text(
                            kicker.toUpperCase(),
                            style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900, letterSpacing: 0.8, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.only(right: 70),
                      child: Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 20, height: 1.15, fontWeight: FontWeight.w900, color: Colors.white),
                      ),
                    ),
                    if (routeTitle != null && !allComplete) ...[
                      const SizedBox(height: 3),
                      Text(
                        routeTitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white.withValues(alpha: 0.85)),
                      ),
                    ],
                    if (cta != null) ...[
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 8, offset: const Offset(0, 3))],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(cta, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: colorDark)),
                            const SizedBox(width: 6),
                            Icon(Icons.arrow_forward_rounded, size: 17, color: colorDark),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _circle(double size, double alpha) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: alpha)),
      );
}

enum QuickTileState { normal, done, locked }

/// Acceso rápido en la cuadrícula del plan de hoy.
class QuickActionTile extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final Color color;
  final QuickTileState state;
  final bool isDark;
  final VoidCallback onTap;

  const QuickActionTile({
    super.key,
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.isDark,
    required this.onTap,
    this.state = QuickTileState.normal,
  });

  @override
  Widget build(BuildContext context) {
    final ink = isDark ? Colors.white : AppColors.textPrimary;
    final locked = state == QuickTileState.locked;
    final done = state == QuickTileState.done;

    return _Pressable(
      onTap: onTap,
      semanticsLabel: '$title. $subtitle',
      child: Container(
        height: 132,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [Color.lerp(const Color(0xFF1B1C2E), color, locked ? 0.05 : 0.2)!, const Color(0xFF17182A)]
                : [Color.lerp(Colors.white, color, locked ? 0.03 : 0.12)!, Colors.white],
          ),
          border: Border.all(color: color.withValues(alpha: locked ? 0.1 : (isDark ? 0.3 : 0.2))),
          boxShadow: isDark ? null : [BoxShadow(color: color.withValues(alpha: 0.12), blurRadius: 14, offset: const Offset(0, 5))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: isDark ? 0.25 : 0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Opacity(opacity: locked ? 0.45 : 1, child: Text(emoji, style: const TextStyle(fontSize: 23))),
                  ),
                ),
                const Spacer(),
                if (done || locked)
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: done ? const Color(0xFF10B981) : ink.withValues(alpha: 0.1),
                    ),
                    child: Icon(done ? Icons.check_rounded : Icons.lock_rounded, size: 14, color: done ? Colors.white : ink.withValues(alpha: 0.5)),
                  ),
              ],
            ),
            const Spacer(),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, color: ink.withValues(alpha: locked ? 0.55 : 1)),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 11.5, height: 1.25, color: isDark ? Colors.white60 : AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

/// Se hunde un poco al tocar y suena el toque suave.
class _Pressable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final String semanticsLabel;

  const _Pressable({required this.child, required this.onTap, required this.semanticsLabel});

  @override
  State<_Pressable> createState() => _PressableState();
}

class _PressableState extends State<_Pressable> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    return Semantics(
      button: enabled,
      label: widget.semanticsLabel,
      onTap: widget.onTap,
      excludeSemantics: true,
      child: GestureDetector(
        onTapDown: enabled ? (_) => setState(() => _down = true) : null,
        onTapUp: enabled ? (_) => setState(() => _down = false) : null,
        onTapCancel: () => setState(() => _down = false),
        onTap: enabled
            ? () {
                HapticFeedback.selectionClick();
                widget.onTap!();
              }
            : null,
        child: AnimatedScale(
          scale: _down ? 0.96 : 1,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          child: widget.child,
        ),
      ),
    );
  }
}
