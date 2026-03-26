import 'dart:math';
import 'package:flutter/material.dart';

/// Widget de fondo animado con partículas flotantes y estrellas fugaces.
/// Funciona en AMBOS modos (dark y light).
/// En light mode usa partículas más sutiles con colores del primary.
class AnimatedParticlesBackground extends StatefulWidget {
  final int particleCount;
  final int maxShootingStars;
  final Color? particleColor; // Si es null, se auto-detecta por tema

  const AnimatedParticlesBackground({
    super.key,
    this.particleCount = 35,
    this.maxShootingStars = 3,
    this.particleColor,
  });

  @override
  State<AnimatedParticlesBackground> createState() =>
      _AnimatedParticlesBackgroundState();
}

class _AnimatedParticlesBackgroundState
    extends State<AnimatedParticlesBackground> with TickerProviderStateMixin {
  late AnimationController _particleController;
  late AnimationController _shootingStarController;

  final Random _random = Random();
  late List<_FloatingParticle> _particles;
  late List<_ShootingStar> _shootingStars;

  @override
  void initState() {
    super.initState();

    _particleController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat();

    _shootingStarController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _regenerateShootingStars();
          _shootingStarController.forward(from: 0);
        }
      });

    _particles = List.generate(
      widget.particleCount,
      (_) => _FloatingParticle.random(_random),
    );

    _shootingStars = List.generate(
      widget.maxShootingStars,
      (_) => _ShootingStar.random(_random),
    );

    if (widget.maxShootingStars > 0) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) _shootingStarController.forward();
      });
    }
  }

  void _regenerateShootingStars() {
    _shootingStars = List.generate(
      widget.maxShootingStars,
      (_) => _ShootingStar.random(_random),
    );
  }

  @override
  void dispose() {
    _particleController.dispose();
    _shootingStarController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Auto-detectar color si no se proporcionó
    final color = widget.particleColor ??
        (isDark
            ? Colors.white.withValues(alpha: 0.5)
            : const Color(0xFF6C63FF).withValues(alpha: 0.2));

    return AnimatedBuilder(
      animation: Listenable.merge([
        _particleController,
        _shootingStarController,
      ]),
      builder: (context, child) {
        return CustomPaint(
          painter: _ParticlesPainter(
            particles: _particles,
            shootingStars: _shootingStars,
            particleProgress: _particleController.value,
            shootingStarProgress: _shootingStarController.value,
            particleColor: color,
            isDark: isDark,
          ),
          size: Size.infinite,
        );
      },
    );
  }
}

class _FloatingParticle {
  double x;
  double y;
  double size;
  double opacity;
  double speedX;
  double speedY;
  double twinkleSpeed;
  double twinkleOffset;

  _FloatingParticle({
    required this.x,
    required this.y,
    required this.size,
    required this.opacity,
    required this.speedX,
    required this.speedY,
    required this.twinkleSpeed,
    required this.twinkleOffset,
  });

  factory _FloatingParticle.random(Random r) {
    return _FloatingParticle(
      x: r.nextDouble(),
      y: r.nextDouble(),
      size: 1.0 + r.nextDouble() * 2.5,
      opacity: 0.15 + r.nextDouble() * 0.45,
      speedX: (r.nextDouble() - 0.5) * 0.0003,
      speedY: -0.0001 - r.nextDouble() * 0.0004,
      twinkleSpeed: 1.5 + r.nextDouble() * 3.0,
      twinkleOffset: r.nextDouble() * pi * 2,
    );
  }

  double currentOpacity(double time) {
    final twinkle = sin(time * twinkleSpeed + twinkleOffset);
    final twinkleFactor = 0.3 + (twinkle + 1) * 0.35;
    return opacity * twinkleFactor;
  }
}

class _ShootingStar {
  double startX;
  double startY;
  double angle;
  double length;
  double speed;
  double delay;
  double thickness;

  _ShootingStar({
    required this.startX,
    required this.startY,
    required this.angle,
    required this.length,
    required this.speed,
    required this.delay,
    required this.thickness,
  });

