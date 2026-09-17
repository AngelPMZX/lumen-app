import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Efectos cortos. Todos en Do mayor pentatónica para que la app suene
/// como una sola "banda sonora".
enum Sfx {
  // Lecciones
  correct,
  wrong,
  complete,
  pop,
  flip,
  commit,
  tick,
  toggleOn,
  toggleOff,
  bubble,
  swipe,
  holdRise,
  tapNode,
  // Hitos
  unlock,
  routeComplete,
  levelUp,
  achievement,
  reward,
  checkin,
  habit,
  save,
  plant,
  harvest,
  booster,
  buy,
  // Repaso diario
  cardDeal,
  reviewStart,
  reviewPerfect,
}

/// Señales de la respiración guiada.
enum BreathCue { inhale, hold, exhale, bowl }

/// Sonidos ambientales en bucle.
enum Ambient {
  rain,
  ocean,
  forest,
  softNoise,
  calmMusic,
  night,
  stream,
  mountain,
  sunrise,
  kalimba,
  musicBox,
}

/// Reproduce todos los sonidos de la app. Singleton.
///
/// Los archivos se generan con `tools/audio/generate_sounds.py` (síntesis
/// propia, sin muestras externas) y viven en `assets/sounds/`.
///
/// - Los efectos respetan el interruptor "Efectos de sonido" del perfil.
/// - El ambiente de las lecciones respeta su propio interruptor.
/// - Las señales de respiración las decide cada pantalla.
/// - Todo se mezcla con la música del usuario en vez de pausarla.
class SoundService {
  SoundService._();
  static final SoundService instance = SoundService._();

  static const _prefEffects = 'sound_effects_enabled';
  static const _prefLessonAmbient = 'lesson_ambient_enabled';

  bool _effectsEnabled = true;
  bool _lessonAmbientEnabled = true;
  bool _initialized = false;

  final Map<String, AudioPlayer> _oneShots = {};
  AudioPlayer? _ambientPlayer;
  Ambient? _currentAmbient;
  final Map<AudioPlayer, int> _fadeTokens = {};

  /// Sube con cada start/stop: un start que quedó a medias por un stop
  /// posterior descarta su reproductor en vez de dejarlo sonando.
  int _ambientGeneration = 0;

  /// Ambiente "de fondo" de la pantalla actual (p. ej. el de la ruta en una
  /// lección). Una práctica guiada lo reemplaza un rato y luego se vuelve a él.
  Ambient? _baseAmbient;
  double _baseVolume = 0.2;

  bool get effectsEnabled => _effectsEnabled;
  bool get lessonAmbientEnabled => _lessonAmbientEnabled;

  static String _sfxPath(Sfx s) {
    const names = {
      Sfx.toggleOn: 'toggle_on',
      Sfx.toggleOff: 'toggle_off',
      Sfx.holdRise: 'hold_rise',
      Sfx.tapNode: 'tap_node',
      Sfx.routeComplete: 'route_complete',
      Sfx.levelUp: 'level_up',
      Sfx.cardDeal: 'card_deal',
      Sfx.reviewStart: 'review_start',
      Sfx.reviewPerfect: 'review_perfect',
    };
    return 'sounds/sfx/${names[s] ?? s.name}.mp3';
  }

  static String _cuePath(BreathCue c) => 'sounds/breathing/${c.name}.mp3';

  static String _ambientPath(Ambient a) {
    const names = {
      Ambient.softNoise: 'soft_noise',
      Ambient.calmMusic: 'calm_music',
      Ambient.musicBox: 'music_box',
    };
    return 'sounds/ambient/${names[a] ?? a.name}.mp3';
  }

