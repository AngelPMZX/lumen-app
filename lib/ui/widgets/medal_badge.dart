import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../data/models/medals.dart';
import '../../domain/services/motion_service.dart';

/// Colores del metal de cada nivel: claro, medio y oscuro.
class MedalMetal {
  final Color light;
  final Color mid;
  final Color dark;
  const MedalMetal(this.light, this.mid, this.dark);

  static const bronze = MedalMetal(Color(0xFFF3C7A0), Color(0xFFCD7F32), Color(0xFF8A4B1C));
  static const silver = MedalMetal(Color(0xFFF8FAFC), Color(0xFFC0C7D2), Color(0xFF7B8594));
  static const gold = MedalMetal(Color(0xFFFFF3B0), Color(0xFFF5B82E), Color(0xFFB7791F));
  static const locked = MedalMetal(Color(0xFFE5E7EB), Color(0xFFB8BEC8), Color(0xFF8B93A1));

  static MedalMetal of(MedalTier tier) => switch (tier) {
        MedalTier.bronze => bronze,
        MedalTier.silver => silver,
        MedalTier.gold => gold,
      };
}

/// Medalla dibujada con código: listón del color del logro, borde metálico
/// según el nivel, disco con el emoji y un brillo que la cruza de vez en
/// cuando. Bloqueada, se ve en gris con un anillo de avance.
class MedalBadge extends StatelessWidget {
  final MedalStatus medal;
  final double size;
  final bool shine;
  final bool showRibbon;

  const MedalBadge({super.key, required this.medal, this.size = 72, this.shine = true, this.showRibbon = true});

  @override
  Widget build(BuildContext context) {
    final unlocked = medal.unlocked;
    final metal = unlocked ? MedalMetal.of(medal.tier) : MedalMetal.locked;
    final color = medal.achievement.color;
    final reduced = MotionService.reduced(context);
    final ribbonH = showRibbon ? size * 0.34 : 0.0;
    final disc = size;

    Widget face = SizedBox(
      width: disc,
      height: disc,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size.square(disc),
            painter: _MedalPainter(metal: metal, color: unlocked ? color : const Color(0xFF9CA3AF), unlocked: unlocked),
          ),
          if (unlocked)
            Text(medal.achievement.emoji, style: TextStyle(fontSize: disc * 0.36))
          else
            Opacity(
              opacity: 0.3,
              child: ColorFiltered(
                colorFilter: const ColorFilter.matrix([
                  0.33, 0.33, 0.33, 0, 0, //
                  0.33, 0.33, 0.33, 0, 0,
                  0.33, 0.33, 0.33, 0, 0,
                  0, 0, 0, 1, 0,
                ]),
                child: Text(medal.achievement.emoji, style: TextStyle(fontSize: disc * 0.34)),
              ),
            ),
          if (!unlocked)
            Positioned(
              bottom: disc * 0.1,
              right: disc * 0.1,
              child: Container(
                width: disc * 0.3,
                height: disc * 0.3,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFD1D5DB), width: 1.5),
                ),
                child: Icon(Icons.lock_rounded, size: disc * 0.17, color: const Color(0xFF6B7280)),
              ),
            ),
          if (unlocked && shine && !reduced)
            ClipOval(
              child: SizedBox(
                width: disc,
                height: disc,
                child: const _ShineSweep(),
              ),
            ),
        ],
      ),
    );

    if (!unlocked && medal.progress > 0) {
      face = SizedBox(
        width: disc,
        height: disc,
        child: Stack(
          alignment: Alignment.center,
          children: [
            face,
            IgnorePointer(
              child: CustomPaint(
                size: Size.square(disc),
                painter: _ProgressArc(progress: medal.progress, color: color),
              ),
            ),
          ],
        ),
      );
    }

    return SizedBox(
      width: size,
      height: size + ribbonH * 0.6,
      child: Stack(
        alignment: Alignment.bottomCenter,
        clipBehavior: Clip.none,
        children: [
          if (showRibbon)
            Positioned(
              top: 0,
              child: CustomPaint(
                size: Size(size * 0.62, ribbonH),
                painter: _RibbonPainter(color: unlocked ? color : const Color(0xFFCBD2DA)),
              ),
            ),
          Positioned(bottom: 0, child: face),
        ],
      ),
    );
  }
}

class _MedalPainter extends CustomPainter {
  final MedalMetal metal;
  final Color color;
  final bool unlocked;

  _MedalPainter({required this.metal, required this.color, required this.unlocked});

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2;

