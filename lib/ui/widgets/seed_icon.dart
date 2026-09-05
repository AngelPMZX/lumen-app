import 'package:flutter/material.dart';

/// Icono reutilizable de las "Semillas de Luz" (moneda del jardín).
///
/// - [size]: tamaño del icono en píxeles lógicos.
/// - [animated]: activa un pulse+float sutil (para popups de recompensa).
/// - [withGlow]: agrega un glow dorado sutil de fondo (default true).
/// - Fallback automático al emoji ✨ si el asset no carga.
///
/// Usa el asset: assets/images/currency/seed.png
class SeedIcon extends StatefulWidget {
  final double size;
  final bool animated;
  final bool withGlow;

  const SeedIcon({
    super.key,
    this.size = 20,
    this.animated = false,
    this.withGlow = true,
  });

  @override
  State<SeedIcon> createState() => _SeedIconState();
}

class _SeedIconState extends State<SeedIcon>
    with SingleTickerProviderStateMixin {
  AnimationController? _controller;

  @override
  void initState() {
    super.initState();
    if (widget.animated) {
      _controller = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1600),
      )..repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant SeedIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animated && _controller == null) {
      _controller = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1600),
      )..repeat(reverse: true);
    } else if (!widget.animated && _controller != null) {
      _controller?.dispose();
      _controller = null;
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final img = Image.asset(
      'assets/images/currency/seed.png',
      width: widget.size,
      height: widget.size,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => Text(
        '✨',
        style: TextStyle(fontSize: widget.size * 0.9),
      ),
    );

    // Envolver con glow sutil dorado (opcional)
    final Widget core = widget.withGlow
        ? Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFBBF24).withValues(alpha: 0.35),
                  blurRadius: widget.size * 0.5,
                  spreadRadius: widget.size * 0.05,
                ),
              ],
            ),
            child: img,
          )
        : img;

    if (!widget.animated || _controller == null) return core;

    return AnimatedBuilder(
      animation: _controller!,
      builder: (context, child) {
        final scale = 1.0 + _controller!.value * 0.12;
        final offsetY = -3 * _controller!.value;
        return Transform.translate(
          offset: Offset(0, offsetY),
          child: Transform.scale(
            scale: scale,
            child: child,
          ),
        );
      },
      child: core,
    );
  }
}