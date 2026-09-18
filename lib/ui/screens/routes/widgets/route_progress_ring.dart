import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../widgets/entrance.dart';

/// Anillo de progreso que se llena animado alrededor de [child].
class RouteProgressRing extends StatelessWidget {
  final double progress;
  final Color color;
  final Color track;
  final double size;
  final double stroke;
  final Widget child;

  const RouteProgressRing({
    super.key,
    required this.progress,
    required this.color,
    required this.track,
    required this.size,
    required this.child,
    this.stroke = 5,
  });

  @override
  Widget build(BuildContext context) {
    // El anillo se llena al abrir la pantalla. Si la tarjeta se creó de nuevo
    // solo porque entró a la vista al desplazarse, se dibuja ya lleno: antes
    // cada ruta que aparecía volvía a empezar de cero y parecía que cargaba.
    final value = progress.clamp(0.0, 1.0);

    return RepaintBoundary(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: entranceFrom(context, value), end: value),
        duration:
            entranceDuration(context, const Duration(milliseconds: 1100)),
        curve: Curves.easeOutCubic,
        builder: (context, value, child) => CustomPaint(
          painter: _RingPainter(
            progress: value,
            color: color,
            track: track,
            stroke: stroke,
          ),
          child:
              SizedBox(width: size, height: size, child: Center(child: child)),
        ),
        child: child,
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color track;
  final double stroke;

  _RingPainter({
    required this.progress,
    required this.color,
    required this.track,
    required this.stroke,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(stroke / 2);
    canvas.drawArc(
      rect,
      0,
      math.pi * 2,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..color = track,
    );
    if (progress <= 0) return;
    canvas.drawArc(
      rect,
      -math.pi / 2,
      math.pi * 2 * progress,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..color = color,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.color != color || old.track != track;
}