  /// Ambiente de cada ruta dentro de sus lecciones.
  static Ambient ambientForRoute(String? routeId) => switch (routeId) {
        'autoconocimiento' => Ambient.night,
        'mindfulness' => Ambient.stream,
        'resiliencia' => Ambient.mountain,
        'autoestima' => Ambient.sunrise,
        'relaciones' => Ambient.kalimba,
        'amor' => Ambient.musicBox,
        _ => Ambient.calmMusic,
      };

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      _effectsEnabled = prefs.getBool(_prefEffects) ?? true;
      _lessonAmbientEnabled = prefs.getBool(_prefLessonAmbient) ?? true;
    } catch (e) {
      debugPrint('SoundService prefs error: $e');
    }
    if (!kIsWeb) {
      try {
        await AudioPlayer.global.setAudioContext(
          AudioContextConfig(focus: AudioContextConfigFocus.mixWithOthers).build(),
        );
      } catch (e) {
        debugPrint('SoundService audio context error: $e');
      }
    }
  }

  Future<void> setEffectsEnabled(bool value) async {
    _effectsEnabled = value;
    await _savePref(_prefEffects, value);
  }

  Future<void> setLessonAmbientEnabled(bool value) async {
    _lessonAmbientEnabled = value;
    await _savePref(_prefLessonAmbient, value);
    if (value) {
      await returnToBaseAmbient();
    } else if (_baseAmbient != null) {
      await stopAmbient(fadeOut: const Duration(milliseconds: 500));
    }
  }

  Future<void> _savePref(String key, bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(key, value);
    } catch (e) {
      debugPrint('SoundService prefs error: $e');
    }
  }

  // ── Efectos ──────────────────────────────────────────────────────────────
  /// Efecto de interfaz. No suena si el usuario apagó los efectos.
  Future<void> play(Sfx sfx, {double volume = 0.6}) async {
    if (!_effectsEnabled) return;
    await _playOneShot(_sfxPath(sfx), volume);
  }

  /// Detiene un efecto largo (p. ej. [Sfx.holdRise] al soltar el botón).
  Future<void> stop(Sfx sfx) async {
    try {
      await _oneShots[_sfxPath(sfx)]?.stop();
    } catch (_) {}
  }

  /// Acierto en racha: cada acierto seguido suena un tono más arriba.
  /// [level] 0 = segundo acierto seguido.
  Future<void> combo(int level, {double volume = 0.55}) async {
    if (!_effectsEnabled) return;
    await _playOneShot('sounds/sfx/combo_${level.clamp(0, 5)}.mp3', volume);
  }

  /// Nota de la escala pentatónica (0-7), para armar melodías al acertar.
  Future<void> note(int index, {double volume = 0.55}) async {
    if (!_effectsEnabled) return;
    await _playOneShot('sounds/sfx/note_${index.clamp(0, 7)}.mp3', volume);
  }

  /// Estrella del resultado (0-2): cada una suena más aguda.
  Future<void> star(int index, {double volume = 0.6}) async {
    if (!_effectsEnabled) return;
    await _playOneShot('sounds/sfx/star_${index.clamp(0, 2)}.mp3', volume);
  }

  /// Señal de respiración. La pantalla decide si suena (tiene su propio switch).
  Future<void> cue(BreathCue cue, {double volume = 0.7}) =>
      _playOneShot(_cuePath(cue), volume);

  Future<void> _playOneShot(String path, double volume) async {
    try {
      final player = _oneShots.putIfAbsent(path, () {
        final p = AudioPlayer();
        p.setReleaseMode(ReleaseMode.stop);
        return p;
      });
      await player.stop();
      await player.play(AssetSource(path), volume: volume);
    } catch (e) {
      debugPrint('SoundService play error ($path): $e');
    }
  }

  // ── Ambiente de fondo de una pantalla ────────────────────────────────────
  /// Define el ambiente base (el de la ruta en una lección) y lo inicia si el
  /// usuario tiene activado el ambiente de lecciones.
  Future<void> setBaseAmbient(Ambient ambient, {double volume = 0.2}) async {
    _baseAmbient = ambient;
    _baseVolume = volume;
    await returnToBaseAmbient();
  }

  /// Quita el ambiente base (al salir de la pantalla) y apaga lo que suene.
  Future<void> clearBaseAmbient() async {
    _baseAmbient = null;
    await stopAmbient();
  }

  /// Vuelve al ambiente base tras un ambiente temporal (p. ej. una práctica).
  Future<void> returnToBaseAmbient() async {
    final base = _baseAmbient;
    if (base == null || !_lessonAmbientEnabled) {
      await stopAmbient();
      return;
    }
    await startAmbient(base, volume: _baseVolume);
  }

  // ── Ambiente ─────────────────────────────────────────────────────────────
  Future<void> startAmbient(
    Ambient ambient, {
    double volume = 0.55,
    Duration fadeIn = const Duration(milliseconds: 1600),
  }) async {
    try {
      if (_currentAmbient == ambient && _ambientPlayer?.state == PlayerState.playing) {
        final player = _ambientPlayer!;
        await _fade(player, player.volume, volume, const Duration(milliseconds: 600));
        return;
      }
      await stopAmbient(fadeOut: const Duration(milliseconds: 300));
      final generation = ++_ambientGeneration;
      final player = AudioPlayer();
      _ambientPlayer = player;
      _currentAmbient = ambient;
      await player.setReleaseMode(ReleaseMode.loop);
      await player.play(AssetSource(_ambientPath(ambient)), volume: 0);
      if (generation != _ambientGeneration) {
        await player.stop();
        await player.dispose();
        return;
      }
      await _fade(player, 0, volume, fadeIn);
    } catch (e) {
      debugPrint('SoundService ambient error: $e');
    }
  }

  Future<void> pauseAmbient() async {
    try {
      await _ambientPlayer?.pause();
    } catch (_) {}
  }

  Future<void> resumeAmbient() async {
    try {
      await _ambientPlayer?.resume();
    } catch (_) {}
  }

  Future<void> stopAmbient({
    Duration fadeOut = const Duration(milliseconds: 1200),
  }) async {
    _ambientGeneration++;
    final player = _ambientPlayer;
    if (player == null) return;
    _ambientPlayer = null;
    _currentAmbient = null;
    try {
      await _fade(player, player.volume, 0, fadeOut);
      await player.stop();
      _fadeTokens.remove(player);
      await player.dispose();
    } catch (e) {
      debugPrint('SoundService stop ambient error: $e');
    }
  }

  Future<void> _fade(AudioPlayer player, double from, double to, Duration d) async {
    final token = (_fadeTokens[player] ?? 0) + 1;
    _fadeTokens[player] = token;
    const steps = 16;
    for (int i = 1; i <= steps; i++) {
      // Un fade nuevo sobre el mismo reproductor cancela el anterior
      if (_fadeTokens[player] != token) return;
      await player.setVolume(from + (to - from) * i / steps);
      await Future.delayed(Duration(milliseconds: d.inMilliseconds ~/ steps));
    }
  }
}
