import 'dart:math';
import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../../domain/services/motion_service.dart';

/// Cada estrella fugaz dura esto y luego se vuelve a sortear.
const double _starCycle = 2.5;

/// Medio segundo de cortesía antes de la primera.
const double _starStart = 0.5;

/// Widget de fondo animado con partículas flotantes y estrellas fugaces.
/// Funciona en AMBOS modos (dark y light).
/// En light mode usa partículas más sutiles con colores del primary.
///
/// Rendimiento: está detrás de pantallas que se desplazan, así que se pinta en
/// cada cuadro. Para que eso no arrastre a toda la pantalla:
/// - va dentro de un [RepaintBoundary], así su repintado no ensucia la capa
///   del contenido que tiene encima;
/// - lo mueve un [Ticker] que solo avisa al painter (`repaint:`), sin
///   reconstruir widgets;
/// - el movimiento se calcula con **segundos transcurridos**, no sumando en
///   cada cuadro: antes, en una pantalla de 120 Hz las partículas iban al
///   doble de velocidad que en una de 60 Hz.
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
    extends State<AnimatedParticlesBackground>
    with SingleTickerProviderStateMixin {
  /// Segundos desde que arrancó. Es lo único que escucha el painter.
  final ValueNotifier<double> _time = ValueNotifier<double>(0);
  Ticker? _ticker;

  final Random _random = Random();
  late List<_FloatingParticle> _particles;
  late List<_ShootingStar> _shootingStars;

  int _lastStarCycle = 0;

  @override
  void initState() {
    super.initState();

    _particles = List.generate(
      widget.particleCount,
      (_) => _FloatingParticle.random(_random),
    );

    _shootingStars = List.generate(
      widget.maxShootingStars,
      (_) => _ShootingStar.random(_random),
    );

    // Con "reducir animaciones" el fondo se queda quieto: sin ticker no hay
    // un solo repintado de más.
    if (!MotionService.instance.reducedNow) {
      _ticker = createTicker(_onTick)..start();
    }
  }

  void _onTick(Duration elapsed) {
    final t = elapsed.inMicroseconds / Duration.microsecondsPerSecond;
    if (widget.maxShootingStars > 0 && t >= _starStart) {
      final cycle = ((t - _starStart) / _starCycle).floor();
      if (cycle != _lastStarCycle) {
        _lastStarCycle = cycle;
        _shootingStars = List.generate(
          widget.maxShootingStars,
          (_) => _ShootingStar.random(_random),
        );
      }
    }
    _time.value = t;
  }

  @override
  void dispose() {
    _ticker?.dispose();
    _time.dispose();
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

    return RepaintBoundary(
      child: CustomPaint(
        painter: _ParticlesPainter(
          time: _time,
          particles: _particles,
          shootingStars: () => _shootingStars,
          particleColor: color,
          isDark: isDark,
        ),
        isComplex: false,
        willChange: true,
        size: Size.infinite,
      ),
    );
  }
}

class _FloatingParticle {
  /// Posición de salida (fracción de la pantalla).
  final double x0;
  final double y0;
  final double size;
  final double opacity;

  /// Velocidad en fracciones de pantalla **por segundo**.
  final double speedX;
  final double speedY;
  final double twinkleSpeed;
  final double twinkleOffset;

  _FloatingParticle({
    required this.x0,
    required this.y0,
    required this.size,
    required this.opacity,
    required this.speedX,
    required this.speedY,
    required this.twinkleSpeed,
    required this.twinkleOffset,
  });

  factory _FloatingParticle.random(Random r) {
    return _FloatingParticle(
      x0: r.nextDouble(),
      y0: r.nextDouble(),
      size: 1.0 + r.nextDouble() * 2.5,
      opacity: 0.15 + r.nextDouble() * 0.45,
      // Las velocidades originales eran por cuadro a 60 fps.
      speedX: (r.nextDouble() - 0.5) * 0.0003 * 60,
      speedY: (-0.0001 - r.nextDouble() * 0.0004) * 60,
      twinkleSpeed: 1.5 + r.nextDouble() * 3.0,
      twinkleOffset: r.nextDouble() * pi * 2,
    );
  }

