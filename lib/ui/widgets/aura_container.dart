import 'package:flutter/material.dart';
import '../../data/models/garden_item.dart';
import '../../domain/services/motion_service.dart';

/// Envuelve cualquier widget de item con un glow/aura de su color y
/// intensidad. Se usa en tienda, inventario y jardín para dar personalidad
/// visual a plantas, decoraciones y boosters.
///
/// Con [pulse] el aura respira despacio (las piezas épicas, legendarias y de
/// temporada lo usan). Con movimiento reducido se queda quieta.
class AuraContainer extends StatefulWidget {
  final GardenItem item;
  final Widget child;
  final double sizeMultiplier;
  final bool pulse;

  const AuraContainer({
    super.key,
    required this.item,
    required this.child,
    this.sizeMultiplier = 1.0,
    this.pulse = false,
  });

  /// ¿Esta rareza merece un aura que respira?
  static bool pulsesFor(ItemRarity rarity) =>
      rarity == ItemRarity.epic || rarity == ItemRarity.legendary || rarity == ItemRarity.seasonal;

  @override
  State<AuraContainer> createState() => _AuraContainerState();
}

class _AuraContainerState extends State<AuraContainer> with SingleTickerProviderStateMixin {
  AnimationController? _ctrl;

  @override
  void initState() {
    super.initState();
    _sync();
  }

  @override
  void didUpdateWidget(AuraContainer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pulse != widget.pulse) _sync();
  }

  void _sync() {
    if (widget.pulse && _ctrl == null) {
      _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2400))
        ..repeatUnlessReduced(reverse: true, rest: 0.5);
    } else if (!widget.pulse && _ctrl != null) {
      _ctrl!.dispose();
      _ctrl = null;
    }
  }

  @override
  void dispose() {
    _ctrl?.dispose();
    super.dispose();
  }

  /// Resplandor suave: un degradado radial del color del item que se
  /// desvanece hacia afuera (sin blur, seguro en web). t = 0.5 es el aura en
  /// reposo; el pulso oscila alrededor.
  Widget _glow(double t, Widget child) {
    final item = widget.item;
    final m = widget.sizeMultiplier;
    final extent = item.auraBlurRadius * m * (1.1 + t * 0.35);
    final opacity = (item.auraOpacity * (1.15 + t * 0.6) + 0.04).clamp(0.0, 1.0);
    final color = item.auraColor;
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        Positioned(
          left: -extent,
          top: -extent,
          right: -extent,
          bottom: -extent,
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    color.withValues(alpha: opacity),
                    color.withValues(alpha: opacity * 0.75),
                    color.withValues(alpha: opacity * 0.3),
                    color.withValues(alpha: 0),
                  ],
                  stops: const [0, 0.4, 0.72, 1],
                ),
              ),
            ),
          ),
        ),
        child,
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = _ctrl;
    if (ctrl == null) return _glow(0.5, widget.child);
    return AnimatedBuilder(
      animation: ctrl,
      child: widget.child,
      builder: (_, child) => _glow(Curves.easeInOut.transform(ctrl.value), child!),
    );
  }
}
