/// Frase del día.
///
/// El catálogo es local y bilingüe: cada frase lleva su `textKey`, que se
/// traduce con easy_localization según el idioma activo.
///
/// Antes esto consultaba ZenQuotes.io, pero esa API solo devuelve frases en
/// inglés y llegaban sin clave de traducción, así que se mostraban en inglés
/// aunque la app estuviera en español. Además se cacheaban por día sin
/// guardar el idioma, así que al cambiar de idioma la frase no cambiaba hasta
/// el día siguiente.
///
/// Ahora la frase se elige de forma determinista por día del año: no hay red,
/// no hay caché que invalidar, funciona sin internet y es igual en web y en
/// móvil.
class QuoteService {
  const QuoteService._();

  /// Frase de hoy. Es estable durante todo el día y cambia a medianoche.
  static Quote getQuoteOfTheDay() {
    final now = DateTime.now();
    final dayOfYear = now.difference(DateTime(now.year, 1, 1)).inDays;
    return _localQuotes[dayOfYear % _localQuotes.length];
  }

  static int get quoteCount => _localQuotes.length;

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
    Quote(
      text: 'La felicidad no es la ausencia de problemas, sino la habilidad de lidiar con ellos.',
      textKey: 'quoteService.localQuotes.31.text',
      author: 'Steve Maraboli',
    ),
  ];
}

class Quote {
  final String text;
  final String author;
  final String source;

  /// Clave i18n del texto. Si existe, se prefiere sobre [text].
  final String? textKey;

  /// Clave i18n del autor. Solo para autores genéricos ("Desconocido");
  /// los nombres propios no se traducen.
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
