import 'dart:math';

class MotivationalQuote {
  final String text;
  final String author;
  final String? textKey;

  const MotivationalQuote({
    required this.text,
    required this.author,
    this.textKey,
  });

  static MotivationalQuote getQuoteOfTheDay() {
    final now = DateTime.now();
    final dayOfYear = now.difference(DateTime(now.year, 1, 1)).inDays;
    final index = dayOfYear % _quotes.length;
    return _quotes[index];
  }

  static const List<MotivationalQuote> _quotes = [
    MotivationalQuote(
      text: 'La paz viene de adentro. No la busques afuera.',
      author: 'Buda',
      textKey: 'motivationalQuotes.0.text',
    ),
    MotivationalQuote(
      text: 'No tienes que controlarlo todo. A veces solo necesitas soltar.',
      author: 'Lumen',
      textKey: 'motivationalQuotes.1.text',
    ),
    MotivationalQuote(
      text: 'Cada día es una nueva oportunidad para ser más amable contigo mismo.',
      author: 'Lumen',
      textKey: 'motivationalQuotes.2.text',
    ),
    MotivationalQuote(
      text: 'La vulnerabilidad no es debilidad. Es la mayor medida de coraje.',
      author: 'Brené Brown',
      textKey: 'motivationalQuotes.3.text',
    ),
    MotivationalQuote(
      text: 'Tu mente es un jardín. Tus pensamientos son las semillas.',
      author: 'Lumen',
      textKey: 'motivationalQuotes.4.text',
    ),
    MotivationalQuote(
      text: 'No es la carga la que te destruye, es cómo la cargas.',
      author: 'Lou Holtz',
      textKey: 'motivationalQuotes.5.text',
    ),
    MotivationalQuote(
      text: 'Respira. Estás exactamente donde necesitas estar.',
      author: 'Lumen',
      textKey: 'motivationalQuotes.6.text',
    ),
    MotivationalQuote(
      text: 'La felicidad no es la ausencia de problemas, sino la habilidad de lidiar con ellos.',
      author: 'Steve Maraboli',
      textKey: 'motivationalQuotes.7.text',
    ),
    MotivationalQuote(
      text: 'Hoy mereces tu propia amabilidad tanto como cualquier otra persona.',
      author: 'Lumen',
      textKey: 'motivationalQuotes.8.text',
    ),
    MotivationalQuote(
      text: 'El autocuidado no es egoísmo. No puedes servir de una taza vacía.',
      author: 'Eleanor Brownn',
      textKey: 'motivationalQuotes.9.text',
    ),
    MotivationalQuote(
      text: 'Las emociones son como olas. Obsérvalas ir y venir.',
      author: 'Lumen',
      textKey: 'motivationalQuotes.10.text',
    ),
    MotivationalQuote(
      text: 'Un paso pequeño hoy es un gran salto para tu bienestar.',
      author: 'Lumen',
      textKey: 'motivationalQuotes.11.text',
    ),
    MotivationalQuote(
      text: 'No tienes que ser perfecto para merecer amor y aceptación.',
      author: 'Lumen',
      textKey: 'motivationalQuotes.12.text',
    ),
    MotivationalQuote(
      text: 'La gratitud transforma lo que tienes en suficiente.',
      author: 'Melody Beattie',
      textKey: 'motivationalQuotes.13.text',
    ),
    MotivationalQuote(
      text: 'Tu valor no disminuye por la incapacidad de alguien de ver tu luz.',
      author: 'Lumen',
      textKey: 'motivationalQuotes.14.text',
    ),
    MotivationalQuote(
      text: 'Está bien no estar bien. Lo que importa es no quedarte ahí.',
      author: 'Lumen',
      textKey: 'motivationalQuotes.15.text',
    ),
    MotivationalQuote(
      text: 'La calma es un superpoder en un mundo lleno de ruido.',
      author: 'Lumen',
      textKey: 'motivationalQuotes.16.text',
    ),
    MotivationalQuote(
      text: 'No compares tu capítulo 1 con el capítulo 20 de alguien más.',
      author: 'Lumen',
      textKey: 'motivationalQuotes.17.text',
    ),
    MotivationalQuote(
      text: 'Sé paciente contigo mismo. El crecimiento toma tiempo.',
      author: 'Lumen',
      textKey: 'motivationalQuotes.18.text',
    ),
    MotivationalQuote(
      text: 'La mejor relación que puedes tener es la que tienes contigo mismo.',
      author: 'Diane Von Furstenberg',
      textKey: 'motivationalQuotes.19.text',
    ),
    MotivationalQuote(
      text: 'Hoy elige la compasión. Empieza contigo.',
      author: 'Lumen',
      textKey: 'motivationalQuotes.20.text',
    ),
    MotivationalQuote(
      text: 'El descanso no es rendirse. Es prepararse para seguir.',
      author: 'Lumen',
      textKey: 'motivationalQuotes.21.text',
    ),
    MotivationalQuote(
      text: 'No necesitas una razón para merecer paz interior.',
      author: 'Lumen',
      textKey: 'motivationalQuotes.22.text',
    ),
    MotivationalQuote(
      text: 'Cada respiración es una oportunidad para empezar de nuevo.',
      author: 'Lumen',
      textKey: 'motivationalQuotes.23.text',
    ),
    MotivationalQuote(
      text: 'Tu salud mental es una prioridad, no un lujo.',
      author: 'Lumen',
      textKey: 'motivationalQuotes.24.text',
    ),
    MotivationalQuote(
      text: 'Las pequeñas victorias de hoy son los grandes logros de mañana.',
      author: 'Lumen',
      textKey: 'motivationalQuotes.25.text',
    ),
    MotivationalQuote(
      text: 'Permítete sentir. Las emociones no son tu enemigo.',
      author: 'Lumen',
      textKey: 'motivationalQuotes.26.text',
    ),
    MotivationalQuote(
      text: 'Lo que nutre tu alma nunca es una pérdida de tiempo.',
      author: 'Lumen',
      textKey: 'motivationalQuotes.27.text',
    ),
    MotivationalQuote(
      text: 'No eres tus pensamientos. Eres quien los observa.',
      author: 'Eckhart Tolle',
      textKey: 'motivationalQuotes.28.text',
    ),
    MotivationalQuote(
      text: 'Hoy es un buen día para cuidar de ti.',
      author: 'Lumen',
      textKey: 'motivationalQuotes.29.text',
    ),
    MotivationalQuote(
      text: 'La verdadera fortaleza se muestra en los momentos de vulnerabilidad.',
      author: 'Lumen',
      textKey: 'motivationalQuotes.30.text',
    ),
  ];
}