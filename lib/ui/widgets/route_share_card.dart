import 'dart:math' as math;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../data/models/lumi.dart';
import '../../data/models/wellness_route.dart';
import 'lumi/lumi_avatar.dart';

/// Tarjeta para compartir al completar una ruta. Tamaño lógico fijo (360×450)
/// para exportarla a 1080×1350 (formato vertical de historias/feed).
///
/// A propósito no incluye datos personales ni de ánimo: solo la ruta.
class RouteShareCard extends StatelessWidget {
  static const width = 360.0;
  static const height = 450.0;

  final WellnessRoute route;
  final DateTime completedAt;

  const RouteShareCard({
    super.key,
    required this.route,
    required this.completedAt,
  });

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    final date = DateFormat.yMMMMd(locale).format(completedAt);

    return SizedBox(
      width: width,
      height: height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: [
            // Fondo con el color de la ruta
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color.lerp(route.color, Colors.white, 0.08)!,
                      route.colorDark,
                      Color.lerp(
                        route.colorDark,
                        const Color(0xFF0B0B1A),
                        0.55,
                      )!,
                    ],
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: CustomPaint(
                painter: _StarfieldPainter(seed: route.id.hashCode),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(26, 26, 26, 22),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'routeShare.badge'.tr().toUpperCase(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 10.5,
                              letterSpacing: 1.4,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          date,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.white.withValues(alpha: 0.75),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  _medal(),
                  const SizedBox(height: 18),
                  Text(
                    'routeShare.completed'.tr(),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    route.title,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    style: const TextStyle(
                      fontSize: 30,
                      height: 1.1,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          color: Colors.black26,
                          blurRadius: 12,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'routeShare.lessons'.tr(
                      namedArgs: {'n': '${route.lessons.length}'},
                    ),
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      const LumiAvatar(mood: LumiMood.proud, size: 54),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Lumen',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              'routeShare.tagline'.tr(),
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.white.withValues(alpha: 0.75),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _medal() {
    return SizedBox(
      width: 150,
      height: 150,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Halo con anillos concéntricos (sin blur)
          for (final (size, alpha) in const [
            (150.0, 0.08),
            (128.0, 0.12),
            (108.0, 0.18),
          ])
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: alpha),
              ),
            ),
          CustomPaint(size: const Size(150, 150), painter: _LaurelPainter()),
          Container(
            width: 92,
            height: 92,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const RadialGradient(
                colors: [
                  Color(0xFFFFF3C4),
                  Color(0xFFFBBF24),
                  Color(0xFFD97706),
                ],
              ),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.85),
                width: 3,
              ),
            ),
            child: Center(
              child: Text(route.emoji, style: const TextStyle(fontSize: 44)),
            ),
          ),
        ],
      ),
    );
  }
}

/// Estrellas y destellos decorativos, deterministas por ruta.
class _StarfieldPainter extends CustomPainter {
  final int seed;
  _StarfieldPainter({required this.seed});

  @override
  void paint(Canvas canvas, Size size) {
    final rng = math.Random(seed);
    for (int i = 0; i < 40; i++) {
      final p = Offset(
        rng.nextDouble() * size.width,
        rng.nextDouble() * size.height,
      );
      canvas.drawCircle(
        p,
        0.6 + rng.nextDouble() * 1.6,
        Paint()
          ..color = Colors.white.withValues(
            alpha: 0.15 + rng.nextDouble() * 0.45,
          ),
      );
    }
    for (int i = 0; i < 7; i++) {
      final p = Offset(
        rng.nextDouble() * size.width,
        rng.nextDouble() * size.height,
      );
      final s = 4 + rng.nextDouble() * 7;
      final path = Path()
        ..moveTo(p.dx, p.dy - s)
        ..quadraticBezierTo(p.dx, p.dy, p.dx + s, p.dy)
        ..quadraticBezierTo(p.dx, p.dy, p.dx, p.dy + s)
        ..quadraticBezierTo(p.dx, p.dy, p.dx - s, p.dy)
        ..quadraticBezierTo(p.dx, p.dy, p.dx, p.dy - s)
        ..close();
      canvas.drawPath(
        path,
        Paint()..color = Colors.white.withValues(alpha: 0.5),
      );
    }
  }

  @override
  bool shouldRepaint(_StarfieldPainter old) => old.seed != seed;
}

/// Corona de laurel dorada alrededor de la medalla.
class _LaurelPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width * 0.4;
    final leaf = Paint()
      ..color = const Color(0xFFFDE68A).withValues(alpha: 0.9);
    for (final side in [-1, 1]) {
      for (int i = 0; i < 7; i++) {
        final a = math.pi / 2 + side * (0.35 + i * 0.3);
        final p = Offset(c.dx + math.cos(a) * r, c.dy + math.sin(a) * r);
        canvas.save();
        canvas.translate(p.dx, p.dy);
        canvas.rotate(a + side * 0.9);
        canvas.drawOval(
          Rect.fromCenter(center: Offset.zero, width: 16, height: 7),
          leaf,
        );
        canvas.restore();
      }
    }
  }

  @override
  bool shouldRepaint(_LaurelPainter old) => false;
}
