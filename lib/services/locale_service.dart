import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleService extends ChangeNotifier {
  static const String _localeKey = 'selected_locale';
  Locale? _currentLocale;

  Locale? get currentLocale => _currentLocale;

  /// Available languages with their display names
  static const Map<String, String> supportedLanguages = {
    'en': 'English',
    'sq': 'Shqip (Albanian)',
    'it': 'Italiano (Italian)',
    'bn': 'বাংলা (Bengali)',
    'zh': '简体中文 (Chinese Simplified)',
    'da': 'Dansk (Danish)',
    'fi': 'Suomi (Finnish)',
    'fr': 'Français (French)',
    'de': 'Deutsch (German)',
    'el': 'Ελληνικά (Greek)',
    'hi': 'हिन्दी (Hindi)',
    'id': 'Bahasa Indonesia (Indonesian)',
    'ga': 'Gaeilge (Irish)',
    'no': 'Norsk (Norwegian)',
    'pl': 'Polski (Polish)',
    'pt': 'Português (Portuguese)',
    'ro': 'Română (Romanian)',
    'ru': 'Русский (Russian)',
    'es': 'Español (Spanish)',
    'sv': 'Svenska (Swedish)',
    'te': 'తెలుగు (Telugu)',
    'tr': 'Türkçe (Turkish)',
    'uk': 'Українська (Ukrainian)',
    'vi': 'Tiếng Việt (Vietnamese)',
  };

  Future<void> loadSavedLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final localeCode = prefs.getString(_localeKey);
    if (localeCode != null) {
      _currentLocale = Locale(localeCode);
      notifyListeners();
    }
  }

  Future<void> setLocale(Locale? locale) async {
    debugPrint('LocaleService: Setting locale to ${locale?.languageCode}');
    _currentLocale = locale;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    if (locale != null) {
      await prefs.setString(_localeKey, locale.languageCode);
      debugPrint('LocaleService: Saved locale ${locale.languageCode} to prefs');
    } else {
      await prefs.remove(_localeKey);
      debugPrint(
        'LocaleService: Removed locale from prefs (using system default)',
      );
    }
  }

  String getLanguageName(String languageCode) {
    return supportedLanguages[languageCode] ?? languageCode.toUpperCase();
  }
}
