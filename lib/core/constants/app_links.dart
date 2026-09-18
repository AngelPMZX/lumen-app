/// Enlaces públicos de Lumen (las páginas viven en `docs/` del repo y se
/// publican con GitHub Pages). Si cambia el hosting, se cambia aquí.
class AppLinks {
  AppLinks._();

  static const site = 'https://angelpmzx.github.io/lumen-app/';

  static const privacyEs = '${site}privacidad.html';
  static const privacyEn = '${site}privacy.html';
  static const terms = '${site}terminos.html';
  static const deleteAccount = '${site}eliminar-cuenta.html';

  static const supportEmail = 'angelperez19663@gmail.com';

  /// Política de privacidad en el idioma de la app.
  static String privacy(String languageCode) => languageCode == 'en' ? privacyEn : privacyEs;

  /// `mailto:` con asunto ya puesto para escribir a soporte.
  static Uri supportMail(String subject) =>
      Uri(scheme: 'mailto', path: supportEmail, query: 'subject=${Uri.encodeComponent(subject)}');
}
