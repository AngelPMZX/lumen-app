import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:gimnasio_emocional/data/models/lumi.dart';
import 'package:gimnasio_emocional/ui/widgets/lumi/lumi_avatar.dart';

/// Arte de marca de Lumen dibujado con código: el ícono de la app y el
/// gráfico de la ficha de Play salen de aquí, así que siempre coinciden con
/// la Lumi que se ve dentro de la app.
///
/// Para exportarlos: `flutter test tool/branding/generate_branding_test.dart`.
class LumenBrand {
  LumenBrand._();

  static const verde = Color(0xFF10B981);
  static const verdeMedio = Color(0xFF059669);
  static const verdeOscuro = Color(0xFF065F46);
  static const noche = Color(0xFF07281F);
}

/// Ícono de la app: fondo verde con luz, un aro suave y Lumi al centro.
/// [safeArea] deja el margen que piden los íconos adaptativos de Android
/// (el sistema recorta hasta un 25 % por lado).
class LumenIcon extends StatelessWidget {
  final double size;
  final bool transparentBackground;
  final double contentScale;

  const LumenIcon({
    super.key,
    required this.size,
    this.transparentBackground = false,
    this.contentScale = 1,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (!transparentBackground)
            CustomPaint(size: Size.square(size), painter: const _IconBackgroundPainter()),
          CustomPaint(size: Size.square(size), painter: _GlowPainter(scale: contentScale)),
          LumiMark(size: size * 0.52 * contentScale, mood: LumiMood.happy),
        ],
      ),
    );
  }
}

class _IconBackgroundPainter extends CustomPainter {
  const _IconBackgroundPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    // Fondo: verde profundo con una luz cálida arriba a la izquierda
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [LumenBrand.verde, LumenBrand.verdeMedio, LumenBrand.noche],
          stops: [0, 0.45, 1],
        ).createShader(rect),
    );

    // Dos arcos muy suaves abajo, como la curva de una colina
    final colina = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.01
      ..color = Colors.white.withValues(alpha: 0.09);
    for (int i = 0; i < 2; i++) {
      final r = size.width * (0.62 + i * 0.2);
      canvas.drawArc(
        Rect.fromCircle(center: Offset(size.width * 0.5, size.height * 1.16), radius: r),
        math.pi * 1.22,
        math.pi * 0.56,
        false,
        colina,
      );
    }
  }

  @override
  bool shouldRepaint(_IconBackgroundPainter old) => false;
}

/// Resplandor detrás de Lumi, con círculos concéntricos (nunca MaskFilter).
class _GlowPainter extends CustomPainter {
  final double scale;
  const _GlowPainter({required this.scale});

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final base = size.width * 0.3 * scale;
    canvas.drawCircle(
      c,
      base * 1.7,
      Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFFFDE68A).withValues(alpha: 0.5),
            const Color(0xFFFDE68A).withValues(alpha: 0.12),
            const Color(0xFFFDE68A).withValues(alpha: 0),
          ],
          stops: const [0, 0.5, 1],
        ).createShader(Rect.fromCircle(center: c, radius: base * 1.7)),
    );

    // Destellos de cuatro puntas, como los de la app
    for (final (angle, dist, r) in [
      (-0.62, 1.18, 0.052),
      (0.75, 1.24, 0.038),
      (2.4, 1.12, 0.044),
      (3.75, 1.26, 0.030),
    ]) {
      final p = c + Offset(math.cos(angle), math.sin(angle)) * base * dist;
      _sparkle(canvas, p, size.width * r * scale);
    }
  }

  /// Destello de cuatro puntas: dos rombos cruzados y un núcleo brillante.
  void _sparkle(Canvas canvas, Offset c, double r) {
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.92);
    final path = Path()
      ..moveTo(c.dx, c.dy - r)
      ..quadraticBezierTo(c.dx + r * 0.16, c.dy - r * 0.16, c.dx + r, c.dy)
      ..quadraticBezierTo(c.dx + r * 0.16, c.dy + r * 0.16, c.dx, c.dy + r)
      ..quadraticBezierTo(c.dx - r * 0.16, c.dy + r * 0.16, c.dx - r, c.dy)
      ..quadraticBezierTo(c.dx - r * 0.16, c.dy - r * 0.16, c.dx, c.dy - r)
      ..close();
    canvas.drawCircle(c, r * 0.9, Paint()..color = Colors.white.withValues(alpha: 0.14));
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_GlowPainter old) => old.scale != scale;
}

/// Gráfico de funciones de Play (1024×500): Lumi a la izquierda y el nombre
/// con su frase a la derecha.
class LumenFeatureGraphic extends StatelessWidget {
  final Size size;
  final String tagline;
  final String subtitle;

  const LumenFeatureGraphic({
    super.key,
    this.size = const Size(1024, 500),
    required this.tagline,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final h = size.height;
    return SizedBox(
      width: size.width,
      height: h,
      child: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: const _IconBackgroundPainter())),
          Positioned(
            left: h * 0.12,
            top: 0,
            bottom: 0,
            width: h * 0.86,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(size: Size.square(h * 0.86), painter: const _GlowPainter(scale: 0.9)),
                LumiMark(size: h * 0.5, mood: LumiMood.happy),
              ],
            ),
          ),
          Positioned(
            left: h * 0.95,
            right: h * 0.12,
            top: 0,
            bottom: 0,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Lumen',
                  style: TextStyle(
                    fontSize: h * 0.2,
                    height: 1.05,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 1.5,
                  ),
                ),
                SizedBox(height: h * 0.02),
                Text(
                  tagline,
                  style: TextStyle(
                    fontSize: h * 0.076,
                    height: 1.2,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFA7F3D0),
                  ),
                ),
                SizedBox(height: h * 0.035),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: h * 0.05,
                    height: 1.35,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
