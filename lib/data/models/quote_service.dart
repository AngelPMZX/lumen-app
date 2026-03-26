import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class QuoteService {
  static const _cacheKey = 'cached_quotes';
  static const _cacheTimestampKey = 'cached_quotes_timestamp';
  static const _todayQuoteKey = 'today_quote';
  static const _todayQuoteDateKey = 'today_quote_date';
  static const _cacheDuration = Duration(hours: 6);

  static Future<Quote> getQuoteOfTheDay() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final cachedDate = prefs.getString(_todayQuoteDateKey);

    // Si ya tenemos frase de hoy en cache, usarla
    if (cachedDate == today) {
      final cached = prefs.getString(_todayQuoteKey);
      if (cached != null) {
        try {
          return Quote.fromJson(jsonDecode(cached));
        } catch (_) {}
      }
    }

    Quote? quote;

    // Solo intentar API en móvil (no web — CORS bloquea)
    if (!kIsWeb) {
      quote = await _fetchFromApi(prefs);
    }

    // Fallback local en español
    quote ??= _getLocalQuote();

    // Cachear como frase de hoy
    await prefs.setString(_todayQuoteKey, jsonEncode(quote.toJson()));
    await prefs.setString(_todayQuoteDateKey, today);

    return quote;
  }

  static Future<Quote?> _fetchFromApi(SharedPreferences prefs) async {
    try {
      final cachedTimestamp = prefs.getInt(_cacheTimestampKey) ?? 0;
      final now = DateTime.now().millisecondsSinceEpoch;
      final cachedQuotes = prefs.getString(_cacheKey);

      if (cachedQuotes != null &&
          now - cachedTimestamp < _cacheDuration.inMilliseconds) {
        final List<dynamic> quotes = jsonDecode(cachedQuotes);
        if (quotes.isNotEmpty) {
          final dayIndex = DateTime.now().day % quotes.length;
          final q = quotes[dayIndex];
          return Quote(
            text: q['q'] ?? '',
            author: q['a'] ?? 'Desconocido',
            source: 'ZenQuotes.io',
          );
        }
      }

      final response = await http
          .get(Uri.parse('https://zenquotes.io/api/quotes'))
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        await prefs.setString(_cacheKey, response.body);
        await prefs.setInt(_cacheTimestampKey, now);

        if (data.isNotEmpty) {
          final dayIndex = DateTime.now().day % data.length;
          final q = data[dayIndex];
          return Quote(
            text: q['q'] ?? '',
            author: q['a'] ?? 'Desconocido',
            source: 'ZenQuotes.io',
          );
        }
      }
    } catch (e) {
      debugPrint('ZenQuotes API error: $e');
    }
    return null;
  }

  static Quote _getLocalQuote() {
    final now = DateTime.now();
    final dayOfYear = now.difference(DateTime(now.year, 1, 1)).inDays;
    final index = dayOfYear % _localQuotes.length;
    return _localQuotes[index];
  }

  static const List<Quote> _localQuotes = [
    Quote(text: 'La paz viene de adentro. No la busques afuera.', author: 'Buda'),
    Quote(text: 'No tienes que controlarlo todo. A veces solo necesitas soltar.', author: 'Lumen'),
    Quote(text: 'Cada día es una nueva oportunidad para ser más amable contigo mismo.', author: 'Lumen'),
    Quote(text: 'La vulnerabilidad no es debilidad. Es la mayor medida de coraje.', author: 'Brené Brown'),
    Quote(text: 'Tu mente es un jardín. Tus pensamientos son las semillas.', author: 'Lumen'),
    Quote(text: 'No es la carga la que te destruye, es cómo la cargas.', author: 'Lou Holtz'),
    Quote(text: 'Respira. Estás exactamente donde necesitas estar.', author: 'Lumen'),
    Quote(text: 'Hoy mereces tu propia amabilidad tanto como cualquier otra persona.', author: 'Lumen'),
    Quote(text: 'El autocuidado no es egoísmo. No puedes servir de una taza vacía.', author: 'Eleanor Brownn'),
    Quote(text: 'Las emociones son como olas. Obsérvalas ir y venir.', author: 'Lumen'),
    Quote(text: 'Un paso pequeño hoy es un gran salto para tu bienestar.', author: 'Lumen'),
    Quote(text: 'No tienes que ser perfecto para merecer amor y aceptación.', author: 'Lumen'),
    Quote(text: 'La gratitud transforma lo que tienes en suficiente.', author: 'Melody Beattie'),
    Quote(text: 'Tu valor no disminuye por la incapacidad de alguien de ver tu luz.', author: 'Lumen'),
    Quote(text: 'Está bien no estar bien. Lo que importa es no quedarte ahí.', author: 'Lumen'),
    Quote(text: 'La calma es un superpoder en un mundo lleno de ruido.', author: 'Lumen'),
    Quote(text: 'No compares tu capítulo 1 con el capítulo 20 de alguien más.', author: 'Lumen'),
    Quote(text: 'Sé paciente contigo mismo. El crecimiento toma tiempo.', author: 'Lumen'),
    Quote(text: 'La mejor relación que puedes tener es la que tienes contigo mismo.', author: 'Diane Von Furstenberg'),
    Quote(text: 'Hoy elige la compasión. Empieza contigo.', author: 'Lumen'),
    Quote(text: 'El descanso no es rendirse. Es prepararse para seguir.', author: 'Lumen'),
    Quote(text: 'No necesitas una razón para merecer paz interior.', author: 'Lumen'),
    Quote(text: 'Cada respiración es una oportunidad para empezar de nuevo.', author: 'Lumen'),
    Quote(text: 'Tu salud mental es una prioridad, no un lujo.', author: 'Lumen'),
    Quote(text: 'Las pequeñas victorias de hoy son los grandes logros de mañana.', author: 'Lumen'),
    Quote(text: 'Permítete sentir. Las emociones no son tu enemigo.', author: 'Lumen'),
    Quote(text: 'Lo que nutre tu alma nunca es una pérdida de tiempo.', author: 'Lumen'),
    Quote(text: 'No eres tus pensamientos. Eres quien los observa.', author: 'Eckhart Tolle'),
    Quote(text: 'Hoy es un buen día para cuidar de ti.', author: 'Lumen'),
    Quote(text: 'La verdadera fortaleza se muestra en los momentos de vulnerabilidad.', author: 'Lumen'),
    Quote(text: 'Tu viaje importa. Cada paso cuenta.', author: 'Lumen'),
  ];
}

class Quote {
  final String text;
  final String author;
  final String source;

  const Quote({
    required this.text,
    required this.author,
    this.source = 'Lumen',
  });

  Map<String, dynamic> toJson() => {'text': text, 'author': author, 'source': source};

  factory Quote.fromJson(Map<String, dynamic> json) => Quote(
        text: json['text'] ?? '',
        author: json['author'] ?? 'Lumen',
        source: json['source'] ?? 'Lumen',
      );
}