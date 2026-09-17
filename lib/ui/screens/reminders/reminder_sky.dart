import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../domain/services/motion_service.dart';

enum SkyPeriod { dawn, day, sunset, night }

/// El cielo de un recordatorio según su hora: amanecer, día, atardecer o
/// noche. Da color e identidad a cada tarjeta sin tener que leer la hora.
class ReminderSky {
  final SkyPeriod period;
  final List<Color> colors;
  final Color accent;

  const ReminderSky._(this.period, this.colors, this.accent);

  /// Clave de traducción del momento del día.
  String get labelKey => switch (period) {
        SkyPeriod.dawn => 'reminders.morning',
        SkyPeriod.day => 'journal.skyDay',
        SkyPeriod.sunset => 'reminders.afternoon',
        SkyPeriod.night => 'reminders.night',
      };

  factory ReminderSky.of(int hour, {required bool isDark}) {
    final period = hour >= 5 && hour < 10
        ? SkyPeriod.dawn
        : hour >= 10 && hour < 17
            ? SkyPeriod.day
            : hour >= 17 && hour < 20
                ? SkyPeriod.sunset
                : SkyPeriod.night;
    return switch (period) {
      SkyPeriod.dawn => const ReminderSky._(
          SkyPeriod.dawn, [Color(0xFFFDE68A), Color(0xFFFCA5A5), Color(0xFFC4B5FD)], Color(0xFFF59E0B)),
      SkyPeriod.day => const ReminderSky._(
          SkyPeriod.day, [Color(0xFFBAE6FD), Color(0xFF7DD3FC), Color(0xFF38BDF8)], Color(0xFF0EA5E9)),
      SkyPeriod.sunset => const ReminderSky._(
          SkyPeriod.sunset, [Color(0xFFFDBA74), Color(0xFFF472B6), Color(0xFF8B5CF6)], Color(0xFFF97316)),
      SkyPeriod.night => const ReminderSky._(
          SkyPeriod.night, [Color(0xFF6366F1), Color(0xFF312E81), Color(0xFF1E1B4B)], Color(0xFF818CF8)),
    };
  }
}

/// Recuadro con el cielo dibujado: sol o luna, nubes o estrellas.
class ReminderSkyTile extends StatefulWidget {
  final ReminderSky sky;
  final double width;
  final double height;
  final bool enabled;
  final double radius;

  const ReminderSkyTile({
    super.key,
    required this.sky,
    required this.width,
    required this.height,
    this.enabled = true,
    this.radius = 0,
  });

  @override
  State<ReminderSkyTile> createState() => _ReminderSkyTileState();
}

class _ReminderSkyTileState extends State<ReminderSkyTile> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(seconds: 8));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MotionService.reduced(context)) {
      _c
        ..stop()
        ..value = 0.25;
    } else if (!_c.isAnimating) {
      _c.repeat();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tile = ClipRRect(
      borderRadius: BorderRadius.circular(widget.radius),
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) => CustomPaint(
            size: Size(widget.width, widget.height),
            painter: _SkyPainter(sky: widget.sky, t: _c.value),
          ),
        ),
      ),
    );
    if (widget.enabled) return tile;
    // Apagado: el cielo en gris
    return ColorFiltered(
      colorFilter: const ColorFilter.matrix([
        0.33, 0.33, 0.33, 0, 0,
        0.33, 0.33, 0.33, 0, 0,
        0.33, 0.33, 0.33, 0, 0,
        0, 0, 0, 1, 0,
      ]),
      child: tile,
    );
  }
}

class _SkyPainter extends CustomPainter {
  final ReminderSky sky;
  final double t;

