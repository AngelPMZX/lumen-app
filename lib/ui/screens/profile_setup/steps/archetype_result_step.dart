import 'dart:math' as math;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../data/models/archetype.dart';
import '../../../../data/models/lumi.dart';
import '../../../../domain/services/motion_service.dart';
import '../../../../domain/services/sound_service.dart';
import '../../../widgets/journal/journal_style.dart';
import '../../../widgets/lumi/lumi_avatar.dart';
import '../../profile/widgets/profile_widgets.dart' show ArchetypeStyle;

/// El momento de descubrir tu arquetipo: el emblema aparece entre rayos de
/// luz, se muestran tus fortalezas y un consejo de Lumi.
/// Qué se lleva la persona de su arquetipo, además del emblema: por dónde va
/// a empezar. Es lo que lo convierte en algo útil y no solo en un adorno.
class ArchetypeResultStep extends StatefulWidget {
  final Archetype archetype;

  /// Qué tan marcado salió (0-1): se muestra como "afinidad".
  final double affinity;

  /// Ruta por la que va a empezar, si se sabe: es el premio de haber hecho el
  /// test, y lo que hace que el arquetipo cambie algo de verdad.
  final String? startingRouteTitle;

  final VoidCallback onContinue;

  const ArchetypeResultStep({
    super.key,
    required this.archetype,
    required this.onContinue,
    this.affinity = 0,
    this.startingRouteTitle,
  });

  @override
  State<ArchetypeResultStep> createState() => _ArchetypeResultStepState();
}

class _ArchetypeResultStepState extends State<ArchetypeResultStep> with TickerProviderStateMixin {
  late final AnimationController _rays =
      AnimationController(vsync: this, duration: const Duration(seconds: 26))..repeatUnlessReduced();
  late final AnimationController _pulse =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 2200))..repeatUnlessReduced(reverse: true, rest: 0.5);

  bool _showEmblem = false;
  bool _showName = false;
  bool _showCard = false;
  bool _showButton = false;

  @override
  void initState() {
    super.initState();
    _reveal();
  }

  Future<void> _reveal() async {
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    setState(() => _showEmblem = true);
    SoundService.instance.play(Sfx.unlock, volume: 0.5);
    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    setState(() => _showName = true);
    SoundService.instance.play(Sfx.achievement, volume: 0.45);
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    setState(() => _showCard = true);
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    setState(() => _showButton = true);
  }

  @override
  void dispose() {
    _rays.dispose();
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.archetype;
    final colors = ArchetypeStyle.colors(a.id);
    final accent = Color.lerp(colors.first, Colors.white, 0.45)!;
    final strengths = a.strengthsKey.tr().split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
    final reduced = MotionService.reduced(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      child: Column(
        children: [
          Text(
            'archetype.revealSubtitle'.tr(),
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white.withValues(alpha: 0.7)),
          ).animate().fadeIn(duration: 400.ms),
          const SizedBox(height: 6),
          Text(
            'archetype.revealTitle'.tr(),
            textAlign: TextAlign.center,
            style: JournalStyle.hand(const TextStyle(fontSize: 26, height: 1.1, color: Colors.white)),
          ).animate().fadeIn(delay: 100.ms, duration: 400.ms),
          const SizedBox(height: 10),
          // Emblema
          SizedBox(
            height: 240,
            child: Stack(
              alignment: Alignment.center,
              children: [
                AnimatedBuilder(
                  animation: _rays,
                  builder: (_, _) => Transform.rotate(
                    angle: _rays.value * math.pi * 2,
                    child: CustomPaint(size: const Size.square(260), painter: _RaysPainter(color: accent)),
                  ),
                ),
                if (_showEmblem)
                  AnimatedBuilder(
                    animation: _pulse,
                    builder: (_, child) => Transform.scale(scale: 1 + Curves.easeInOut.transform(_pulse.value) * 0.05, child: child),
                    child: _Emblem(colors: colors, emoji: a.emoji),
                  )
                      .animate()
                      .scale(begin: const Offset(0.3, 0.3), end: const Offset(1, 1), duration: 900.ms, curve: Curves.elasticOut)
                      .fadeIn(duration: 350.ms),
                if (_showEmblem && !reduced)
                  SparkleBurst(color: accent, size: 280, seed: a.index + 3),
              ],
            ),
          ),
          if (_showName) ...[
            Semantics(
              header: true,
              child: Text(
                a.nameKey.tr(),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 27, height: 1.15, fontWeight: FontWeight.w900, color: Colors.white),
              ),
            ).animate().fadeIn(duration: 450.ms).slideY(begin: 0.25, end: 0, curve: Curves.easeOutCubic),
            const SizedBox(height: 10),
            if (widget.affinity > 0)
              _AffinityBar(value: widget.affinity, color: accent)
                  .animate()
                  .fadeIn(delay: 200.ms, duration: 400.ms),
          ],
          const SizedBox(height: 16),
          if (_showCard)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(26),
                border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    a.descriptionKey.tr(),
                    style: TextStyle(fontSize: 14.5, height: 1.5, color: Colors.white.withValues(alpha: 0.92)),
                  ),
                  if (strengths.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Text(
                      'archetype.strengths'.tr(),
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 0.8, color: accent),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final (i, s) in strengths.indexed)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: accent.withValues(alpha: 0.4)),
                            ),
                            child: Text(s, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Colors.white)),
                          ).animate().fadeIn(delay: (120 * i).ms, duration: 300.ms).scale(
                                begin: const Offset(0.85, 0.85),
                                end: const Offset(1, 1),
                                curve: Curves.easeOutCubic,
                              ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const LumiAvatar(mood: LumiMood.proud, size: 52),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(16),
                              topRight: Radius.circular(16),
                              bottomRight: Radius.circular(16),
                              bottomLeft: Radius.circular(4),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                a.tipKey.tr(),
                                style: const TextStyle(fontSize: 12.5, height: 1.35, fontWeight: FontWeight.w600, color: Color(0xFF2D2D3A)),
                              ),
                              if (widget.startingRouteTitle != null) ...[
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Text('🧭', style: TextStyle(fontSize: 13)),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        'archetypeQuiz.startsWith'.tr(namedArgs: {
                                          'route': widget.startingRouteTitle!,
                                        }),
                                        style: TextStyle(
                                          fontSize: 12.5,
                                          height: 1.3,
                                          fontWeight: FontWeight.w800,
                                          // El color del arquetipo, oscurecido
                                          // para leerse sobre el globo blanco.
                                          color: Color.lerp(
                                              colors.first, Colors.black, 0.25),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 450.ms).slideY(begin: 0.12, end: 0, curve: Curves.easeOutCubic),
          const SizedBox(height: 22),
          if (_showButton)
            SizedBox(
              width: double.infinity,
              height: 56,
              child: FilledButton(
                onPressed: widget.onContinue,
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: colors.last,
                  elevation: 6,
                  shadowColor: Colors.black.withValues(alpha: 0.3),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('archetype.startJourney'.tr(), style: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.w900)),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward_rounded, size: 20),
                  ],
                ),
              ),
            ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.2, end: 0, curve: Curves.easeOutCubic),
        ],
      ),
    );
  }
}

