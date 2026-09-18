/// Cuándo y con qué palabras se recuerda Lumen a quien lleva días sin abrirla.
///
/// La idea: **nunca regañar**. Se programan dos avisos locales al abrir la app
/// y se reprograman cada vez que vuelve, así que solo suenan si de verdad se
/// alejó. Si después del segundo no vuelve, Lumen se calla.
class WinBack {
  WinBack._();

  /// Días sin abrir para el primer y el segundo aviso.
  static const firstDays = 3;
  static const secondDays = 14;

  /// Hora local del aviso (7 de la noche: ni temprano ni de madrugada).
  static const hour = 19;

  /// Cuántas variantes hay del primer mensaje.
  static const firstVariants = 3;

  /// Momento exacto del aviso: [days] días después de [from], a las [hour].
  /// Si esa hora ya pasó ese día (no debería con days >= 1), se corre al
  /// siguiente para no programar algo en el pasado.
  static DateTime dateFor(DateTime from, int days, {int atHour = hour}) {
    final day = DateTime(from.year, from.month, from.day + days, atHour);
    return day.isAfter(from) ? day : DateTime(from.year, from.month, from.day + days + 1, atHour);
  }

  /// Variante del primer mensaje, elegida por el día para que no sea siempre
  /// la misma frase.
  static int variantFor(DateTime date) {
    final dayOfYear = date.difference(DateTime(date.year)).inDays;
    return dayOfYear % firstVariants;
  }

  static String firstTitleKey(int variant) => 'notifications.winBack.first.$variant.title';
  static String firstBodyKey(int variant) => 'notifications.winBack.first.$variant.body';

  static const secondTitleKey = 'notifications.winBack.second.title';
  static const secondBodyKey = 'notifications.winBack.second.body';
}
