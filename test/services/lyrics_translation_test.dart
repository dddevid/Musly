import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:musly/models/lyric_line.dart';
import 'package:musly/services/lyrics_translation_service.dart';
import 'package:musly/services/player_ui_settings_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LyricLine Translation tests', () {
    test('hasTranslation returns correct boolean based on translation value', () {
      final line1 = LyricLine(
        text: 'Hello world',
        startTime: const Duration(seconds: 1),
      );
      expect(line1.hasTranslation, isFalse);

      line1.translation = '   ';
      expect(line1.hasTranslation, isFalse);

      line1.translation = 'Ciao mondo';
      expect(line1.hasTranslation, isTrue);
      expect(line1.translation, equals('Ciao mondo'));
    });
  });

  group('PlayerUiSettingsService Lyrics Translation Settings', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('defaults and updates lyrics translation settings', () async {
      final service = PlayerUiSettingsService();
      await service.initialize();

      expect(service.getLyricsTranslationEnabled(), isFalse);
      expect(service.lyricsTranslationEnabledNotifier.value, isFalse);
      expect(service.getLyricsTranslationLanguage(), equals('en'));
      expect(service.lyricsTranslationLanguageNotifier.value, equals('en'));

      await service.setLyricsTranslationEnabled(true);
      expect(service.getLyricsTranslationEnabled(), isTrue);
      expect(service.lyricsTranslationEnabledNotifier.value, isTrue);

      await service.setLyricsTranslationLanguage('it');
      expect(service.getLyricsTranslationLanguage(), equals('it'));
      expect(service.lyricsTranslationLanguageNotifier.value, equals('it'));
    });
  });

  group('LyricsTranslationService tests', () {
    test('singleton returns same instance', () {
      final s1 = LyricsTranslationService();
      final s2 = LyricsTranslationService();
      expect(identical(s1, s2), isTrue);
    });

    test('translateText returns null for blank text', () async {
      final service = LyricsTranslationService();
      final res = await service.translateText('   ');
      expect(res, isNull);
    });

    test('translateLyrics returns empty list when given empty list', () async {
      final service = LyricsTranslationService();
      final res = await service.translateLyrics([]);
      expect(res, isEmpty);
    });
  });
}
