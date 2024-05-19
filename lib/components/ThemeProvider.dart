import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeNotifier with ChangeNotifier {
  ThemeData _currentTheme;
  final String key = "theme";
  SharedPreferences? _prefs;

  ThemeNotifier() : _currentTheme = whiteTheme {
    _loadFromPrefs();
  }

  ThemeData get currentTheme => _currentTheme;

  Future<void> toggleTheme() async {
    _currentTheme = (_currentTheme == whiteTheme) ? blackTheme : whiteTheme;
    await _saveToPrefs(_currentTheme == whiteTheme ? 'white' : 'purple[50]');
    notifyListeners();
  }

  Future<void> _initPrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  Future<void> _loadFromPrefs() async {
    await _initPrefs();
    final themeStr = _prefs!.getString(key) ?? 'white';
    _currentTheme = (themeStr == 'purple[50]') ? blackTheme : whiteTheme;
    notifyListeners();
  }

  Future<void> _saveToPrefs(String themeStr) async {
    await _initPrefs();
    await _prefs!.setString(key, themeStr);
  }
}

ThemeData whiteTheme = ThemeData(
  primaryColor: Colors.white,
  hintColor: Colors.deepPurple,
  scaffoldBackgroundColor: Colors.grey,
  // Define other text styles as needed
  bottomNavigationBarTheme: BottomNavigationBarThemeData(
    backgroundColor: Colors.white,
    selectedItemColor: Colors.white,
    unselectedItemColor: Colors.grey, // Or any other color
  ),
  // Add other customizations as needed
);

ThemeData blackTheme = ThemeData(
  primaryColor: Colors.purple[100],
  hintColor: Colors.grey,
  scaffoldBackgroundColor: Colors.purple[100],
  // Define other text styles as needed
  bottomNavigationBarTheme: BottomNavigationBarThemeData(
    backgroundColor: Colors.purple[100],
    selectedItemColor: Colors.grey,
    unselectedItemColor: Colors.grey, // Or any other color
  ),
  // Add other customizations as needed
);

