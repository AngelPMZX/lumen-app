import 'package:flutter/foundation.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/auth_provider.dart';
import 'analytics_service.dart';

/// Pide una reseña en la tienda solo en momentos felices y con cuidado:
///
/// - Solo tras logros (ruta completada, cofre abierto, repaso perfecto).
/// - Nunca si hoy el usuario registró un ánimo difícil.
/// - Solo con algo de recorrido (XP mínima y al menos un logro anterior).
/// - Como máximo una vez cada [cooldown].
/// - Nunca en web.
///
/// Google Play además limita cuántas veces se muestra el diálogo, así que
/// `requestReview` puede no mostrar nada: es normal.
class AppReviewService {
  AppReviewService._();
  static final AppReviewService instance = AppReviewService._();

  static const cooldown = Duration(days: 120);
  static const minXp = 150;
  static const minHappyMoments = 2;

  static const _prefLast = 'app_review_last_request';
  static const _prefMoments = 'app_review_happy_moments';

  /// Decisión pura (sin plataforma), para poder probarla.
  static bool shouldAsk({
    required DateTime now,
    required DateTime? lastRequest,
    required int happyMoments,
    required int totalXp,
    required bool hardDayToday,
  }) {
    if (hardDayToday) return false;
    if (totalXp < minXp) return false;
    if (happyMoments < minHappyMoments) return false;
    if (lastRequest != null && now.difference(lastRequest) < cooldown) return false;
    return true;
  }

  Future<void> onHappyMoment(String moment, AuthProvider auth) async {
    if (kIsWeb) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final moments = (prefs.getInt(_prefMoments) ?? 0) + 1;
      await prefs.setInt(_prefMoments, moments);

      final lastMs = prefs.getInt(_prefLast);
      final todayMood = await auth.getTodayMood();
      final ask = shouldAsk(
        now: DateTime.now(),
        lastRequest: lastMs == null ? null : DateTime.fromMillisecondsSinceEpoch(lastMs),
        happyMoments: moments,
        totalXp: auth.userProgress?.totalXp ?? 0,
        hardDayToday: todayMood?.category == 'negative',
      );
      if (!ask) return;

      final review = InAppReview.instance;
      if (!await review.isAvailable()) return;
      // Pausa breve: que la celebración termine antes de la tarjeta de Play
      await Future.delayed(const Duration(milliseconds: 1200));
      await review.requestReview();
      await prefs.setInt(_prefLast, DateTime.now().millisecondsSinceEpoch);
      AnalyticsService.instance.reviewPromptRequested(moment);
    } catch (e) {
      debugPrint('App review error: $e');
    }
  }
}
