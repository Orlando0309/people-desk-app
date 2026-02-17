import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Controller to manage app theme (light/dark mode)
class ThemeController extends ChangeNotifier {
  static const String _themeKey = 'app_theme_mode';
  
  ThemeMode _themeMode = ThemeMode.system;
  late SharedPreferences _prefs;
  bool _isInitialized = false;

  ThemeMode get themeMode => _themeMode;
  bool get isInitialized => _isInitialized;

  /// Initialize theme from saved preferences
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    final savedTheme = _prefs.getString(_themeKey);
    
    if (savedTheme != null) {
      _themeMode = ThemeMode.values.firstWhere(
        (mode) => mode.toString() == 'ThemeMode.$savedTheme',
        orElse: () => ThemeMode.system,
      );
    }
    
    _isInitialized = true;
    notifyListeners();
  }

  /// Toggle between light and dark theme
  Future<void> toggleTheme() async {
    if (_themeMode == ThemeMode.light) {
      _themeMode = ThemeMode.dark;
    } else if (_themeMode == ThemeMode.dark) {
      _themeMode = ThemeMode.light;
    } else {
      // If in system mode, switch to opposite of current system theme
      final brightness = WidgetsBinding.instance.window.platformDispatcher.views.first.platformDispatcher.platformBrightness;
      _themeMode = brightness == Brightness.light ? ThemeMode.dark : ThemeMode.light;
    }
    
    // Save to preferences
    await _prefs.setString(
      _themeKey,
      _themeMode.toString().split('.').last,
    );
    
    notifyListeners();
  }

  /// Set theme to light mode
  Future<void> setLightMode() async {
    _themeMode = ThemeMode.light;
    await _prefs.setString(_themeKey, 'light');
    notifyListeners();
  }

  /// Set theme to dark mode
  Future<void> setDarkMode() async {
    _themeMode = ThemeMode.dark;
    await _prefs.setString(_themeKey, 'dark');
    notifyListeners();
  }

  /// Set theme to system mode
  Future<void> setSystemMode() async {
    _themeMode = ThemeMode.system;
    await _prefs.remove(_themeKey);
    notifyListeners();
  }
}
