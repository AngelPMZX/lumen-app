import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../domain/services/motion_service.dart';

/// Fondo de la lección.
///
/// - Oscuro: cielo nocturno con estrellas que titilan, estrellas fugaces y
///   nebulosas del color de la ruta.
/// - Claro: amanecer suave con un sol tibio y burbujas de luz que suben.
///
/// Todo se pinta con un solo `CustomPainter` y un solo controlador (antes
/// eran 80 widgets con su propio `AnimationController`). Sin
/// `MaskFilter.blur`: los halos son degradados radiales. Con movimiento
/// reducido el cielo queda quieto.
class LessonBackground extends StatefulWidget {
  final Color routeColor;
  final bool isDark;

  const LessonBackground({
    super.key,
    required this.routeColor,
    required this.isDark,
  });

  @override
  State<LessonBackground> createState() => _LessonBackgroundState();
}

class _LessonBackgroundState extends State<LessonBackground>
    with SingleTickerProviderStateMixin {
  /// Un ciclo largo: todas las frecuencias son múltiplos enteros, así el
  /// bucle no salta al reiniciar.
  static const _cycle = Duration(seconds: 60);

  late final AnimationController _clock;

  @override
  void initState() {
    super.initState();
    _clock = AnimationController(vsync: this, duration: _cycle);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MotionService.reduced(context)) {
      _clock
        ..stop()
        ..value = 0.37; // un instante bonito y fijo
    } else if (!_clock.isAnimating) {
      _clock.repeat();
    }
  }

  @override
  void dispose() {
    _clock.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(
        painter: widget.isDark
            ? _NightSkyPainter(clock: _clock, accent: widget.routeColor)
            : _DawnSkyPainter(clock: _clock, accent: widget.routeColor),
        child: const SizedBox.expand(),
      ),
    );
  }
}

/// Halo sin blur: un círculo con degradado radial que se desvanece hacia el
/// borde (los degradados son seguros en WebGL; `MaskFilter.blur` no).
void _halo(Canvas canvas, Offset c, double radius, Color color, double alpha) {
  if (radius <= 0 || alpha <= 0) return;
  final rect = Rect.fromCircle(center: c, radius: radius);
  canvas.drawCircle(
    c,
    radius,
    Paint()
      ..shader = RadialGradient(
        colors: [
          color.withValues(alpha: alpha),
          color.withValues(alpha: alpha * 0.35),
          color.withValues(alpha: 0),
        ],
        stops: const [0, 0.4, 1],
      ).createShader(rect),
  );
}

// ═══════════════════════════════════════════════════════════════════════════
// NOCHE
// ═══════════════════════════════════════════════════════════════════════════
class _Star {
  final double x, y, size, maxOpacity, phase;
  final int speed; // ciclos por minuto (entero: bucle sin salto)
  final bool accent;
  const _Star(this.x, this.y, this.size, this.maxOpacity, this.phase,
      this.speed, this.accent);
}

class _NightSkyPainter extends CustomPainter {
  final Animation<double> clock;
  final Color accent;

  _NightSkyPainter({required this.clock, required this.accent})
      : super(repaint: clock);

  static final List<_Star> _stars = () {
    final rng = math.Random(99);
    return List.generate(80, (i) {
      return _Star(
        rng.nextDouble(),
        rng.nextDouble(),
        1.0 + rng.nextDouble() * 2.5,
        0.4 + rng.nextDouble() * 0.6,
        rng.nextDouble() * math.pi * 2,
        20 + rng.nextInt(50),
        i % 6 == 0,
      );
    });
  }();

