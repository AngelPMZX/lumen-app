import 'package:flutter/material.dart';

import '../../../domain/services/sound_service.dart';

// ═════════════════════════════════════════════════════════════════════════════
// Técnicas y fases
// ═════════════════════════════════════════════════════════════════════════════

enum BreathMove { inhale, hold, exhale }

class BreathPhase {
  final BreathMove move;
  final int seconds;

  const BreathPhase(this.move, this.seconds);

  /// ¿El orbe crece o se queda grande durante esta fase?
  bool get expanded => move != BreathMove.exhale;

  String get labelKey => 'breathing.phase.${move.name}';

  BreathCue get cue => switch (move) {
        BreathMove.inhale => BreathCue.inhale,
        BreathMove.hold => BreathCue.hold,
        BreathMove.exhale => BreathCue.exhale,
      };
}

class BreathingTechnique {
  final String id;
  final String nameKey;
  final String descriptionKey;
  final String benefitKey;
  final String emoji;
  final Color color;
  final List<BreathPhase> phases;

  const BreathingTechnique({
    required this.id,
    required this.nameKey,
    required this.descriptionKey,
    required this.benefitKey,
    required this.emoji,
    required this.color,
    required this.phases,
  });

  int get cycleSeconds => phases.fold(0, (sum, p) => sum + p.seconds);
}

const kTechniques = [
  BreathingTechnique(
    id: 'box',
    nameKey: 'breathing.box.name',
    descriptionKey: 'breathing.box.description',
    benefitKey: 'breathing.box.benefit',
    emoji: '⬜',
    color: Color(0xFF6366F1),
    phases: [
      BreathPhase(BreathMove.inhale, 4),
      BreathPhase(BreathMove.hold, 4),
      BreathPhase(BreathMove.exhale, 4),
      BreathPhase(BreathMove.hold, 4),
    ],
  ),
  BreathingTechnique(
    id: 'calm_478',
    nameKey: 'breathing.calm478.name',
    descriptionKey: 'breathing.calm478.description',
    benefitKey: 'breathing.calm478.benefit',
    emoji: '🌊',
    color: Color(0xFF0EA5E9),
    phases: [
      BreathPhase(BreathMove.inhale, 4),
      BreathPhase(BreathMove.hold, 7),
      BreathPhase(BreathMove.exhale, 8),
    ],
  ),
  BreathingTechnique(
    id: 'flow',
    nameKey: 'breathing.flow.name',
    descriptionKey: 'breathing.flow.description',
    benefitKey: 'breathing.flow.benefit',
    emoji: '🍃',
    color: Color(0xFF10B981),
    phases: [
      BreathPhase(BreathMove.inhale, 4),
      BreathPhase(BreathMove.exhale, 8),
    ],
  ),
];

// ═════════════════════════════════════════════════════════════════════════════
// Ambientes
// ═════════════════════════════════════════════════════════════════════════════

class AmbientChoice {
  final String id;
  final String labelKey;
  final String emoji;

  /// null = en silencio.
  final Ambient? ambient;

  const AmbientChoice({required this.id, required this.labelKey, required this.emoji, required this.ambient});
}

const kAmbientChoices = [
  AmbientChoice(id: 'music', labelKey: 'breathing.sound.music', emoji: '🎵', ambient: Ambient.calmMusic),
  AmbientChoice(id: 'rain', labelKey: 'breathing.sound.rain', emoji: '🌧️', ambient: Ambient.rain),
  AmbientChoice(id: 'forest', labelKey: 'breathing.sound.forest', emoji: '🌲', ambient: Ambient.forest),
  AmbientChoice(id: 'ocean', labelKey: 'breathing.sound.ocean', emoji: '🌊', ambient: Ambient.ocean),
  AmbientChoice(id: 'stream', labelKey: 'breathing.sound.stream', emoji: '🏞️', ambient: Ambient.stream),
  AmbientChoice(id: 'night', labelKey: 'breathing.sound.night', emoji: '🌙', ambient: Ambient.night),
  AmbientChoice(id: 'tide', labelKey: 'breathing.sound.tide', emoji: '🐚', ambient: Ambient.tide),
  AmbientChoice(id: 'lullaby', labelKey: 'breathing.sound.lullaby', emoji: '💤', ambient: Ambient.lullaby),
  AmbientChoice(id: 'chimes', labelKey: 'breathing.sound.chimes', emoji: '🎐', ambient: Ambient.mountain),
  AmbientChoice(id: 'white', labelKey: 'breathing.sound.white', emoji: '☁️', ambient: Ambient.softNoise),
  AmbientChoice(id: 'none', labelKey: 'breathing.sound.none', emoji: '🔇', ambient: null),
];

