import 'package:flutter/material.dart';

/// Amplía el área táctil a 48×48 dp (mínimo de accesibilidad de Android) sin
/// cambiar el tamaño visible del botón.
class MinTapTarget extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;

  const MinTapTarget({super.key, required this.child, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
        child: Center(widthFactor: 1, heightFactor: 1, child: child),
      ),
    );
  }
}
