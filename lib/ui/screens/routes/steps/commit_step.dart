import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../data/models/wellness_route.dart';
import 'step_common.dart';

/// COMMIT — cierra la lección con un micro-reto para hoy.
///
/// Elige uno de los retos y mantén presionado el botón hasta que se llene.
/// El reto elegido se devuelve con [onCommitted] para mostrarlo al final.
class CommitStep extends StatefulWidget {
  final LessonStep step;
  final Color routeColor;
  final StepCallbacks callbacks;
  final ValueChanged<String> onCommitted;

  const CommitStep({
    super.key,
    required this.step,
    required this.routeColor,
    required this.callbacks,
    required this.onCommitted,
  });

  @override
  State<CommitStep> createState() => _CommitStepState();
}

class _CommitStepState extends State<CommitStep>
    with SingleTickerProviderStateMixin {
  static const _accent = Color(0xFFFBBF24);

  late final AnimationController _hold;
  int? _choice;
  bool _committed = false;

  List<String> get _options => widget.step.options ?? const [];

  @override
  void initState() {
    super.initState();
    // Un solo reto: queda elegido de entrada.
    if (_options.length == 1) _choice = 0;
    _hold = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    )..addStatusListener((s) {
        if (s == AnimationStatus.completed) _commit();
      });
  }

  @override
  void dispose() {
    _hold.dispose();
    super.dispose();
  }

  void _commit() {
    if (_committed || _choice == null) return;
    HapticFeedback.heavyImpact();
    setState(() => _committed = true);
    widget.onCommitted(_options[_choice!]);
    widget.callbacks.onReflect(5);
    widget.callbacks.onReady();
  }

  void _startHold() {
    if (_committed || _choice == null) return;
    HapticFeedback.lightImpact();
    _hold.forward();
  }

  void _cancelHold() {
    if (_committed) return;
    _hold.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        StepChip(
          icon: Icons.flag_rounded,
          label: 'routes.commitLabel'.tr(),
          color: _accent,
        ),
        const SizedBox(height: 16),
        StepHeading(text: widget.step.title, glow: widget.routeColor),
        const SizedBox(height: 10),
        Text(
          widget.step.content ?? '',
          style: TextStyle(
            fontSize: 15,
            height: 1.65,
            color: Colors.white.withValues(alpha: 0.8),
          ),
        ),
        const SizedBox(height: 18),
        ...List.generate(_options.length, (i) {
          final chosen = _choice == i;
          final locked = _committed && !chosen;
          return Padding(
            padding: const EdgeInsets.only(bottom: 9),
            child: GestureDetector(
              onTap: _committed
                  ? null
                  : () {
                      HapticFeedback.selectionClick();
                      _hold.reset();
                      setState(() => _choice = i);
                    },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 240),
                width: double.infinity,
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: chosen
                      ? _accent.withValues(alpha: 0.16)
                      : Colors.white.withValues(alpha: locked ? 0.02 : 0.06),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: chosen
                        ? _accent
                        : Colors.white.withValues(alpha: locked ? 0.05 : 0.13),
                    width: chosen ? 1.8 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      chosen
                          ? Icons.radio_button_checked_rounded
                          : Icons.radio_button_off_rounded,
                      size: 20,
                      color: chosen ? _accent : Colors.white38,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _options[i],
                        style: TextStyle(
                          fontSize: 14.5,
                          height: 1.4,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withValues(alpha: locked ? 0.35 : 1),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
        const SizedBox(height: 14),
        Center(child: _committed ? _buildCommitted() : _buildHoldButton()),
      ],
    );
  }

  Widget _buildHoldButton() {
    final enabled = _choice != null;
    return GestureDetector(
      onTapDown: (_) => _startHold(),
      onTapUp: (_) => _cancelHold(),
      onTapCancel: _cancelHold,
      child: AnimatedBuilder(
        animation: _hold,
        builder: (context, _) {
          return Container(
            width: double.infinity,
            height: 58,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: _accent.withValues(alpha: enabled ? 0.14 : 0.05),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: _accent.withValues(alpha: enabled ? 0.7 : 0.2),
                width: 1.5,
              ),
            ),
            child: Stack(
              children: [
                // Relleno que avanza mientras se mantiene presionado
                FractionallySizedBox(
                  widthFactor: _hold.value,
                  heightFactor: 1,
                  child: Container(color: _accent.withValues(alpha: 0.55)),
                ),
                Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.fingerprint_rounded,
                        size: 22,
                        color: Colors.white.withValues(alpha: enabled ? 1 : 0.35),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        enabled
                            ? 'routes.commitHold'.tr()
                            : 'routes.commitChooseFirst'.tr(),
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Colors.white.withValues(alpha: enabled ? 1 : 0.4),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCommitted() {
    return Column(
      children: [
        const Text('🤝', style: TextStyle(fontSize: 42))
            .animate()
            .scale(duration: 450.ms, curve: Curves.easeOutBack),
        const SizedBox(height: 8),
        Text(
          'routes.commitDone'.tr(),
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}
