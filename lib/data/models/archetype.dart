/// Los cinco arquetipos de Lumen. El id es lo que se guarda en Firestore
/// (`users/{uid}.archetype`): **no renombrarlos**.
enum Archetype {
  explorador,
  guerrero,
  social,
  sabio,
  libre;

  String get id => name;

  String get nameKey => switch (this) {
        Archetype.explorador => 'archetype.explorerName',
        Archetype.guerrero => 'archetype.warriorName',
        Archetype.social => 'archetype.socialName',
        Archetype.sabio => 'archetype.sageName',
        Archetype.libre => 'archetype.freeSpiritName',
      };

  String get descriptionKey => switch (this) {
        Archetype.explorador => 'archetype.explorerDesc',
        Archetype.guerrero => 'archetype.warriorDesc',
        Archetype.social => 'archetype.socialDesc',
        Archetype.sabio => 'archetype.sageDesc',
        Archetype.libre => 'archetype.freeSpiritDesc',
      };

  String get strengthsKey => switch (this) {
        Archetype.explorador => 'archetype.explorerStrengths',
        Archetype.guerrero => 'archetype.warriorStrengths',
        Archetype.social => 'archetype.socialStrengths',
        Archetype.sabio => 'archetype.sageStrengths',
        Archetype.libre => 'archetype.freeSpiritStrengths',
      };

  String get tipKey => switch (this) {
        Archetype.explorador => 'archetype.explorerTip',
        Archetype.guerrero => 'archetype.warriorTip',
        Archetype.social => 'archetype.socialTip',
        Archetype.sabio => 'archetype.sageTip',
        Archetype.libre => 'archetype.freeSpiritTip',
      };

  String get emoji => switch (this) {
        Archetype.explorador => '🧭',
        Archetype.guerrero => '🛡️',
        Archetype.social => '🤝',
        Archetype.sabio => '🦉',
        Archetype.libre => '🕊️',
      };

  /// Por dónde le sienta mejor empezar a cada arquetipo.
  ///
  /// Es lo que hace que el arquetipo **sirva para algo**: mientras no haya
  /// ninguna ruta empezada, Lumen propone la primera de esta lista en vez de
  /// la primera del catálogo. Al empezar cualquier ruta manda el progreso, no
  /// esto. Ids de `seed/routes/`.
  List<String> get preferredRouteIds => switch (this) {
        // Mirada reflexiva: entender lo que siente y mirarse dentro.
        Archetype.explorador => const ['emociones', 'autoconocimiento'],
        // Ganas de actuar: levantarse de los golpes y plantarse firme.
        Archetype.guerrero => const ['resiliencia', 'autoestima'],
        // La energía le viene de los vínculos.
        Archetype.social => const ['relaciones', 'amor'],
        // Busca calma y equilibrio.
        Archetype.sabio => const ['mindfulness', 'sueno'],
        // Curiosidad y cambio: conocerse y aprender a estar en el momento.
        Archetype.libre => const ['autoconocimiento', 'mindfulness'],
      };

  static Archetype? fromId(String? id) {
    for (final a in Archetype.values) {
      if (a.id == id) return a;
    }
    return null;
  }
}

/// Una opción del mini test: lo que se responde y a qué arquetipo tira.
class ArchetypeOption {
  final String textKey;
  final String emoji;
  final Archetype archetype;

  const ArchetypeOption(this.textKey, this.emoji, this.archetype);
}

/// Una pregunta del mini test, con una opción por arquetipo.
class ArchetypeQuestion {
  final String promptKey;
  final List<ArchetypeOption> options;

  const ArchetypeQuestion(this.promptKey, this.options);
}

/// Cómo se descubre el arquetipo.
///
/// Manda el **mini test**: cuatro preguntas sobre cómo llevas lo que sientes,
/// que es de lo que va la app. Antes el arquetipo salía solo de los gustos y
/// la música, que no dicen nada del bienestar emocional, y el resultado se
/// sentía a horóscopo. Los gustos y la música siguen sumando, pero poco: solo
/// desempatan.
///
/// Los valores de gustos y música se guardan en español en Firestore desde la
/// primera versión, así que aquí se mantienen tal cual.
class ArchetypeQuiz {
  ArchetypeQuiz._();