  /// Estrellas fugaces: inicio (0-1 del minuto), posición, ángulo y largo.
  static const _shooting = [
    (0.05, 0.10, 0.05, 0.63, 0.22),
    (0.30, 0.60, 0.02, 0.73, 0.18),
    (0.55, 0.30, 0.15, 0.48, 0.25),
    (0.80, 0.75, 0.08, 0.68, 0.15),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final t = clock.value;
    final rect = Offset.zero & size;

    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF060612),
            Color.lerp(const Color(0xFF0A0A1E), accent, 0.14)!,
            const Color(0xFF0C0C1E),
          ],
        ).createShader(rect),
    );

    // Nebulosas
    canvas.drawCircle(
      Offset(80, 60),
      220,
      Paint()
        ..shader = RadialGradient(colors: [
          accent.withValues(alpha: 0.28),
          accent.withValues(alpha: 0),
        ]).createShader(Rect.fromCircle(center: const Offset(80, 60), radius: 220)),
    );
    final bottomRight = Offset(size.width + 30, size.height + 50);
    canvas.drawCircle(
      bottomRight,
      180,
      Paint()
        ..shader = RadialGradient(colors: [
          const Color(0xFF818CF8).withValues(alpha: 0.2),
          const Color(0xFF818CF8).withValues(alpha: 0),
        ]).createShader(Rect.fromCircle(center: bottomRight, radius: 180)),
    );

    // Estrellas que titilan
    for (final s in _stars) {
      final wave = 0.5 + 0.5 * math.sin(t * math.pi * 2 * s.speed + s.phase);
      final o = 0.05 + (s.maxOpacity - 0.05) * wave;
      final p = Offset(s.x * size.width, s.y * size.height);
      if (s.size > 1.8) {
        _halo(canvas, p, s.size * 3, s.accent ? accent : Colors.white, o * 0.3);
      }
      canvas.drawCircle(p, s.size / 2, Paint()..color = Colors.white.withValues(alpha: o));
    }

    // Estrellas fugaces: cada una cruza durante ~1.5 s de su minuto
    for (final (start, x, y, angle, length) in _shooting) {
      var local = (t - start) % 1.0;
      const span = 1.5 / 60;
      if (local > span) continue;
      local /= span;
      final eased = Curves.easeIn.transform(local);
      final len = size.width * length;
      final dist = eased * len * 2.5;
      final head = Offset(
        x * size.width + math.cos(angle) * dist,
        y * size.height + math.sin(angle) * dist,
      );
      final tailLen = len * (0.3 + eased * 0.7);
      final tail = head - Offset(math.cos(angle), math.sin(angle)) * tailLen;
      final headO = local < 0.3 ? local / 0.3 : ((1 - local) / 0.7).clamp(0.0, 1.0);
      canvas.drawLine(
        tail,
        head,
        Paint()
          ..shader = LinearGradient(colors: [
            Colors.white.withValues(alpha: 0),
            accent.withValues(alpha: (1 - local) * 0.5),
            Colors.white.withValues(alpha: headO),
          ]).createShader(Rect.fromPoints(tail, head))
          ..strokeWidth = 1.5
          ..strokeCap = StrokeCap.round,
      );
      _halo(canvas, head, 5, Colors.white, headO);
      canvas.drawCircle(head, 1.4, Paint()..color = Colors.white.withValues(alpha: headO));
    }
  }

  @override
  bool shouldRepaint(_NightSkyPainter old) => old.accent != accent;
}

// ═══════════════════════════════════════════════════════════════════════════
// AMANECER
// ═══════════════════════════════════════════════════════════════════════════
class _Mote {
  final double x, phase, size, drift;
  final int rise; // vueltas por minuto (entero)
  final bool warm;
  const _Mote(this.x, this.phase, this.size, this.drift, this.rise, this.warm);
}

class _DawnSkyPainter extends CustomPainter {
  final Animation<double> clock;
  final Color accent;

  _DawnSkyPainter({required this.clock, required this.accent})
      : super(repaint: clock);

  static const _sun = Color(0xFFFBBF24);

  static final List<_Mote> _motes = () {
    final rng = math.Random(7);
    return List.generate(22, (i) {
      return _Mote(
        rng.nextDouble(),
        rng.nextDouble(),
        6 + rng.nextDouble() * 22,
        10 + rng.nextDouble() * 22,
        1 + rng.nextInt(3),
        i % 4 == 0,
      );
    });
  }();

  @override
  void paint(Canvas canvas, Size size) {
    final t = clock.value;
    final rect = Offset.zero & size;

    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.lerp(const Color(0xFFFFFBF5), accent, 0.16)!,
            const Color(0xFFF8F6FF),
            Color.lerp(const Color(0xFFFFFFFF), accent, 0.07)!,
          ],
          stops: const [0, 0.55, 1],
        ).createShader(rect),
    );

    // Sol tibio que respira muy despacio
    final sunCenter = Offset(size.width * 0.86, size.height * 0.07);
    final breathe = 1 + 0.04 * math.sin(t * math.pi * 2 * 4);
    _halo(canvas, sunCenter, 190 * breathe, _sun, 0.55);
    _halo(canvas, sunCenter, 90 * breathe, const Color(0xFFFDE68A), 0.7);

    // Resplandor del color de la ruta abajo a la izquierda
    _halo(canvas, Offset(-20, size.height * 0.92), 260, accent, 0.35);

    // Burbujas de luz que suben y se mecen
    for (final m in _motes) {
      final progress = (m.phase + t * m.rise) % 1.0;
      final y = size.height * (1.1 - progress * 1.25);
      final x = m.x * size.width +
          math.sin((progress + m.phase) * math.pi * 2) * m.drift;
      // Aparecen y desaparecen en los extremos del recorrido
      final fade = math.sin(progress * math.pi).clamp(0.0, 1.0);
      final color = m.warm ? _sun : accent;
      _halo(canvas, Offset(x, y), m.size, color, 0.45 * fade);
      canvas.drawCircle(
        Offset(x, y),
        m.size * 0.18,
        Paint()..color = Colors.white.withValues(alpha: 0.7 * fade),
      );
    }
  }

  @override
  bool shouldRepaint(_DawnSkyPainter old) => old.accent != accent;
}
