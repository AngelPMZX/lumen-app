import 'dart:math' as math;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../data/models/wellness_route.dart';
import '../../../../domain/services/sound_service.dart';
import 'step_common.dart';
import '../lesson_palette.dart';
import '../../../../domain/services/motion_service.dart';

/// PRACTICE — práctica guiada con temporizador: respiración, grounding,
/// escaneo corporal. Cada indicación dura sus segundos y el orbe se mueve
/// según [LessonStep.motions]:
///   `in`    → crece (inhalar)
///   `out`   → se encoge (exhalar)
///   `hold`  → se queda quieto
///   `still` → late suavemente (por defecto)
class PracticeStep extends StatefulWidget {
  final LessonStep step;
  final Color routeColor;
  final StepCallbacks callbacks;

  const PracticeStep({
    super.key,
    required this.step,
    required this.routeColor,
    required this.callbacks,
  });

  @override
  State<PracticeStep> createState() => _PracticeStepState();
}

enum _Phase { intro, running, done }

class _PracticeStepState extends State<PracticeStep>
    with SingleTickerProviderStateMixin {
  static const _small = 0.62;
  static const _big = 1.0;

  late final AnimationController _controller;
  _Phase _phase = _Phase.intro;
  int _index = 0;
  double _scaleFrom = 0.8;
  bool _completedNaturally = false;

  List<String> get _prompts => widget.step.prompts ?? const [];

  int _durationOf(int i) {
    final d = widget.step.durations;
    if (d == null || i >= d.length) return 5;
    return d[i].clamp(1, 120);
  }

  String _motionOf(int i) {
    final m = widget.step.motions;
    if (m == null || i >= m.length) return 'still';
    return m[i];
  }

  int get _totalSeconds {
    var total = 0;
    for (int i = 0; i < _prompts.length; i++) {
      total += _durationOf(i);
    }
    return total;
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) _advance();
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    if (_phase == _Phase.running) SoundService.instance.returnToBaseAmbient();
    super.dispose();
  }

  /// Señal suave según el movimiento del orbe; `still` no suena para no
  /// saturar las indicaciones de observar.
  void _cueFor(int i) {
    final cue = switch (_motionOf(i)) {
      'in' => BreathCue.inhale,
      'out' => BreathCue.exhale,
      'hold' => BreathCue.hold,
      _ => null,
    };
    if (cue != null) SoundService.instance.cue(cue, volume: 0.45);
  }

  void _start() {
    if (_prompts.isEmpty) {
      _finish(naturally: true);
      return;
    }
    HapticFeedback.mediumImpact();
    setState(() {
      _phase = _Phase.running;
      _index = 0;
      _scaleFrom = 0.8;
    });
    SoundService.instance.startAmbient(Ambient.calmMusic, volume: 0.35);
    _runCurrent();
  }

  void _runCurrent() {
    _cueFor(_index);
    _controller.duration = Duration(seconds: _durationOf(_index));
    _controller.forward(from: 0);
  }

  void _advance() {
    if (!mounted) return;
    final endScale = _scaleAt(_index, 1);
    if (_index >= _prompts.length - 1) {
      _finish(naturally: true);
      return;
    }
    HapticFeedback.selectionClick();
    setState(() {
      _scaleFrom = endScale;
      _index++;
    });
    _runCurrent();
  }

  void _finish({required bool naturally}) {
    _controller.stop();
    HapticFeedback.heavyImpact();
    if (_phase == _Phase.running) SoundService.instance.returnToBaseAmbient();
    if (naturally) SoundService.instance.cue(BreathCue.bowl, volume: 0.6);
    setState(() {
      _phase = _Phase.done;
      _completedNaturally = naturally;
    });
    widget.callbacks.onReflect(naturally ? 6 : 1);
    widget.callbacks.onReady();
  }

  /// Escala del orbe en la indicación [i] con progreso [t] (0-1).
  double _scaleAt(int i, double t) {
    final eased = Curves.easeInOut.transform(t);
    final from = i == _index ? _scaleFrom : 0.8;
    switch (_motionOf(i)) {
      case 'in':
        return from + (_big - from) * eased;
      case 'out':
        return from + (_small - from) * eased;
      case 'hold':
        return from;
      default:
        return from + math.sin(t * math.pi * 2) * 0.04;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        StepChip(
          icon: Icons.self_improvement_rounded,
          label: 'routes.practiceLabel'.tr(),
          color: const Color(0xFF22D3EE),
        ),
        const SizedBox(height: 16),
        StepHeading(text: widget.step.title, glow: widget.routeColor),
        const SizedBox(height: 14),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 350),
          child: switch (_phase) {
            _Phase.intro => _buildIntro(),
            _Phase.running => _buildRunning(),
            _Phase.done => _buildDone(),
          },
        ),
      ],
    );
  }

  Widget _buildIntro() {
    final p = LessonPalette.of(context);
    final minutes = _totalSeconds >= 60
        ? 'routes.practiceMinutes'.tr(namedArgs: {
            'n': (_totalSeconds / 60).toStringAsFixed(
                _totalSeconds % 60 == 0 ? 0 : 1),
          })
        : 'routes.practiceSeconds'.tr(namedArgs: {'n': '$_totalSeconds'});

    return Column(
      key: const ValueKey('intro'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: p.card(0.07),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: widget.routeColor.withValues(alpha: 0.25)),
            boxShadow: p.cardShadow,
          ),
          child: Text(
            widget.step.content ?? '',
            style: TextStyle(
              fontSize: 15.5,
              height: 1.7,
              color: p.inkA(0.88),
            ),
          ),
        ),
        const SizedBox(height: 22),
        Center(
          child: GestureDetector(
            onTap: _start,
            child: Container(
              width: 128,
              height: 128,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  widget.routeColor.withValues(alpha: 0.9),
                  widget.routeColor.withValues(alpha: 0.45),
                ]),
                boxShadow: [
                  BoxShadow(
                    color: widget.routeColor.withValues(alpha: 0.45),
                    blurRadius: 30,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.play_arrow_rounded,
                      size: 44, color: Colors.white),
                  Text(
                    'routes.practiceStart'.tr(),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          )
              .animate(onPlay: MotionService.loop(context, reverse: true))
              .scale(
                begin: const Offset(1, 1),
                end: const Offset(1.06, 1.06),
                duration: 1400.ms,
                curve: Curves.easeInOut,
              ),
        ),
        const SizedBox(height: 12),
        Center(
          child: Text(
            minutes,
            style: TextStyle(fontSize: 12.5, color: p.inkA(0.38)),
          ),
        ),
      ],
    );
  }

  Widget _buildRunning() {
    final p = LessonPalette.of(context);
    return Column(
      key: const ValueKey('running'),
      children: [
        const SizedBox(height: 6),
        SizedBox(
          width: 230,
          height: 230,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              final t = _controller.value;
              final scale = _scaleAt(_index, t);
              final remaining =
                  (_durationOf(_index) * (1 - t)).ceil().clamp(1, 999);
              return Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(
                    size: const Size(230, 230),
                    painter: _RingPainter(
                      progress: t,
                      color: widget.routeColor,
                      track: p.line(0.1),
                    ),
                  ),
                  Transform.scale(scale: scale, child: _orb()),
                  // Sobre el orbe: blanco en ambos temas
                  Text(
                    '$remaining',
                    style: const TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      shadows: [Shadow(color: Colors.black26, blurRadius: 8)],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 20),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: Text(
            _prompts[_index],
            key: ValueKey('prompt_$_index'),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 19,
              height: 1.45,
              fontWeight: FontWeight.w700,
              color: p.ink,
            ),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          '${_index + 1} / ${_prompts.length}',
          style: TextStyle(fontSize: 12.5, color: p.inkA(0.38)),
        ),
        const SizedBox(height: 10),
        TextButton(
          onPressed: () => _finish(naturally: false),
          child: Text(
            'routes.practiceSkip'.tr(),
            style: TextStyle(fontSize: 13, color: p.inkA(0.38)),
          ),
        ),
      ],
    );
  }

  /// Orbe con capas concéntricas de alpha decreciente (sin MaskFilter.blur,
  /// que rompe WebGL en web).
  Widget _orb() {
    return SizedBox(
      width: 170,
      height: 170,
      child: Stack(
        alignment: Alignment.center,
        children: [
          for (final layer in const [
            [170.0, 0.10],
            [140.0, 0.18],
            [112.0, 0.32],
            [86.0, 0.6],
          ])
            Container(
              width: layer[0],
              height: layer[0],
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.routeColor.withValues(alpha: layer[1]),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDone() {
    final outro = widget.step.explanation;
    return Column(
      key: const ValueKey('done'),
      children: [
        const SizedBox(height: 8),
        Text(_completedNaturally ? '🌿' : '👍', style: const TextStyle(fontSize: 48))
            .animate()
            .scale(duration: 450.ms, curve: Curves.easeOutBack),
        const SizedBox(height: 10),
        Text(
          _completedNaturally
              ? 'routes.practiceDone'.tr()
              : 'routes.practiceSkipped'.tr(),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: LessonPalette.of(context).ink,
          ),
        ),
        if (outro != null) ...[
          const SizedBox(height: 16),
          StepNote(text: outro, color: const Color(0xFF22D3EE)),
        ],
      ],
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color track;

  _RingPainter({
    required this.progress,
    required this.color,
    required this.track,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2 - 6;
    final base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..color = track;
    canvas.drawCircle(center, radius, base);

    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..color = color;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      math.pi * 2 * progress,
      false,
      arc,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.color != color || old.track != track;
}
