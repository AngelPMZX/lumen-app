import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../data/models/wellness_route.dart';
import '../../../../domain/services/sound_service.dart';
import 'step_common.dart';
import '../lesson_palette.dart';
import '../../../../domain/services/motion_service.dart';

/// STORY — una mini historia en burbujas de chat que se revelan al tocar.
///
/// Sustituye a los muros de texto: la misma idea, dosificada línea a línea.
/// Convenciones de cada línea:
///   `> texto` → lo dice "tú" (burbuja a la derecha)
///   `* texto` → narración (centrada, en cursiva)
///   `texto`   → lo dice el personaje ([LessonStep.speaker])
class StoryStep extends StatefulWidget {
  final LessonStep step;
  final Color routeColor;
  final String fallbackSpeaker;
  final StepCallbacks callbacks;

  const StoryStep({
    super.key,
    required this.step,
    required this.routeColor,
    required this.fallbackSpeaker,
    required this.callbacks,
  });

  @override
  State<StoryStep> createState() => _StoryStepState();
}

class _StoryStepState extends State<StoryStep> {
  int _shown = 1;
  final _tapKey = GlobalKey();

  List<String> get _lines => widget.step.lines ?? const [];
  bool get _finished => _shown >= _lines.length;

  @override
  void initState() {
    super.initState();
    // Una historia de una sola línea ya está completa.
    if (_lines.length <= 1) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _complete();
      });
    }
  }

  void _complete() {
    widget.callbacks.onReflect(2);
    widget.callbacks.onReady();
  }

  void _showNext() {
    if (_finished) return;
    HapticFeedback.selectionClick();
    SoundService.instance.play(Sfx.bubble, volume: 0.55);
    setState(() => _shown++);
    if (_finished) _complete();
    // Mantener visible el botón de "toca para seguir".
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _tapKey.currentContext;
      if (ctx != null && ctx.mounted) {
        Scrollable.ensureVisible(
          ctx,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
          alignment: 1,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final speaker = widget.step.speaker ?? widget.fallbackSpeaker;
    final p = LessonPalette.of(context);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _showNext,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StepChip(
            icon: Icons.chat_bubble_rounded,
            label: 'routes.storyLabel'.tr(),
            color: const Color(0xFFEC4899),
          ),
          const SizedBox(height: 16),
          StepHeading(text: widget.step.title, glow: widget.routeColor),
          const SizedBox(height: 18),
          for (int i = 0; i < _shown && i < _lines.length; i++)
            _buildLine(_lines[i], speaker, i),
          const SizedBox(height: 6),
          Center(
            key: _tapKey,
            child: _finished
                ? const Icon(Icons.check_circle_rounded,
                        color: Color(0xFF10B981), size: 26)
                    .animate()
                    .scale(duration: 300.ms, curve: Curves.easeOutBack)
                : Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 9),
                    decoration: BoxDecoration(
                      color: p.card(0.08),
                      borderRadius: BorderRadius.circular(20),
                      border: p.isDark ? null : Border.all(color: p.line(0.08)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.touch_app_rounded,
                            size: 16, color: p.inkA(0.6)),
                        const SizedBox(width: 6),
                        Text(
                          'routes.storyTap'.tr(namedArgs: {
                            'current': '$_shown',
                            'total': '${_lines.length}',
                          }),
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: p.inkA(0.6),
                          ),
                        ),
                      ],
                    ),
                  )
                    .animate(onPlay: MotionService.loop(context, reverse: true))
                    .fade(begin: 0.55, end: 1, duration: 900.ms),
          ),
        ],
      ),
    );
  }

  Widget _buildLine(String raw, String speaker, int index) {
    final p = LessonPalette.of(context);
    final Widget child;

    if (raw.startsWith('* ')) {
      child = Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        child: Center(
          child: Text(
            raw.substring(2),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              height: 1.55,
              fontStyle: FontStyle.italic,
              color: p.inkA(0.6),
            ),
          ),
        ),
      );
    } else if (raw.startsWith('> ')) {
      child = Align(
        alignment: Alignment.centerRight,
        child: Container(
          margin: const EdgeInsets.only(left: 48, bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 11),
          decoration: BoxDecoration(
            color: widget.routeColor.withValues(alpha: p.isDark ? 0.32 : 0.18),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(18),
              topRight: Radius.circular(18),
              bottomLeft: Radius.circular(18),
              bottomRight: Radius.circular(4),
            ),
            border: Border.all(
                color: widget.routeColor.withValues(alpha: 0.55)),
          ),
          child: Text(
            raw.substring(2),
            style: TextStyle(fontSize: 15, height: 1.5, color: p.ink),
          ),
        ),
      );
    } else {
      child = Padding(
        padding: const EdgeInsets.only(right: 36, bottom: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: p.card(0.1),
                shape: BoxShape.circle,
                boxShadow: p.cardShadow,
              ),
              child: Center(
                child: Text(speaker, style: const TextStyle(fontSize: 18)),
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 15, vertical: 11),
                decoration: BoxDecoration(
                  color: p.card(0.09),
                  boxShadow: p.cardShadow,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(18),
                    topRight: Radius.circular(18),
                    bottomLeft: Radius.circular(4),
                    bottomRight: Radius.circular(18),
                  ),
                  border:
                      Border.all(color: p.line(0.12)),
                ),
                child: Text(
                  raw,
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.5,
                    color: p.inkA(0.92),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return child
        .animate(key: ValueKey('line_$index'))
        .fadeIn(duration: 320.ms)
        .slideY(begin: 0.25, end: 0, curve: Curves.easeOutCubic);
  }
}