/// El emblema: disco con el color del arquetipo, borde de luz y su emoji.
class _Emblem extends StatelessWidget {
  final List<Color> colors;
  final String emoji;

  const _Emblem({required this.colors, required this.emoji});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 148,
      height: 148,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          center: const Alignment(-0.3, -0.35),
          colors: [Color.lerp(colors.first, Colors.white, 0.5)!, colors.first, colors.last],
          stops: const [0, 0.55, 1],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.85), width: 3),
        boxShadow: [BoxShadow(color: colors.first.withValues(alpha: 0.55), blurRadius: 34, spreadRadius: 4)],
      ),
      child: Center(child: Text(emoji, style: const TextStyle(fontSize: 62))),
    );
  }
}

class _AffinityBar extends StatelessWidget {
  final double value;
  final Color color;

  const _AffinityBar({required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    final percent = (value * 100).round();
    return Semantics(
      label: '${'archetype.affinity'.tr()}: $percent%',
      excludeSemantics: true,
      child: Column(
        children: [
          Text(
            'archetype.affinity'.tr(),
            style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, letterSpacing: 0.6, color: Colors.white.withValues(alpha: 0.75)),
          ),
          const SizedBox(height: 6),
          LayoutBuilder(
            builder: (context, c) {
              final width = math.min(c.maxWidth, 240.0);
              return SizedBox(
                width: width,
                child: Stack(
                  children: [
                    Container(
                      height: 8,
                      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(4)),
                    ),
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: value.clamp(0.0, 1.0)),
                      duration: MotionService.reduced(context) ? Duration.zero : const Duration(milliseconds: 1100),
                      curve: Curves.easeOutCubic,
                      builder: (_, v, _) => Container(
                        width: width * v,
                        height: 8,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [Colors.white, color]),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 4),
          Text('$percent%', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Colors.white)),
        ],
      ),
    );
  }
}

/// Rayos de luz suaves detrás del emblema (sin blur).
class _RaysPainter extends CustomPainter {
  final Color color;
  const _RaysPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2;
    final paint = Paint()
      ..shader = RadialGradient(colors: [color.withValues(alpha: 0.3), color.withValues(alpha: 0)])
          .createShader(Rect.fromCircle(center: c, radius: r));
    const rays = 14;
    for (int i = 0; i < rays; i++) {
      final a = i / rays * math.pi * 2;
      const half = math.pi / rays * 0.4;
      final path = Path()
        ..moveTo(c.dx, c.dy)
        ..lineTo(c.dx + math.cos(a - half) * r, c.dy + math.sin(a - half) * r)
        ..lineTo(c.dx + math.cos(a + half) * r, c.dy + math.sin(a + half) * r)
        ..close();
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_RaysPainter old) => old.color != color;
}
