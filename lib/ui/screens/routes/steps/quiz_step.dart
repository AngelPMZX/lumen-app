import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../data/models/wellness_route.dart';
import '../lesson_palette.dart';
import 'step_common.dart';

/// QUIZ — pregunta de opción múltiple con una respuesta correcta.
class QuizStep extends StatefulWidget {
  final LessonStep step;
  final Color routeColor;
  final StepCallbacks callbacks;

  const QuizStep({
    super.key,
    required this.step,
    required this.routeColor,
    required this.callbacks,
  });

  @override
  State<QuizStep> createState() => _QuizStepState();
}

class _QuizStepState extends State<QuizStep> {
  int? _selected;

  bool get _answered => _selected != null;
  List<String> get _options => widget.step.options ?? const [];

  void _select(int index) {
    if (_answered) return;
    HapticFeedback.lightImpact();
    final correct = index == widget.step.correctIndex;
    setState(() => _selected = index);
    widget.callbacks.onAnswer(correct, correct ? 5 : 0);
    widget.callbacks.onReady();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        StepChip(
          icon: Icons.quiz_rounded,
          label: 'routes.questionLabel'.tr(),
          color: StepColors.warning,
        ),
        const SizedBox(height: 16),
        StepHeading(
          text: widget.step.question ?? widget.step.title,
          glow: widget.routeColor,
          fontSize: 22,
        ),
        const SizedBox(height: 20),
        ...List.generate(_options.length, _buildOption),
        if (_answered && widget.step.explanation != null) ...[
          const SizedBox(height: 12),
          StepNote(
            text: widget.step.explanation!,
            color: _selected == widget.step.correctIndex
                ? StepColors.correct
                : StepColors.warning,
            icon: _selected == widget.step.correctIndex
                ? Icons.check_circle_rounded
                : Icons.info_rounded,
          ),
        ],
      ],
    );
  }

  Widget _buildOption(int i) {
    final p = LessonPalette.of(context);
    final isSelected = _selected == i;
    final isCorrect = i == widget.step.correctIndex;
    final showCorrect = _answered && isCorrect;
    final showWrong = _answered && isSelected && !isCorrect;

    final Color accent = showCorrect
        ? StepColors.correct
        : showWrong
            ? StepColors.wrong
            : widget.routeColor;
    final highlighted = isSelected || showCorrect;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: () => _select(i),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          // Sin rebote: al interpolar sombras volvería negativo el blur.
          curve: Curves.easeOutCubic,
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: highlighted
                ? (p.isDark
                    ? accent.withValues(alpha: 0.18)
                    // Opaco en claro: si no, la sombra de color se ve a través
                    : Color.lerp(Colors.white, accent, 0.14))
                : p.card(0.07),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: highlighted ? accent : p.line(0.12),
              width: highlighted ? 2 : 1,
            ),
            boxShadow: highlighted
                ? [
                    BoxShadow(
                      color: accent.withValues(alpha: 0.3),
                      blurRadius: 14,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : p.cardShadow,
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: highlighted ? accent : p.line(0.12),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: _answered && (showCorrect || showWrong)
                      ? Icon(
                          showCorrect ? Icons.check_rounded : Icons.close_rounded,
                          color: Colors.white,
                          size: 18,
                        )
                      : Text(
                          String.fromCharCode(65 + i),
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                            color: highlighted ? Colors.white : p.inkA(0.6),
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _options[i],
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: p.ink,
                  ),
                ),
              ),
            ],
          ),
        ),
      )
          .animate(delay: (i * 60).ms)
          .fadeIn(duration: 300.ms)
          .slideX(begin: 0.04, end: 0),
    );
  }
}
