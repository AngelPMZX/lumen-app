import 'package:flutter/material.dart';

/// Recorta a los lados y deja respirar arriba y abajo.
///
/// Las listas que se deslizan en horizontal llevan `clipBehavior: Clip.none`
/// para que la sombra o el brillo de la tarjeta elegida no se corten. El
/// precio era que, al deslizarlas, las tarjetas se seguían pintando **fuera de
/// su recuadro** y quedaban encima del borde de la tarjeta que las contiene —
/// que es justo lo que se veía mal en el check-in de ánimo.
///
/// Esto recorta solo en los bordes izquierdo y derecho: las tarjetas aparecen
/// y desaparecen donde deben, y la sombra sigue saliendo por arriba y por
/// abajo como antes.
///
/// Se pone **por fuera** de la lista, que conserva su `Clip.none`.
class ClipSideways extends StatelessWidget {
  final Widget child;

  /// Cuánto se deja salir por arriba y por abajo (para sombras y destellos).
  final double margin;

  const ClipSideways({super.key, required this.child, this.margin = 60});

  @override
  Widget build(BuildContext context) =>
      ClipRect(clipper: _SidewaysClipper(margin), child: child);
}

class _SidewaysClipper extends CustomClipper<Rect> {
  final double margin;

  const _SidewaysClipper(this.margin);

  @override
  Rect getClip(Size size) =>
      Rect.fromLTRB(0, -margin, size.width, size.height + margin);

  @override
  bool shouldReclip(_SidewaysClipper old) => old.margin != margin;
}
