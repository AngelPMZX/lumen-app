import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../data/models/lumi.dart';
import '../../../domain/services/sound_service.dart';
import '../../../domain/services/motion_service.dart';

/// Lumi, dibujada con código: una gota de luz con llamita, ojos grandes y
/// mejillas. Flota, respira, parpadea, mece su llama y rebota al tocarla.
///
/// El resplandor usa círculos concéntricos con alpha decreciente
/// (MaskFilter.blur rompe WebGL en web).
class LumiAvatar extends StatefulWidget {
  final LumiMood mood;
  final double size;

  /// Si es interactiva, rebota y hace un sonido al tocarla.
  final VoidCallback? onTap;

  const LumiAvatar({
    super.key,
    this.mood = LumiMood.happy,
    this.size = 96,
    this.onTap,
  });

  @override
  State<LumiAvatar> createState() => _LumiAvatarState();
}

class _LumiAvatarState extends State<LumiAvatar> with TickerProviderStateMixin {
  late final AnimationController _idle; // flotar, respirar, mecer
  late final AnimationController _bounce; // rebote al tocar
  late final AnimationController _blink;
  Timer? _blinkTimer;
  final _rng = math.Random();
  int _chirp = 0;

  @override
  void initState() {
    super.initState();
    _idle = AnimationController(vsync: this, duration: const Duration(milliseconds: 3200))..repeatUnlessReduced();
    _bounce = AnimationController(vsync: this, duration: const Duration(milliseconds: 650));
    _blink = AnimationController(vsync: this, duration: const Duration(milliseconds: 160));
    _scheduleBlink();
  }

  void _scheduleBlink() {
    _blinkTimer = Timer(Duration(milliseconds: 2200 + _rng.nextInt(3200)), () async {
      if (!mounted) return;
      await _blink.forward();
      if (!mounted) return;
      await _blink.reverse();
      // A veces parpadea dos veces seguidas, como una persona
      if (mounted && _rng.nextDouble() < 0.25) {
        await _blink.forward();
        if (mounted) await _blink.reverse();
      }
      if (mounted) _scheduleBlink();
    });
  }

  @override
  void dispose() {
    _blinkTimer?.cancel();
    _idle.dispose();
    _bounce.dispose();
    _blink.dispose();
    super.dispose();
  }

  void _handleTap() {
    if (widget.onTap == null) return;
    HapticFeedback.lightImpact();
    SoundService.instance.lumiChirp(_chirp++);
    _bounce.forward(from: 0);
    widget.onTap!();
  }

  @override
  Widget build(BuildContext context) {
    // Lumi respira y parpadea siempre: sin RepaintBoundary, cada cuadro suyo
    // obliga a repintar todo lo que la rodea (listas incluidas).
    final avatar = RepaintBoundary(
      child: AnimatedBuilder(
        animation: Listenable.merge([_idle, _bounce, _blink]),
        builder: (context, _) {
          final t = _idle.value;
          final wave = math.sin(t * math.pi * 2);
          // Rebote amortiguado: se estira hacia arriba y se aplasta al caer
          final b = _bounce.value;
          final bounce = b == 0 ? 0.0 : math.sin(b * math.pi * 3) * math.exp(-b * 3.2);
          final jump = b == 0 ? 0.0 : -math.sin(b * math.pi).clamp(0.0, 1.0) * widget.size * 0.12;

          return Transform.translate(
            offset: Offset(0, wave * widget.size * 0.03 + jump),
            child: Transform(
              alignment: Alignment.bottomCenter,
              transform: Matrix4.diagonal3Values(1 - bounce * 0.12, 1 + bounce * 0.14, 1),
              child: CustomPaint(
                size: Size.square(widget.size),
                painter: _LumiPainter(
                  mood: widget.mood,
                  time: t,
                  blink: _blink.value,
                  excitement: b,
                ),
              ),
            ),
          );
        },
      ),
    );

    return Semantics(
      label: 'Lumi',
      button: widget.onTap != null,
      child: widget.onTap == null
          ? avatar
          : GestureDetector(behavior: HitTestBehavior.opaque, onTap: _handleTap, child: avatar),
    );
  }
}

/// Lumi quieta, sin animación ni gestos: para el ícono de la app, los
/// gráficos de la tienda y cualquier sitio donde no deba moverse.
class LumiMark extends StatelessWidget {
  final double size;
  final LumiMood mood;