    // Sombra suave debajo (círculos concéntricos, sin blur)
    for (int i = 3; i >= 1; i--) {
      canvas.drawCircle(
        c + Offset(0, r * 0.06),
        r + i * 1.5,
        Paint()..color = Colors.black.withValues(alpha: 0.035 * (4 - i)),
      );
    }

    // Borde metálico con dientes
    final rim = Rect.fromCircle(center: c, radius: r);
    final rimPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [metal.light, metal.mid, metal.dark, metal.mid],
        stops: const [0, 0.4, 0.75, 1],
      ).createShader(rim);
    const teeth = 24;
    final path = Path();
    for (int i = 0; i <= teeth * 2; i++) {
      final a = i / (teeth * 2) * math.pi * 2 - math.pi / 2;
      final rr = i.isEven ? r : r * 0.94;
      final p = c + Offset(math.cos(a), math.sin(a)) * rr;
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    path.close();
    canvas.drawPath(path, rimPaint);

    // Anillo interior
    canvas.drawCircle(
      c,
      r * 0.8,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.bottomRight,
          end: Alignment.topLeft,
          colors: [metal.light, metal.dark],
        ).createShader(rim),
    );

    // Disco con el color del logro
    final discRect = Rect.fromCircle(center: c, radius: r * 0.72);
    canvas.drawCircle(
      c,
      r * 0.72,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.35, -0.4),
          radius: 1.1,
          colors: unlocked
              ? [Color.lerp(color, Colors.white, 0.55)!, color, Color.lerp(color, Colors.black, 0.35)!]
              : [const Color(0xFFF3F4F6), const Color(0xFFD1D5DB), const Color(0xFF9CA3AF)],
          stops: const [0, 0.55, 1],
        ).createShader(discRect),
    );

    // Brillo fijo arriba a la izquierda
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: r * 0.6),
      math.pi * 1.05,
      math.pi * 0.45,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = r * 0.07
        ..color = Colors.white.withValues(alpha: unlocked ? 0.55 : 0.4),
    );
  }

  @override
  bool shouldRepaint(_MedalPainter old) => old.metal != metal || old.color != color || old.unlocked != unlocked;
}

class _RibbonPainter extends CustomPainter {
  final Color color;
  _RibbonPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final dark = Color.lerp(color, Colors.black, 0.25)!;
    final left = Path()
      ..moveTo(0, 0)
      ..lineTo(w * 0.42, 0)
      ..lineTo(w * 0.62, h * 1.25)
      ..lineTo(w * 0.22, h * 1.25)
      ..close();
    final right = Path()
      ..moveTo(w, 0)
      ..lineTo(w * 0.58, 0)
      ..lineTo(w * 0.38, h * 1.25)
      ..lineTo(w * 0.78, h * 1.25)
      ..close();
    canvas.drawPath(left, Paint()..color = dark);
    canvas.drawPath(right, Paint()..color = color);
    // raya central clara
    canvas.drawPath(
      Path()
        ..moveTo(w * 0.66, 0)
        ..lineTo(w * 0.74, 0)
        ..lineTo(w * 0.52, h * 1.25)
        ..lineTo(w * 0.44, h * 1.25)
        ..close(),
      Paint()..color = Colors.white.withValues(alpha: 0.35),
    );
  }

  @override
  bool shouldRepaint(_RibbonPainter old) => old.color != color;
}

class _ProgressArc extends CustomPainter {
  final double progress;
  final Color color;
  _ProgressArc({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromCircle(center: size.center(Offset.zero), radius: size.width / 2 + 3);
    canvas.drawArc(
      rect,
      -math.pi / 2,
      math.pi * 2 * progress,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5
        ..strokeCap = StrokeCap.round
        ..color = color,
    );
  }

  @override
  bool shouldRepaint(_ProgressArc old) => old.progress != progress || old.color != color;
}

/// Destello diagonal que cruza la medalla cada pocos segundos.
class _ShineSweep extends StatelessWidget {
  const _ShineSweep();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: LayoutBuilder(
        builder: (context, c) {
          final w = c.maxWidth;
          return Transform.rotate(
            angle: -0.5,
            child: OverflowBox(
              maxWidth: w * 2,
              maxHeight: w * 2,
              child: Container(
                width: w * 0.28,
                height: w * 2,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.white.withValues(alpha: 0), Colors.white.withValues(alpha: 0.55), Colors.white.withValues(alpha: 0)],
                  ),
                ),
              ),
            ),
          )
              .animate(onPlay: MotionService.loop(context))
              .moveX(begin: -w * 1.3, end: -w * 1.3, duration: 2600.ms)
              .then()
              .moveX(begin: 0, end: w * 2.6, duration: 900.ms, curve: Curves.easeInOut);
        },
      ),
    );
  }
}
