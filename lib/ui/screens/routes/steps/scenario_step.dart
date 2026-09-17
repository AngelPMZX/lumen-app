import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../data/models/wellness_route.dart';
import '../../../../domain/services/sound_service.dart';
import '../lesson_palette.dart';
import 'step_common.dart';

/// SCENARIO — una situación real y varias reacciones, ninguna "incorrecta":
/// al elegir se despliega la consecuencia de esa opción.
class ScenarioStep extends StatefulWidget {
  final LessonStep step;
  final Color routeColor;
  final StepCallbacks callbacks;

  const ScenarioStep({
    super.key,
    required this.step,
    required this.routeColor,
    required this.callbacks,
  });

  @override
  State<ScenarioStep> createState() => _ScenarioStepState();
}

class _ScenarioStepState extends State<ScenarioStep> {
  static const _accent = StepColors.warning;

  int? _choice;

  void _choose(int index) {
    HapticFeedback.lightImpact();
    SoundService.instance.play(Sfx.pop);
    setState(() => _choice = index);
    // No hay opción incorrecta: reflexionar ya cuenta.
    widget.callbacks.onReflect(5);
    widget.callbacks.onReady();
  }

  @override
  Widget build(BuildContext context) {
    final p = LessonPalette.of(context);
    final options = widget.step.options ?? const [];
    final outcomes = widget.step.outcomes ?? const [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        StepChip(
          icon: Icons.forum_rounded,
          label: 'routes.scenarioLabel'.tr(),
          color: _accent,
        ),
        const SizedBox(height: 16),
        StepHeading(text: widget.step.title, glow: widget.routeColor),
        const SizedBox(height: 14),
        // La situación, presentada como si alguien te la contara
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: p.isDark
                ? _accent.withValues(alpha: 0.1)
                : Color.lerp(Colors.white, _accent, 0.1),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
              bottomRight: Radius.circular(20),
              bottomLeft: Radius.circular(4),
            ),
            border: Border.all(color: _accent.withValues(alpha: 0.3)),
          ),
          child: Text(
            widget.step.content ?? '',
            style: TextStyle(fontSize: 15.5, height: 1.7, color: p.inkA(0.9)),
          ),
        ),
        const SizedBox(height: 18),
        Text(
          'routes.scenarioPrompt'.tr(),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
            color: p.inkA(0.38),
          ),
        ),
        const SizedBox(height: 10),
        ...List.generate(options.length, (i) {
          final chosen = _choice == i;
          final decided = _choice != null;

          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: GestureDetector(
              onTap: decided ? null : () => _choose(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 280),
                // Sin rebote: al interpolar sombras volvería negativo el blur.
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: chosen
                      ? (p.isDark
                          ? widget.routeColor.withValues(alpha: 0.22)
                          : Color.lerp(Colors.white, widget.routeColor, 0.12))
                      : p.card(decided ? 0.03 : 0.07),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: chosen
                        ? widget.routeColor
                        : p.line(decided ? 0.06 : 0.14),
                    width: chosen ? 2 : 1,
                  ),
                  boxShadow: decided ? null : p.cardShadow,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 280),
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: chosen ? widget.routeColor : p.line(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: chosen
                              ? const Icon(Icons.check_rounded,
                                  size: 16, color: Colors.white)
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            options[i],
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              height: 1.4,
                              color: p.inkA(decided && !chosen ? 0.45 : 1),
                            ),
                          ),
                        ),
                      ],
                    ),
                    // La consecuencia se despliega solo en la opción elegida
                    if (chosen && i < outcomes.length) ...[
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(13),
                        decoration: BoxDecoration(
                          color: p.isDark
                              ? Colors.black.withValues(alpha: 0.25)
                              : Colors.white.withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.arrow_forward_rounded,
                                size: 15, color: p.inkA(0.54)),
                            const SizedBox(width: 9),
                            Expanded(
                              child: Text(
                                outcomes[i],
                                style: TextStyle(
                                  fontSize: 13.5,
                                  height: 1.55,
                                  color: p.inkA(0.85),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ).animate().fadeIn(duration: 350.ms).slideY(begin: 0.15, end: 0),
                    ],
                  ],
                ),
              ),
            ),
          ).animate(delay: (i * 70).ms).fadeIn(duration: 300.ms).slideX(begin: 0.05, end: 0);
        }),
      ],
    );
  }
}
