import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/models/wellness_route.dart';

/// Servicio que carga las rutas de bienestar desde Firestore.
/// Mantiene cache en memoria para no hacer queries repetidas.
/// Soporta idioma dinámico (es/en).
class RoutesService {
  static final RoutesService _instance = RoutesService._();
  factory RoutesService() => _instance;
  RoutesService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Cache en memoria: locale → lista de rutas
  final Map<String, List<WellnessRoute>> _cache = {};

  /// Timestamp de última carga por locale
  final Map<String, DateTime> _lastFetch = {};

  /// Duración del cache (30 minutos)
  static const _cacheDuration = Duration(minutes: 30);

  /// Carga todas las rutas con sus lecciones y steps.
  /// [locale] es 'es' o 'en'.
  /// Usa cache si está fresco, sino carga de Firestore.
  Future<List<WellnessRoute>> getRoutes(String locale) async {
    // Verificar cache
    if (_cache.containsKey(locale) && _lastFetch.containsKey(locale)) {
      final elapsed = DateTime.now().difference(_lastFetch[locale]!);
      if (elapsed < _cacheDuration) {
        return _cache[locale]!;
      }
    }

    try {
      final routes = await _fetchRoutesFromFirestore(locale);
      _cache[locale] = routes;
      _lastFetch[locale] = DateTime.now();
      return routes;
    } catch (e) {
      debugPrint('❌❌❌ Error loading routes from Firestore: $e');
debugPrint('StackTrace: ${StackTrace.current}');
      // Si hay cache expirado, usarlo como fallback
      if (_cache.containsKey(locale)) {
        return _cache[locale]!;
      }
      // Último recurso: rutas hardcodeadas
      return WellnessRoute.all;
    }
  }

  /// Fuerza recarga desde Firestore (ignora cache)
  Future<List<WellnessRoute>> refreshRoutes(String locale) async {
    _cache.remove(locale);
    _lastFetch.remove(locale);
    return getRoutes(locale);
  }

  /// Limpia todo el cache
  void clearCache() {
    _cache.clear();
    _lastFetch.clear();
  }

  static const _prefsVersionKey = 'routes_content_version';