  factory _ShootingStar.random(Random r) {
    return _ShootingStar(
      startX: r.nextDouble() * 0.8 + 0.1,
      startY: r.nextDouble() * 0.35,
      angle: pi / 6 + r.nextDouble() * pi / 4,
      length: 0.08 + r.nextDouble() * 0.15,
      speed: 0.6 + r.nextDouble() * 0.8,
      delay: r.nextDouble() * 0.5,
      thickness: 1.0 + r.nextDouble() * 1.5,
    );
  }
}

class _ParticlesPainter extends CustomPainter {
  final List<_FloatingParticle> particles;
  final List<_ShootingStar> shootingStars;
  final double particleProgress;
  final double shootingStarProgress;
  final Color particleColor;
  final bool isDark;

  _ParticlesPainter({
    required this.particles,
    required this.shootingStars,
    required this.particleProgress,
    required this.shootingStarProgress,
    required this.particleColor,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    _paintFloatingParticles(canvas, size);
    if (shootingStars.isNotEmpty) {
      _paintShootingStars(canvas, size);
    }
  }

  void _paintFloatingParticles(Canvas canvas, Size size) {
    final time = DateTime.now().millisecondsSinceEpoch / 1000.0;

    for (final p in particles) {
      p.x += p.speedX;
      p.y += p.speedY;

      if (p.y < -0.05) {
        p.y = 1.05;
        p.x = Random().nextDouble();
      }
      if (p.x < -0.05) p.x = 1.05;
      if (p.x > 1.05) p.x = -0.05;

      final currentOpacity = p.currentOpacity(time);
      // En light mode, opacidad más baja para ser más sutil
      final adjustedOpacity = isDark ? currentOpacity : currentOpacity * 0.6;

      final paint = Paint()
        ..color = particleColor.withValues(alpha: adjustedOpacity)
        ..style = PaintingStyle.fill;

      final px = p.x * size.width;
      final py = p.y * size.height;

      canvas.drawCircle(Offset(px, py), p.size, paint);

      if (p.size > 2.0) {
        final glowPaint = Paint()
          ..color = particleColor.withValues(alpha: adjustedOpacity * 0.3)
          ..style = PaintingStyle.fill
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
        canvas.drawCircle(Offset(px, py), p.size * 2, glowPaint);
      }
    }
  }

  void _paintShootingStars(Canvas canvas, Size size) {
    for (final star in shootingStars) {
      final localProgress =
          ((shootingStarProgress - star.delay) / (1.0 - star.delay))
              .clamp(0.0, 1.0);

      if (localProgress <= 0.0) continue;

      final travel = localProgress * star.speed;

      final headX =
          star.startX * size.width + cos(star.angle) * travel * size.width;
      final headY =
          star.startY * size.height + sin(star.angle) * travel * size.height;

      final tailLength = star.length * size.width;
      final tailX = headX - cos(star.angle) * tailLength;
      final tailY = headY - sin(star.angle) * tailLength;

      double opacity;
      if (localProgress < 0.15) {
        opacity = localProgress / 0.15;
      } else if (localProgress > 0.7) {
        opacity = (1.0 - localProgress) / 0.3;
      } else {
        opacity = 1.0;
      }
      opacity = opacity.clamp(0.0, 1.0) * (isDark ? 0.7 : 0.4);

      final trailPaint = Paint()
        ..shader = LinearGradient(
          colors: [
            particleColor.withValues(alpha: 0.0),
            particleColor.withValues(alpha: opacity * 0.3),
            particleColor.withValues(alpha: opacity * 0.8),
            particleColor.withValues(alpha: opacity),
          ],
          stops: const [0.0, 0.3, 0.7, 1.0],
        ).createShader(Rect.fromPoints(
          Offset(tailX, tailY),
          Offset(headX, headY),
        ))
        ..strokeWidth = star.thickness
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;

      canvas.drawLine(Offset(tailX, tailY), Offset(headX, headY), trailPaint);

      if (opacity > 0.2) {
        final headPaint = Paint()
          ..color = particleColor.withValues(alpha: opacity)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(Offset(headX, headY), star.thickness * 1.2, headPaint);

        final headGlow = Paint()
          ..color = particleColor.withValues(alpha: opacity * 0.4)
          ..style = PaintingStyle.fill
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
        canvas.drawCircle(Offset(headX, headY), star.thickness * 3, headGlow);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlesPainter oldDelegate) => true;
}