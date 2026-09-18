import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/services/motion_service.dart';

/// Suaviza el cambio entre el modo claro y el oscuro.
///
/// Flutter interpola el `ThemeData`, pero media app decide sus colores con un
/// `brightness == Brightness.dark`, y eso salta de golpe: pasabas de una
/// pantalla clara a una oscura (o al revés) en un cuadro, y de noche eso
/// deslumbra.
///
/// Aquí se deja el fondo **del tema anterior** encima de todo y se desvanece:
/// la luz cambia poco a poco en vez de dar un salto. No toca nada del diseño,
/// solo cómo se llega a él.
///
/// [brightness] viene de arriba (del `ThemeProvider`) a propósito: dentro del
/// `MaterialApp` el tema se interpola durante 200 ms y su `brightness` cambia
/// a mitad de camino, así que el velo llegaría tarde y se vería un destello.
///
/// Con "Reducir animaciones" el cambio es instantáneo, como antes.
class ThemeFade extends StatefulWidget {
  final Brightness brightness;
  final Widget child;

  /// Cuánto dura el desvanecido.
  final Duration duration;

  const ThemeFade({
    super.key,
    required this.brightness,
    required this.child,
    this.duration = const Duration(milliseconds: 450),
  });

  @override
  State<ThemeFade> createState() => _ThemeFadeState();
}

class _ThemeFadeState extends State<ThemeFade>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fade = AnimationController(
    vsync: this,
    duration: widget.duration,
  );

  late final Animation<double> _opacity = Tween<double>(begin: 1, end: 0)
      .animate(CurvedAnimation(parent: _fade, curve: Curves.easeInOut));

  /// El fondo que se está desvaneciendo (el del tema que acaba de salir).
  Color? _veil;

  static Color _backgroundOf(Brightness brightness) =>
      brightness == Brightness.dark
          ? AppTheme.darkTheme.scaffoldBackgroundColor
          : AppTheme.lightTheme.scaffoldBackgroundColor;

  @override
  void initState() {
    super.initState();
    _fade.addStatusListener((status) {
      // Al terminar se quita el velo: nada de una capa de más para siempre.
      if (status == AnimationStatus.completed && mounted) {
        setState(() => _veil = null);
      }
    });
  }

  @override
  void didUpdateWidget(ThemeFade old) {
    super.didUpdateWidget(old);
    if (old.brightness == widget.brightness) return;
    if (MotionService.reduced(context)) return;
    setState(() => _veil = _backgroundOf(old.brightness));
    _fade.forward(from: 0);
  }

  @override
  void dispose() {
    _fade.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final veil = _veil;
    if (veil == null) return widget.child;

    return Stack(
      children: [
        widget.child,
        Positioned.fill(
          child: IgnorePointer(
            child: RepaintBoundary(
              child: FadeTransition(
                opacity: _opacity,
                child: ColoredBox(color: veil),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
