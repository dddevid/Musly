import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AccentColor {
  red,
  pink,
  orange,
  yellow,
  green,
  blue,
  purple,
}

extension AccentColorExt on AccentColor {
  
  Color get color {
    switch (this) {
      case AccentColor.red:
        return const Color(0xFFFA243C);
      case AccentColor.pink:
        return const Color(0xFFFC5C65);
      case AccentColor.orange:
        return const Color(0xFFFF9500);
      case AccentColor.yellow:
        return const Color(0xFFFFCC00);
      case AccentColor.green:
        return const Color(0xFF1DB954);
      case AccentColor.blue:
        return const Color(0xFF007AFF);
      case AccentColor.purple:
        return const Color(0xFF8B5CF6);
    }
  }

  String get persistKey {
    switch (this) {
      case AccentColor.red:
        return 'red';
      case AccentColor.pink:
        return 'pink';
      case AccentColor.orange:
        return 'orange';
      case AccentColor.yellow:
        return 'yellow';
      case AccentColor.green:
        return 'green';
      case AccentColor.blue:
        return 'blue';
      case AccentColor.purple:
        return 'purple';
    }
  }

  static AccentColor fromKey(String key) {
    switch (key) {
      case 'pink':
        return AccentColor.pink;
      case 'orange':
        return AccentColor.orange;
      case 'yellow':
        return AccentColor.yellow;
      case 'green':
        return AccentColor.green;
      case 'blue':
        return AccentColor.blue;
      case 'purple':
        return AccentColor.purple;
      default:
        return AccentColor.red;
    }
  }
}

class ThemeService extends ChangeNotifier {
  static const String _keyThemeMode = 'app_theme_mode';
  static const String _keyAccentColor = 'app_accent_color';
  static const String _keyLiquidGlass = 'app_liquid_glass';

  ThemeMode _themeMode = ThemeMode.system;
  AccentColor _accentColor = AccentColor.red;
  bool _liquidGlass = false;

  ThemeMode get themeMode => _themeMode;
  AccentColor get accentColor => _accentColor;
  bool get liquidGlass => _liquidGlass;

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();

    final modeKey = prefs.getString(_keyThemeMode) ?? 'system';
    _themeMode = _themeModeFromKey(modeKey);

    final colorKey = prefs.getString(_keyAccentColor) ?? 'red';
    _accentColor = AccentColorExt.fromKey(colorKey);

    _liquidGlass = prefs.getBool(_keyLiquidGlass) ?? false;
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyThemeMode, _themeModeToKey(mode));
  }

  Future<void> setAccentColor(AccentColor color) async {
    _accentColor = color;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyAccentColor, color.persistKey);
  }

  Future<void> setLiquidGlass(bool enabled) async {
    _liquidGlass = enabled;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyLiquidGlass, enabled);
  }

  static ThemeMode _themeModeFromKey(String key) {
    switch (key) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  static String _themeModeToKey(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      default:
        return 'system';
    }
  }
}
