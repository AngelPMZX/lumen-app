import 'package:flutter/material.dart';

/// Colores de la pantalla de lección según el tema.
///
/// En oscuro la lección es un cielo nocturno y todo es blanco con alpha; en
/// claro es un amanecer suave y el texto pasa a tinta oscura. Los pasos no
/// usan `Colors.white` directo: piden aquí el color según su función.
class LessonPalette {
  final bool isDark;
  final Color route;

  const LessonPalette({required this.isDark, required this.route});

  static const _lightInk = Color(0xFF1F1B3A);

  /// Texto principal.
  Color get ink => isDark ? Colors.white : _lightInk;

  /// Texto secundario. En claro sube el alpha: la tinta tenue sobre fondo
  /// claro se lee peor que el blanco tenue sobre fondo oscuro.
  Color inkA(double a) {
    if (a >= 1) return ink;
    return ink.withValues(alpha: isDark ? a : 0.35 + a * 0.65);
  }

  /// Relleno de tarjetas y opciones (en oscuro, blanco casi transparente).
  Color card(double a) => isDark
      ? Colors.white.withValues(alpha: a)
      : Colors.white.withValues(alpha: (0.55 + a * 2.5).clamp(0.0, 0.95));

  /// Bordes y separadores.
  Color line(double a) => isDark
      ? Colors.white.withValues(alpha: a)
      : _lightInk.withValues(alpha: a * 0.8);

  /// Un color de acento usado como texto o icono: en claro se oscurece para
  /// mantener el contraste (el ámbar puro casi no se lee sobre blanco).
  Color accent(Color c) => isDark ? c : Color.lerp(c, Colors.black, 0.3)!;

  /// Resplandor de títulos: solo tiene sentido de noche.
  List<Shadow>? glow(Color c) =>
      isDark ? [Shadow(color: c.withValues(alpha: 0.5), blurRadius: 14)] : null;

  /// Sombra suave de tarjetas en claro (en oscuro no hace falta).
  List<BoxShadow>? get cardShadow => isDark
      ? null
      : [
          BoxShadow(
            color: _lightInk.withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ];

  static LessonPalette of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<LessonPaletteScope>();
    if (scope != null) return scope.palette;
    final theme = Theme.of(context);
    return LessonPalette(
      isDark: theme.brightness == Brightness.dark,
      route: theme.colorScheme.primary,
    );
  }
}

class LessonPaletteScope extends InheritedWidget {
  final LessonPalette palette;

  const LessonPaletteScope({
    super.key,
    required this.palette,
    required super.child,
  });

  @override
  bool updateShouldNotify(LessonPaletteScope old) =>
      old.palette.isDark != palette.isDark || old.palette.route != palette.route;
}
