import 'dart:math' as math;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../data/models/wellness_route.dart';
import '../../../../domain/services/motion_service.dart';
import '../../../../domain/services/sound_service.dart';
import '../lesson_palette.dart';
import 'step_common.dart';

/// REVEAL — piensa primero, luego gira la tarjeta para ver la respuesta.
class RevealStep extends StatefulWidget {
  final LessonStep step;
  final Color routeColor;
  final StepCallbacks callbacks;

  const RevealStep({
    super.key,
    required this.step,
    required this.routeColor,
    required this.callbacks,
  });

  @override
  State<RevealStep> createState() => _RevealStepState();
}

class _RevealStepState extends State<RevealStep> {
  static const _accent = Color(0xFF8B5CF6);

  bool _revealed = false;

  void _reveal() {
    HapticFeedback.mediumImpact();
    SoundService.instance.play(Sfx.flip, volume: 0.8);
    setState(() => _revealed = true);
    widget.callbacks.onReflect(3);
    widget.callbacks.onReady();
  }

  @override
  Widget build(BuildContext context) {
    // Con movimiento reducido la tarjeta cambia sin girar.
    final flipDuration = MotionService.reduced(context)
        ? Duration.zero
        : const Duration(milliseconds: 620);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        StepChip(
          icon: Icons.psychology_rounded,
          label: 'routes.revealLabel'.tr(),
          color: _accent,
        ),
        const SizedBox(height: 16),
        StepHeading(
          text: widget.step.question ?? widget.step.title,
          glow: widget.routeColor,
        ),
        const SizedBox(height: 20),
        GestureDetector(
          onTap: _revealed ? null : _reveal,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: _revealed ? 1 : 0),
            duration: flipDuration,
            curve: Curves.easeInOutCubic,
            builder: (context, t, _) {
              // Giro 3D: a mitad del recorrido se cambia la cara visible.
              final showBack = t > 0.5;
              return Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.0012)
                  ..rotateY(t * math.pi),
                child: showBack
                    ? Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.identity()..rotateY(math.pi),
                        child: _card(revealed: true),
                      )
                    : _card(revealed: false),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _card({required bool revealed}) {
    final p = LessonPalette.of(context);
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 190),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: revealed
              ? [
                  _accent.withValues(alpha: p.isDark ? 0.28 : 0.14),
                  widget.routeColor.withValues(alpha: p.isDark ? 0.16 : 0.08),
                ]
              : [p.card(0.09), p.card(0.04)],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: revealed ? _accent.withValues(alpha: 0.6) : p.line(0.16),
          width: revealed ? 2 : 1,
        ),
        boxShadow: revealed
            ? [
                BoxShadow(
                  color: _accent.withValues(alpha: p.isDark ? 0.28 : 0.16),
                  blurRadius: 24,
                  spreadRadius: 1,
                ),
              ]
            : p.cardShadow,
      ),
      child: revealed
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lightbulb_rounded, color: Color(0xFFFBBF24), size: 26),
                const SizedBox(height: 12),
                Text(
                  widget.step.content ?? '',
                  style: TextStyle(fontSize: 16, height: 1.75, color: p.inkA(0.92)),
                ),
              ],
            )
          : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.touch_app_rounded, size: 34, color: p.inkA(0.5))
                    .animate(onPlay: MotionService.loop(context, reverse: true))
                    .moveY(begin: 0, end: -7, duration: 1100.ms, curve: Curves.easeInOut),
                const SizedBox(height: 14),
                Text(
                  'routes.revealTap'.tr(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    height: 1.5,
                    color: p.inkA(0.6),
                  ),
                ),
              ],
            ),
    );
  }
}
