import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../data/models/lumi.dart';
import '../../../data/models/mood_entry.dart';
import '../lumi/lumi_avatar.dart';

/// Estilo "cuaderno personal" del diario, hábitos y recordatorios: papel
/// cálido, líneas de renglón, cinta washi, notas adhesivas y letra a mano.
class JournalStyle {
  final bool isDark;

  const JournalStyle(this.isDark);

  factory JournalStyle.of(BuildContext context) =>
      JournalStyle(Theme.of(context).brightness == Brightness.dark);

  /// Acento del diario (verde azulado sereno).
  static const accent = Color(0xFF10B981);
  static const accentDeep = Color(0xFF0F766E);
  static const sticky = Color(0xFFFDE68A);

  Color get paper => isDark ? const Color(0xFF1B1C2E) : const Color(0xFFFFFBF3);
  Color get paperEdge => isDark ? const Color(0xFF2A2B40) : const Color(0xFFF1E6D2);
  Color get rule => isDark
      ? Colors.white.withValues(alpha: 0.055)
      : const Color(0xFF93C5FD).withValues(alpha: 0.28);
  Color get margin => isDark
      ? const Color(0xFFF472B6).withValues(alpha: 0.18)
      : const Color(0xFFF87171).withValues(alpha: 0.35);
  Color get ink => isDark ? const Color(0xFFF5F3FF) : const Color(0xFF2E2A3A);
  Color get inkSoft => isDark ? Colors.white60 : const Color(0xFF6B6477);

  List<BoxShadow> get paperShadow => [
        BoxShadow(
          color: (isDark ? Colors.black : const Color(0xFF8B6F47))
              .withValues(alpha: isDark ? 0.35 : 0.10),
          blurRadius: 18,
          offset: const Offset(0, 6),
        ),
      ];

  /// Papel teñido apenas con el color del ánimo.
  Color paperFor(MoodType? mood) =>
      mood == null ? paper : Color.lerp(paper, mood.color, isDark ? 0.08 : 0.05)!;

  // ── Tipografía ─────────────────────────────────────────────────────────────
  /// Solo para pruebas: evita descargar fuentes de Google en el entorno de test.
  @visibleForTesting
  static bool useSystemFonts = false;

  /// Letra manuscrita para fechas, notas y detalles (no para textos largos).
  static TextStyle hand(TextStyle style) =>
      useSystemFonts ? style.copyWith(fontStyle: FontStyle.italic) : GoogleFonts.caveat(textStyle: style);

  /// Serif de libro para lo que el usuario escribe.
  static TextStyle serif(TextStyle style) =>
      useSystemFonts ? style : GoogleFonts.lora(textStyle: style);

  /// Lumi según el ánimo: cariñosa ante lo difícil, contenta con lo bueno.
  static LumiMood lumiFor(MoodType? mood) {
    if (mood == null) return LumiMood.curious;
    return switch (mood.category) {
      'positive' => mood == MoodType.calm ? LumiMood.calm : LumiMood.happy,
      'negative' => LumiMood.caring,
      _ => mood == MoodType.tired ? LumiMood.sleepy : LumiMood.calm,
    };
  }
}

/// Hoja de papel con renglones (y margen opcional).
class JournalPaper extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double lineHeight;
  final double firstLine;
  final bool showMargin;
  final Color? tint;
  final double radius;

  const JournalPaper({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(22, 18, 18, 18),
    this.lineHeight = 30,
    this.firstLine = 48,
    this.showMargin = true,
    this.tint,
    this.radius = 22,
  });

  @override
  Widget build(BuildContext context) {
    final s = JournalStyle.of(context);
    return Container(
      decoration: BoxDecoration(
        color: tint ?? s.paper,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: s.paperEdge),
        boxShadow: s.paperShadow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: CustomPaint(
          painter: _RulesPainter(
            rule: s.rule,
            margin: showMargin ? s.margin : null,
            lineHeight: lineHeight,
            firstLine: firstLine,
          ),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

class _RulesPainter extends CustomPainter {
  final Color rule;
  final Color? margin;
  final double lineHeight;
  final double firstLine;

  _RulesPainter({
    required this.rule,
    required this.margin,
    required this.lineHeight,
    required this.firstLine,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = rule
      ..strokeWidth = 1;
    for (double y = firstLine; y <= size.height + 0.5; y += lineHeight) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), p);
    }
    if (margin != null) {
      final m = Paint()
        ..color = margin!
        ..strokeWidth = 1.2;
      canvas.drawLine(const Offset(14, 0), Offset(14, size.height), m);
    }
  }

  @override
  bool shouldRepaint(_RulesPainter old) =>
      old.rule != rule || old.margin != margin || old.lineHeight != lineHeight || old.firstLine != firstLine;
}

/// Texto sobre renglones: las líneas se dibujan bajo cada línea de texto,
/// sin depender de la altura de lo que haya encima.
class RuledText extends StatelessWidget {
  final Widget child;
  final double lineHeight;

  /// Distancia desde el borde inferior de cada línea hasta el renglón.
  final double baselineInset;

  const RuledText({
    super.key,
    required this.child,
    required this.lineHeight,
    this.baselineInset = 4,
  });

  @override
  Widget build(BuildContext context) {
    final s = JournalStyle.of(context);
    return CustomPaint(
      painter: _RulesPainter(
        rule: s.rule,
        margin: null,
        lineHeight: lineHeight,
        firstLine: lineHeight - baselineInset,
      ),
      child: child,
    );
  }
}

/// Tira de cinta washi translúcida con bordes dentados.
class WashiTape extends StatelessWidget {
  final Color color;
  final double width;
  final double angle;

  const WashiTape({super.key, required this.color, this.width = 84, this.angle = -0.06});

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: angle,
      child: CustomPaint(
        size: Size(width, 22),
        painter: _TapePainter(color),
      ),
    );
  }
}

