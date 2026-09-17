import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart' show Color;
import 'package:gimnasio_emocional/ui/screens/breathing/breathing_data.dart';

void main() {
  final box = kTechniques.firstWhere((t) => t.id == 'box');
  final calm = kTechniques.firstWhere((t) => t.id == 'calm_478');

  group('BreathingSession.positionAt', () {
    final session = BreathingSession.minutes(box, 3);

    test('empieza inhalando con la fase completa por delante', () {
      final p = session.positionAt(0);
      expect(p.phaseIndex, 0);
      expect(p.phase.move, BreathMove.inhale);
      expect(p.secondsLeft, 4);
      expect(p.cycle, 1);
    });

    test('cambia de fase en el segundo exacto', () {
      expect(session.positionAt(3).phase.move, BreathMove.inhale);
      expect(session.positionAt(3).secondsLeft, 1);
      expect(session.positionAt(4).phase.move, BreathMove.hold);
      expect(session.positionAt(4).phaseIndex, 1);
      expect(session.positionAt(8).phase.move, BreathMove.exhale);
      expect(session.positionAt(12).phaseIndex, 3);
    });

    test('vuelve al inicio en el siguiente ciclo', () {
      final p = session.positionAt(16);
      expect(p.phaseIndex, 0);
      expect(p.cycle, 2);
      expect(session.positionAt(33).cycle, 3);
    });

    test('funciona con fases de distinta duración', () {
      final s = BreathingSession.minutes(calm, 1);
      expect(s.cycleSeconds, 19);
      expect(s.positionAt(4).phase.move, BreathMove.hold);
      expect(s.positionAt(10).secondsLeft, 1);
      expect(s.positionAt(11).phase.move, BreathMove.exhale);
      expect(s.positionAt(18).secondsLeft, 1);
      expect(s.positionAt(19).phase.move, BreathMove.inhale);
      expect(s.positionAt(19).cycle, 2);
    });

    test('nunca devuelve segundos restantes en cero', () {
      final s = BreathingSession.minutes(calm, 5);
      for (var t = 0; t < s.totalSeconds; t++) {
        expect(s.positionAt(t).secondsLeft, greaterThan(0), reason: 'segundo $t');
        expect(s.positionAt(t).secondsLeft, lessThanOrEqualTo(8));
      }
    });
  });

  group('BreathingSession: tiempo y ciclos', () {
    test('cuenta el tiempo que falta y el avance', () {
      final s = BreathingSession.minutes(box, 1);
      expect(s.totalSeconds, 60);
      expect(s.secondsLeftAt(0), 60);
      expect(s.secondsLeftAt(45), 15);
      expect(s.secondsLeftAt(80), 0);
      expect(s.progressAt(30), closeTo(0.5, 1e-9));
      expect(s.progressAt(90), 1);
      expect(s.isOver(59), isFalse);
      expect(s.isOver(60), isTrue);
    });

    test('cuenta ciclos completos', () {
      final s = BreathingSession.minutes(box, 3);
      expect(s.cyclesDoneAt(15), 0);
      expect(s.cyclesDoneAt(16), 1);
      expect(s.cyclesDoneAt(180), 11);
      expect(s.plannedCycles, 11);
    });

    test('una sesión corta planea al menos un ciclo', () {
      expect(BreathingSession.minutes(calm, 1).plannedCycles, 3);
      expect(const BreathingSession(technique: BreathingTechnique(
        id: 'x',
        nameKey: 'x',
        descriptionKey: 'x',
        benefitKey: 'x',
        emoji: '',
        color: Color(0xFF000000),
        phases: [BreathPhase(BreathMove.inhale, 30), BreathPhase(BreathMove.exhale, 40)],
      ), totalSeconds: 60).plannedCycles, 1);
    });
  });

  group('Fases', () {
    test('el orbe solo baja al exhalar', () {
      expect(const BreathPhase(BreathMove.inhale, 4).expanded, isTrue);
      expect(const BreathPhase(BreathMove.hold, 4).expanded, isTrue);
      expect(const BreathPhase(BreathMove.exhale, 4).expanded, isFalse);
    });

    test('cada fase tiene su señal de sonido y su texto', () {
      for (final t in kTechniques) {
        for (final p in t.phases) {
          expect(p.labelKey, 'breathing.phase.${p.move.name}');
          expect(p.cue.name, p.move.name);
        }
      }
    });
  });
}
