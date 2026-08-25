import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musly/services/locale_service.dart';
import 'package:musly/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LocaleService', () {
    late LocaleService localeService;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      localeService = LocaleService();
    });

    test('initial locale is null (system default)', () {
      expect(localeService.currentLocale, isNull);
    });

    test('setLocale updates currentLocale and persists to SharedPreferences', () async {
      await localeService.setLocale(const Locale('it'));
      expect(localeService.currentLocale?.languageCode, 'it');

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('selected_locale'), 'it');
    });

    test('loadSavedLocale restores saved locale', () async {
      SharedPreferences.setMockInitialValues({'selected_locale': 'ar'});
      await localeService.loadSavedLocale();
      expect(localeService.currentLocale?.languageCode, 'ar');
    });

    test('setLocale(null) resets to system default and removes from prefs', () async {
      await localeService.setLocale(const Locale('az'));
      expect(localeService.currentLocale?.languageCode, 'az');

      await localeService.setLocale(null);
      expect(localeService.currentLocale, isNull);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.containsKey('selected_locale'), isFalse);
    });

    test('contains newly added languages (ar, az, nl)', () {
      expect(LocaleService.supportedLanguages.containsKey('ar'), isTrue);
      expect(LocaleService.supportedLanguages['ar'], contains('Arabic'));

      expect(LocaleService.supportedLanguages.containsKey('az'), isTrue);
      expect(LocaleService.supportedLanguages['az'], contains('Azerbaijani'));

      expect(LocaleService.supportedLanguages.containsKey('nl'), isTrue);
      expect(LocaleService.supportedLanguages['nl'], contains('Dutch'));
    });

    test('all AppLocalizations supportedLocales match LocaleService.supportedLanguages', () {
      final appLocales = AppLocalizations.supportedLocales.map((l) => l.languageCode).toSet();
      final serviceLocales = LocaleService.supportedLanguages.keys.toSet();

      expect(serviceLocales, equals(appLocales));
    });

    test('getLanguageName returns correct name or uppercase code as fallback', () {
      expect(localeService.getLanguageName('en'), 'English');
      expect(localeService.getLanguageName('it'), 'Italiano (Italian)');
      expect(localeService.getLanguageName('ar'), 'العربية (Arabic)');
      expect(localeService.getLanguageName('az'), 'Azərbaycanca (Azerbaijani)');
      expect(localeService.getLanguageName('nl'), 'Nederlands (Dutch)');
      expect(localeService.getLanguageName('ja'), '日本語 (Japanese)');
      expect(localeService.getLanguageName('xyz'), 'XYZ');
    });

    test('getFlagEmoji returns correct emoji or fallback', () {
      expect(LocaleService.getFlagEmoji('it'), '🇮🇹');
      expect(LocaleService.getFlagEmoji('ar'), '🇸🇦');
      expect(LocaleService.getFlagEmoji('az'), '🇦🇿');
      expect(LocaleService.getFlagEmoji('nl'), '🇳🇱');
      expect(LocaleService.getFlagEmoji('ja'), '🇯🇵');
      expect(LocaleService.getFlagEmoji('unknown_lang'), '🌐');
    });
  });
}
