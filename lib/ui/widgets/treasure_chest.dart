import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Cofre del tesoro dibujado con código: madera con bandas doradas, candados
/// que se iluminan al reclamar misiones, tapa que se abre y rayos de luz.
///
/// [open] va de 0 (cerrado) a 1 (abierto). [shake] es el desplazamiento
/// horizontal del temblor. Sin MaskFilter.blur (rompe WebGL en web).
class TreasureChest extends StatelessWidget {
  final double size;
  final int locks;
  final int unlocked;
  final double open;
  final double rays; // rotación de los rayos, 0-1 en bucle
  final bool glowing;

  const TreasureChest({
    super.key,
    this.size = 180,
    this.locks = 3,
    required this.unlocked,
    this.open = 0,
    this.rays = 0,
    this.glowing = false,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size * 0.9),
      painter: _ChestPainter(
        locks: locks,
        unlocked: unlocked,
        open: open,
        rays: rays,
        glowing: glowing,
      ),
    );
  }
}

class _ChestPainter extends CustomPainter {
  final int locks;
  final int unlocked;
  final double open;
  final double rays;
  final bool glowing;

  _ChestPainter({
    required this.locks,
    required this.unlocked,
    required this.open,
    required this.rays,
    required this.glowing,
  });

  static const _woodLight = Color(0xFFB7793E);
  static const _woodDark = Color(0xFF7A4A22);
  static const _gold = Color(0xFFFBBF24);
  static const _goldDark = Color(0xFFD97706);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final boxW = w * 0.72;
    final boxH = h * 0.4;
    final left = (w - boxW) / 2;
    final boxTop = h * 0.5;
    final box = Rect.fromLTWH(left, boxTop, boxW, boxH);
    final center = Offset(w / 2, boxTop);

    // Rayos y resplandor cuando está listo o abierto
    if (glowing || open > 0) {
      final strength = math.max(open, glowing ? 0.45 : 0.0);
      for (final (scale, alpha) in const [(0.62, 0.07), (0.5, 0.1), (0.38, 0.14)]) {
        canvas.drawCircle(center, w * scale, Paint()..color = _gold.withValues(alpha: alpha * strength));
      }
      final rayPaint = Paint()..color = const Color(0xFFFFF3C4).withValues(alpha: 0.28 * strength);
      const count = 12;
      for (int i = 0; i < count; i++) {
        final a = rays * math.pi * 2 + i * math.pi * 2 / count;
        final len = w * (0.55 + 0.08 * math.sin(i * 1.7));
        final path = Path()
          ..moveTo(center.dx, center.dy)
          ..lineTo(center.dx + math.cos(a - 0.08) * len, center.dy + math.sin(a - 0.08) * len)
          ..lineTo(center.dx + math.cos(a + 0.08) * len, center.dy + math.sin(a + 0.08) * len)
          ..close();
        canvas.drawPath(path, rayPaint);
      }
    }

    // Sombra en el piso
    canvas.drawOval(
      Rect.fromCenter(center: Offset(w / 2, boxTop + boxH + h * 0.03), width: boxW * 1.05, height: h * 0.07),
      Paint()..color = Colors.black.withValues(alpha: 0.25),
    );

    // Interior brillante (se ve cuando la tapa sube)
    if (open > 0) {
      final inner = RRect.fromRectAndRadius(
        Rect.fromLTWH(left + boxW * 0.05, boxTop - h * 0.03, boxW * 0.9, h * 0.1),
        const Radius.circular(6),
      );
      canvas.drawRRect(
        inner,
        Paint()..color = Color.lerp(const Color(0xFF3B2410), const Color(0xFFFFE08A), open)!,
      );
    }

