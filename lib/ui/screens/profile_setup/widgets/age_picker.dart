import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../domain/services/sound_service.dart';
import '../../../widgets/min_tap_target.dart';

/// Rueda para elegir la edad **exacta**.
///
/// Antes eran seis botones de rango (`18-24`, `25-34`…) que se guardaban como
/// un número inventado en medio del rango, así que la edad real nunca se sabía.
///
/// La rueda no da la edad por elegida hasta que la persona la toca: si
/// devolviera el valor donde arranca, todas las cuentas que pasan de largo
/// quedarían con la misma edad y las estadísticas no valdrían nada.
class AgePicker extends StatefulWidget {
  /// Edad elegida, o null si todavía no ha tocado nada.
  final int? value;
  final ValueChanged<int> onChanged;

  static const int min = 13;
  static const int max = 99;

  /// Dónde arranca la rueda cuando aún no hay nada elegido.
  static const int _start = 20;

  const AgePicker({super.key, required this.value, required this.onChanged});

  @override
  State<AgePicker> createState() => _AgePickerState();
}

class _AgePickerState extends State<AgePicker> {
  static const double _itemExtent = 54;

  late final FixedExtentScrollController _controller =
      FixedExtentScrollController(
    initialItem: (widget.value ?? AgePicker._start) - AgePicker.min,
  );

  /// Lo que hay bajo la marca, esté confirmado o no.
  late int _centered = widget.value ?? AgePicker._start;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _confirm(int age) {
    HapticFeedback.selectionClick();
    SoundService.instance.play(Sfx.tick, volume: 0.25);
    widget.onChanged(age);
  }

  void _nudge(int delta) {
    final next = (_centered + delta).clamp(AgePicker.min, AgePicker.max);
    if (next == _centered) return;
    _controller.animateToItem(
      next - AgePicker.min,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
    );
    _confirm(next);
  }

  @override
  Widget build(BuildContext context) {
    final chosen = widget.value != null;

    return Semantics(
      label: 'profileSetup.age'.tr(),
      value: chosen ? '${widget.value}' : 'profileSetup.ageHint'.tr(),
      child: Container(
        height: 176,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: chosen ? 0.12 : 0.08),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: Colors.white.withValues(alpha: chosen ? 0.45 : 0.18),
            width: 2,
          ),
        ),
        child: Row(
          children: [
            _NudgeButton(
              icon: Icons.remove_rounded,
              label: 'profileSetup.ageLess'.tr(),
              onTap: () => _nudge(-1),
            ),
            Expanded(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Marca del centro: dónde queda la edad elegida.
                  IgnorePointer(
                    child: Container(
                      height: _itemExtent,
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: chosen ? 0.22 : 0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                  ExcludeSemantics(
                    child: ListWheelScrollView.useDelegate(
                      controller: _controller,
                      itemExtent: _itemExtent,
                      perspective: 0.003,
                      diameterRatio: 1.6,
                      overAndUnderCenterOpacity: 0.32,
                      physics: const FixedExtentScrollPhysics(),
                      onSelectedItemChanged: (index) {
                        setState(() => _centered = AgePicker.min + index);
                        _confirm(_centered);
                      },
                      childDelegate: ListWheelChildBuilderDelegate(
                        childCount: AgePicker.max - AgePicker.min + 1,
                        builder: (context, index) {
                          final age = AgePicker.min + index;
                          final isCentered = age == _centered;
                          return Center(
                            child: Text(
                              '$age',
                              style: TextStyle(
                                fontSize: isCentered ? 34 : 24,
                                fontWeight:
                                    isCentered ? FontWeight.w900 : FontWeight.w600,
                                color: Colors.white,
                                height: 1.1,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  // Tocar la marca también vale: si tu edad es justo donde
                  // arranca la rueda, no tendrías que moverla y volver.
                  Positioned.fill(
                    child: Align(
                      alignment: Alignment.center,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => _confirm(_centered),
                        child: SizedBox(height: _itemExtent, width: 110),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            _NudgeButton(
              icon: Icons.add_rounded,
              label: 'profileSetup.ageMore'.tr(),
              onTap: () => _nudge(1),
            ),
          ],
        ),
      ),
    );
  }
}

/// Un año arriba o abajo sin tener que atinarle a la rueda (y para que se
/// pueda elegir la edad sin depender de un gesto).
class _NudgeButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _NudgeButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      onTap: onTap,
      excludeSemantics: true,
      child: MinTapTarget(
        onTap: onTap,
        child: Container(
          width: 46,
          height: 46,
          margin: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.14),
            border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
          ),
          child: Icon(icon, color: Colors.white, size: 22),
        ),
      ),
    );
  }
}
