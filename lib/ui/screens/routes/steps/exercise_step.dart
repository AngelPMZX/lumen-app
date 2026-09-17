import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../data/models/wellness_route.dart';
import '../lesson_palette.dart';
import 'step_common.dart';

/// EXERCISE — respuesta escrita (mínimo 10 caracteres para continuar).
///
/// No guarda nada: avisa con [onDraftChanged] y `LessonScreen` decide al
/// pulsar "Continuar" (así también puede guardarlo en el diario).
class ExerciseStep extends StatefulWidget {
  static const minChars = 10;

  final LessonStep step;
  final Color routeColor;
  final void Function(String text, bool saveToDiary) onDraftChanged;

  const ExerciseStep({
    super.key,
    required this.step,
    required this.routeColor,
    required this.onDraftChanged,
  });

  @override
  State<ExerciseStep> createState() => _ExerciseStepState();
}

class _ExerciseStepState extends State<ExerciseStep> {
  final _controller = TextEditingController();
  bool _saveToDiary = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _notify() => widget.onDraftChanged(_controller.text, _saveToDiary);

  @override
  Widget build(BuildContext context) {
    final p = LessonPalette.of(context);
    const green = StepColors.correct;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        StepChip(
          icon: Icons.edit_rounded,
          label: 'routes.exerciseLabel'.tr(),
          color: green,
        ),
        const SizedBox(height: 16),
        StepHeading(text: widget.step.title, glow: widget.routeColor),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: p.isDark
                ? green.withValues(alpha: 0.12)
                : Color.lerp(Colors.white, green, 0.1),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: green.withValues(alpha: 0.25)),
          ),
          child: Text(
            widget.step.instruction ?? '',
            style: TextStyle(fontSize: 15, height: 1.65, color: p.inkA(0.88)),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _controller,
          onChanged: (_) {
            setState(() {});
            _notify();
          },
          maxLines: 5,
          maxLength: 500,
          style: TextStyle(fontSize: 15, color: p.ink),
          cursorColor: widget.routeColor,
          decoration: InputDecoration(
            hintText: widget.step.placeholder ?? 'routes.exercisePlaceholder'.tr(),
            hintStyle: TextStyle(color: p.inkA(0.3)),
            filled: true,
            fillColor: p.card(0.07),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide(color: p.line(0.12)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide(color: widget.routeColor, width: 1.8),
            ),
            counterStyle: TextStyle(color: p.inkA(0.38), fontSize: 11),
            contentPadding: const EdgeInsets.all(18),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(Icons.info_outline_rounded, size: 13, color: p.inkA(0.38)),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                'routes.exerciseMinChars'.tr(),
                style: TextStyle(
                  fontSize: 12,
                  color: p.inkA(0.38),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: () {
            setState(() => _saveToDiary = !_saveToDiary);
            _notify();
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: p.card(0.05),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: p.line(0.1)),
            ),
            child: Row(
              children: [
                Icon(Icons.book_rounded, size: 18, color: p.inkA(0.6)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'routes.saveToDiary'.tr(),
                    style: TextStyle(fontSize: 13.5, color: p.inkA(0.7)),
                  ),
                ),
                Switch(
                  value: _saveToDiary,
                  activeThumbColor: widget.routeColor,
                  onChanged: (v) {
                    setState(() => _saveToDiary = v);
                    _notify();
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
