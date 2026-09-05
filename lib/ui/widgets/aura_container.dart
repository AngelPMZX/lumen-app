import 'package:flutter/material.dart';
import '../../data/models/garden_item.dart';

/// Envuelve cualquier widget de item con un glow/aura de su color y
/// intensidad. Se usa en tienda, inventario y jardín para dar personalidad
/// visual a plantas, decoraciones y boosters.
class AuraContainer extends StatelessWidget {
  final GardenItem item;
  final Widget child;
  final double sizeMultiplier;

  const AuraContainer({
    super.key,
    required this.item,
    required this.child,
    this.sizeMultiplier = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: item.auraColor.withValues(alpha: item.auraOpacity),
            blurRadius: item.auraBlurRadius * sizeMultiplier,
            spreadRadius: item.auraBlurRadius * 0.2 * sizeMultiplier,
          ),
        ],
      ),
      child: child,
    );
  }
}