  /// Las preguntas, en orden. Cada una tiene una opción por arquetipo y
  /// ninguna es "la correcta".
  static const questions = <ArchetypeQuestion>[
    ArchetypeQuestion('archetypeQuiz.q1', [
      ArchetypeOption('archetypeQuiz.q1a', '🧭', Archetype.explorador),
      ArchetypeOption('archetypeQuiz.q1b', '🛡️', Archetype.guerrero),
      ArchetypeOption('archetypeQuiz.q1c', '🤝', Archetype.social),
      ArchetypeOption('archetypeQuiz.q1d', '🦉', Archetype.sabio),
      ArchetypeOption('archetypeQuiz.q1e', '🕊️', Archetype.libre),
    ]),
    ArchetypeQuestion('archetypeQuiz.q2', [
      ArchetypeOption('archetypeQuiz.q2a', '📓', Archetype.explorador),
      ArchetypeOption('archetypeQuiz.q2b', '⚡', Archetype.guerrero),
      ArchetypeOption('archetypeQuiz.q2c', '💬', Archetype.social),
      ArchetypeOption('archetypeQuiz.q2d', '🍵', Archetype.sabio),
      ArchetypeOption('archetypeQuiz.q2e', '✨', Archetype.libre),
    ]),
    ArchetypeQuestion('archetypeQuiz.q3', [
      ArchetypeOption('archetypeQuiz.q3a', '🌀', Archetype.explorador),
      ArchetypeOption('archetypeQuiz.q3b', '🛑', Archetype.guerrero),
      ArchetypeOption('archetypeQuiz.q3c', '🚧', Archetype.social),
      ArchetypeOption('archetypeQuiz.q3d', '🎭', Archetype.sabio),
      ArchetypeOption('archetypeQuiz.q3e', '📍', Archetype.libre),
    ]),
    ArchetypeQuestion('archetypeQuiz.q4', [
      ArchetypeOption('archetypeQuiz.q4a', '🌱', Archetype.explorador),
      ArchetypeOption('archetypeQuiz.q4b', '🎯', Archetype.guerrero),
      ArchetypeOption('archetypeQuiz.q4c', '🎉', Archetype.social),
      ArchetypeOption('archetypeQuiz.q4d', '🙏', Archetype.sabio),
      ArchetypeOption('archetypeQuiz.q4e', '🎈', Archetype.libre),
    ]),
  ];

  /// Cada gusto suma 2 puntos a su arquetipo.
  static const hobbyPoints = <String, Archetype>{
    'Lectura': Archetype.explorador,
    'Escritura': Archetype.explorador,
    'Arte': Archetype.explorador,
    'Deportes': Archetype.guerrero,
    'Gym': Archetype.guerrero,
    'Artes marciales': Archetype.guerrero,
    'Cocina': Archetype.social,
    'Voluntariado': Archetype.social,
    'Fiestas': Archetype.social,
    'Meditación': Archetype.sabio,
    'Yoga': Archetype.sabio,
    'Naturaleza': Archetype.sabio,
    'Viajar': Archetype.libre,
    'Fotografía': Archetype.libre,
    'Videojuegos': Archetype.libre,
  };

  /// Cada género musical suma 1 punto.
  static const genrePoints = <String, Archetype>{
    'Lo-fi': Archetype.explorador,
    'Clásica': Archetype.explorador,
    'Indie': Archetype.explorador,
    'Rock': Archetype.guerrero,
    'Metal': Archetype.guerrero,
    'Hip Hop': Archetype.guerrero,
    'Pop': Archetype.social,
    'Reggaetón': Archetype.social,
    'Cumbia': Archetype.social,
    'Jazz': Archetype.sabio,
    'Ambient': Archetype.sabio,
    'New Age': Archetype.sabio,
    'Electrónica': Archetype.libre,
    'Alternativa': Archetype.libre,
    'K-Pop': Archetype.libre,
  };

  /// Una respuesta del test pesa más que todos los gustos de un arquetipo
  /// juntos: el arquetipo sale de cómo llevas lo que sientes, no de si te
  /// gusta el rock. Los gustos y la música siguen contando para desempatar.
  static const answerWeight = 7;
  static const hobbyWeight = 2;
  static const genreWeight = 1;

  /// Puntos de cada arquetipo con lo elegido.
  static Map<Archetype, int> scores({
    required List<String> hobbies,
    required List<String> genres,
    List<Archetype> answers = const [],
  }) {
    final result = {for (final a in Archetype.values) a: 0};
    for (final answer in answers) {
      result[answer] = result[answer]! + answerWeight;
    }
    for (final hobby in hobbies) {
      final a = hobbyPoints[hobby];
      if (a != null) result[a] = result[a]! + hobbyWeight;
    }
    for (final genre in genres) {
      final a = genrePoints[genre];
      if (a != null) result[a] = result[a]! + genreWeight;
    }
    return result;
  }

  /// El arquetipo dominante. Si hay empate gana el primero en el orden de
  /// [Archetype] (siempre el mismo resultado con las mismas respuestas).
  static Archetype compute({
    required List<String> hobbies,
    required List<String> genres,
    List<Archetype> answers = const [],
  }) {
    final points = scores(hobbies: hobbies, genres: genres, answers: answers);
    var best = Archetype.values.first;
    var bestScore = -1;
    for (final a in Archetype.values) {
      final score = points[a]!;
      if (score > bestScore) {
        bestScore = score;
        best = a;
      }
    }
    return best;
  }

  /// Qué tanto pesa el arquetipo ganador frente al total (0-1), para la
  /// barrita de "afinidad" del resultado.
  static double affinity({
    required List<String> hobbies,
    required List<String> genres,
    List<Archetype> answers = const [],
  }) {
    final points = scores(hobbies: hobbies, genres: genres, answers: answers);
    final total = points.values.fold(0, (a, b) => a + b);
    if (total == 0) return 0;
    final best = points.values.reduce((a, b) => a > b ? a : b);
    return best / total;
  }
}
