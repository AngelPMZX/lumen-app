import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../data/models/wellness_route.dart';
import 'step_common.dart';

/// PICK — "marca todas las que te pasen". No hay respuestas correctas.
///
/// Si el paso trae tres [LessonStep.responses], la respuesta depende de
/// cuántas marcó (pocas, algunas, muchas); si no, se muestra la explicación.
class PickStep extends StatefulWidget {
  final LessonStep step;
  final Color routeColor;
  final StepCallbacks callbacks;

  const PickStep({
    super.key,
    required this.step,
    required this.routeColor,
    required this.callbacks,
  });

  @override
  State<PickStep> createState() => _PickStepState();
}

class _PickStepState extends State<PickStep> {
  static const _accent = Color(0xFF8B5CF6);

  final Set<int> _selected = {};
  bool _confirmed = false;

  List<String> get _options => widget.step.options ?? const [];

  void _toggle(int i) {
    if (_confirmed) return;
    HapticFeedback.selectionClick();
    setState(() {
      if (!_selected.remove(i)) _selected.add(i);
    });
  }

  void _confirm() {
    HapticFeedback.mediumImpact();
    setState(() => _confirmed = true);
    widget.callbacks.onReflect(3);
    widget.callbacks.onReady();
  }

  String? get _feedback {
    final responses = widget.step.responses;
    if (responses != null && responses.length >= 3 && _options.isNotEmpty) {
      final ratio = _selected.length / _options.length;
      final band = ratio <= 1 / 3 ? 0 : (ratio <= 2 / 3 ? 1 : 2);
      return responses[band];
    }
    return widget.step.explanation;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        StepChip(
          icon: Icons.checklist_rounded,
          label: 'routes.pickLabel'.tr(),
          color: _accent,
        ),
        const SizedBox(height: 16),
        StepHeading(
          text: widget.step.question ?? widget.step.title,
          glow: widget.routeColor,
          fontSize: 23,
        ),
        const SizedBox(height: 8),
        Text(
          'routes.pickHint'.tr(),
          style: TextStyle(
            fontSize: 13.5,
            color: Colors.white.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 16),
        ...List.generate(_options.length, (i) {
          final on = _selected.contains(i);
          return Padding(
            padding: const EdgeInsets.only(bottom: 9),
            child: GestureDetector(
              onTap: () => _toggle(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                decoration: BoxDecoration(
                  color: on
                      ? _accent.withValues(alpha: 0.2)
                      : Colors.white.withValues(
                          alpha: _confirmed ? 0.03 : 0.07),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: on
                        ? _accent
                        : Colors.white.withValues(alpha: 0.13),
                    width: on ? 1.8 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: on ? _accent : Colors.transparent,
                        borderRadius: BorderRadius.circular(7),
                        border: Border.all(
                          color: on
                              ? _accent
                              : Colors.white.withValues(alpha: 0.35),
                          width: 1.6,
                        ),
                      ),
                      child: on
                          ? const Icon(Icons.check_rounded,
                              size: 16, color: Colors.white)
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _options[i],
                        style: TextStyle(
                          fontSize: 14.5,
                          height: 1.4,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withValues(
                              alpha: _confirmed && !on ? 0.45 : 1),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ).animate(delay: (i * 50).ms).fadeIn(duration: 260.ms);
        }),
        const SizedBox(height: 8),
        if (!_confirmed)
          Align(
            alignment: Alignment.centerRight,
            child: StepInlineButton(
              label: _selected.isEmpty
                  ? 'routes.pickNone'.tr()
                  : 'routes.pickConfirm'.tr(namedArgs: {'n': '${_selected.length}'}),
              color: _accent,
              icon: Icons.check_rounded,
              onPressed: _confirm,
            ),
          )
        else if (_feedback != null)
          StepNote(text: _feedback!, color: _accent, icon: Icons.favorite_rounded),
      ],
    );
  }
}
