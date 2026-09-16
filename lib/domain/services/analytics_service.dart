import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Eventos de uso para medir retención y mejorar la app. Singleton.
///
/// **Privacidad (app de salud mental)**: aquí NUNCA se envía contenido
/// sensible: ni qué ánimo registró el usuario, ni textos del diario o de los
/// ejercicios, ni el texto de sus retos, ni si abrió la pantalla de ayuda en
/// crisis. Solo acciones y ids de contenido (rutas, lecciones, técnicas).
///
/// En debug no se envía nada salvo con `--dart-define=ANALYTICS_DEBUG=true`,
/// para no ensuciar las métricas reales. En web solo funciona si las opciones
/// de Firebase traen `measurementId`.
class AnalyticsService {
  AnalyticsService._();
  static final AnalyticsService instance = AnalyticsService._();

  static const _debugOverride = bool.fromEnvironment('ANALYTICS_DEBUG');

  FirebaseAnalytics? _analytics;

  bool get _supported {
    if (!kIsWeb) return true;
    try {
      return Firebase.app().options.measurementId != null;
    } catch (_) {
      return false;
    }
  }

  Future<void> initialize() async {
    if (!_supported) return;
    try {
      _analytics = FirebaseAnalytics.instance;
      await _analytics!.setAnalyticsCollectionEnabled(!kDebugMode || _debugOverride);
    } catch (e) {
      debugPrint('Analytics init error: $e');
      _analytics = null;
    }
  }

  /// Observador para las pantallas con nombre (`Navigator.pushNamed`).
  /// [excludedRoutes] no se registran (p. ej. la pantalla de ayuda en crisis).
  FirebaseAnalyticsObserver? observer({Set<String> excludedRoutes = const {}}) {
    final analytics = _analytics;
    if (analytics == null) return null;
    return FirebaseAnalyticsObserver(
      analytics: analytics,
      routeFilter: (route) {
        final name = route?.settings.name;
        return route is PageRoute && name != null && !excludedRoutes.contains(name);
      },
    );
  }

  Future<void> _log(String name, [Map<String, Object>? params]) async {
    final analytics = _analytics;
    if (analytics == null) return;
    try {
      await analytics.logEvent(name: name, parameters: params);
    } catch (e) {
      debugPrint('Analytics event error ($name): $e');
    }
  }

  Future<void> setLanguage(String languageCode) async {
    try {
      await _analytics?.setUserProperty(name: 'app_language', value: languageCode);
    } catch (_) {}
  }

  // ── Rutas y lecciones ────────────────────────────────────────────────────
  Future<void> lessonStart(String? routeId, String lessonId) =>
      _log('lesson_start', {'route_id': routeId ?? 'unknown', 'lesson_id': lessonId});

  Future<void> lessonComplete(String? routeId, String lessonId, int xp) => _log(
      'lesson_complete', {'route_id': routeId ?? 'unknown', 'lesson_id': lessonId, 'xp': xp});

  /// Dónde abandonan las lecciones: clave para saber qué paso no funciona.
  Future<void> lessonAbandoned(String? routeId, String lessonId, int stepIndex, int totalSteps) =>
      _log('lesson_abandoned', {
        'route_id': routeId ?? 'unknown',
        'lesson_id': lessonId,
        'step_index': stepIndex,
        'total_steps': totalSteps,
      });

  Future<void> routeComplete(String routeId) => _log('route_complete', {'route_id': routeId});

  Future<void> nextLessonTapped(String? routeId) =>
      _log('next_lesson_tapped', {'route_id': routeId ?? 'unknown'});

  Future<void> exerciseSavedToDiary(String lessonId) =>
      _log('exercise_saved_to_diary', {'lesson_id': lessonId});

  // ── Retos ────────────────────────────────────────────────────────────────
  Future<void> commitmentCreated(String? routeId, String lessonId) =>
      _log('commitment_created', {'route_id': routeId ?? 'unknown', 'lesson_id': lessonId});

  /// Solo el estado (done / partial / skipped), nunca el texto del reto.
  Future<void> commitmentAnswered(String status, int daysAgo) =>
      _log('commitment_answered', {'status': status, 'days_ago': daysAgo});

  Future<void> commitmentRetried() => _log('commitment_retried');

  // ── Hábitos de bienestar ─────────────────────────────────────────────────
  Future<void> breathingComplete(String technique, int minutes) =>
      _log('breathing_complete', {'technique': technique, 'minutes': minutes});

  /// Sin el ánimo elegido: es un dato de salud.
  Future<void> moodCheckIn() => _log('mood_checkin');

  /// Sin contenido ni longitud del texto.
  Future<void> diaryEntrySaved() => _log('diary_entry_saved');

  Future<void> habitCheckIn() => _log('habit_checkin');

  // ── Jardín ───────────────────────────────────────────────────────────────
  Future<void> gardenAction(String action, {String? itemId}) =>
      _log('garden_action', {'action': action, 'item_id': ?itemId});
}
