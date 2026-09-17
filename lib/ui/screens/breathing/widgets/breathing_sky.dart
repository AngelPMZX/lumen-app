import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../domain/services/motion_service.dart';

/// Cielo nocturno de la respiración: estrellas que titilan y auroras que se
/// mecen con el color de la técnica. Todo en un solo `CustomPainter` (antes
/// eran 60 widgets con su propio controlador) y sin `MaskFilter.blur`.
class BreathingSky extends StatefulWidget {
  final Color tint;

  /// 0 en reposo, 1 con el orbe expandido: el cielo respira un poquito.
  final Animation<double>? breath;

  const BreathingSky({super.key, required this.tint, this.breath});

  @override
  State<BreathingSky> createState() => _BreathingSkyState();
}

class _BreathingSkyState extends State<BreathingSky> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl =
      AnimationController(vsync: this, duration: const Duration(seconds: 60))..repeatUnlessReduced(rest: 0.25);
  late final List<_Star> _stars = _buildStars();

  static List<_Star> _buildStars() {
    final rng = math.Random(42);
    return List.generate(70, (i) {
      return _Star(
        x: rng.nextDouble(),
        y: rng.nextDouble(),
        radius: 0.6 + rng.nextDouble() * 1.5,
        base: 0.25 + rng.nextDouble() * 0.6,
        phase: rng.nextDouble(),
        speed: 0.6 + rng.nextDouble() * 1.8,
      );
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final breath = widget.breath;
    final listenable = breath == null ? _ctrl : Listenable.merge([_ctrl, breath]);
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: listenable,
        builder: (_, _) => CustomPaint(
          size: Size.infinite,
          painter: _SkyPainter(
            stars: _stars,
            t: _ctrl.value,
            breath: breath?.value ?? 0,
            tint: widget.tint,
          ),
        ),
      ),
    );
  }
}

class _Star {
  final double x;
  final double y;
  final double radius;
  final double base;
  final double phase;
  final double speed;

  const _Star({required this.x, required this.y, required this.radius, required this.base, required this.phase, required this.speed});
}

class _SkyPainter extends CustomPainter {
  final List<_Star> stars;
  final double t;
  final double breath;
  final Color tint;

  const _SkyPainter({required this.stars, required this.t, required this.breath, required this.tint});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    // Fondo nocturno con un toque del color de la técnica
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.lerp(const Color(0xFF05060F), tint, 0.1)!,
            const Color(0xFF0A0B1C),
            Color.lerp(const Color(0xFF0C0D22), tint, 0.08)!,
          ],
        ).createShader(rect),
    );

    // Auroras: dos bandas suaves que ondulan
    for (var band = 0; band < 2; band++) {
      final color = band == 0 ? tint : const Color(0xFF818CF8);
      final amp = size.height * (band == 0 ? 0.045 : 0.035);
      final yBase = size.height * (band == 0 ? 0.28 : 0.62);
      final phase = t * math.pi * 2 + band * 1.7;
      final path = Path()..moveTo(0, yBase);
      for (double x = 0; x <= size.width; x += size.width / 24) {
        final y = yBase + math.sin(x / size.width * math.pi * 2 + phase) * amp;
        path.lineTo(x, y);
      }
      path
        ..lineTo(size.width, yBase + size.height * 0.16)
        ..lineTo(0, yBase + size.height * 0.16)
        ..close();
      canvas.drawPath(
        path,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              color.withValues(alpha: 0.12 + breath * 0.06),
              color.withValues(alpha: 0),
            ],
          ).createShader(Rect.fromLTWH(0, yBase - amp, size.width, size.height * 0.2)),
      );
    }

    // Estrellas
    for (final s in stars) {
      final twinkle = 0.55 + math.sin((t * s.speed + s.phase) * math.pi * 2) * 0.45;
      final alpha = (s.base * twinkle).clamp(0.0, 1.0);
      final center = Offset(s.x * size.width, s.y * size.height);
      final r = s.radius * (1 + breath * 0.15);
      if (s.radius > 1.4) {
        // resplandor en círculos concéntricos (sin blur)
        for (int i = 3; i >= 1; i--) {
          canvas.drawCircle(center, r * (1 + i * 0.9), Paint()..color = Colors.white.withValues(alpha: alpha * 0.05 * (4 - i)));
        }
      }
      canvas.drawCircle(center, r, Paint()..color = Colors.white.withValues(alpha: alpha));
    }
  }

  @override
  bool shouldRepaint(_SkyPainter old) => old.t != t || old.breath != breath || old.tint != tint;
}