  /// Momento del ciclo de reposo que se dibuja (0-1). 0.25 la deja mirando
  /// al frente con la llama centrada.
  final double pose;

  const LumiMark({super.key, required this.size, this.mood = LumiMood.happy, this.pose = 0.25});

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: CustomPaint(
        size: Size.square(size),
        painter: _LumiPainter(mood: mood, time: pose, blink: 0, excitement: 0),
      ),
    );
  }
}

class _LumiPainter extends CustomPainter {
  final LumiMood mood;
  final double time; // 0-1 en bucle
  final double blink; // 0 abierto · 1 cerrado
  final double excitement; // 0-1 durante el rebote

  _LumiPainter({
    required this.mood,
    required this.time,
    required this.blink,
    required this.excitement,
  });

  static const _core = Color(0xFFFFF4C2);
  static const _gold = Color(0xFFFBBF24);
  static const _amber = Color(0xFFF59E0B);
  static const _ink = Color(0xFF3B2A1A);
  static const _blush = Color(0xFFFB7185);

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final r = s * 0.3; // radio del cuerpo
    final c = Offset(s / 2, s * 0.58);
    final wave = math.sin(time * math.pi * 2);
    final breathe = 1 + math.sin(time * math.pi * 4) * 0.015;

    _paintGlow(canvas, c, r, wave);
    _paintExtras(canvas, c, r, s);

    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.scale(breathe, breathe);
    canvas.translate(-c.dx, -c.dy);

    _paintBody(canvas, c, r, wave);
    _paintFace(canvas, c, r, wave);

