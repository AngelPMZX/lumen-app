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

  static Archetype? fromId(String? id) {
    for (final a in Archetype.values) {
      if (a.id == id) return a;
    }
    return null;
  }
}

/// Cómo se descubre el arquetipo con lo que la persona elige en su registro.
/// Los valores de gustos y música se guardan en español en Firestore desde la
/// primera versión, así que aquí se mantienen tal cual.
class ArchetypeQuiz {
  ArchetypeQuiz._();

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

  static const hobbyWeight = 2;
  static const genreWeight = 1;

  /// Puntos de cada arquetipo con lo elegido.
  static Map<Archetype, int> scores({
    required List<String> hobbies,
    required List<String> genres,
  }) {
    final result = {for (final a in Archetype.values) a: 0};
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
  }) {
    final points = scores(hobbies: hobbies, genres: genres);
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
  }) {
    final points = scores(hobbies: hobbies, genres: genres);
    final total = points.values.fold(0, (a, b) => a + b);
    if (total == 0) return 0;
    final best = points.values.reduce((a, b) => a > b ? a : b);
    return best / total;
  }
}
