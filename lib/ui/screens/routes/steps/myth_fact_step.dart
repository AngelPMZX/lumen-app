import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../data/models/wellness_route.dart';
import 'step_common.dart';
import '../../../../domain/services/sound_service.dart';
import '../lesson_palette.dart';

/// MYTH / FACT — tarjetas rápidas: desliza (o toca) "Mito" o "Realidad".
class MythFactStep extends StatefulWidget {
  final LessonStep step;
  final Color routeColor;
  final StepCallbacks callbacks;

  const MythFactStep({
    super.key,
    required this.step,
    required this.routeColor,
    required this.callbacks,
  });

  @override
  State<MythFactStep> createState() => _MythFactStepState();
}

class _MythFactStepState extends State<MythFactStep> {
  static const _mythColor = Color(0xFFF43F5E);
  static const _factColor = Color(0xFF10B981);

  int _index = 0;
  bool? _answer; // respuesta del usuario en la tarjeta actual
  int _correctCount = 0;
  double _dragX = 0;
  bool _finished = false;

  List<String> get _statements => widget.step.statements ?? const [];
  List<bool> get _truths => widget.step.truths ?? const [];
  List<String> get _feedbacks => widget.step.feedbacks ?? const [];

  bool get _isTrue => _index < _truths.length ? _truths[_index] : true;

  void _choose(bool saysTrue) {
    if (_answer != null || _finished) return;
    final correct = saysTrue == _isTrue;
    HapticFeedback.mediumImpact();
    SoundService.instance.play(Sfx.swipe, volume: 0.7);
    setState(() {
      _answer = saysTrue;
      _dragX = 0;
      if (correct) _correctCount++;
    });
    widget.callbacks.onAnswer(correct, correct ? 3 : 0);
  }

  void _next() {
    HapticFeedback.lightImpact();
    if (_index >= _statements.length - 1) {
      setState(() => _finished = true);
      widget.callbacks.onReady();
      return;
    }
    setState(() {
      _index++;
      _answer = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final total = _statements.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        StepChip(
          icon: Icons.swap_horiz_rounded,
          label: 'routes.mythFactLabel'.tr(),
          color: const Color(0xFFF43F5E),
        ),
        const SizedBox(height: 16),
        StepHeading(text: widget.step.title, glow: widget.routeColor),
        const SizedBox(height: 8),
        StepBody('routes.mythFactHint'.tr(), alpha: 0.6, fontSize: 13.5),
        const SizedBox(height: 18),
        if (_finished)
          _buildSummary(total)
        else if (total > 0) ...[
          _buildDots(total),
          const SizedBox(height: 14),
          _buildCard(),
          const SizedBox(height: 16),
          if (_answer == null)
            _buildButtons()
          else ...[
            if (_index < _feedbacks.length)
              StepNote(
                key: ValueKey('fb_$_index'),
                text: _feedbacks[_index],
                color: _answer == _isTrue
                    ? _factColor
                    : const Color(0xFFF59E0B),
                icon: _answer == _isTrue
                    ? Icons.check_circle_rounded
                    : Icons.info_rounded,
              ),
            const SizedBox(height: 14),
            Align(
              alignment: Alignment.centerRight,
              child: StepInlineButton(
                label: _index >= total - 1
                    ? 'routes.mythFactSeeResult'.tr()
                    : 'common.next'.tr(),
                color: widget.routeColor,
                onPressed: _next,
              ),
            ),
          ],
        ],
      ],
    );
  }