const kScienceFacts = [
  ('🧠', 'breathing.science.vagus.title', 'breathing.science.vagus.desc'),
  ('❤️', 'breathing.science.hrv.title', 'breathing.science.hrv.desc'),
  ('⚡', 'breathing.science.amygdala.title', 'breathing.science.amygdala.desc'),
  ('🌙', 'breathing.science.sleep.title', 'breathing.science.sleep.desc'),
];

const kMotivationalKeys = [
  'breathing.motivational.0',
  'breathing.motivational.1',
  'breathing.motivational.2',
  'breathing.motivational.3',
];

// ═════════════════════════════════════════════════════════════════════════════
// Dónde va la sesión en cada segundo (lógica pura)
// ═════════════════════════════════════════════════════════════════════════════

/// En qué punto de la respiración está la sesión.
class BreathPosition {
  final int phaseIndex;
  final BreathPhase phase;

  /// Segundos que faltan de esta fase (1..duración; nunca 0 mientras dura).
  final int secondsLeft;

  /// Ciclo completo en el que va, empezando en 1.
  final int cycle;

  const BreathPosition({
    required this.phaseIndex,
    required this.phase,
    required this.secondsLeft,
    required this.cycle,
  });
}

/// Una sesión de respiración: sabe en qué fase toca estar en cada segundo.
/// Al derivar todo del tiempo transcurrido, pausar y reanudar no descuadra
/// nada ni deja temporizadores sueltos.
class BreathingSession {
  final BreathingTechnique technique;
  final int totalSeconds;

  const BreathingSession({required this.technique, required this.totalSeconds});

  BreathingSession.minutes(this.technique, int minutes) : totalSeconds = minutes * 60;

  int get cycleSeconds => technique.cycleSeconds;

  /// Ciclos completos que caben en la sesión (al menos uno).
  int get plannedCycles => (totalSeconds / cycleSeconds).floor().clamp(1, 9999);

  int secondsLeftAt(int elapsed) => (totalSeconds - elapsed).clamp(0, totalSeconds);

  double progressAt(int elapsed) => totalSeconds == 0 ? 1 : (elapsed / totalSeconds).clamp(0.0, 1.0);

  bool isOver(int elapsed) => elapsed >= totalSeconds;

  /// Fase que corresponde al segundo [elapsed] (0 = recién empezada).
  BreathPosition positionAt(int elapsed) {
    final t = elapsed % cycleSeconds;
    final cycle = elapsed ~/ cycleSeconds + 1;
    var acc = 0;
    for (var i = 0; i < technique.phases.length; i++) {
      final phase = technique.phases[i];
      if (t < acc + phase.seconds) {
        return BreathPosition(
          phaseIndex: i,
          phase: phase,
          secondsLeft: acc + phase.seconds - t,
          cycle: cycle,
        );
      }
      acc += phase.seconds;
    }
    final last = technique.phases.length - 1;
    return BreathPosition(phaseIndex: last, phase: technique.phases[last], secondsLeft: 1, cycle: cycle);
  }

  /// Ciclos completados al llevar [elapsed] segundos.
  int cyclesDoneAt(int elapsed) => elapsed ~/ cycleSeconds;
}
