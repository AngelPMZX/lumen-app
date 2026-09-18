import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Los colores entre los que elegir para un hábito.
///
/// Va en un `Wrap` y no en un `Row`: ocho círculos en una sola fila no caben
/// en una pantalla estrecha y se desbordaban por la derecha (la franja negra y
/// amarilla de "RIGHT OVERFLOWED BY 26 PIXELS"). Cada color ocupa siempre un
/// hueco de [_slot], así que elegir uno tampoco recoloca a los demás.
class HabitColorPicker extends StatelessWidget {
  final List<Color> colors;
  final Color selected;
  final ValueChanged<Color> onSelected;

  /// Lo que mide el círculo elegido, y el hueco que ocupan todos.
  static const double _slot = 38;

  /// Lo que mide un círculo sin elegir.
  static const double _small = 30;

  const HabitColorPicker({
    super.key,
    required this.colors,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: colors.map((color) {
        final isSelected = selected == color;
        return Semantics(
          button: true,
          selected: isSelected,
          inMutuallyExclusiveGroup: true,
          label: 'habits.habitColor'.tr(),
          excludeSemantics: true,
          child: GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              onSelected(color);
            },
            child: SizedBox(
              width: _slot,
              height: _slot,
              child: Center(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: isSelected ? _slot : _small,
                  height: isSelected ? _slot : _small,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: isSelected
                        ? Border.all(color: Colors.white, width: 3)
                        : null,
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: color.withValues(alpha: 0.4),
                              blurRadius: 10,
                              spreadRadius: 1,
                            ),
                          ]
                        : [],
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