  Widget _buildDots(int total) {
    final p = LessonPalette.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(total, (i) {
        final active = i == _index;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: active ? 20 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: i < _index || active ? widget.routeColor : p.line(0.15),
            borderRadius: BorderRadius.circular(8),
          ),
        );
      }),
    );
  }

  Widget _buildCard() {
    final p = LessonPalette.of(context);
    final answered = _answer != null;
    final tilt = (_dragX / 600).clamp(-0.18, 0.18);
    // Mientras arrastra, el borde anticipa qué opción está eligiendo.
    Color border = p.line(0.16);
    if (!answered && _dragX > 30) border = _factColor;
    if (!answered && _dragX < -30) border = _mythColor;
    if (answered) border = _isTrue ? _factColor : _mythColor;

    return GestureDetector(
          onHorizontalDragUpdate: answered
              ? null
              : (d) => setState(() => _dragX += d.delta.dx),
          onHorizontalDragEnd: answered
              ? null
              : (_) {
                  if (_dragX > 90) {
                    _choose(true);
                  } else if (_dragX < -90) {
                    _choose(false);
                  } else {
                    setState(() => _dragX = 0);
                  }
                },
          child: AnimatedContainer(
            key: ValueKey('card_$_index'),
            duration: Duration(milliseconds: _dragX == 0 ? 260 : 0),
            curve: Curves.easeOutBack,
            transform: Matrix4.translationValues(_dragX, 0, 0)..rotateZ(tilt),
            transformAlignment: Alignment.bottomCenter,
            width: double.infinity,
            constraints: const BoxConstraints(minHeight: 170),
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  p.card(0.11),
                  p.isDark
                      ? widget.routeColor.withValues(alpha: 0.08)
                      : Color.lerp(Colors.white, widget.routeColor, 0.08)!,
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: border, width: answered ? 2 : 1.4),
              boxShadow: p.cardShadow,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (answered)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 5,
                    ),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: (_isTrue ? _factColor : _mythColor).withValues(
                        alpha: 0.2,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      _isTrue
                          ? 'routes.factWord'.tr().toUpperCase()
                          : 'routes.mythWord'.tr().toUpperCase(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                        color: p.accent(_isTrue ? _factColor : _mythColor),
                      ),
                    ),
                  ).animate().scale(
                    duration: 300.ms,
                    curve: Curves.easeOutBack,
                  ),
                Text(
                  '"${_statements[_index]}"',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 19,
                    height: 1.45,
                    fontWeight: FontWeight.w700,
                    color: p.ink,
                  ),
                ),
              ],
            ),
          ),
        )
        .animate(key: ValueKey('enter_$_index'))
        .fadeIn(duration: 300.ms)
        .slideX(begin: 0.15, end: 0, curve: Curves.easeOutCubic);
  }

  Widget _buildButtons() {
    final p = LessonPalette.of(context);
    Widget button(bool saysTrue) {
      final color = saysTrue ? _factColor : _mythColor;
      return Expanded(
        child: GestureDetector(
          onTap: () => _choose(saysTrue),
          child: Container(
            height: 54,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withValues(alpha: 0.6)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  saysTrue
                      ? Icons.arrow_forward_rounded
                      : Icons.arrow_back_rounded,
                  size: 16,
                  color: p.accent(color),
                ),
                const SizedBox(width: 6),
                Text(
                  saysTrue ? 'routes.factWord'.tr() : 'routes.mythWord'.tr(),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: p.accent(color),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Mito a la izquierda, realidad a la derecha: coincide con el deslizamiento.
    return Row(
      children: [button(false), const SizedBox(width: 12), button(true)],
    );
  }

  Widget _buildSummary(int total) {
    final p = LessonPalette.of(context);
    final perfect = _correctCount == total;
    return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: widget.routeColor.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: widget.routeColor.withValues(alpha: 0.4)),
          ),
          child: Column(
            children: [
              Text(perfect ? '🏆' : '🧠', style: const TextStyle(fontSize: 40)),
              const SizedBox(height: 8),
              Text(
                'routes.mythFactScore'.tr(
                  namedArgs: {'correct': '$_correctCount', 'total': '$total'},
                ),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: p.ink,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                perfect
                    ? 'routes.mythFactPerfect'.tr()
                    : 'routes.mythFactKeepGoing'.tr(),
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, height: 1.5, color: p.inkA(0.7)),
              ),
            ],
          ),
        )
        .animate()
        .fadeIn(duration: 400.ms)
        .scale(
          begin: const Offset(0.9, 0.9),
          end: const Offset(1, 1),
          curve: Curves.easeOutBack,
        );
  }
}
