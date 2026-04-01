import 'dart:convert';
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

    if (cachedDate == today) {
      final cached = prefs.getString(_todayQuoteKey);
      if (cached != null) {
        try {
          return Quote.fromJson(jsonDecode(cached));
        } catch (_) {}
      }
    }

    Quote? quote;

    if (!kIsWeb) {
      quote = await _fetchFromApi(prefs);
    }

    quote ??= _getLocalQuote();

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
            authorKey: q['a'] == null ? 'quoteService.unknownAuthor' : null,
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
            authorKey: q['a'] == null ? 'quoteService.unknownAuthor' : null,
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
    Quote(
      text: 'La paz viene de adentro. No la busques afuera.',
      textKey: 'quoteService.localQuotes.0.text',
      author: 'Buda',
    ),
    Quote(
      text: 'No tienes que controlarlo todo. A veces solo necesitas soltar.',
      textKey: 'quoteService.localQuotes.1.text',
      author: 'Lumen',
    ),
    Quote(
      text: 'Cada día es una nueva oportunidad para ser más amable contigo mismo.',
      textKey: 'quoteService.localQuotes.2.text',
      author: 'Lumen',
    ),
    Quote(
      text: 'La vulnerabilidad no es debilidad. Es la mayor medida de coraje.',
      textKey: 'quoteService.localQuotes.3.text',
      author: 'Brené Brown',
    ),
    Quote(
      text: 'Tu mente es un jardín. Tus pensamientos son las semillas.',
      textKey: 'quoteService.localQuotes.4.text',
      author: 'Lumen',
    ),
    Quote(
      text: 'No es la carga la que te destruye, es cómo la cargas.',
      textKey: 'quoteService.localQuotes.5.text',
      author: 'Lou Holtz',
    ),
    Quote(
      text: 'Respira. Estás exactamente donde necesitas estar.',
      textKey: 'quoteService.localQuotes.6.text',
      author: 'Lumen',
    ),
    Quote(
      text: 'Hoy mereces tu propia amabilidad tanto como cualquier otra persona.',
      textKey: 'quoteService.localQuotes.7.text',
      author: 'Lumen',
    ),
    Quote(
      text: 'El autocuidado no es egoísmo. No puedes servir de una taza vacía.',
      textKey: 'quoteService.localQuotes.8.text',
      author: 'Eleanor Brownn',
    ),
    Quote(
      text: 'Las emociones son como olas. Obsérvalas ir y venir.',
      textKey: 'quoteService.localQuotes.9.text',
      author: 'Lumen',
    ),
    Quote(
      text: 'Un paso pequeño hoy es un gran salto para tu bienestar.',
      textKey: 'quoteService.localQuotes.10.text',
      author: 'Lumen',
    ),
    Quote(
      text: 'No tienes que ser perfecto para merecer amor y aceptación.',
      textKey: 'quoteService.localQuotes.11.text',
      author: 'Lumen',
    ),
    Quote(
      text: 'La gratitud transforma lo que tienes en suficiente.',
      textKey: 'quoteService.localQuotes.12.text',
      author: 'Melody Beattie',
    ),
    Quote(
      text: 'Tu valor no disminuye por la incapacidad de alguien de ver tu luz.',
      textKey: 'quoteService.localQuotes.13.text',
      author: 'Lumen',
    ),
    Quote(
      text: 'Está bien no estar bien. Lo que importa es no quedarte ahí.',
      textKey: 'quoteService.localQuotes.14.text',
      author: 'Lumen',
    ),
    Quote(
      text: 'La calma es un superpoder en un mundo lleno de ruido.',
      textKey: 'quoteService.localQuotes.15.text',
      author: 'Lumen',
    ),
    Quote(
      text: 'No compares tu capítulo 1 con el capítulo 20 de alguien más.',
      textKey: 'quoteService.localQuotes.16.text',
      author: 'Lumen',
    ),
    Quote(
      text: 'Sé paciente contigo mismo. El crecimiento toma tiempo.',
      textKey: 'quoteService.localQuotes.17.text',
      author: 'Lumen',
    ),
    Quote(
      text: 'La mejor relación que puedes tener es la que tienes contigo mismo.',
      textKey: 'quoteService.localQuotes.18.text',
      author: 'Diane Von Furstenberg',
    ),
    Quote(
      text: 'Hoy elige la compasión. Empieza contigo.',
      textKey: 'quoteService.localQuotes.19.text',
      author: 'Lumen',
    ),
    Quote(
      text: 'El descanso no es rendirse. Es prepararse para seguir.',
      textKey: 'quoteService.localQuotes.20.text',
      author: 'Lumen',
    ),
    Quote(
      text: 'No necesitas una razón para merecer paz interior.',
      textKey: 'quoteService.localQuotes.21.text',
      author: 'Lumen',
    ),
    Quote(
      text: 'Cada respiración es una oportunidad para empezar de nuevo.',
      textKey: 'quoteService.localQuotes.22.text',
      author: 'Lumen',
    ),
    Quote(
      text: 'Tu salud mental es una prioridad, no un lujo.',
      textKey: 'quoteService.localQuotes.23.text',
      author: 'Lumen',
    ),
    Quote(
      text: 'Las pequeñas victorias de hoy son los grandes logros de mañana.',
      textKey: 'quoteService.localQuotes.24.text',
      author: 'Lumen',
    ),
    Quote(
      text: 'Permítete sentir. Las emociones no son tu enemigo.',
      textKey: 'quoteService.localQuotes.25.text',
      author: 'Lumen',
    ),
    Quote(
      text: 'Lo que nutre tu alma nunca es una pérdida de tiempo.',
      textKey: 'quoteService.localQuotes.26.text',
      author: 'Lumen',
    ),
    Quote(
      text: 'No eres tus pensamientos. Eres quien los observa.',
      textKey: 'quoteService.localQuotes.27.text',
      author: 'Eckhart Tolle',
    ),
    Quote(
      text: 'Hoy es un buen día para cuidar de ti.',
      textKey: 'quoteService.localQuotes.28.text',
      author: 'Lumen',
    ),
    Quote(
      text: 'La verdadera fortaleza se muestra en los momentos de vulnerabilidad.',
      textKey: 'quoteService.localQuotes.29.text',
      author: 'Lumen',
    ),
    Quote(
      text: 'Tu viaje importa. Cada paso cuenta.',
      textKey: 'quoteService.localQuotes.30.text',
      author: 'Lumen',
    ),
  ];
}

class Quote {
  final String text;
  final String author;
  final String source;
  final String? textKey;
  final String? authorKey;

  const Quote({
    required this.text,
    required this.author,
    this.source = 'Lumen',
    this.textKey,
    this.authorKey,
  });

  Map<String, dynamic> toJson() => {
        'text': text,
        'author': author,
        'source': source,
        'textKey': textKey,
        'authorKey': authorKey,
      };

  factory Quote.fromJson(Map<String, dynamic> json) => Quote(
        text: json['text'] ?? '',
        author: json['author'] ?? 'Lumen',
        source: json['source'] ?? 'Lumen',
        textKey: json['textKey'],
        authorKey: json['authorKey'],
      );
}