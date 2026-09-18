import 'package:flutter/widgets.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../domain/services/motion_service.dart';

/// Entradas escalonadas que **solo corren al abrir la pantalla**.
///
/// El problema que resuelve: en una lista perezosa (`SliverList.builder`,
/// `SliverGrid`, `ListView.builder`) los elementos se construyen cuando entran
/// a la vista, no al abrir la pantalla. Si cada uno se anima con un retraso
/// `60 ms × índice`, al bajar rápido el elemento 15 espera casi un segundo
/// antes de aparecer: se ve como si la app estuviera cargando, aunque los
/// datos ya estén ahí. Lo mismo al volver a subir, porque la lista descarta y
/// vuelve a crear lo que sale de pantalla.
///
/// [EntranceScope] guarda el momento en que la lista apareció. [ListEntrance]
/// le resta el tiempo ya transcurrido al retraso y, si el elemento se
/// construyó después de la entrada (al desplazarse), lo muestra de inmediato.
/// Se ve igual al abrir la pantalla, sin huecos en blanco al desplazarse.
class EntranceScope extends StatefulWidget {
  /// Al cambiar este valor la entrada vuelve a correr (p. ej. al cambiar de
  /// filtro, cuando la lista se rehace y sí queremos volver a escalonarla).
  final Object? restartOn;

  final Widget child;

  const EntranceScope({super.key, this.restartOn, required this.child});

  /// Reloj de pared. Solo las pruebas lo reemplazan.
  @visibleForTesting
  static DateTime Function() clock = DateTime.now;

  /// Retraso para el elemento [index], o `null` si ya pasó la entrada y hay
  /// que mostrarlo de inmediato.
  ///
  /// Sin un [EntranceScope] arriba (columnas cortas que se construyen enteras)
  /// se comporta como siempre, con un tope de [maxStagger] escalones.
  static Duration? delayFor(
    BuildContext context,
    int index, {
    Duration step = const Duration(milliseconds: 60),
    Duration base = Duration.zero,
    Duration grace = const Duration(milliseconds: 260),
    int maxStagger = 8,
  }) {
    final target = base + step * index;
    final marker = _EntranceMarker.of(context);
    if (marker == null) return base + step * (index.clamp(0, maxStagger));

    final elapsed = EntranceScope.clock().difference(marker.start);
    if (elapsed > target + grace) return null;
    final remaining = target - elapsed;
    return remaining.isNegative ? Duration.zero : remaining;
  }

  /// ¿La pantalla acaba de abrirse? Para animaciones de una sola vez que no
  /// dependen de un índice (anillos que se llenan, contadores que suben).
  static bool fresh(
    BuildContext context, {
    Duration within = const Duration(milliseconds: 900),
  }) {
    final marker = _EntranceMarker.of(context);
    if (marker == null) return true;
    return EntranceScope.clock().difference(marker.start) <= within;
  }

  @override
  State<EntranceScope> createState() => _EntranceScopeState();
}

class _EntranceScopeState extends State<EntranceScope> {
  DateTime _start = EntranceScope.clock();

  @override
  void didUpdateWidget(EntranceScope oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.restartOn != oldWidget.restartOn) {
      _start = EntranceScope.clock();
    }
  }

  @override
  Widget build(BuildContext context) =>
      _EntranceMarker(start: _start, child: widget.child);
}

class _EntranceMarker extends InheritedWidget {
  final DateTime start;

  const _EntranceMarker({required this.start, required super.child});

  static _EntranceMarker? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_EntranceMarker>();

  @override
  bool updateShouldNotify(_EntranceMarker old) => old.start != start;
}

/// Un elemento de lista que entra escalonado al abrir la pantalla y aparece
/// de inmediato si se construyó después (al desplazarse). Ver [EntranceScope].
class ListEntrance extends StatelessWidget {
  final int index;
  final Widget child;

  /// Cuánto separa a un elemento del siguiente.
  final Duration step;

  /// Retraso antes del primer elemento.
  final Duration base;
  final Duration duration;

