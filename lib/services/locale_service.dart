import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:musly/l10n/app_localizations.dart';
import 'package:musly/services/translation_ota_service.dart';

class LocaleService extends ChangeNotifier {
  static const String _localeKey = 'selected_locale';
  Locale? _currentLocale;

  Locale? get currentLocale => _currentLocale;
  final TranslationOtaService _otaService = TranslationOtaService();

  TranslationOtaService get otaService => _otaService;

  /// Comprehensive dictionary of native language names with English labels.
  static const Map<String, String> _languageNames = {
    'en': 'English',
    'sq': 'Shqip (Albanian)',
    'it': 'Italiano (Italian)',
    'ar': 'العربية (Arabic)',
    'az': 'Azərbaycanca (Azerbaijani)',
    'bg': 'Български (Bulgarian)',
    'bn': 'বাংলা (Bengali)',
    'ca': 'Català (Catalan)',
    'cs': 'Čeština (Czech)',
    'da': 'Dansk (Danish)',
    'de': 'Deutsch (German)',
    'el': 'Ελληνικά (Greek)',
    'es': 'Español (Spanish)',
    'et': 'Eesti (Estonian)',
    'fa': 'فارسی (Persian)',
    'fi': 'Suomi (Finnish)',
    'fil': 'Filipino',
    'fr': 'Français (French)',
    'ga': 'Gaeilge (Irish)',
    'gu': 'ગુજરાતી (Gujarati)',
    'he': 'עברית (Hebrew)',
    'hi': 'हिन्दी (Hindi)',
    'hr': 'Hrvatski (Croatian)',
    'hu': 'Magyar (Hungarian)',
    'id': 'Bahasa Indonesia (Indonesian)',
    'is': 'Íslenska (Icelandic)',
    'ja': '日本語 (Japanese)',
    'ka': 'ქართული (Georgian)',
    'kk': 'Қазақша (Kazakh)',
    'km': 'ភាសាខ្មែរ (Khmer)',
    'kn': 'ಕನ್ನಡ (Kannada)',
    'ko': '한국어 (Korean)',
    'lt': 'Lietuvių (Lithuanian)',
    'lv': 'Latviešu (Latvian)',
    'mk': 'Македонски (Macedonian)',
    'ml': 'മലയാളം (Malayalam)',
    'mr': 'मराठी (Marathi)',
    'ms': 'Bahasa Melayu (Malay)',
    'my': 'မြန်မာဘာသာ (Burmese)',
    'nb': 'Norsk Bokmål (Norwegian)',
    'ne': 'नेपाली (Nepali)',
    'nl': 'Nederlands (Dutch)',
    'nn': 'Norsk Nynorsk (Norwegian)',
    'no': 'Norsk (Norwegian)',
    'pl': 'Polski (Polish)',
    'pt': 'Português (Portuguese)',
    'ro': 'Română (Romanian)',
    'ru': 'Русский (Russian)',
    'si': 'සිංහල (Sinhala)',
    'sk': 'Slovenčina (Slovak)',
    'sl': 'Slovenščina (Slovenian)',
    'sr': 'Српски (Serbian)',
    'sv': 'Svenska (Swedish)',
    'sw': 'Kiswahili (Swahili)',
    'ta': 'தமிழ் (Tamil)',
    'te': 'తెలుగు (Telugu)',
    'th': 'ไทย (Thai)',
    'tr': 'Türkçe (Turkish)',
    'uk': 'Українська (Ukrainian)',
    'ur': 'اردو (Urdu)',
    'uz': 'Oʻzbekcha (Uzbek)',
    'vi': 'Tiếng Việt (Vietnamese)',
    'zh': '简体中文 (Chinese Simplified)',
    'zh_TW': '繁體中文 (Chinese Traditional)',
    'zh_HK': '繁體中文 (Hong Kong)',
  };