  _SkyPainter({required this.sky, required this.t});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: sky.colors,
        ).createShader(rect),
    );

    final wave = math.sin(t * math.pi * 2);
    // En tarjetas anchas (editor) el sol, la luna y las nubes se quedan a la
    // derecha y con tamaño según la altura, para no tapar la hora.
    final wide = size.width > size.height * 1.4;
    final h = size.height;
    final w = wide ? h * 0.8 : size.width;
    canvas.save();
    if (wide) canvas.translate(size.width - w - h * 0.02, 0);

    switch (sky.period) {
      case SkyPeriod.night:
        final rng = math.Random(3);
        for (int i = 0; i < 14; i++) {
          final p = Offset(rng.nextDouble() * w, rng.nextDouble() * h * 0.8);
          final tw = 0.35 + 0.65 * (0.5 + 0.5 * math.sin(t * math.pi * 2 * (1 + i % 3) + i));
          canvas.drawCircle(p, 0.8 + rng.nextDouble() * 1.1, Paint()..color = Colors.white.withValues(alpha: tw));
        }
        _moon(canvas, Offset(w * 0.55, h * 0.36), w * 0.2);
      case SkyPeriod.dawn:
        _sun(canvas, Offset(w * 0.5, h * 0.72 - wave * 2), w * 0.2, const Color(0xFFFFF7ED));
        _cloud(canvas, Offset(w * 0.22 + wave * 3, h * 0.3), w * 0.16);
      case SkyPeriod.day:
        _sun(canvas, Offset(w * 0.62, h * 0.32), w * 0.18, const Color(0xFFFEF08A));
        _cloud(canvas, Offset(w * 0.3 + wave * 4, h * 0.62), w * 0.2);
      case SkyPeriod.sunset:
        _sun(canvas, Offset(w * 0.5, h * 0.8 + wave * 1.5), w * 0.24, const Color(0xFFFFEDD5));
        // Líneas de horizonte
        final line = Paint()
          ..color = Colors.white.withValues(alpha: 0.35)
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round;
        for (int i = 0; i < 3; i++) {
          final y = h * (0.86 + i * 0.05);
          canvas.drawLine(Offset(w * (0.25 + i * 0.05), y), Offset(w * (0.75 - i * 0.05), y), line);
        }
    }
    canvas.restore();

    // Estrellas repartidas por todo el ancho en tarjetas anchas de noche
    if (wide && sky.period == SkyPeriod.night) {
      final rng = math.Random(11);
      for (int i = 0; i < 24; i++) {
        final p = Offset(rng.nextDouble() * size.width * 0.7, rng.nextDouble() * h * 0.7);
        final tw = 0.3 + 0.7 * (0.5 + 0.5 * math.sin(t * math.pi * 2 * (1 + i % 3) + i));
        canvas.drawCircle(p, 0.8 + rng.nextDouble(), Paint()..color = Colors.white.withValues(alpha: tw));
      }
    }
  }

  void _sun(Canvas canvas, Offset c, double r, Color core) {
    canvas.drawCircle(
      c,
      r * 2.2,
      Paint()
        ..shader = RadialGradient(colors: [core.withValues(alpha: 0.55), core.withValues(alpha: 0)])
            .createShader(Rect.fromCircle(center: c, radius: r * 2.2)),
    );
    canvas.drawCircle(c, r, Paint()..color = core);
  }

  void _moon(Canvas canvas, Offset c, double r) {
    canvas.drawCircle(
      c,
      r * 2.2,
      Paint()
        ..shader = RadialGradient(colors: [Colors.white.withValues(alpha: 0.25), Colors.white.withValues(alpha: 0)])
            .createShader(Rect.fromCircle(center: c, radius: r * 2.2)),
    );
    // Luna creciente: un círculo claro menos otro desplazado
    final moon = Path()..addOval(Rect.fromCircle(center: c, radius: r));
    final bite = Path()..addOval(Rect.fromCircle(center: c + Offset(r * 0.45, -r * 0.25), radius: r * 0.85));
    canvas.drawPath(Path.combine(PathOperation.difference, moon, bite), Paint()..color = const Color(0xFFFEF9C3));
  }

  void _cloud(Canvas canvas, Offset c, double r) {
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.85);
    canvas.drawCircle(c, r * 0.6, paint);
    canvas.drawCircle(c + Offset(r * 0.6, r * 0.12), r * 0.48, paint);
    canvas.drawCircle(c + Offset(-r * 0.6, r * 0.16), r * 0.42, paint);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTRB(c.dx - r, c.dy + r * 0.05, c.dx + r, c.dy + r * 0.55), Radius.circular(r * 0.3)),
      paint,
    );
  }

  @override
  bool shouldRepaint(_SkyPainter old) => old.t != t || old.sky.period != sky.period;
}
