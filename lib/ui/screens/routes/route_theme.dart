/// Decoración visual por ruta (por id), compartida por el menú y el mapa.
abstract final class RouteTheme {
  static const _decorations = <String, List<String>>{
    'emociones': ['🌈', '☁️', '🎈', '✨', '🌤️', '💭'],
    'autoconocimiento': ['🧭', '🔮', '🗝️', '✨', '🌙', '📜'],
    'mindfulness': ['🍃', '🪷', '🌿', '🫧', '🕊️', '🌸'],
    'resiliencia': ['⛰️', '🎋', '🌱', '🔥', '🌄', '🪨'],
    'autoestima': ['⭐', '🌟', '💫', '🌻', '👑', '✨'],
    'relaciones': ['💬', '🫶', '🤝', '🌷', '🎶', '☕'],
    'amor': ['💗', '🌹', '💌', '🦋', '💞', '🌸'],
    'ansiedad': ['🌊', '🐚', '🫧', '⛵', '🐢', '🌿'],
    'sueno': ['🌙', '⭐', '☁️', '💤', '🦉', '✨'],
  };

  /// Emojis decorativos de la ruta. Al agregar una ruta nueva, agregar sus
  /// emojis aquí (si no, usa un set genérico).
  static List<String> decorations(String routeId) =>
      _decorations[routeId] ?? const ['✨', '🌿', '☁️', '⭐'];
}
