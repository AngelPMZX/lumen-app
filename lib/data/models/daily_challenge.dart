import 'package:flutter/material.dart';

/// Tipo de acción que ejecuta el reto al tocarlo
enum ChallengeActionType {
  breathing,    // → BreathingScreen
  diary,        // → NewDiaryEntryScreen
  timedGuide,   // Dialog con guía paso a paso + timer
  infoComplete, // Dialog informativo + botón "Lo hice"
}

class DailyChallenge {
  final String title;
  final String description;
  final String? titleKey;
  final String? descriptionKey;
  final String? categoryKey;
  final IconData icon;
  final Color color;
  final int xpReward;
  final String duration;
  final String category;
  final ChallengeActionType actionType;

  /// Claves de los pasos guiados (para timedGuide e infoComplete)
  final List<String> stepKeys;

  const DailyChallenge({
    required this.title,
    required this.description,
    this.titleKey,
    this.descriptionKey,
    this.categoryKey,
    required this.icon,
    required this.color,
    required this.xpReward,
    required this.duration,
    required this.category,
    required this.actionType,
    this.stepKeys = const [],
  });

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
      titleKey: 'dailyChallenges.breathe.title',
      descriptionKey: 'dailyChallenges.breathe.description',
      categoryKey: 'dailyChallenges.categories.calm',
      icon: Icons.air_rounded,
      color: Color(0xFF3B82F6),
      xpReward: 15,
      duration: '3 min',
      category: 'Calma',
      actionType: ChallengeActionType.breathing,
    ),
    DailyChallenge(
      title: 'Gratitud express',
      description: 'Escribe 3 cosas por las que estás agradecido hoy',
      titleKey: 'dailyChallenges.gratitudeExpress.title',
      descriptionKey: 'dailyChallenges.gratitudeExpress.description',
      categoryKey: 'dailyChallenges.categories.gratitude',
      icon: Icons.favorite_rounded,
      color: Color(0xFFEC4899),
      xpReward: 15,
      duration: '2 min',
      category: 'Gratitud',
      actionType: ChallengeActionType.diary,
    ),
    DailyChallenge(
      title: 'Caminata consciente',
      description: 'Camina 5 minutos prestando atención a cada paso',
      titleKey: 'dailyChallenges.mindfulWalk.title',
      descriptionKey: 'dailyChallenges.mindfulWalk.description',
      categoryKey: 'dailyChallenges.categories.mindfulness',
      icon: Icons.directions_walk_rounded,
      color: Color(0xFF10B981),
      xpReward: 20,
      duration: '5 min',
      category: 'Mindfulness',
      actionType: ChallengeActionType.timedGuide,
      stepKeys: [
        'dailyChallenges.mindfulWalk.step1',
        'dailyChallenges.mindfulWalk.step2',
        'dailyChallenges.mindfulWalk.step3',
      ],
    ),
    DailyChallenge(
      title: 'Desconexión digital',
      description: 'Pasa 15 minutos sin mirar tu teléfono',
      titleKey: 'dailyChallenges.digitalDetox.title',
      descriptionKey: 'dailyChallenges.digitalDetox.description',
      categoryKey: 'dailyChallenges.categories.wellbeing',
      icon: Icons.phone_disabled_rounded,
      color: Color(0xFF8B5CF6),
      xpReward: 25,
      duration: '15 min',
      category: 'Bienestar',
      actionType: ChallengeActionType.infoComplete,
      stepKeys: [
        'dailyChallenges.digitalDetox.step1',
        'dailyChallenges.digitalDetox.step2',
        'dailyChallenges.digitalDetox.step3',
      ],
    ),
    DailyChallenge(
      title: 'Diario rápido',
      description: 'Escribe 3 oraciones sobre cómo te sientes ahora',
      titleKey: 'dailyChallenges.quickDiary.title',
      descriptionKey: 'dailyChallenges.quickDiary.description',
      categoryKey: 'dailyChallenges.categories.reflection',
      icon: Icons.edit_note_rounded,
      color: Color(0xFFF59E0B),
      xpReward: 15,
      duration: '3 min',
      category: 'Reflexión',
      actionType: ChallengeActionType.diary,
    ),
    DailyChallenge(
      title: 'Body scan',
      description: 'Escanea tu cuerpo de pies a cabeza notando tensiones',
      titleKey: 'dailyChallenges.bodyScan.title',
      descriptionKey: 'dailyChallenges.bodyScan.description',
      categoryKey: 'dailyChallenges.categories.mindfulness',
      icon: Icons.accessibility_new_rounded,
      color: Color(0xFF06B6D4),
      xpReward: 20,
      duration: '5 min',
      category: 'Mindfulness',
      actionType: ChallengeActionType.timedGuide,
      stepKeys: [
        'dailyChallenges.bodyScan.step1',
        'dailyChallenges.bodyScan.step2',
        'dailyChallenges.bodyScan.step3',
        'dailyChallenges.bodyScan.step4',
      ],
    ),
    DailyChallenge(
      title: 'Acto de bondad',
      description: 'Haz algo amable por alguien hoy, sin esperar nada',
      titleKey: 'dailyChallenges.actOfKindness.title',
      descriptionKey: 'dailyChallenges.actOfKindness.description',
      categoryKey: 'dailyChallenges.categories.social',
      icon: Icons.volunteer_activism_rounded,
      color: Color(0xFFEC4899),
      xpReward: 20,
      duration: 'Sin límite',
      category: 'Social',
      actionType: ChallengeActionType.infoComplete,
      stepKeys: [
        'dailyChallenges.actOfKindness.step1',
        'dailyChallenges.actOfKindness.step2',
        'dailyChallenges.actOfKindness.step3',
      ],
    ),
    DailyChallenge(
      title: 'Estiramiento',
      description: 'Estira tu cuerpo durante 5 minutos al despertar',
      titleKey: 'dailyChallenges.stretching.title',
      descriptionKey: 'dailyChallenges.stretching.description',
      categoryKey: 'dailyChallenges.categories.body',
      icon: Icons.self_improvement_rounded,
      color: Color(0xFF10B981),
      xpReward: 15,
      duration: '5 min',
      category: 'Cuerpo',
      actionType: ChallengeActionType.timedGuide,
      stepKeys: [
        'dailyChallenges.stretching.step1',
        'dailyChallenges.stretching.step2',
        'dailyChallenges.stretching.step3',
      ],
    ),
    DailyChallenge(
      title: 'Meditación breve',
      description: 'Siéntate en silencio y observa tus pensamientos',
      titleKey: 'dailyChallenges.shortMeditation.title',
      descriptionKey: 'dailyChallenges.shortMeditation.description',
      categoryKey: 'dailyChallenges.categories.calm',
      icon: Icons.spa_rounded,
      color: Color(0xFF6366F1),
      xpReward: 20,
      duration: '5 min',
      category: 'Calma',
      actionType: ChallengeActionType.timedGuide,
      stepKeys: [
        'dailyChallenges.shortMeditation.step1',
        'dailyChallenges.shortMeditation.step2',
        'dailyChallenges.shortMeditation.step3',
      ],
    ),
    DailyChallenge(
      title: 'Música sanadora',
      description: 'Escucha una canción que te haga feliz, con atención plena',
      titleKey: 'dailyChallenges.healingMusic.title',
      descriptionKey: 'dailyChallenges.healingMusic.description',
      categoryKey: 'dailyChallenges.categories.wellbeing',
      icon: Icons.headphones_rounded,
      color: Color(0xFFF97316),
      xpReward: 10,
      duration: '4 min',
      category: 'Bienestar',
      actionType: ChallengeActionType.infoComplete,
      stepKeys: [
        'dailyChallenges.healingMusic.step1',
        'dailyChallenges.healingMusic.step2',
      ],
    ),
    DailyChallenge(
      title: 'Afirmación positiva',
      description: 'Repite 3 veces: "Merezco paz y felicidad"',
      titleKey: 'dailyChallenges.positiveAffirmation.title',
      descriptionKey: 'dailyChallenges.positiveAffirmation.description',
      categoryKey: 'dailyChallenges.categories.selfEsteem',
      icon: Icons.record_voice_over_rounded,
      color: Color(0xFF8B5CF6),
      xpReward: 10,
      duration: '1 min',
      category: 'Autoestima',
      actionType: ChallengeActionType.timedGuide,
      stepKeys: [
        'dailyChallenges.positiveAffirmation.step1',
        'dailyChallenges.positiveAffirmation.step2',
        'dailyChallenges.positiveAffirmation.step3',
      ],
    ),
    DailyChallenge(
      title: 'Observa la naturaleza',
      description: 'Sal y observa algo natural por 3 minutos (cielo, árbol, etc.)',
      titleKey: 'dailyChallenges.observeNature.title',
      descriptionKey: 'dailyChallenges.observeNature.description',
      categoryKey: 'dailyChallenges.categories.mindfulness',
      icon: Icons.park_rounded,
      color: Color(0xFF22C55E),
      xpReward: 15,
      duration: '3 min',
      category: 'Mindfulness',
      actionType: ChallengeActionType.infoComplete,
      stepKeys: [
        'dailyChallenges.observeNature.step1',
        'dailyChallenges.observeNature.step2',
      ],
    ),
    DailyChallenge(
      title: 'Perdón silencioso',
      description: 'Piensa en algo que te molesta y practícalo dejando ir',
      titleKey: 'dailyChallenges.silentForgiveness.title',
      descriptionKey: 'dailyChallenges.silentForgiveness.description',
      categoryKey: 'dailyChallenges.categories.reflection',
      icon: Icons.healing_rounded,
      color: Color(0xFF14B8A6),
      xpReward: 20,
      duration: '5 min',
      category: 'Reflexión',
      actionType: ChallengeActionType.timedGuide,
      stepKeys: [
        'dailyChallenges.silentForgiveness.step1',
        'dailyChallenges.silentForgiveness.step2',
        'dailyChallenges.silentForgiveness.step3',
      ],
    ),
    DailyChallenge(
      title: 'Limita las quejas',
      description: 'Intenta pasar 2 horas sin quejarte de nada',
      titleKey: 'dailyChallenges.limitComplaints.title',
      descriptionKey: 'dailyChallenges.limitComplaints.description',
      categoryKey: 'dailyChallenges.categories.wellbeing',
      icon: Icons.do_not_disturb_alt_rounded,
      color: Color(0xFFEF4444),
      xpReward: 30,
      duration: '2 hrs',
      category: 'Bienestar',
      actionType: ChallengeActionType.infoComplete,
      stepKeys: [
        'dailyChallenges.limitComplaints.step1',
        'dailyChallenges.limitComplaints.step2',
        'dailyChallenges.limitComplaints.step3',
      ],
    ),
  ];
}