import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Lo que un paso le avisa a `LessonScreen`.
///
/// Cada paso interactivo vive en su propio widget con su propio estado; la
/// pantalla solo se entera de aciertos, reflexiones y de cuándo puede
/// habilitar "Continuar".
class StepCallbacks {
  /// Respuesta con correcta/incorrecta: flash, racha, personaje y sonido.
  /// [sound] en false cuando el paso toca su propio sonido (p. ej. las notas
  /// de `order`).
  final void Function(bool correct, int xp, {bool sound}) onAnswer;

  /// Participación sin respuesta correcta (reflexionar, practicar).
  final void Function(int xp) onReflect;

  /// El paso ya se completó: se habilita "Continuar".
  final VoidCallback onReady;

  const StepCallbacks({
    required this.onAnswer,
    required this.onReflect,
    required this.onReady,
  });
}

/// Etiqueta de color con el tipo de paso.
class StepChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const StepChip({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// Título grande con resplandor del color de la ruta.
class StepHeading extends StatelessWidget {
  final String text;
  final Color glow;
  final double fontSize;

  const StepHeading({
    super.key,
    required this.text,
    required this.glow,
    this.fontSize = 24,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.w800,
        height: 1.25,
        color: Colors.white,
        shadows: [Shadow(color: glow.withValues(alpha: 0.5), blurRadius: 14)],
      ),
    );
  }
}

/// Caja de retroalimentación con icono.
class StepNote extends StatelessWidget {
  final String text;
  final Color color;
  final IconData icon;

  const StepNote({
    super.key,
    required this.text,
    required this.color,
    this.icon = Icons.lightbulb_rounded,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.32)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 19),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14.5,
                height: 1.6,
                color: Colors.white.withValues(alpha: 0.9),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 380.ms).slideY(begin: 0.1, end: 0);
  }
}

/// Botón secundario pequeño dentro de un paso ("Listo", "Siguiente").
class StepInlineButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback? onPressed;
  final IconData icon;

  const StepInlineButton({
    super.key,
    required this.label,
    required this.color,
    required this.onPressed,
    this.icon = Icons.arrow_forward_rounded,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return GestureDetector(
      onTap: onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
        decoration: BoxDecoration(
          color: color.withValues(alpha: enabled ? 0.25 : 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: color.withValues(alpha: enabled ? 0.7 : 0.2),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: Colors.white.withValues(alpha: enabled ? 1 : 0.4),
              ),
            ),
            const SizedBox(width: 6),
            Icon(
              icon,
              size: 17,
              color: Colors.white.withValues(alpha: enabled ? 1 : 0.4),
            ),
          ],
        ),
      ),
    );
  }
}