  /// Carga las rutas usando la caché local de Firestore cuando el contenido
  /// no cambió.
  ///
  /// `seed/seed_routes.js` escribe `wellness_routes/_meta` con `version` y el
  /// total de rutas, lecciones y pasos (no tiene `order`, así que no aparece
  /// en la lista de rutas). Flujo:
  /// 1. Leer `_meta` del servidor: 1 lectura.
  /// 2. Si la versión coincide con la guardada, cargar todo desde la caché
  ///    local (0 lecturas) y verificar que estén todas las lecciones y pasos.
  /// 3. Si cambió, falta algo en caché o no hay `_meta`, cargar del servidor
  ///    (~473 lecturas) y guardar la versión.
  /// Sin internet se usa lo que haya en caché.
  Future<List<WellnessRoute>> _fetchRoutesFromFirestore(String locale) async {
    Map<String, dynamic>? meta;
    var metaReachable = false;
    try {
      final metaDoc = await _firestore
          .collection('wellness_routes')
          .doc('_meta')
          .get(const GetOptions(source: Source.server));
      metaReachable = true;
      meta = metaDoc.data();
    } catch (e) {
      debugPrint('Routes meta unavailable (offline?): $e');
    }

    final serverVersion = (meta?['version'] as num?)?.toInt();
    int? savedVersion;
    try {
      final prefs = await SharedPreferences.getInstance();
      savedVersion = prefs.getInt(_prefsVersionKey);
    } catch (_) {}

    final offline = !metaReachable;
    final unchanged = serverVersion != null && serverVersion == savedVersion;

    if (offline || unchanged) {
      try {
        final cached = await _loadRoutes(locale, Source.cache);
        if (cached.isNotEmpty && (offline || _matchesMeta(cached, meta!))) {
          debugPrint('📦 Routes loaded from local cache (v$savedVersion)');
          return cached;
        }
      } catch (e) {
        debugPrint('Routes cache miss: $e');
      }
    }

    final fresh = await _loadRoutes(locale, Source.server);
    if (serverVersion != null && _matchesMeta(fresh, meta!)) {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt(_prefsVersionKey, serverVersion);
      } catch (_) {}
    }
    return fresh;
  }

  /// La caché puede estar incompleta (desalojo parcial): contar antes de usarla.
  bool _matchesMeta(List<WellnessRoute> routes, Map<String, dynamic> meta) {
    final lessons = routes.fold<int>(0, (n, r) => n + r.lessons.length);
    final steps = routes.fold<int>(
        0, (n, r) => n + r.lessons.fold<int>(0, (m, l) => m + l.steps.length));
    return routes.length == (meta['routeCount'] as num?)?.toInt() &&
        lessons == (meta['lessonCount'] as num?)?.toInt() &&
        steps == (meta['stepCount'] as num?)?.toInt();
  }

  Future<List<WellnessRoute>> _loadRoutes(String locale, Source source) async {
    final options = GetOptions(source: source);
    final routesSnap = await _firestore
        .collection('wellness_routes')
        .orderBy('order')
        .get(options);

    // Rutas, lecciones y pasos se piden en paralelo: con 70 lecciones, hacerlo
    // en secuencia eran ~78 consultas una tras otra y la pantalla tardaba.
    // Future.wait conserva el orden, así que el `orderBy` se respeta.
    return Future.wait(routesSnap.docs.map((routeDoc) async {
      final routeData = routeDoc.data();

      final lessonsSnap = await routeDoc.reference
          .collection('lessons')
          .orderBy('order')
          .get(options);

      final lessons = await Future.wait(lessonsSnap.docs.map((lessonDoc) async {
        final lessonData = lessonDoc.data();

        final stepsSnap = await lessonDoc.reference
            .collection('steps')
            .orderBy('order')
            .get(options);

        return Lesson(
          id: lessonDoc.id,
          title: _localized(lessonData, 'title', locale),
          subtitle: _localized(lessonData, 'subtitle', locale),
          xpReward: lessonData['xpReward'] ?? 15,
          steps: stepsSnap.docs
              .map((stepDoc) => _parseStep(stepDoc.data(), locale))
              .toList(),
        );
      }));

      return WellnessRoute(
        id: routeDoc.id,
        title: _localized(routeData, 'title', locale),
        description: _localized(routeData, 'description', locale),
        emoji: routeData['emoji'] ?? '📘',
        color: Color(routeData['color'] ?? 0xFF6366F1),
        colorDark: Color(routeData['colorDark'] ?? 0xFF4338CA),
        lessons: lessons,
      );
    }));
  }

  /// Parsea un step desde Firestore
  LessonStep _parseStep(Map<String, dynamic> data, String locale) {
    final type = data['type'] ?? 'reading';

    switch (type) {
      case 'quiz':
        return LessonStep.quiz(
          question: _localized(data, 'question', locale),
          options: _localizedList(data, 'options', locale),
          correctIndex: data['correctIndex'] ?? 0,
          explanation: _localized(data, 'explanation', locale),
        );
      case 'exercise':
        return LessonStep.exercise(
          title: _localized(data, 'title', locale),
          instruction: _localized(data, 'instruction', locale),
          placeholder: _localizedNullable(data, 'placeholder', locale),
        );
      case 'scenario':
        return LessonStep.scenario(
          title: _localized(data, 'title', locale),
          situation: _localized(data, 'situation', locale),
          options: _localizedList(data, 'options', locale),
          outcomes: _localizedList(data, 'outcomes', locale),
        );
      case 'reveal':
        return LessonStep.reveal(
          question: _localized(data, 'question', locale),
          answer: _localized(data, 'answer', locale),
          title: _localizedNullable(data, 'title', locale),
        );
      case 'slider':
        return LessonStep.slider(
          question: _localized(data, 'question', locale),
          minLabel: _localized(data, 'minLabel', locale),
          maxLabel: _localized(data, 'maxLabel', locale),
          responses: _localizedList(data, 'responses', locale),
          title: _localizedNullable(data, 'title', locale),
        );
      case 'sort':
        return LessonStep.sort(
          title: _localized(data, 'title', locale),
          instruction: _localized(data, 'instruction', locale),
          categories: _localizedList(data, 'categories', locale),
          items: _localizedList(data, 'items', locale),
          itemCategory: List<int>.from(data['itemCategory'] ?? const []),
          explanation: _localizedNullable(data, 'explanation', locale),
        );
      case 'mythfact':
        return LessonStep.mythFact(
          title: _localized(data, 'title', locale),
          statements: _localizedList(data, 'statements', locale),
          truths: List<bool>.from(data['truths'] ?? const []),
          feedbacks: _localizedList(data, 'feedbacks', locale),
        );
      case 'practice':
        return LessonStep.practice(
          title: _localized(data, 'title', locale),
          intro: _localized(data, 'intro', locale),
          prompts: _localizedList(data, 'prompts', locale),
          durations: List<int>.from(data['durations'] ?? const []),
          motions: data['motions'] == null
              ? null
              : List<String>.from(data['motions']),
          outro: _localizedNullable(data, 'outro', locale),
        );
      case 'order':
        return LessonStep.order(
          title: _localized(data, 'title', locale),
          instruction: _localized(data, 'instruction', locale),
          items: _localizedList(data, 'items', locale),
          explanation: _localizedNullable(data, 'explanation', locale),
        );
      case 'pick':
        final responses = _localizedList(data, 'responses', locale);
        return LessonStep.pick(
          question: _localized(data, 'question', locale),
          options: _localizedList(data, 'options', locale),
          explanation: _localizedNullable(data, 'explanation', locale),
          responses: responses.isEmpty ? null : responses,
          title: _localizedNullable(data, 'title', locale),
        );
      case 'story':
        return LessonStep.story(
          title: _localized(data, 'title', locale),
          lines: _localizedList(data, 'lines', locale),
          speaker: data['speaker'] as String?,
        );
      case 'commit':
        return LessonStep.commit(
          title: _localized(data, 'title', locale),
          content: _localized(data, 'content', locale),
          options: _localizedList(data, 'options', locale),
        );
      case 'reading':
      default:
        return LessonStep.reading(
          title: _localized(data, 'title', locale),
          content: _localized(data, 'content', locale),
        );
    }
  }

  /// Obtiene el string localizado: busca field_es o field_en,
  /// con fallback al otro idioma si no existe
  String _localized(Map<String, dynamic> data, String field, String locale) {
    final primary = data['${field}_$locale'];
    if (primary != null && primary is String && primary.isNotEmpty) {
      return primary;
    }
    // Fallback al otro idioma
    final fallbackLocale = locale == 'es' ? 'en' : 'es';
    final fallback = data['${field}_$fallbackLocale'];
    if (fallback != null && fallback is String) return fallback;
    // Fallback sin sufijo de idioma
    final raw = data[field];
    if (raw != null && raw is String) return raw;
    return '';
  }

  /// Obtiene un string localizado nullable
  String? _localizedNullable(Map<String, dynamic> data, String field, String locale) {
    final primary = data['${field}_$locale'];
    if (primary != null && primary is String && primary.isNotEmpty) {
      return primary;
    }
    final fallbackLocale = locale == 'es' ? 'en' : 'es';
    final fallback = data['${field}_$fallbackLocale'];
    if (fallback != null && fallback is String && fallback.isNotEmpty) {
      return fallback;
    }
    return null;
  }

  /// Obtiene una lista localizada (para options del quiz)
  List<String> _localizedList(Map<String, dynamic> data, String field, String locale) {
    final primary = data['${field}_$locale'];
    if (primary != null && primary is List && primary.isNotEmpty) {
      return List<String>.from(primary);
    }
    final fallbackLocale = locale == 'es' ? 'en' : 'es';
    final fallback = data['${field}_$fallbackLocale'];
    if (fallback != null && fallback is List) {
      return List<String>.from(fallback);
    }
    return [];
  }
}