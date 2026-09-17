import 'dart:math' as math;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../domain/services/mission_service.dart';
import '../screens/missions/missions_screen.dart';
import '../../domain/services/motion_service.dart';

/// Resumen de las misiones en el Home: tres anillos de progreso y un aviso
/// cuando hay algo para reclamar o el cofre está listo.
class MissionsHomeCard extends StatelessWidget {
  final MissionsState state;
  final bool isDark;
  final VoidCallback onTap;

  const MissionsHomeCard({
    super.key,
    required this.state,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final claimable = state.claimableCount;
    final (badgeKey, badgeColor) = state.chestReady
        ? ('missions.home.chestReady', const Color(0xFFFBBF24))
        : claimable > 0
            ? ('missions.home.claimable', const Color(0xFF10B981))
            : state.chestClaimed
                ? ('missions.home.allDone', const Color(0xFF8B5CF6))
                : ('missions.home.progress', const Color(0xFF8B5CF6));
    final highlight = state.chestReady || claimable > 0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [const Color(0xFF2A2152), const Color(0xFF1B1636)]
                : [const Color(0xFFEDE9FE), const Color(0xFFFFFBEB)],
          ),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: highlight ? badgeColor : const Color(0xFF8B5CF6).withValues(alpha: 0.3),
            width: highlight ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(state.chestClaimed ? '🏆' : '🎁', style: const TextStyle(fontSize: 18)),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          'missions.title'.tr(),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 15.5,
                            height: 1.2,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white : const Color(0xFF2D2D3A),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: badgeColor.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      badgeKey.tr(namedArgs: {
                        'n': '$claimable',
                        'done': '${state.missions.where((m) => m.completed).length}',
                        'total': '${state.missions.length}',
                      }),
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: badgeColor),
                    ),
                  ),
                ],
              ),
            ),
            for (final m in state.missions)
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: SizedBox(
                  width: 44,
                  height: 44,
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: m.fraction),
                    duration: const Duration(milliseconds: 900),
                    curve: Curves.easeOutCubic,
                    builder: (context, v, _) => CustomPaint(
                      painter: _MiniRing(
                        progress: v,
                        color: m.completed ? const Color(0xFF10B981) : MissionStyle.of(m.type).color,
                        track: isDark ? Colors.white12 : Colors.black12,
                      ),
                      child: Center(
                        child: Icon(
                          m.claimed ? Icons.check_rounded : MissionStyle.of(m.type).icon,
                          size: 18,
                          color: m.completed ? const Color(0xFF10B981) : MissionStyle.of(m.type).color,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    )
        .animate(target: highlight ? 1 : 0, onPlay: (c) => highlight ? MotionService.loop(context, reverse: true)(c) : null)
        .scale(begin: const Offset(1, 1), end: const Offset(1.015, 1.015), duration: 900.ms);
  }
}

class _MiniRing extends CustomPainter {
  final double progress;
  final Color color;
  final Color track;

  _MiniRing({required this.progress, required this.color, required this.track});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(3);
    canvas.drawArc(rect, 0, math.pi * 2, false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4
          ..color = track);
    canvas.drawArc(rect, -math.pi / 2, math.pi * 2 * progress, false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4
          ..strokeCap = StrokeCap.round
          ..color = color);
  }

  @override
  bool shouldRepaint(_MiniRing old) => old.progress != progress || old.color != color;
}