class _TapePainter extends CustomPainter {
  final Color color;
  _TapePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    const teeth = 5;
    final path = Path()..moveTo(0, 0);
    // Borde izquierdo dentado
    for (int i = 0; i <= teeth; i++) {
      final y = size.height * i / teeth;
      path.lineTo(i.isEven ? 0 : 3, y);
    }
    path.lineTo(size.width, size.height);
    for (int i = teeth; i >= 0; i--) {
      final y = size.height * i / teeth;
      path.lineTo(i.isEven ? size.width : size.width - 3, y);
    }
    path.close();
    canvas.drawPath(path, Paint()..color = color.withValues(alpha: 0.55));
    // Rayitas del estampado, recortadas a la forma de la cinta
    canvas.save();
    canvas.clipPath(path);
    final stripe = Paint()
      ..color = Colors.white.withValues(alpha: 0.28)
      ..strokeWidth = 3;
    for (double x = 8; x < size.width; x += 12) {
      canvas.drawLine(Offset(x, 0), Offset(x - 6, size.height), stripe);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_TapePainter old) => old.color != color;
}

/// Nota adhesiva amarilla, ligeramente girada.
class StickyNote extends StatelessWidget {
  final Widget child;
  final double angle;
  final Color color;

  const StickyNote({
    super.key,
    required this.child,
    this.angle = -0.018,
    this.color = JournalStyle.sticky,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Transform.rotate(
      angle: angle,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 22, 16, 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: isDark
                    ? [Color.lerp(const Color(0xFF2B2A22), color, 0.18)!, Color.lerp(const Color(0xFF25241C), color, 0.12)!]
                    : [Color.lerp(color, Colors.white, 0.25)!, color],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(4),
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(22),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.12),
                  blurRadius: 12,
                  offset: const Offset(2, 6),
                ),
              ],
            ),
            child: child,
          ),
          Positioned(
            top: -9,
            left: 0,
            right: 0,
            child: Center(
              child: WashiTape(color: isDark ? const Color(0xFFF9A8D4) : const Color(0xFFF472B6), width: 70, angle: 0.04),
            ),
          ),
        ],
      ),
    );
  }
}

/// Lumi con un globo de texto manuscrito.
class LumiNote extends StatelessWidget {
  final String text;
  final LumiMood mood;
  final double size;
  final VoidCallback? onTap;
  final Widget? trailing;

  const LumiNote({
    super.key,
    required this.text,
    this.mood = LumiMood.happy,
    this.size = 58,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final s = JournalStyle.of(context);
    return Semantics(
      label: text,
      button: onTap != null,
      onTap: onTap,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            LumiAvatar(mood: mood, size: size),
            const SizedBox(width: 6),
            Expanded(
              child: Container(
                padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
                decoration: BoxDecoration(
                  color: s.isDark ? Colors.white.withValues(alpha: 0.07) : Colors.white,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(18),
                    topRight: Radius.circular(18),
                    bottomRight: Radius.circular(18),
                    bottomLeft: Radius.circular(4),
                  ),
                  border: Border.all(
                    color: s.isDark ? Colors.white.withValues(alpha: 0.08) : JournalStyle.accent.withValues(alpha: 0.15),
                  ),
                  boxShadow: s.isDark
                      ? null
                      : [BoxShadow(color: JournalStyle.accent.withValues(alpha: 0.08), blurRadius: 12, offset: const Offset(0, 4))],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        text,
                        style: JournalStyle.hand(TextStyle(fontSize: 19, height: 1.15, color: s.ink)),
                      ),
                    ),
                    ?trailing,
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Pequeños destellos que salen disparados desde el centro (al marcar algo).
class SparkleBurst extends StatefulWidget {
  final Color color;
  final double size;
  final int seed;

  const SparkleBurst({super.key, required this.color, this.size = 90, this.seed = 0});

  @override
  State<SparkleBurst> createState() => _SparkleBurstState();
}

class _SparkleBurstState extends State<SparkleBurst> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 650))..forward();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) => CustomPaint(
          size: Size.square(widget.size),
          painter: _BurstPainter(t: _c.value, color: widget.color, seed: widget.seed),
        ),
      ),
    );
  }
}

class _BurstPainter extends CustomPainter {
  final double t;
  final Color color;
  final int seed;
  _BurstPainter({required this.t, required this.color, required this.seed});

  @override
  void paint(Canvas canvas, Size size) {
    if (t >= 1) return;
    final c = size.center(Offset.zero);
    final rng = math.Random(seed);
    final eased = Curves.easeOutCubic.transform(t);
    for (int i = 0; i < 10; i++) {
      final a = i / 10 * math.pi * 2 + rng.nextDouble() * 0.4;
      final dist = size.width * 0.18 + eased * size.width * (0.28 + rng.nextDouble() * 0.12);
      final p = c + Offset(math.cos(a), math.sin(a)) * dist;
      final r = (1 - t) * (2.2 + rng.nextDouble() * 2.2);
      canvas.drawCircle(p, r, Paint()..color = (i.isEven ? color : const Color(0xFFFBBF24)).withValues(alpha: 1 - t));
    }
  }

  @override
  bool shouldRepaint(_BurstPainter old) => old.t != t;
}
