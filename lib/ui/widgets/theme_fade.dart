import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../domain/services/motion_service.dart';

/// Atardecer entre el modo claro y el oscuro.
///
/// Flutter interpola el `ThemeData`, pero media app decide sus colores con un
/// `brightness == Brightness.dark`, y eso salta en un cuadro: de noche,
/// deslumbra.
///
/// Lo que hace: justo antes de que se pinte el tema nuevo, saca una **foto de
/// la pantalla tal y como estaba** ([RenderRepaintBoundary.toImageSync], que
/// devuelve la capa ya pintada del cuadro anterior) y la deja encima
/// desvaneciéndose. Debajo ya está la pantalla nueva, así que lo que se ve es
/// un fundido de la misma escena de día a la misma escena de noche.
///
/// Un primer intento usó un color plano en vez de la foto, y eso **era** el
/// destello: el home pinta degradados, así que el velo liso ya no coincidía
/// con lo que había en pantalla.
///
/// [brightness] viene de arriba (del `ThemeProvider`) a propósito: dentro del
/// `MaterialApp` el tema se interpola durante 200 ms y su `brightness` cambia
/// a mitad de camino, así que la foto se tomaría tarde.
///
/// Con "Reducir animaciones" el cambio es instantáneo, como antes.
class ThemeFade extends StatefulWidget {
  final Brightness brightness;
  final Widget child;

  /// Cuánto dura el atardecer.
  final Duration duration;

  const ThemeFade({
    super.key,
    required this.brightness,
    required this.child,
    this.duration = const Duration(milliseconds: 700),
  });

  @override
  State<ThemeFade> createState() => _ThemeFadeState();
}

class _ThemeFadeState extends State<ThemeFade>
    with SingleTickerProviderStateMixin {
  final GlobalKey _boundaryKey = GlobalKey();

  late final AnimationController _fade = AnimationController(
    vsync: this,
    duration: widget.duration,
  );

  /// Se queda opaca un momento y luego baja: da tiempo a que el tema nuevo se
  /// asiente debajo, y el cambio de luz se siente como una puesta de sol en
  /// vez de un interruptor.
  late final Animation<double> _opacity = CurvedAnimation(
    parent: _fade,
    curve: const Interval(0.12, 1, curve: Curves.easeInOutSine),
  ).drive(Tween<double>(begin: 1, end: 0));

  ui.Image? _snapshot;
  double _snapshotScale = 1;

  @override
  void initState() {
    super.initState();
    _fade.addStatusListener((status) {
      if (status == AnimationStatus.completed) _clearSnapshot();
    });
  }

  void _clearSnapshot() {
    if (_snapshot == null) return;
    final image = _snapshot;
    _snapshot = null;
    // Una captura a pantalla completa ocupa varios MB: se suelta en cuanto
    // deja de verse.
    WidgetsBinding.instance.addPostFrameCallback((_) => image?.dispose());
    if (mounted) setState(() {});
  }

  @override
  void didUpdateWidget(ThemeFade old) {
    super.didUpdateWidget(old);
    if (old.brightness == widget.brightness) return;
    if (MotionService.reduced(context)) return;

    final captured = _capture();
    if (!captured) return;
    _fade.forward(from: 0);
  }

  /// La foto se toma durante la reconstrucción, **antes** de pintar: el
  /// `RepaintBoundary` todavía guarda la capa del cuadro anterior, que es
  /// justo la pantalla con el tema viejo.
  bool _capture() {
    try {
      final object = _boundaryKey.currentContext?.findRenderObject();
      if (object is! RenderRepaintBoundary) return false;
      // Techo al detalle: en un teléfono 3x una captura entera son ~10 MB.
      final scale =
          math.min(MediaQuery.devicePixelRatioOf(context), 2.0).toDouble();
      final image = object.toImageSync(pixelRatio: scale);
      _snapshot?.dispose();
      setState(() {
        _snapshot = image;
        _snapshotScale = scale;
      });
      return true;
    } catch (e) {
      // Si todavía no se ha pintado nada (primer cuadro) no hay foto que
      // tomar: el cambio es instantáneo y ya está.
      debugPrint('ThemeFade: sin captura ($e)');
      return false;
    }
  }

  @override
  void dispose() {
    _fade.dispose();
    _snapshot?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final snapshot = _snapshot;
    return Stack(
      children: [
        RepaintBoundary(key: _boundaryKey, child: widget.child),
        if (snapshot != null)
          Positioned.fill(
            child: IgnorePointer(
              child: RepaintBoundary(
                child: FadeTransition(
                  opacity: _opacity,
                  child: RawImage(
                    image: snapshot,
                    scale: _snapshotScale,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
