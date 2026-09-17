import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../data/models/lumi.dart';
import '../../../domain/services/sound_service.dart';
import 'lumi_avatar.dart';

/// Lumi en el Home: la personaje y un globo de diálogo que se escribe letra
/// por letra. Al tocar a Lumi, rebota y dice otra cosa.
class LumiCompanionCard extends StatefulWidget {
  final LumiLine line;
  final bool isDark;

  /// Se llama cuando el usuario leyó la presentación (para no repetirla).
  final VoidCallback? onIntroSeen;

  /// Sin fondo propio: para ponerla sobre otra escena (el cielo del Home).
  final bool transparent;

  const LumiCompanionCard({
    super.key,
    required this.line,
    required this.isDark,
    this.onIntroSeen,
    this.transparent = false,
  });

  @override
  State<LumiCompanionCard> createState() => _LumiCompanionCardState();
}

class _LumiCompanionCardState extends State<LumiCompanionCard> {
  late LumiLine _line;
  int _taps = 0;
  int _visibleChars = 0;
  Timer? _typer;

  String get _text => _line.key.tr(namedArgs: _line.args);

  @override
  void initState() {
    super.initState();
    _line = widget.line;
    // Deja que la tarjeta entre antes de empezar a "hablar"
    Future.delayed(const Duration(milliseconds: 650), () {
      if (!mounted) return;
      SoundService.instance.play(Sfx.lumiHello, volume: 0.4);
      _type();
    });
  }

  @override
  void didUpdateWidget(LumiCompanionCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.line.key != widget.line.key || !mapEquals(oldWidget.line.args, widget.line.args)) {
      _say(widget.line);
    }
  }

  @override
  void dispose() {
    _typer?.cancel();
    super.dispose();
  }

  void _type() {
    _typer?.cancel();
    setState(() => _visibleChars = 0);
    final total = _text.characters.length;
    _typer = Timer.periodic(const Duration(milliseconds: 22), (timer) {
      if (!mounted) return timer.cancel();
      setState(() => _visibleChars = (_visibleChars + 1).clamp(0, total));
      if (_visibleChars >= total) {
        timer.cancel();
        if (_line.key == 'lumi.intro') widget.onIntroSeen?.call();
      }
    });
  }

  void _say(LumiLine line) {
    setState(() => _line = line);
    _type();
  }

  void _onTap() {
    // Si todavía está escribiendo, el toque completa la frase
    final total = _text.characters.length;
    if (_visibleChars < total) {
      _typer?.cancel();
      setState(() => _visibleChars = total);
      if (_line.key == 'lumi.intro') widget.onIntroSeen?.call();
      return;
    }
    _say(LumiDialog.tap(_taps++));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final text = _text;
    final shown = text.characters.take(_visibleChars).toString();
    const gold = Color(0xFFFBBF24);

    return Semantics(
      button: true,
      label: '${'lumi.name'.tr()}: $text',
      onTap: _onTap,
      excludeSemantics: true,
      child: GestureDetector(
      onTap: _onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(6, 10, 14, 10),
        decoration: widget.transparent
            ? null
            : BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    gold.withValues(alpha: isDark ? 0.16 : 0.14),
                    gold.withValues(alpha: isDark ? 0.04 : 0.03),
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: gold.withValues(alpha: isDark ? 0.25 : 0.35)),
              ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            LumiAvatar(mood: _line.mood, size: 92, onTap: _onTap),
            const SizedBox(width: 4),
            Expanded(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Globo de diálogo con colita hacia Lumi
                  Positioned(
                    left: -7,
                    top: 22,
                    child: CustomPaint(
                      size: const Size(10, 14),
                      painter: _TailPainter(color: isDark ? const Color(0xFF26243A) : Colors.white),
                    ),
                  ),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(14, 11, 14, 11),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF26243A) : Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: isDark
                          ? null
                          : [BoxShadow(color: gold.withValues(alpha: 0.15), blurRadius: 12, offset: const Offset(0, 3))],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'lumi.name'.tr(),
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.6,
                            color: Color(0xFFF59E0B),
                          ),
                        ),
                        const SizedBox(height: 3),
                        // El texto completo reserva el alto para que la
                        // tarjeta no salte mientras se escribe.
                        Stack(
                          children: [
                            Opacity(opacity: 0, child: Text(text, style: _bubbleStyle(isDark))),
                            Text(shown, style: _bubbleStyle(isDark)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
    ).animate().fadeIn(duration: 450.ms).slideY(begin: 0.12, end: 0, curve: Curves.easeOutCubic);
  }

  TextStyle _bubbleStyle(bool isDark) => TextStyle(
        fontSize: 14,
        height: 1.4,
        fontWeight: FontWeight.w600,
        color: isDark ? Colors.white.withValues(alpha: 0.92) : const Color(0xFF2D2D3A),
      );
}

class _TailPainter extends CustomPainter {
  final Color color;
  _TailPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width, 0)
      ..lineTo(0, size.height / 2)
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_TailPainter old) => old.color != color;
}