    canvas.restore();
  }

  // ── Resplandor ─────────────────────────────────────────────────────────────
  void _paintGlow(Canvas canvas, Offset c, double r, double wave) {
    final pulse = 1 + wave * 0.04 + excitement * 0.15;
    for (final (scale, alpha) in const [(1.75, 0.05), (1.5, 0.08), (1.3, 0.12), (1.15, 0.16)]) {
      canvas.drawCircle(
        c,
        r * scale * pulse,
        Paint()..color = _gold.withValues(alpha: alpha),
      );
    }
  }

  // ── Cuerpo: gota con llamita que se mece ───────────────────────────────────
  void _paintBody(Canvas canvas, Offset c, double r, double wave) {
    final sway = wave * r * 0.18;
    final tip = Offset(c.dx + sway, c.dy - r * 1.55);

    final body = Path()
      ..moveTo(tip.dx, tip.dy)
      ..cubicTo(c.dx + r * 0.25 + sway * 0.4, c.dy - r * 1.05, c.dx + r * 1.02, c.dy - r * 0.65,
          c.dx + r, c.dy)
      ..cubicTo(c.dx + r, c.dy + r * 0.62, c.dx + r * 0.56, c.dy + r, c.dx, c.dy + r)
      ..cubicTo(c.dx - r * 0.56, c.dy + r, c.dx - r, c.dy + r * 0.62, c.dx - r, c.dy)
      ..cubicTo(c.dx - r * 1.02, c.dy - r * 0.65, c.dx - r * 0.25 + sway * 0.4, c.dy - r * 1.05,
          tip.dx, tip.dy)
      ..close();

    canvas.drawPath(
      body,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.2, -0.1),
          radius: 0.85,
          colors: const [_core, _gold, _amber],
          stops: const [0.0, 0.55, 1.0],
        ).createShader(Rect.fromCircle(center: Offset(c.dx, c.dy - r * 0.3), radius: r * 1.4)),
    );

    // Contorno suave para que se lea sobre fondos claros
    canvas.drawPath(
      body,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.04
        ..color = _amber.withValues(alpha: 0.55),
    );

    // Brillo
    canvas.drawOval(
      Rect.fromCenter(center: Offset(c.dx - r * 0.45, c.dy - r * 0.45), width: r * 0.32, height: r * 0.5),
      Paint()..color = Colors.white.withValues(alpha: 0.55),
    );
    canvas.drawCircle(Offset(c.dx - r * 0.2, c.dy - r * 0.85), r * 0.06, Paint()..color = Colors.white.withValues(alpha: 0.6));
  }

  // ── Cara ───────────────────────────────────────────────────────────────────
  void _paintFace(Canvas canvas, Offset c, double r, double wave) {
    final eyeY = c.dy + r * 0.02;
    final eyeDx = r * 0.36;
    final look = math.sin(time * math.pi * 2 * 0.5) * r * 0.03;
    final left = Offset(c.dx - eyeDx + look, eyeY);
    final right = Offset(c.dx + eyeDx + look, eyeY);
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = r * 0.075
      ..color = _ink;

    // Mejillas
    final cheek = Paint()..color = _blush.withValues(alpha: mood == LumiMood.caring ? 0.45 : 0.32);
    for (final x in [-1, 1]) {
      canvas.drawOval(
        Rect.fromCenter(center: Offset(c.dx + x * r * 0.62, c.dy + r * 0.3), width: r * 0.3, height: r * 0.17),
        cheek,
      );
    }

    // Ojos
    switch (mood) {
      case LumiMood.sleepy:
      case LumiMood.calm:
        // Ojos cerrados y relajados (tranquila o con sueño)
        for (final e in [left, right]) {
          canvas.drawArc(Rect.fromCenter(center: e, width: r * 0.26, height: r * 0.16), 0, math.pi, false, stroke);
        }
      case LumiMood.proud:
      case LumiMood.excited when excitement == 0 && wave > 0.6:
        // ^ ^ ojos sonrientes
        for (final e in [left, right]) {
          canvas.drawArc(Rect.fromCenter(center: e.translate(0, r * 0.05), width: r * 0.26, height: r * 0.24),
              math.pi, math.pi, false, stroke);
        }
      default:
        final big = mood == LumiMood.excited || mood == LumiMood.curious;
        for (final (i, e) in [left, right].indexed) {
          var h = r * (big ? 0.34 : 0.3);
          var w = r * (big ? 0.25 : 0.22);
          if (mood == LumiMood.curious && i == 1) {
            h *= 1.12;
            w *= 1.1;
          }
          _paintEye(canvas, e, w, h, r);

        }
        if (mood == LumiMood.caring) {
          // Cejas inclinadas hacia arriba por dentro: ternura
          final brow = Paint()
            ..style = PaintingStyle.stroke
            ..strokeCap = StrokeCap.round
            ..strokeWidth = r * 0.05
            ..color = _ink.withValues(alpha: 0.8);
          canvas.drawLine(left.translate(-r * 0.12, -r * 0.24), left.translate(r * 0.08, -r * 0.31), brow);
          canvas.drawLine(right.translate(r * 0.12, -r * 0.24), right.translate(-r * 0.08, -r * 0.31), brow);
        }
        if (mood == LumiMood.curious) {
          final brow = Paint()
            ..style = PaintingStyle.stroke
            ..strokeCap = StrokeCap.round
            ..strokeWidth = r * 0.05
            ..color = _ink.withValues(alpha: 0.8);
          canvas.drawArc(Rect.fromCenter(center: right.translate(0, -r * 0.28), width: r * 0.26, height: r * 0.12),
              math.pi * 1.1, math.pi * 0.8, false, brow);
        }
    }

    // Boca
    final mouthC = Offset(c.dx + look * 0.5, c.dy + r * 0.36);
    switch (mood) {
      case LumiMood.excited:
      case LumiMood.proud:
        final open = Path()
          ..moveTo(mouthC.dx - r * 0.17, mouthC.dy - r * 0.03)
          ..quadraticBezierTo(mouthC.dx, mouthC.dy + r * 0.3, mouthC.dx + r * 0.17, mouthC.dy - r * 0.03)
          ..close();
        canvas.drawPath(open, Paint()..color = _ink);
        canvas.drawOval(
          Rect.fromCenter(center: mouthC.translate(0, r * 0.1), width: r * 0.14, height: r * 0.07),
          Paint()..color = _blush,
        );
      case LumiMood.sleepy:
        canvas.drawOval(Rect.fromCenter(center: mouthC, width: r * 0.1, height: r * 0.12), Paint()..color = _ink);
      case LumiMood.curious:
        canvas.drawOval(Rect.fromCenter(center: mouthC.translate(r * 0.05, 0), width: r * 0.12, height: r * 0.13),
            Paint()..color = _ink);
      case LumiMood.calm:
      case LumiMood.caring:
        canvas.drawArc(Rect.fromCenter(center: mouthC.translate(0, -r * 0.04), width: r * 0.24, height: r * 0.14),
            0.2, math.pi - 0.4, false, stroke..strokeWidth = r * 0.06);
      case LumiMood.happy:
        canvas.drawArc(Rect.fromCenter(center: mouthC.translate(0, -r * 0.06), width: r * 0.32, height: r * 0.24),
            0.15, math.pi - 0.3, false, stroke..strokeWidth = r * 0.07);
    }
  }

  void _paintEye(Canvas canvas, Offset e, double w, double h, double r) {
    final openH = h * (1 - blink * 0.92);
    canvas.drawOval(Rect.fromCenter(center: e, width: w, height: openH), Paint()..color = _ink);
    if (blink < 0.5) {
      canvas.drawCircle(e.translate(-w * 0.18, -openH * 0.2), w * 0.2, Paint()..color = Colors.white);
      canvas.drawCircle(e.translate(w * 0.18, openH * 0.22), w * 0.09, Paint()..color = Colors.white.withValues(alpha: 0.8));
    }
  }

  // ── Detalles por emoción ───────────────────────────────────────────────────
  void _paintExtras(Canvas canvas, Offset c, double r, double s) {
    switch (mood) {
      case LumiMood.excited:
      case LumiMood.proud:
        // Destellos que orbitan
        for (int i = 0; i < 4; i++) {
          final a = time * math.pi * 2 + i * math.pi / 2;
          final p = Offset(c.dx + math.cos(a) * r * 1.45, c.dy - r * 0.35 + math.sin(a) * r * 1.05);
          _sparkle(canvas, p, r * (0.12 + 0.05 * math.sin(time * math.pi * 6 + i)),
              Colors.white.withValues(alpha: 0.9));
        }
      case LumiMood.sleepy:
        for (int i = 0; i < 2; i++) {
          final phase = (time + i * 0.5) % 1.0;
          final p = Offset(c.dx + r * (0.9 + phase * 0.5), c.dy - r * (1.0 + phase * 0.9));
          final tp = TextPainter(
            text: TextSpan(
              text: 'z',
              style: TextStyle(
                fontSize: r * (0.35 + phase * 0.25),
                fontWeight: FontWeight.w900,
                color: const Color(0xFF93C5FD).withValues(alpha: 1 - phase),
              ),
            ),
            textDirection: TextDirection.ltr,
          )..layout();
          tp.paint(canvas, p);
        }
      case LumiMood.caring:
        final phase = time;
        final p = Offset(c.dx + r * 1.15, c.dy - r * (0.9 + phase * 0.5));
        _heart(canvas, p, r * 0.18, _blush.withValues(alpha: 1 - phase * 0.8));
      case LumiMood.curious:
        final tp = TextPainter(
          text: TextSpan(
            text: '?',
            style: TextStyle(
              fontSize: r * 0.5,
              fontWeight: FontWeight.w900,
              color: const Color(0xFFA78BFA).withValues(alpha: 0.9),
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, Offset(c.dx + r * 1.05, c.dy - r * 1.45 + math.sin(time * math.pi * 2) * r * 0.08));
      default:
        break;
    }
  }

  void _sparkle(Canvas canvas, Offset p, double size, Color color) {
    final path = Path()
      ..moveTo(p.dx, p.dy - size)
      ..quadraticBezierTo(p.dx, p.dy, p.dx + size, p.dy)
      ..quadraticBezierTo(p.dx, p.dy, p.dx, p.dy + size)
      ..quadraticBezierTo(p.dx, p.dy, p.dx - size, p.dy)
      ..quadraticBezierTo(p.dx, p.dy, p.dx, p.dy - size)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  void _heart(Canvas canvas, Offset p, double size, Color color) {
    final path = Path()
      ..moveTo(p.dx, p.dy + size * 0.9)
      ..cubicTo(p.dx - size * 1.4, p.dy, p.dx - size * 0.6, p.dy - size, p.dx, p.dy - size * 0.3)
      ..cubicTo(p.dx + size * 0.6, p.dy - size, p.dx + size * 1.4, p.dy, p.dx, p.dy + size * 0.9)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_LumiPainter old) =>
      old.time != time || old.blink != blink || old.mood != mood || old.excitement != excitement;
}
