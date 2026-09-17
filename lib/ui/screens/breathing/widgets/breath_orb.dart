import 'dart:math' as math;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../breathing_data.dart';

/// El orbe que guía la respiración: crece al inhalar, se queda quieto al
/// sostener y se encoge al exhalar. Alrededor lleva el anillo de la fase y
/// unas motas de luz que entran y salen con el aire.
class BreathOrb extends StatelessWidget {
  final Animation<double> breath;
  final Color color;
  final BreathPosition? position;
  final double size;
  final bool paused;

  /// Texto bajo el contador ("Ciclo 3 de 11").
  final String? caption;

  const BreathOrb({
    super.key,
    required this.breath,
    required this.color,
    required this.position,
    this.size = 260,
    this.paused = false,
    this.caption,
  });

  @override
  Widget build(BuildContext context) {
    final phase = position?.phase;
    final label = paused
        ? 'breathing.paused'.tr()
        : phase == null
            ? 'breathing.getReady'.tr()
            : phase.labelKey.tr();
    final seconds = position?.secondsLeft;
    final phaseProgress = position == null ? 0.0 : 1 - (position!.secondsLeft - 1) / position!.phase.seconds;

    return Semantics(
      liveRegion: true,
      label: seconds == null ? label : '$label, $seconds',
      excludeSemantics: true,
      child: AnimatedBuilder(
        animation: breath,
        builder: (_, _) {
          final v = breath.value;
          return SizedBox(
            width: size,
            height: size,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: Size.square(size),
                  painter: _OrbPainter(
                    breath: v,
                    color: color,
                    phaseProgress: phaseProgress,
                    move: phase?.move,
                    paused: paused,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 0.5),
                    ),
                    if (seconds != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        '$seconds',
                        style: TextStyle(
                          fontSize: 54,
                          height: 1.05,
                          fontWeight: FontWeight.w900,
                          color: Color.lerp(color, Colors.white, 0.45),
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                    if (caption != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        caption!,
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white.withValues(alpha: 0.6)),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _OrbPainter extends CustomPainter {
  final double breath;
  final Color color;
  final double phaseProgress;
  final BreathMove? move;
  final bool paused;

  const _OrbPainter({
    required this.breath,
    required this.color,
    required this.phaseProgress,
    required this.move,
    required this.paused,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final maxR = size.width / 2;
    final r = maxR * (0.52 + breath * 0.33);
    final alpha = paused ? 0.5 : 1.0;

    // Resplandor exterior: círculos concéntricos que crecen con el aire
    for (int i = 5; i >= 1; i--) {
      canvas.drawCircle(
        c,
        r + i * maxR * 0.045,
        Paint()..color = color.withValues(alpha: (0.05 + breath * 0.04) * (6 - i) / 6 * alpha),
      );
    }

    // Motas de luz que entran y salen
    final dots = 14;
    for (int i = 0; i < dots; i++) {
      final a = i / dots * math.pi * 2 + breath * 0.5;
      final dist = r + maxR * (0.08 + (1 - breath) * 0.22);
      final p = c + Offset(math.cos(a), math.sin(a)) * dist;
      canvas.drawCircle(
        p,
        1.6 + breath * 1.6,
        Paint()..color = Color.lerp(color, Colors.white, 0.5)!.withValues(alpha: (0.15 + breath * 0.35) * alpha),
      );
    }

    // Cuerpo del orbe
    final body = Rect.fromCircle(center: c, radius: r);
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.3, -0.35),
          colors: [
            Color.lerp(color, Colors.white, 0.55)!.withValues(alpha: 0.55 * alpha),
            color.withValues(alpha: 0.35 * alpha),
            color.withValues(alpha: 0.1 * alpha),
          ],
          stops: const [0, 0.55, 1],
        ).createShader(body),
    );
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = color.withValues(alpha: (0.45 + breath * 0.35) * alpha),
    );

    // Brillo superior
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: r * 0.82),
      math.pi * 1.1,
      math.pi * 0.5,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = r * 0.07
        ..color = Colors.white.withValues(alpha: 0.28 * alpha),
    );

    // Anillo de la fase
    final ringRect = Rect.fromCircle(center: c, radius: maxR * 0.93);
    canvas.drawCircle(
      c,
      maxR * 0.93,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..color = Colors.white.withValues(alpha: 0.12),
    );
    if (move != null && phaseProgress > 0) {
      canvas.drawArc(
        ringRect,
        -math.pi / 2,
        math.pi * 2 * phaseProgress.clamp(0.0, 1.0),
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = 4
          ..shader = SweepGradient(
            startAngle: -math.pi / 2,
            endAngle: math.pi * 1.5,
            colors: [Color.lerp(color, Colors.white, 0.6)!, color],
          ).createShader(ringRect),
      );
    }
  }

  @override
  bool shouldRepaint(_OrbPainter old) =>
      old.breath != breath || old.color != color || old.phaseProgress != phaseProgress || old.move != move || old.paused != paused;
}
