import 'package:easy_localization/easy_localization.dart';

import '../../data/models/password_strength.dart';

class Validators {
  static String? email(String? value) {
    if (value == null || value.isEmpty) {
      return 'validation.enterEmail'.tr();
    }
    // El dominio de primer nivel puede tener más de 4 letras (.online, .digital)
    final emailRegex = RegExp(r'^[\w.+-]+@([\w-]+\.)+[A-Za-z]{2,}$');
    if (!emailRegex.hasMatch(value)) {
      return 'validation.invalidEmail'.tr();
    }
    return null;
  }

  /// Contraseña para entrar: solo comprobamos que haya algo (las cuentas
  /// viejas pueden tener contraseñas de 6 caracteres).
  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'validation.enterPassword'.tr();
    }
    return null;
  }

  /// Contraseña nueva (registro y cambio de contraseña): tiene que pasar
  /// todas las reglas de [PasswordStrength]. [personal] son el correo y el
  /// nombre, para que no los use como contraseña.
  static String? strongPassword(String? value, {List<String> personal = const []}) {
    if (value == null || value.isEmpty) {
      return 'validation.enterPassword'.tr();
    }
    final strength = PasswordStrength.check(value, personal: personal);
    if (strength.isValid) return null;
    final missing = PasswordStrength.required.firstWhere((r) => !strength.has(r));
    return PasswordStrength.ruleKey(missing).tr();
  }

  static String? confirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'validation.confirmYourPassword'.tr();
    }
    if (value != password) {
      return 'validation.passwordsDoNotMatch'.tr();
    }
    return null;
  }

  static String? name(String? value) {
    if (value == null || value.isEmpty) {
      return 'validation.enterName'.tr();
    }
    if (value.length < 2) {
      return 'validation.nameTooShort'.tr();
    }
    return null;
  }

  static String? username(String? value) {
    if (value == null || value.isEmpty) {
      return 'validation.chooseUsername'.tr();
    }
    if (value.length < 3) {
      return 'validation.minChars'.tr(namedArgs: {'count': '3'});
    }
    if (value.length > 20) {
      return 'validation.maxChars'.tr(namedArgs: {'count': '20'});
    }
    final usernameRegex = RegExp(r'^[a-z0-9._]+$');
    if (!usernameRegex.hasMatch(value)) {
      return 'validation.onlyLowercaseEtc'.tr();
    }
    if (value.startsWith('.') || value.endsWith('.')) {
      return 'validation.noStartEndDot'.tr();
    }
    return null;
  }
}
