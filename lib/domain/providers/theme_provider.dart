import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
 
class ThemeProvider extends ChangeNotifier {
  static const _key = 'theme_mode';
  ThemeMode _themeMode = ThemeMode.system;
  ThemeMode get themeMode => _themeMode;
 
  bool get isDark => _themeMode == ThemeMode.dark;
 
  ThemeProvider() {
    _loadTheme();
  }
 
  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_key);
    if (value == 'dark') {
      _themeMode = ThemeMode.dark;
    } else if (value == 'light') {
      _themeMode = ThemeMode.light;
    } else {
      _themeMode = ThemeMode.system;
    }
    notifyListeners();
  }
 
  Future<void> toggleTheme() async {
    final prefs = await SharedPreferences.getInstance();
    if (_themeMode == ThemeMode.dark) {
      _themeMode = ThemeMode.light;
      await prefs.setString(_key, 'light');
    } else {
      _themeMode = ThemeMode.dark;
      await prefs.setString(_key, 'dark');
    }
    notifyListeners();
  }
 
  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, mode.name);
    notifyListeners();
  }
}