    // Caja
    final boxR = RRect.fromRectAndCorners(box,
        bottomLeft: Radius.circular(w * 0.05), bottomRight: Radius.circular(w * 0.05));
    canvas.drawRRect(
      boxR,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_woodLight, _woodDark],
        ).createShader(box),
    );
    // Vetas de madera
    final grain = Paint()
      ..color = _woodDark.withValues(alpha: 0.35)
      ..strokeWidth = 1.5;
    for (int i = 1; i < 4; i++) {
      final y = boxTop + boxH * i / 4;
      canvas.drawLine(Offset(left + 6, y), Offset(left + boxW - 6, y), grain);
    }
    _bands(canvas, box, w);

    // Candados en la banda frontal
    final lockY = boxTop + boxH * 0.45;
    for (int i = 0; i < locks; i++) {
      final x = left + boxW * (i + 1) / (locks + 1);
      _lock(canvas, Offset(x, lockY), w * 0.065, i < unlocked);
    }

    // Tapa: sube y se inclina hacia atrás al abrirse
    final lidH = h * 0.24;
    canvas.save();
    canvas.translate(0, -open * h * 0.2);
    final squash = 1 - open * 0.55;
    canvas.translate(w / 2, boxTop);
    canvas.scale(1 + open * 0.04, squash);
    canvas.translate(-w / 2, -boxTop);
    final lidRect = Rect.fromLTWH(left - boxW * 0.02, boxTop - lidH, boxW * 1.04, lidH);
    final lid = Path()
      ..moveTo(lidRect.left, lidRect.bottom)
      ..lineTo(lidRect.left, lidRect.top + lidH * 0.45)
      ..quadraticBezierTo(lidRect.left, lidRect.top, lidRect.center.dx, lidRect.top)
      ..quadraticBezierTo(lidRect.right, lidRect.top, lidRect.right, lidRect.top + lidH * 0.45)
      ..lineTo(lidRect.right, lidRect.bottom)
      ..close();
    canvas.drawPath(
      lid,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFC98A4B), _woodLight],
        ).createShader(lidRect),
    );
    canvas.drawPath(
      lid,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.02
        ..color = _goldDark,
    );
    _bands(canvas, lidRect, w, lid: true);
    // Brillo en la tapa
    canvas.drawOval(
      Rect.fromCenter(center: Offset(lidRect.left + boxW * 0.25, lidRect.top + lidH * 0.3), width: boxW * 0.22, height: lidH * 0.14),
      Paint()..color = Colors.white.withValues(alpha: 0.25),
    );
    canvas.restore();
  }

  void _bands(Canvas canvas, Rect r, double w, {bool lid = false}) {
    final band = Paint()
      ..shader = const LinearGradient(colors: [_goldDark, _gold, _goldDark]).createShader(r);
    final bw = w * 0.045;
    for (final x in [r.left + r.width * 0.18, r.right - r.width * 0.18]) {
      final top = lid ? r.top + r.height * 0.12 : r.top;
      canvas.drawRect(Rect.fromLTWH(x - bw / 2, top, bw, r.bottom - top), band);
      // Remaches
      for (final y in [top + bw, r.bottom - bw]) {
        canvas.drawCircle(Offset(x, y), bw * 0.22, Paint()..color = const Color(0xFFFFF3C4));
      }
    }
  }

  void _lock(Canvas canvas, Offset c, double s, bool isOpen) {
    final body = RRect.fromRectAndRadius(
      Rect.fromCenter(center: c, width: s * 1.5, height: s * 1.2),
      Radius.circular(s * 0.25),
    );
    final color = isOpen ? _gold : const Color(0xFF6B7280);
    // Resplandor del candado abierto
    if (isOpen) {
      canvas.drawCircle(c, s * 1.5, Paint()..color = _gold.withValues(alpha: 0.25));
      canvas.drawCircle(c, s * 1.15, Paint()..color = _gold.withValues(alpha: 0.3));
    }
    // Arco: abierto se desplaza a un lado
    final shackle = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.28
      ..strokeCap = StrokeCap.round
      ..color = isOpen ? _goldDark : const Color(0xFF4B5563);
    final arcRect = Rect.fromCenter(
      center: c.translate(isOpen ? s * 0.35 : 0, -s * (isOpen ? 0.95 : 0.6)),
      width: s * 0.95,
      height: s * 1.1,
    );
    canvas.drawArc(arcRect, math.pi, math.pi, false, shackle);
    canvas.drawRRect(body, Paint()..color = color);
    canvas.drawCircle(c.translate(0, -s * 0.05), s * 0.16, Paint()..color = const Color(0xFF3B2410));
  }

  @override
  bool shouldRepaint(_ChestPainter old) =>
      old.unlocked != unlocked || old.open != open || old.rays != rays || old.glowing != glowing;
}
