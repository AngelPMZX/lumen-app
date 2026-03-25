import 'package:flutter/material.dart';

// Por ahora usamos autenticación simulada.
// En el siguiente paso conectamos Firebase.
class AuthProvider extends ChangeNotifier {
  bool _isLoggedIn = false;
  bool _isLoading = false;
  String? _errorMessage;
  String _userName = '';
  String _userEmail = '';

  bool get isLoggedIn => _isLoggedIn;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get userName => _userName;
  String get userEmail => _userEmail;

  Future<bool> loginWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      // Simular delay de red
      await Future.delayed(const Duration(seconds: 2));

      // Validación demo
      if (password.length < 6) {
        _errorMessage = 'Contraseña incorrecta';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      _isLoggedIn = true;
      _userEmail = email;
      _userName = email.split('@').first;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Ocurrió un error. Intenta de nuevo.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> registerWithEmail({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await Future.delayed(const Duration(seconds: 2));

      _isLoggedIn = true;
      _userName = name;
      _userEmail = email;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Ocurrió un error. Intenta de nuevo.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> loginWithGoogle() async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await Future.delayed(const Duration(seconds: 2));

      _isLoggedIn = true;
      _userName = 'Usuario Google';
      _userEmail = 'user@gmail.com';
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Error al iniciar con Google';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    _isLoggedIn = false;
    _userName = '';
    _userEmail = '';
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}