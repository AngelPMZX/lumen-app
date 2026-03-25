class Validators {
  static String? email(String? value) {
    if (value == null || value.isEmpty) {
      return 'Ingresa tu correo electrónico';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Ingresa un correo válido';
    }
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Ingresa tu contraseña';
    }
    if (value.length < 6) {
      return 'La contraseña debe tener al menos 6 caracteres';
    }
    return null;
  }

  static String? confirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'Confirma tu contraseña';
    }
    if (value != password) {
      return 'Las contraseñas no coinciden';
    }
    return null;
  }

  static String? name(String? value) {
    if (value == null || value.isEmpty) {
      return 'Ingresa tu nombre';
    }
    if (value.length < 2) {
      return 'El nombre debe tener al menos 2 caracteres';
    }
    return null;
  }
}