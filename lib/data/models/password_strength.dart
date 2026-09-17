/// Qué le falta a una contraseña para ser segura.
enum PasswordRule { length, letters, numbers, notCommon, notPersonal }

enum PasswordLevel { empty, weak, fair, good, strong }

/// Revisión de la contraseña al escribirla: qué reglas cumple, qué tan fuerte
/// es y si se puede usar. Es lógica pura (sin Flutter) para poder probarla.
class PasswordStrength {
  final String password;
  final Set<PasswordRule> passed;
  final PasswordLevel level;

  const PasswordStrength._(this.password, this.passed, this.level);

  /// Mínimo obligatorio para registrarse o cambiar la contraseña.
  static const required = {
    PasswordRule.length,
    PasswordRule.letters,
    PasswordRule.numbers,
    PasswordRule.notCommon,
    PasswordRule.notPersonal,
  };

  static const minLength = 8;

  /// Contraseñas demasiado vistas: se rechazan aunque cumplan el largo.
  /// (Las más usadas de las filtraciones públicas, en inglés y español.)
  static const commonPasswords = {
    '12345678', '123456789', '1234567890', 'password', 'password1', 'password123',
    'qwerty123', 'qwertyuiop', 'contrasena', 'contrasena1', 'contraseña', 'contraseña1',
    'iloveyou', 'princess', 'sunshine', 'football', 'baseball', 'superman', 'batman123',
    'abc12345', 'a1b2c3d4', 'admin123', 'usuario1', 'welcome1', 'welcome123',
    'micontrasena', 'letmein1', 'monkey12', 'dragon12', 'trustno1', 'starwars',
    'lumen123', 'hola1234', 'amoramor', 'teamo123', 'mexico123', 'holamundo',
  };

  bool has(PasswordRule rule) => passed.contains(rule);

  /// ¿Cumple todo lo obligatorio?
  bool get isValid => required.every(passed.contains);

  /// 0 a 4, para la barrita de fuerza.
  int get score => switch (level) {
        PasswordLevel.empty => 0,
        PasswordLevel.weak => 1,
        PasswordLevel.fair => 2,
        PasswordLevel.good => 3,
        PasswordLevel.strong => 4,
      };

  /// [personal] son datos del usuario (correo, nombre): la contraseña no debe
  /// contenerlos ni ser parte de ellos.
  factory PasswordStrength.check(String password, {List<String> personal = const []}) {
    if (password.isEmpty) {
      return const PasswordStrength._('', {}, PasswordLevel.empty);
    }
    final lower = password.toLowerCase();
    final passed = <PasswordRule>{};

    if (password.length >= minLength) passed.add(PasswordRule.length);
    if (RegExp(r'[A-Za-zÁÉÍÓÚáéíóúÑñ]').hasMatch(password)) passed.add(PasswordRule.letters);
    if (RegExp(r'[0-9]').hasMatch(password)) passed.add(PasswordRule.numbers);

    final digitsOnly = RegExp(r'^\d+$').hasMatch(password);
    final repeated = RegExp(r'^(.)\1+$').hasMatch(password);
    final sequential = _isSequential(lower);
    if (!commonPasswords.contains(lower) && !digitsOnly && !repeated && !sequential) {
      passed.add(PasswordRule.notCommon);
    }

    var personalHit = false;
    for (final raw in personal) {
      final value = raw.trim().toLowerCase();
      if (value.isEmpty) continue;
      // El correo cuenta por su parte local: angel@correo.com → "angel"
      final parts = <String>{value, if (value.contains('@')) value.split('@').first};
      for (final part in parts) {
        if (part.length < 3) continue;
        if (lower.contains(part) || part.contains(lower)) personalHit = true;
      }
    }
    if (!personalHit) passed.add(PasswordRule.notPersonal);

    return PasswordStrength._(password, passed, _levelFor(password, passed));
  }

  static PasswordLevel _levelFor(String password, Set<PasswordRule> passed) {
    if (!required.every(passed.contains)) {
      // Todavía no sirve: débil, o "aceptable" si ya le falta poco
      return passed.length >= 4 ? PasswordLevel.fair : PasswordLevel.weak;
    }
    var bonus = 0;
    if (password.length >= 12) bonus++;
    if (RegExp(r'[A-ZÁÉÍÓÚÑ]').hasMatch(password) && RegExp(r'[a-záéíóúñ]').hasMatch(password)) bonus++;
    if (RegExp(r'''[!@#$%^&*(),.?":{}|<>_\-+=\[\]/\\~`';]''').hasMatch(password)) bonus++;
    return bonus >= 2 ? PasswordLevel.strong : PasswordLevel.good;
  }

  /// "abcdefgh" o "12345678": series seguidas de 6 o más.
  static bool _isSequential(String value) {
    if (value.length < 6) return false;
    var ascending = true;
    var descending = true;
    for (var i = 1; i < value.length; i++) {
      final diff = value.codeUnitAt(i) - value.codeUnitAt(i - 1);
      if (diff != 1) ascending = false;
      if (diff != -1) descending = false;
    }
    return ascending || descending;
  }

  /// Clave de traducción del nivel, para la etiqueta de la barra.
  String get levelKey => 'validation.strength.${level.name}';

  /// Clave de traducción de cada regla.
  static String ruleKey(PasswordRule rule) => 'validation.passwordRules.${rule.name}';
}
