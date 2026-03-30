import 'package:easy_localization/easy_localization.dart';

class Validators {
  static String? email(String? value) {
    if (value == null || value.isEmpty) {
      return 'validation.enterEmail'.tr();
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'validation.invalidEmail'.tr();
    }
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'validation.enterPassword'.tr();
    }
    if (value.length < 6) {
      return 'validation.passwordTooShort'.tr();
    }
    return null;
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
