import 'dart:math';
import 'package:flutter/material.dart';

/// Retos diarios que rotan automáticamente.
/// Cada reto tiene una categoría, duración estimada y XP reward.
class DailyChallenge {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final int xpReward;
  final String duration;
  final String category;

  const DailyChallenge({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.xpReward,
    required this.duration,
    required this.category,
  });

  /// Obtiene el reto del día basado en la fecha
  static DailyChallenge getToday() {
    final now = DateTime.now();
    final dayOfYear = now.difference(DateTime(now.year, 1, 1)).inDays;
    final index = dayOfYear % _challenges.length;
    return _challenges[index];
  }

  static const List<DailyChallenge> _challenges = [
    DailyChallenge(
      title: 'Respira profundo',
      description: 'Haz 3 minutos de respiración diafragmática',
      icon: Icons.air_rounded,
      color: Color(0xFF3B82F6),
      xpReward: 15,
      duration: '3 min',
      category: 'Calma',
    ),
    DailyChallenge(
      title: 'Gratitud express',
      description: 'Escribe 3 cosas por las que estás agradecido hoy',
      icon: Icons.favorite_rounded,
      color: Color(0xFFEC4899),
      xpReward: 15,
      duration: '2 min',
      category: 'Gratitud',
    ),
    DailyChallenge(
      title: 'Caminata consciente',
      description: 'Camina 5 minutos prestando atención a cada paso',
      icon: Icons.directions_walk_rounded,
      color: Color(0xFF10B981),
      xpReward: 20,
      duration: '5 min',
      category: 'Mindfulness',
    ),
    DailyChallenge(
      title: 'Desconexión digital',
      description: 'Pasa 15 minutos sin mirar tu teléfono',
      icon: Icons.phone_disabled_rounded,
      color: Color(0xFF8B5CF6),
      xpReward: 25,
      duration: '15 min',
      category: 'Bienestar',
    ),
    DailyChallenge(
      title: 'Diario rápido',
      description: 'Escribe 3 oraciones sobre cómo te sientes ahora',
      icon: Icons.edit_note_rounded,
      color: Color(0xFFF59E0B),
      xpReward: 15,
      duration: '3 min',
      category: 'Reflexión',
    ),
    DailyChallenge(
      title: 'Body scan',
      description: 'Escanea tu cuerpo de pies a cabeza notando tensiones',
      icon: Icons.accessibility_new_rounded,
      color: Color(0xFF06B6D4),
      xpReward: 20,
      duration: '5 min',
      category: 'Mindfulness',
    ),
    DailyChallenge(
      title: 'Acto de bondad',
      description: 'Haz algo amable por alguien hoy, sin esperar nada',
      icon: Icons.volunteer_activism_rounded,
      color: Color(0xFFEC4899),
      xpReward: 20,
      duration: 'Sin límite',
      category: 'Social',
    ),
    DailyChallenge(
      title: 'Estiramiento',
      description: 'Estira tu cuerpo durante 5 minutos al despertar',
      icon: Icons.self_improvement_rounded,
      color: Color(0xFF10B981),
      xpReward: 15,
      duration: '5 min',
      category: 'Cuerpo',
    ),
    DailyChallenge(
      title: 'Meditación breve',
      description: 'Siéntate en silencio y observa tus pensamientos',
      icon: Icons.spa_rounded,
      color: Color(0xFF6366F1),
      xpReward: 20,
      duration: '5 min',
      category: 'Calma',
    ),
    DailyChallenge(
      title: 'Música sanadora',
      description: 'Escucha una canción que te haga feliz, con atención plena',
      icon: Icons.headphones_rounded,
      color: Color(0xFFF97316),
      xpReward: 10,
      duration: '4 min',
      category: 'Bienestar',
    ),
    DailyChallenge(
      title: 'Afirmación positiva',
      description: 'Repite 3 veces: "Merezco paz y felicidad"',
      icon: Icons.record_voice_over_rounded,
      color: Color(0xFF8B5CF6),
      xpReward: 10,
      duration: '1 min',
      category: 'Autoestima',
    ),
    DailyChallenge(
      title: 'Observa la naturaleza',
      description: 'Sal y observa algo natural por 3 minutos (cielo, árbol, etc.)',
      icon: Icons.park_rounded,
      color: Color(0xFF22C55E),
      xpReward: 15,
      duration: '3 min',
      category: 'Mindfulness',
    ),
    DailyChallenge(
      title: 'Perdón silencioso',
      description: 'Piensa en algo que te molesta y practícalo dejando ir',
      icon: Icons.healing_rounded,
      color: Color(0xFF14B8A6),
      xpReward: 20,
      duration: '5 min',
      category: 'Reflexión',
    ),
    DailyChallenge(
      title: 'Limita las quejas',
      description: 'Intenta pasar 2 horas sin quejarte de nada',
      icon: Icons.do_not_disturb_alt_rounded,
      color: Color(0xFFEF4444),
      xpReward: 30,
      duration: '2 hrs',
      category: 'Bienestar',
    ),
  ];
}