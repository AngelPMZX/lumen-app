import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../data/models/wellness_route.dart';
import '../../../../domain/services/sound_service.dart';
import '../lesson_palette.dart';
import 'step_common.dart';

/// SLIDER — termómetro del 0 al 10. La respuesta depende del tramo:
/// 0-3 (verde), 4-6 (ámbar), 7-10 (rojo). "Alto" es siempre lo difícil.
class SliderStep extends StatefulWidget {
  final LessonStep step;
  final Color routeColor;
  final StepCallbacks callbacks;

  const SliderStep({
    super.key,
    required this.step,
    required this.routeColor,
    required this.callbacks,
  });

  @override
  State<SliderStep> createState() => _SliderStepState();
}

class _SliderStepState extends State<SliderStep> {
  static const _bandColors = [
    StepColors.correct,
    StepColors.warning,
    StepColors.wrong,
  ];

  double _value = 5;

  /// Hasta que lo mueve no cuenta: el 5 inicial no es una respuesta.
  bool _touched = false;

  void _onChanged(double val) {
    if (!_touched || val.round() != _value.round()) {
      HapticFeedback.selectionClick();
      SoundService.instance.play(Sfx.tick, volume: 0.35);
    }
    final first = !_touched;
    setState(() {
      _value = val;
      _touched = true;
    });
    if (first) widget.callbacks.onReady();
  }

  @override
  Widget build(BuildContext context) {
    final p = LessonPalette.of(context);
    final v = _value.round();
    final responses = widget.step.responses ?? const [];
    final band = v <= 3 ? 0 : (v <= 6 ? 1 : 2);
    final bandColor = _bandColors[band];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        StepChip(
          icon: Icons.thermostat_rounded,
          label: 'routes.sliderLabel'.tr(),
          color: const Color(0xFF3B82F6),
        ),
        const SizedBox(height: 16),
        StepHeading(
          text: widget.step.question ?? widget.step.title,
          glow: widget.routeColor,
        ),
        const SizedBox(height: 26),
        // Número grande que cambia de color con el valor
        Center(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            transitionBuilder: (child, anim) => ScaleTransition(
              scale: anim,
              child: FadeTransition(opacity: anim, child: child),
            ),
            child: Text(
              '$v',
              key: ValueKey(v),
              style: TextStyle(
                fontSize: 64,
                fontWeight: FontWeight.w900,
                height: 1,
                color: _touched ? p.accent(bandColor) : p.inkA(0.24),
                shadows: _touched && p.isDark
                    ? [
                        Shadow(
                          color: bandColor.withValues(alpha: 0.5),
                          blurRadius: 26,
                        ),
                      ]
                    : null,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 8,
            activeTrackColor: bandColor,
            inactiveTrackColor: p.line(0.12),
            thumbColor: p.isDark ? Colors.white : bandColor,
            overlayColor: bandColor.withValues(alpha: 0.2),
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 13),
          ),
          child: Slider(
            value: _value,
            min: 0,
            max: 10,
            divisions: 10,
            onChanged: _onChanged,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  widget.step.minLabel ?? '0',
                  style: TextStyle(fontSize: 12, color: p.inkA(0.38)),
                ),
              ),
              Flexible(
                child: Text(
                  widget.step.maxLabel ?? '10',
                  textAlign: TextAlign.right,
                  style: TextStyle(fontSize: 12, color: p.inkA(0.38)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        // La respuesta cambia según el tramo en el que caiga
        if (_touched && band < responses.length)
          StepNote(
            key: ValueKey('resp_$band'),
            text: responses[band],
            color: bandColor,
            icon: Icons.favorite_rounded,
          ),
      ],
    ).animate().fadeIn(duration: 300.ms);
  }
}
