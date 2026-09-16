/// Líneas de ayuda en crisis emocional.
///
/// IMPORTANTE: estos números son información de seguridad. Cada uno fue
/// verificado contra la fuente oficial del país (ver `sourceUrl`). No agregar
/// ni modificar números sin confirmarlos en la fuente oficial primero.
///
/// Última verificación: 2026-09-15.
library;

/// Cómo se contacta una línea de ayuda.
enum CrisisContactType {
  /// Llamada telefónica — abre el marcador con el número ya puesto.
  phone,

  /// Mensaje de texto — abre la app de SMS.
  text,

  /// Sitio web — abre el navegador.
  web,
}

/// Una línea de ayuda concreta.
class CrisisLine {
  /// Nombre propio de la línea (no se traduce): "Línea de la Vida", "988".
  final String name;

  /// Lo que se le muestra al usuario: "800 911 2000", "*4141".
  final String display;

  /// Lo que se marca de verdad, sin espacios ni guiones.
  final String dial;

  final CrisisContactType type;

  /// Clave i18n con la descripción de a quién atiende y en qué horario.
  final String descriptionKey;

  /// Clave i18n con una nota extra (opcional): "desde celular", "presiona 2
  /// para español".
  final String? noteKey;

  const CrisisLine({
    required this.name,
    required this.display,
    required this.dial,
    required this.descriptionKey,
    this.type = CrisisContactType.phone,
    this.noteKey,
  });
}

/// Las líneas de un país.
class CrisisCountry {
  /// Código ISO 3166-1 alfa-2 en minúsculas.
  final String code;

  /// Nombre del país (no se traduce).
  final String name;

  final String flag;

  /// Número de emergencias generales del país.
  final String emergencyNumber;

  final List<CrisisLine> lines;

  /// Fuente oficial de donde salieron los números, para poder reverificarlos.
  final String sourceUrl;

  const CrisisCountry({
    required this.code,
    required this.name,
    required this.flag,
    required this.emergencyNumber,
    required this.lines,
    required this.sourceUrl,
  });
}

/// Catálogo de líneas de ayuda verificadas.
class CrisisResources {
  CrisisResources._();

  /// Directorio internacional de ThroughLine: líneas verificadas de 175+
  /// países. Es el respaldo para quien no esté en la lista de abajo.
  static const findAHelplineUrl = 'https://findahelpline.com';

  static const mexico = CrisisCountry(
    code: 'mx',
    name: 'México',
    flag: '🇲🇽',
    emergencyNumber: '911',
    sourceUrl: 'https://www.gob.mx/conasama/articulos/linea-de-la-vida-800-911-2000',
    lines: [
      CrisisLine(
        name: 'Línea de la Vida',
        display: '800 911 2000',
        dial: '8009112000',
        descriptionKey: 'crisis.lines.mxLifeLine',
      ),
    ],
  );

  static const spain = CrisisCountry(
    code: 'es',
    name: 'España',
    flag: '🇪🇸',
    emergencyNumber: '112',
    sourceUrl: 'https://www.sanidad.gob.es/linea024/home.htm',
    lines: [
      CrisisLine(
        name: '024',
        display: '024',
        dial: '024',
        descriptionKey: 'crisis.lines.es024',
      ),
    ],
  );

  static const unitedStates = CrisisCountry(
    code: 'us',
    name: 'Estados Unidos',
    flag: '🇺🇸',
    emergencyNumber: '911',
    sourceUrl: 'https://988lifeline.org',
    lines: [
      CrisisLine(
        name: '988 Suicide & Crisis Lifeline',
        display: '988',
        dial: '988',
        descriptionKey: 'crisis.lines.us988',
        noteKey: 'crisis.lines.us988Note',
      ),
      CrisisLine(
        name: '988 — texto',
        display: 'AYUDA → 988',
        dial: '988',
        type: CrisisContactType.text,
        descriptionKey: 'crisis.lines.us988Text',
      ),
    ],
  );

  static const colombia = CrisisCountry(
    code: 'co',
    name: 'Colombia',
    flag: '🇨🇴',
    emergencyNumber: '123',
    sourceUrl: 'https://www.minsalud.gov.co/salud/publica/salud-mental/Paginas/linea-106.aspx',
    lines: [
      CrisisLine(
        name: 'Línea 106',
        display: '106',
        dial: '106',
        descriptionKey: 'crisis.lines.co106',
      ),
    ],
  );

  static const argentina = CrisisCountry(
    code: 'ar',
    name: 'Argentina',
    flag: '🇦🇷',
    emergencyNumber: '911',
    sourceUrl: 'https://www.asistenciaalsuicida.org.ar/',
    lines: [
      CrisisLine(
        name: 'Centro de Asistencia al Suicida',
        display: '135',
        dial: '135',
        descriptionKey: 'crisis.lines.ar135',
        noteKey: 'crisis.lines.ar135Note',
      ),
      CrisisLine(
        name: 'Centro de Asistencia al Suicida',
        display: '(011) 5275-1135',
        dial: '01152751135',
        descriptionKey: 'crisis.lines.arNational',
      ),
    ],
  );

  static const chile = CrisisCountry(
    code: 'cl',
    name: 'Chile',
    flag: '🇨🇱',
    emergencyNumber: '131',
    sourceUrl: 'https://www.minsal.cl/linea-de-atencion-4141-no-estas-solo-no-estas-sola/',
    lines: [
      CrisisLine(
        name: 'Línea Prevención del Suicidio',
        display: '*4141',
        dial: '*4141',
        descriptionKey: 'crisis.lines.cl4141',
        noteKey: 'crisis.lines.cl4141Note',
      ),
    ],
  );

  /// Todos los países, con México primero por ser el principal de la app.
  static const List<CrisisCountry> all = [
    mexico,
    colombia,
    argentina,
    chile,
    spain,
    unitedStates,
  ];

  /// País sugerido según el código de región del dispositivo (`es_MX` → mx).
  /// Cae en México si la región no está en la lista.
  static CrisisCountry forCountryCode(String? countryCode) {
    if (countryCode == null) return mexico;
    final code = countryCode.toLowerCase();
    for (final country in all) {
      if (country.code == code) return country;
    }
    return mexico;
  }
}