  /// Flag emojis corresponding to language/locale codes.
  static const Map<String, String> _flagMap = {
    'en': '🇬🇧',
    'sq': '🇦🇱',
    'it': '🇮🇹',
    'ar': '🇸🇦',
    'az': '🇦🇿',
    'bg': '🇧🇬',
    'bn': '🇧🇩',
    'ca': '🇪🇸',
    'cs': '🇨🇿',
    'da': '🇩🇰',
    'de': '🇩🇪',
    'el': '🇬🇷',
    'es': '🇪🇸',
    'et': '🇪🇪',
    'fa': '🇮🇷',
    'fi': '🇫🇮',
    'fil': '🇵🇭',
    'fr': '🇫🇷',
    'ga': '🇮🇪',
    'gu': '🇮🇳',
    'he': '🇮🇱',
    'hi': '🇮🇳',
    'hr': '🇭🇷',
    'hu': '🇭🇺',
    'id': '🇮🇩',
    'is': '🇮🇸',
    'ja': '🇯🇵',
    'ka': '🇬🇪',
    'kk': '🇰🇿',
    'km': '🇰🇭',
    'kn': '🇮🇳',
    'ko': '🇰🇷',
    'lt': '🇱🇹',
    'lv': '🇱🇻',
    'mk': '🇲🇰',
    'ml': '🇮🇳',
    'mr': '🇮🇳',
    'ms': '🇲🇾',
    'my': '🇲🇲',
    'nb': '🇳🇴',
    'ne': '🇳🇵',
    'nl': '🇳🇱',
    'nn': '🇳🇴',
    'no': '🇳🇴',
    'pl': '🇵🇱',
    'pt': '🇵🇹',
    'ro': '🇷🇴',
    'ru': '🇷🇺',
    'si': '🇱🇰',
    'sk': '🇸🇰',
    'sl': '🇸🇮',
    'sr': '🇷🇸',
    'sv': '🇸🇪',
    'sw': '🇰🇪',
    'ta': '🇮🇳',
    'te': '🇮🇳',
    'th': '🇹🇭',
    'tr': '🇹🇷',
    'uk': '🇺🇦',
    'ur': '🇵🇰',
    'uz': '🇺🇿',
    'vi': '🇻🇳',
    'zh': '🇨🇳',
  };

  /// Returns all languages supported by the app (dynamically combining compiled locales + OTA discovered locales).
  /// Any new language added on Crowdin will automatically show up here.
  static Map<String, String> get supportedLanguages {
    final Map<String, String> result = {};
    final preferredOrder = ['en', 'sq', 'it'];
    final allSupportedCodes = AppLocalizations.supportedLocales.map((l) => l.languageCode).toSet();
    allSupportedCodes.addAll(TranslationOtaService().discoveredLocales);

    for (final code in preferredOrder) {
      if (allSupportedCodes.contains(code)) {
        result[code] = _languageNames[code] ?? code.toUpperCase();
      }
    }

    for (final code in allSupportedCodes) {
      if (!result.containsKey(code)) {
        result[code] = _languageNames[code] ?? code.toUpperCase();
      }
    }
    return result;
  }

  Future<void> loadSavedLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final localeCode = prefs.getString(_localeKey);
    if (localeCode != null) {
      _currentLocale = Locale(localeCode);
    }
    
    // Initialize OTA local cache
    await _otaService.init(_currentLocale?.languageCode ?? 'en');
    notifyListeners();

    // Check for updates in background (non-blocking)
    syncOtaTranslations(force: false);
  }

  Future<void> setLocale(Locale? locale) async {
    debugPrint('LocaleService: Setting locale to ${locale?.languageCode}');
    _currentLocale = locale;
    await _otaService.loadCachedLocale(locale?.languageCode ?? 'en');
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

    // Sync OTA in background for newly selected locale
    syncOtaTranslations(force: false);
  }

  /// Sync translations Over-The-Air from GitHub/Crowdin live
  Future<bool> syncOtaTranslations({bool force = false}) async {
    final activeCode = _currentLocale?.languageCode ?? 'en';
    final updated = await _otaService.syncTranslations(
      localeCode: activeCode,
      force: force,
    );
    if (updated) {
      notifyListeners();
    }
    return updated;
  }

  /// Translation completion percentages for supported languages based on the Crowdin catalog.
  static const Map<String, int> translationPercentages = {
    'en': 100,
    'it': 89,
    'es': 54,
    'fr': 54,
    'pt': 54,
    'ru': 54,
    'sv': 54,
    'zh': 47,
    'de': 43,
    'sq': 24,
    'ro': 11,
    'az': 1,
    'ar': 0,
    'bn': 0,
    'da': 0,
    'el': 0,
    'fi': 0,
    'ga': 0,
    'hi': 0,
    'id': 0,
    'nl': 0,
    'no': 0,
    'pl': 0,
    'te': 0,
    'tr': 0,
    'uk': 0,
    'vi': 0,
  };

  static int getCompletionPercentage(String languageCode) {
    return translationPercentages[languageCode] ?? 0;
  }

  String getLanguageName(String languageCode) {
    return supportedLanguages[languageCode] ?? _languageNames[languageCode] ?? languageCode.toUpperCase();
  }

  static String getFlagEmoji(String languageCode) {
    return _flagMap[languageCode] ?? '🌐';
  }
}