  /// Las partículas dan la vuelta al salirse, en el mismo margen de antes.
  static double _wrap(double v) {
    const min = -0.05;
    const span = 1.1; // de -0.05 a 1.05
    final k = (v - min) % span;
    return min + (k < 0 ? k + span : k);
  }

  double xAt(double time) => _wrap(x0 + speedX * time);

  double yAt(double time) => _wrap(y0 + speedY * time);

  double currentOpacity(double time) {
    final twinkle = sin(time * twinkleSpeed + twinkleOffset);
    final twinkleFactor = 0.3 + (twinkle + 1) * 0.35;
    return opacity * twinkleFactor;
  }
}

class _ShootingStar {
  final double startX;
  final double startY;
  final double angle;
  final double length;
  final double speed;
  final double delay;
  final double thickness;

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
  final ValueListenable<double> time;
  final List<_FloatingParticle> particles;

  /// Las estrellas se vuelven a sortear en cada vuelta, por eso se leen al
  /// pintar en vez de guardarse en el painter.
  final List<_ShootingStar> Function() shootingStars;
  final Color particleColor;
  final bool isDark;

  _ParticlesPainter({
    required this.time,
    required this.particles,
    required this.shootingStars,
    required this.particleColor,
    required this.isDark,
  }) : super(repaint: time);

  @override
  void paint(Canvas canvas, Size size) {
    final t = time.value;
    // Un solo Paint reutilizado: antes se creaba uno por partícula y por
    // anillo de resplandor, decenas por cuadro.
    final paint = Paint()..style = PaintingStyle.fill;
    _paintFloatingParticles(canvas, size, t, paint);
    final stars = shootingStars();
    if (stars.isNotEmpty) {
      _paintShootingStars(canvas, size, t, stars, paint);
    }
  }

  void _paintFloatingParticles(
    Canvas canvas,
    Size size,
    double t,
    Paint paint,
  ) {
    for (final p in particles) {
      final currentOpacity = p.currentOpacity(t);
      // En light mode, opacidad más baja para ser más sutil
      final adjustedOpacity = isDark ? currentOpacity : currentOpacity * 0.6;

      final px = p.xAt(t) * size.width;
      final py = p.yAt(t) * size.height;

      paint.color = particleColor.withValues(alpha: adjustedOpacity);
      canvas.drawCircle(Offset(px, py), p.size, paint);

      if (p.size > 2.0) {
        // Resplandor con círculos concéntricos: MaskFilter.blur rompe WebGL
        for (int ring = 3; ring >= 1; ring--) {
          paint.color = particleColor.withValues(
            alpha: adjustedOpacity * 0.1 * (4 - ring) / 3,
          );
          canvas.drawCircle(Offset(px, py), p.size * (1 + ring * 0.5), paint);
        }
      }
    }
  }

  void _paintShootingStars(
    Canvas canvas,
    Size size,
    double t,
    List<_ShootingStar> stars,
    Paint paint,
  ) {
    if (t < _starStart) return;
    final progress = ((t - _starStart) % _starCycle) / _starCycle;

    final trailPaint = Paint()
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    for (final star in stars) {
      final localProgress =
          ((progress - star.delay) / (1.0 - star.delay)).clamp(0.0, 1.0);

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

      trailPaint
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
        ..strokeWidth = star.thickness;

      canvas.drawLine(Offset(tailX, tailY), Offset(headX, headY), trailPaint);

      if (opacity > 0.2) {
        paint.color = particleColor.withValues(alpha: opacity);
        canvas.drawCircle(Offset(headX, headY), star.thickness * 1.2, paint);

        for (int ring = 3; ring >= 1; ring--) {
          paint.color = particleColor.withValues(
            alpha: opacity * 0.12 * (4 - ring) / 3,
          );
          canvas.drawCircle(
            Offset(headX, headY),
            star.thickness * (1.2 + ring * 0.6),
            paint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlesPainter old) =>
      old.particleColor != particleColor ||
      old.isDark != isDark ||
      old.particles != particles;
}