  /// Desplazamientos de entrada (fracción del alto/ancho del elemento).
  final double slideY;
  final double slideX;

  /// Si no es null, además entra creciendo desde esta escala.
  final double? scaleFrom;

  final Curve curve;

  /// Curva del `scale` cuando quiere rebotar (`easeOutBack`) aunque el
  /// desplazamiento no lo haga.
  final Curve? scaleCurve;

  const ListEntrance({
    super.key,
    required this.index,
    required this.child,
    this.step = const Duration(milliseconds: 60),
    this.base = Duration.zero,
    this.duration = const Duration(milliseconds: 350),
    this.slideY = 0,
    this.slideX = 0,
    this.scaleFrom,
    this.curve = Curves.easeOutCubic,
    this.scaleCurve,
  });

  @override
  Widget build(BuildContext context) {
    // La tolerancia cubre la animación entera: si algo hace reconstruir la
    // lista a media entrada, el elemento la termina en vez de saltar a su
    // sitio de golpe.
    final delay = EntranceScope.delayFor(
      context,
      index,
      step: step,
      base: base,
      grace: duration + const Duration(milliseconds: 160),
    );
    if (delay == null) return child;

    // El primer efecto lleva delay y duration; los demás los heredan
    // (comportamiento de flutter_animate), como en el resto de la app.
    var animation = child.animate().fadeIn(delay: delay, duration: duration);
    if (slideY != 0) {
      animation = animation.slideY(begin: slideY, end: 0, curve: curve);
    }
    if (slideX != 0) {
      animation = animation.slideX(begin: slideX, end: 0, curve: curve);
    }
    final scale = scaleFrom;
    if (scale != null) {
      animation = animation.scale(
        begin: Offset(scale, scale),
        end: const Offset(1, 1),
        curve: scaleCurve ?? curve,
      );
    }
    return animation;
  }
}

/// Un elemento suelto que entra al abrir la pantalla: encabezados, tarjetas
/// fijas, secciones. Mismo criterio que [ListEntrance] —del que es azúcar—:
/// si la lista lo descartó al desplazarse y lo vuelve a crear, aparece de
/// inmediato en vez de repetir su entrada.
class Entrance extends StatelessWidget {
  final Widget child;
  final Duration delay;
  final Duration duration;
  final double slideY;
  final double slideX;
  final double? scaleFrom;
  final Curve curve;
  final Curve? scaleCurve;

  const Entrance({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 350),
    this.slideY = 0,
    this.slideX = 0,
    this.scaleFrom,
    this.curve = Curves.easeOutCubic,
    this.scaleCurve,
  });

  @override
  Widget build(BuildContext context) => ListEntrance(
        index: 0,
        base: delay,
        duration: duration,
        slideY: slideY,
        slideX: slideX,
        scaleFrom: scaleFrom,
        curve: curve,
        scaleCurve: scaleCurve,
        child: child,
      );
}

/// Valor de partida de un `TweenAnimationBuilder` que se llena o sube contando
/// (anillos de progreso, barras de XP, contadores del perfil).
///
/// Al abrir la pantalla arranca en 0 y se llena, como siempre. Si el widget se
/// creó de nuevo solo porque la lista lo descartó al desplazarse, arranca ya en
/// su valor: antes el contador volvía a empezar desde 0 cada vez que subías o
/// bajabas, y se veía como si la app estuviera recargando.
///
/// Ojo con la diferencia: esto es el **punto de partida**, no la duración. Si
/// el valor cambia de verdad —ganaste XP, completaste una lección— el widget ya
/// existe y su animación corre igual de bien.
double entranceFrom(
  BuildContext context,
  double end, {
  Duration within = const Duration(milliseconds: 1400),
}) {
  if (MotionService.reduced(context)) return end;
  return EntranceScope.fresh(context, within: within) ? 0 : end;
}

/// Duración de esa misma animación, respetando "Reducir animaciones".
Duration entranceDuration(BuildContext context, Duration duration) =>
    MotionService.reduced(context) ? Duration.zero : duration;
