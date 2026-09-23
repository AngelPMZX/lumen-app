import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'breathing_setup.dart' show BreathIconButton;

/// Barra de arriba de la sesión: cerrar, la técnica con el tiempo que falta y
/// el ambiente que suena.
///
/// Los dos lados miden lo mismo ([slot], el área táctil mínima de un botón) y
/// el centro va en un `Expanded`: así el reloj queda **en el centro de la
/// pantalla** pase lo que pase. Antes eran dos `Spacer` entre un botón de 48
/// dp y un hueco de 38, y el reloj se veía corrido hacia un lado.
class BreathSessionBar extends StatelessWidget {
  final String techniqueName;

  /// Tiempo que falta, ya formateado (`m:ss`).
  final String timeLeft;
  final Color color;

  /// Nombre del ambiente que suena, o null si la sesión va en silencio.
  final String? soundLabel;
  final VoidCallback onClose;

  static const double slot = 48;

  const BreathSessionBar({
    super.key,
    required this.techniqueName,
    required this.timeLeft,
    required this.color,
    required this.soundLabel,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
      child: Row(
        children: [
          SizedBox(
            width: slot,
            child: Align(
              alignment: Alignment.centerLeft,
              child: BreathIconButton(
                icon: Icons.close_rounded,
                label: 'common.close'.tr(),
                onTap: onClose,
              ),
            ),
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  techniqueName,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                    color: Color.lerp(color, Colors.white, 0.45),
                  ),
                ),
                Semantics(
                  label: 'breathing.timeLeft'.tr(namedArgs: {'time': timeLeft}),
                  excludeSemantics: true,
                  child: Text(
                    timeLeft,
                    style: const TextStyle(
                      fontSize: 26,
                      height: 1.1,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: slot,
            child: soundLabel == null
                ? null
                : Align(
                    alignment: Alignment.centerRight,
                    child: BreathIconButton(
                      icon: Icons.graphic_eq_rounded,
                      label: soundLabel!,
                      onTap: () {},
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
