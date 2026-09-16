import 'dart:math' as math;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../data/models/wellness_route.dart';
import 'step_common.dart';
import '../../../../domain/services/sound_service.dart';

/// ORDER — tocar los pasos de un proceso en el orden correcto.
///
/// [LessonStep.items] llega ya ordenado; aquí se desordena. Un toque en el
/// paso equivocado no lo coloca: sacude la tarjeta y rompe la racha.
class OrderStep extends StatefulWidget {
  final LessonStep step;
  final Color routeColor;
  final StepCallbacks callbacks;

  const OrderStep({
    super.key,
    required this.step,
    required this.routeColor,
    required this.callbacks,
  });

  @override
  State<OrderStep> createState() => _OrderStepState();
}

class _OrderStepState extends State<OrderStep> {
  static const _accent = Color(0xFF14B8A6);

  late final List<int> _shuffled;
  int _placed = 0;
  int? _wrongIndex;
  int _mistakes = 0;

  List<String> get _items => widget.step.items ?? const [];
  bool get _finished => _items.isNotEmpty && _placed >= _items.length;

  @override
  void initState() {
    super.initState();
    _shuffled = List.generate(_items.length, (i) => i);
    // Semilla por contenido: no se reordena en cada rebuild.
    _shuffled.shuffle(math.Random(_items.join('|').hashCode));
    // Si quedó justo en orden, rotar para que no sea trivial.
    var inOrder = true;
    for (int i = 0; i < _shuffled.length; i++) {
      if (_shuffled[i] != i) {
        inOrder = false;
        break;
      }
    }
    if (inOrder && _shuffled.length > 1) {
      _shuffled.add(_shuffled.removeAt(0));
    }
  }

  void _tap(int itemIndex) {
    if (_finished) return;
    if (itemIndex == _placed) {
      HapticFeedback.lightImpact();
      // Cada acierto es la siguiente nota de la escala: se arma una melodía.
      SoundService.instance.note(_placed);
      setState(() {
        _placed++;
        _wrongIndex = null;
      });
      widget.callbacks.onAnswer(true, 2, sound: false);
      if (_finished) widget.callbacks.onReady();
    } else {
      HapticFeedback.heavyImpact();
      setState(() {
        _wrongIndex = itemIndex;
        _mistakes++;
      });
      widget.callbacks.onAnswer(false, 0);
      Future.delayed(const Duration(milliseconds: 450), () {
        if (mounted && _wrongIndex == itemIndex) {
          setState(() => _wrongIndex = null);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        StepChip(
          icon: Icons.format_list_numbered_rounded,
          label: 'routes.orderLabel'.tr(),
          color: _accent,
        ),
        const SizedBox(height: 16),
        StepHeading(text: widget.step.title, glow: widget.routeColor, fontSize: 23),
        const SizedBox(height: 10),
        Text(
          widget.step.instruction ?? '',
          style: TextStyle(
            fontSize: 14.5,
            height: 1.6,
            color: Colors.white.withValues(alpha: 0.72),
          ),
        ),
        const SizedBox(height: 18),

        // Pasos ya colocados, numerados
        for (int i = 0; i < _placed; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _placedTile(i),
          ),

        if (!_finished) ...[
          if (_placed > 0) const SizedBox(height: 6),
          Text(
            'routes.orderNext'.tr(namedArgs: {'n': '${_placed + 1}'}),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
              color: Colors.white38,
            ),
          ),
          const SizedBox(height: 10),
          for (final i in _shuffled)
            if (i >= _placed)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _poolTile(i),
              ),
        ],

        if (_finished) ...[
          const SizedBox(height: 8),
          StepNote(
            text: [
              _mistakes == 0
                  ? 'routes.orderPerfect'.tr()
                  : 'routes.orderMistakes'.tr(namedArgs: {'n': '$_mistakes'}),
              if (widget.step.explanation != null) widget.step.explanation!,
            ].join('\n\n'),
            color: const Color(0xFF10B981),
            icon: Icons.check_circle_rounded,
          ),
        ],
      ],
    );
  }

  Widget _placedTile(int i) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF10B981).withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: const BoxDecoration(
              color: Color(0xFF10B981),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '${i + 1}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _items[i],
              style: const TextStyle(
                fontSize: 14.5,
                height: 1.4,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    ).animate(key: ValueKey('placed_$i')).fadeIn(duration: 250.ms).slideY(
          begin: 0.3,
          end: 0,
          curve: Curves.easeOutBack,
        );
  }

  Widget _poolTile(int i) {
    final wrong = _wrongIndex == i;
    final tile = GestureDetector(
      onTap: () => _tap(i),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: wrong
              ? const Color(0xFFEF4444).withValues(alpha: 0.18)
              : Colors.white.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: wrong
                ? const Color(0xFFEF4444)
                : Colors.white.withValues(alpha: 0.14),
            width: wrong ? 1.8 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.radio_button_unchecked_rounded,
                size: 18, color: Colors.white.withValues(alpha: 0.4)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _items[i],
                style: const TextStyle(
                  fontSize: 14.5,
                  height: 1.4,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );

    if (!wrong) return tile;
    return tile
        .animate(key: ValueKey('shake_${i}_$_mistakes'))
        .shakeX(hz: 6, amount: 5, duration: 380.ms);
  }
}
