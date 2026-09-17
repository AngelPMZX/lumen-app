import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Preferencia "Reducir animaciones". Singleton.
///
/// Se suma a la opción del sistema (Android: "Quitar animaciones"). `app.dart`
/// la inyecta en `MediaQuery.disableAnimations`, así que dentro de la app la
/// fuente única es [MotionService.reduced]. Qué se apaga: bucles (flotar,
/// latir, estrellas, destellos), sacudidas y confeti. Las transiciones cortas
/// de entrada se quedan porque orientan sin marear.
class MotionService extends ChangeNotifier {
  MotionService._();
  static final MotionService instance = MotionService._();

  static const _pref = 'reduce_motion';

  bool _userReduce = false;

  /// Lo que eligió el usuario en Perfil (sin contar el sistema).
  bool get userReduce => _userReduce;

  /// Sin contexto (p. ej. en `initState`): preferencia o sistema.
  bool get reducedNow =>
      _userReduce ||
      PlatformDispatcher.instance.accessibilityFeatures.disableAnimations;

  Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _userReduce = prefs.getBool(_pref) ?? false;
    } catch (e) {
      debugPrint('MotionService prefs error: $e');
    }
  }

  Future<void> setReduceMotion(bool value) async {
    _userReduce = value;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_pref, value);
    } catch (e) {
      debugPrint('MotionService prefs error: $e');
    }
  }

  /// ¿Hay que reducir animaciones en esta parte del árbol?
  static bool reduced(BuildContext context) =>
      MediaQuery.maybeDisableAnimationsOf(context) ?? instance.reducedNow;

  /// `onPlay` para bucles de flutter_animate: repite, salvo con movimiento
  /// reducido (se queda en el estado inicial, que es el de reposo).
  static void Function(AnimationController) loop(
    BuildContext context, {
    bool reverse = false,
  }) {
    final still = reduced(context);
    return (c) => still ? c.stop() : c.repeat(reverse: reverse);
  }
}

/// Bucles con `AnimationController` (fondos, halos, pulsos).
extension MotionAwareController on AnimationController {
  /// Repite en bucle, salvo con movimiento reducido: entonces se queda quieto
  /// en [rest] (0 = estado inicial). Se decide al crear la pantalla.
  void repeatUnlessReduced({bool reverse = false, double rest = 0}) {
    if (MotionService.instance.reducedNow) {
      value = rest;
    } else {
      repeat(reverse: reverse);
    }
  }
}
