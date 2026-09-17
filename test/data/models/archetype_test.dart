import 'package:flutter_test/flutter_test.dart';
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
  });
}
