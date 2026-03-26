import 'dart:math';
 
class MotivationalQuote {
  final String text;
  final String author;
 
  const MotivationalQuote({required this.text, required this.author});
 
  static MotivationalQuote getQuoteOfTheDay() {
    // Usar el día del año como seed para que sea la misma frase todo el día
    final now = DateTime.now();
    final dayOfYear = now.difference(DateTime(now.year, 1, 1)).inDays;
    final index = dayOfYear % _quotes.length;
    return _quotes[index];
  }
 
  static const List<MotivationalQuote> _quotes = [
    MotivationalQuote(
      text: 'La paz viene de adentro. No la busques afuera.',
      author: 'Buda',
    ),
    MotivationalQuote(
      text: 'No tienes que controlarlo todo. A veces solo necesitas soltar.',
      author: 'Lumen',
    ),
    MotivationalQuote(
      text: 'Cada día es una nueva oportunidad para ser más amable contigo mismo.',
      author: 'Lumen',
    ),
    MotivationalQuote(
      text: 'La vulnerabilidad no es debilidad. Es la mayor medida de coraje.',
      author: 'Brené Brown',
    ),
    MotivationalQuote(
      text: 'Tu mente es un jardín. Tus pensamientos son las semillas.',
      author: 'Lumen',
    ),
    MotivationalQuote(
      text: 'No es la carga la que te destruye, es cómo la cargas.',
      author: 'Lou Holtz',
    ),
    MotivationalQuote(
      text: 'Respira. Estás exactamente donde necesitas estar.',
      author: 'Lumen',
    ),
    MotivationalQuote(
      text: 'La felicidad no es la ausencia de problemas, sino la habilidad de lidiar con ellos.',
      author: 'Steve Maraboli',
    ),
    MotivationalQuote(
      text: 'Hoy mereces tu propia amabilidad tanto como cualquier otra persona.',
      author: 'Lumen',
    ),
    MotivationalQuote(
      text: 'El autocuidado no es egoísmo. No puedes servir de una taza vacía.',
      author: 'Eleanor Brownn',
    ),
    MotivationalQuote(
      text: 'Las emociones son como olas. Obsérvalas ir y venir.',
      author: 'Lumen',
    ),
    MotivationalQuote(
      text: 'Un paso pequeño hoy es un gran salto para tu bienestar.',
      author: 'Lumen',
    ),
    MotivationalQuote(
      text: 'No tienes que ser perfecto para merecer amor y aceptación.',
      author: 'Lumen',
    ),
    MotivationalQuote(
      text: 'La gratitud transforma lo que tienes en suficiente.',
      author: 'Melody Beattie',
    ),
    MotivationalQuote(
      text: 'Tu valor no disminuye por la incapacidad de alguien de ver tu luz.',
      author: 'Lumen',
    ),
    MotivationalQuote(
      text: 'Está bien no estar bien. Lo que importa es no quedarte ahí.',
      author: 'Lumen',
    ),
    MotivationalQuote(
      text: 'La calma es un superpoder en un mundo lleno de ruido.',
      author: 'Lumen',
    ),
    MotivationalQuote(
      text: 'No compares tu capítulo 1 con el capítulo 20 de alguien más.',
      author: 'Lumen',
    ),
    MotivationalQuote(
      text: 'Sé paciente contigo mismo. El crecimiento toma tiempo.',
      author: 'Lumen',
    ),
    MotivationalQuote(
      text: 'La mejor relación que puedes tener es la que tienes contigo mismo.',
      author: 'Diane Von Furstenberg',
    ),
    MotivationalQuote(
      text: 'Hoy elige la compasión. Empieza contigo.',
      author: 'Lumen',
    ),
    MotivationalQuote(
      text: 'El descanso no es rendirse. Es prepararse para seguir.',
      author: 'Lumen',
    ),
    MotivationalQuote(
      text: 'No necesitas una razón para merecer paz interior.',
      author: 'Lumen',
    ),
    MotivationalQuote(
      text: 'Cada respiración es una oportunidad para empezar de nuevo.',
      author: 'Lumen',
    ),
    MotivationalQuote(
      text: 'Tu salud mental es una prioridad, no un lujo.',
      author: 'Lumen',
    ),
    MotivationalQuote(
      text: 'Las pequeñas victorias de hoy son los grandes logros de mañana.',
      author: 'Lumen',
    ),
    MotivationalQuote(
      text: 'Permítete sentir. Las emociones no son tu enemigo.',
      author: 'Lumen',
    ),
    MotivationalQuote(
      text: 'Lo que nutre tu alma nunca es una pérdida de tiempo.',
      author: 'Lumen',
    ),
    MotivationalQuote(
      text: 'No eres tus pensamientos. Eres quien los observa.',
      author: 'Eckhart Tolle',
    ),
    MotivationalQuote(
      text: 'Hoy es un buen día para cuidar de ti.',
      author: 'Lumen',
    ),
    MotivationalQuote(
      text: 'La verdadera fortaleza se muestra en los momentos de vulnerabilidad.',
      author: 'Lumen',
    ),
  ];
}
