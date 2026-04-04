import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
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
      debugPrint('Error loading routes from Firestore: $e');
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

  /// Carga las rutas desde Firestore
  Future<List<WellnessRoute>> _fetchRoutesFromFirestore(String locale) async {
    final routesSnap = await _firestore
        .collection('wellness_routes')
        .orderBy('order')
        .get();

    final List<WellnessRoute> routes = [];

    for (final routeDoc in routesSnap.docs) {
      final routeData = routeDoc.data();

      // Cargar lecciones de la subcolección
      final lessonsSnap = await _firestore
          .collection('wellness_routes')
          .doc(routeDoc.id)
          .collection('lessons')
          .orderBy('order')
          .get();

      final List<Lesson> lessons = [];

      for (final lessonDoc in lessonsSnap.docs) {
        final lessonData = lessonDoc.data();

        // Cargar steps de la subcolección
        final stepsSnap = await _firestore
            .collection('wellness_routes')
            .doc(routeDoc.id)
            .collection('lessons')
            .doc(lessonDoc.id)
            .collection('steps')
            .orderBy('order')
            .get();

        final List<LessonStep> steps = stepsSnap.docs
            .map((stepDoc) => _parseStep(stepDoc.data(), locale))
            .toList();

        lessons.add(Lesson(
          id: lessonDoc.id,
          title: _localized(lessonData, 'title', locale),
          subtitle: _localized(lessonData, 'subtitle', locale),
          xpReward: lessonData['xpReward'] ?? 15,
          steps: steps,
        ));
      }

      routes.add(WellnessRoute(
        id: routeDoc.id,
        title: _localized(routeData, 'title', locale),
        description: _localized(routeData, 'description', locale),
        emoji: routeData['emoji'] ?? '📘',
        color: Color(routeData['color'] ?? 0xFF6366F1),
        colorDark: Color(routeData['colorDark'] ?? 0xFF4338CA),
        lessons: lessons,
      ));
    }

    return routes;
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