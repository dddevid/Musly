import 'package:flutter_test/flutter_test.dart';
import 'package:musly/services/theme_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AccentColor Tests', () {
    test('AccentColor enum includes dynamicColor and handles serialization', () {
      expect(AccentColor.dynamicColor.persistKey, 'dynamic');
      expect(AccentColor.dynamicColor.isDynamic, isTrue);
      expect(AccentColor.red.isDynamic, isFalse);

      expect(AccentColorExt.fromKey('dynamic'), AccentColor.dynamicColor);
      expect(AccentColorExt.fromKey('red'), AccentColor.red);
      expect(AccentColorExt.fromKey('pink'), AccentColor.pink);
      expect(AccentColorExt.fromKey('orange'), AccentColor.orange);
      expect(AccentColorExt.fromKey('yellow'), AccentColor.yellow);
      expect(AccentColorExt.fromKey('green'), AccentColor.green);
      expect(AccentColorExt.fromKey('blue'), AccentColor.blue);
      expect(AccentColorExt.fromKey('purple'), AccentColor.purple);
      expect(AccentColorExt.fromKey('unknown'), AccentColor.red);
    });

    test('ThemeService initializes and persists dynamicColor', () async {
      SharedPreferences.setMockInitialValues({
        'app_accent_color': 'dynamic',
      });
      final themeService = ThemeService();
      await themeService.initialize();

      expect(themeService.accentColor, AccentColor.dynamicColor);

      await themeService.setAccentColor(AccentColor.blue);
      expect(themeService.accentColor, AccentColor.blue);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('app_accent_color'), 'blue');

      await themeService.setAccentColor(AccentColor.dynamicColor);
      expect(themeService.accentColor, AccentColor.dynamicColor);
      expect(prefs.getString('app_accent_color'), 'dynamic');
    });
  });
}
