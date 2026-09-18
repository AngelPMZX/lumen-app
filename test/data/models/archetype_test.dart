import 'package:flutter_test/flutter_test.dart';
import 'dart:io';

import 'package:gimnasio_emocional/data/models/archetype.dart';

void main() {
  group('ArchetypeQuiz.compute', () {
    test('los gustos pesan más que la música', () {
      final a = ArchetypeQuiz.compute(
        hobbies: ['Meditación', 'Yoga', 'Naturaleza'],
        genres: ['Rock', 'Metal'],
      );
      expect(a, Archetype.sabio);
    });

    test('la música desempata cuando los gustos están repartidos', () {
      final a = ArchetypeQuiz.compute(
        hobbies: ['Lectura', 'Deportes'],
        genres: ['Rock', 'Hip Hop'],
      );
      expect(a, Archetype.guerrero);
    });

    test('cada combinación cae en su arquetipo', () {
      expect(ArchetypeQuiz.compute(hobbies: ['Lectura', 'Escritura'], genres: ['Indie']), Archetype.explorador);
      expect(ArchetypeQuiz.compute(hobbies: ['Gym', 'Artes marciales'], genres: ['Metal']), Archetype.guerrero);
      expect(ArchetypeQuiz.compute(hobbies: ['Cocina', 'Fiestas'], genres: ['Cumbia']), Archetype.social);
      expect(ArchetypeQuiz.compute(hobbies: ['Yoga', 'Naturaleza'], genres: ['Ambient']), Archetype.sabio);
      expect(ArchetypeQuiz.compute(hobbies: ['Viajar', 'Videojuegos'], genres: ['K-Pop']), Archetype.libre);
    });

    test('ignora valores desconocidos y no truena sin respuestas', () {
      expect(ArchetypeQuiz.compute(hobbies: ['Algo raro'], genres: ['Otro']), Archetype.explorador);
      expect(ArchetypeQuiz.compute(hobbies: [], genres: []), Archetype.explorador);
    });

    test('con las mismas respuestas siempre da lo mismo', () {
      final hobbies = ['Arte', 'Cocina', 'Gym'];
      final genres = ['Pop', 'Jazz'];
      final first = ArchetypeQuiz.compute(hobbies: hobbies, genres: genres);
      for (var i = 0; i < 5; i++) {
        expect(ArchetypeQuiz.compute(hobbies: hobbies, genres: genres), first);
      }
    });
  });

  group('Puntos y afinidad', () {
    test('suma 2 por gusto y 1 por género', () {
      final points = ArchetypeQuiz.scores(hobbies: ['Lectura', 'Arte'], genres: ['Indie', 'Rock']);
      expect(points[Archetype.explorador], 5);
      expect(points[Archetype.guerrero], 1);
      expect(points[Archetype.social], 0);
    });

    test('la afinidad es la parte del ganador sobre el total', () {
      expect(
        ArchetypeQuiz.affinity(hobbies: ['Lectura', 'Escritura', 'Arte'], genres: ['Indie', 'Lo-fi']),
        1.0,
      );
      final mixed = ArchetypeQuiz.affinity(hobbies: ['Lectura', 'Gym'], genres: ['Pop', 'Jazz']);
      expect(mixed, closeTo(2 / 6, 1e-9));
      expect(ArchetypeQuiz.affinity(hobbies: [], genres: []), 0);
    });
  });

  group('Mini test emocional', () {
    test('manda sobre los gustos y la música', () {
      // Todo lo que elige tira a guerrero, pero responde como Mente Serena.
      final a = ArchetypeQuiz.compute(
        hobbies: ['Gym', 'Deportes', 'Artes marciales'],
        genres: ['Rock', 'Metal'],
        answers: const [
          Archetype.sabio,
          Archetype.sabio,
          Archetype.sabio,
          Archetype.sabio,
        ],
      );
      expect(a, Archetype.sabio);
    });

    test('los gustos desempatan cuando el test sale repartido', () {
      final a = ArchetypeQuiz.compute(
        hobbies: ['Cocina', 'Fiestas'],
        genres: ['Cumbia'],
        answers: const [Archetype.social, Archetype.libre],
      );
      expect(a, Archetype.social);
    });

    test('sin responder el test sigue funcionando como antes', () {
      expect(
        ArchetypeQuiz.compute(hobbies: ['Yoga', 'Naturaleza'], genres: ['Ambient']),
        Archetype.sabio,
      );
    });

    test('cada respuesta suma lo suyo', () {
      final points = ArchetypeQuiz.scores(
        hobbies: const [],
        genres: const [],
        answers: const [Archetype.libre, Archetype.libre],
      );
      expect(points[Archetype.libre], ArchetypeQuiz.answerWeight * 2);
      expect(points[Archetype.sabio], 0);
    });

    test('responder siempre igual da afinidad total', () {
      expect(
        ArchetypeQuiz.affinity(
          hobbies: const [],
          genres: const [],
          answers: const [Archetype.guerrero, Archetype.guerrero],
        ),
        1.0,
      );
    });

    group('las preguntas', () {
      test('son cuatro y ninguna repite arquetipo', () {
        expect(ArchetypeQuiz.questions.length, 4);
        for (final q in ArchetypeQuiz.questions) {
          final archetypes = q.options.map((o) => o.archetype).toList();
          // Una opción por arquetipo: ninguno queda sin salida.
          expect(archetypes.toSet(), Archetype.values.toSet());
          expect(archetypes.length, Archetype.values.length);
        }
      });

      test('todas tienen su texto y su emoji', () {
        final keys = <String>{};
        for (final q in ArchetypeQuiz.questions) {
          expect(q.promptKey, startsWith('archetypeQuiz.'));
          expect(keys.add(q.promptKey), isTrue, reason: 'clave repetida');
          for (final o in q.options) {
            expect(o.textKey, startsWith('archetypeQuiz.'));
            expect(o.emoji, isNotEmpty);
            expect(keys.add(o.textKey), isTrue, reason: 'clave repetida');
          }
        }
      });
    });
  });

  group('Archetype', () {
    test('el id es el que se guarda en Firestore', () {
      expect(Archetype.explorador.id, 'explorador');
      expect(Archetype.guerrero.id, 'guerrero');
      expect(Archetype.social.id, 'social');
      expect(Archetype.sabio.id, 'sabio');
      expect(Archetype.libre.id, 'libre');
    });

    test('fromId acepta lo guardado y tolera lo desconocido', () {
      expect(Archetype.fromId('sabio'), Archetype.sabio);
      expect(Archetype.fromId('no-existe'), isNull);
      expect(Archetype.fromId(null), isNull);
    });

    test('todos tienen sus claves de texto y su emoji', () {
      for (final a in Archetype.values) {
        expect(a.nameKey, startsWith('archetype.'));
        expect(a.descriptionKey, startsWith('archetype.'));
        expect(a.strengthsKey, startsWith('archetype.'));
        expect(a.tipKey, startsWith('archetype.'));
        expect(a.emoji, isNotEmpty);
      }
    });

    test('todos saben por dónde empezar, y esas rutas existen', () {
      // El catálogo de verdad es `seed/routes/` (`WellnessRoute.all` es solo
      // el respaldo viejo y le faltan rutas). Así una errata en un id se ve
      // aquí y no cuando alguien se queda sin ruta sugerida.
      final ids = Directory('seed/routes')
          .listSync()
          .whereType<File>()
          .map((f) => f.uri.pathSegments.last.replaceAll('.js', ''))
          .toSet();
      expect(ids, isNotEmpty, reason: 'no se encontró seed/routes');

      for (final a in Archetype.values) {
        expect(a.preferredRouteIds, isNotEmpty);
        for (final id in a.preferredRouteIds) {
          expect(ids, contains(id), reason: '\${a.id} apunta a \$id');
        }
      }
    });
  });
}
