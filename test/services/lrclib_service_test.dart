import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:musly/services/lrclib_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    HttpOverrides.global = null;
    SharedPreferences.setMockInitialValues({});
  });

  group('LrcLibService Title and Artist Cleaning', () {
    test('cleans official video fluff from YouTube titles', () {
      expect(
        LrcLibService.cleanTitle('Bohemian Rhapsody (Official Video)'),
        equals('Bohemian Rhapsody'),
      );
      expect(
        LrcLibService.cleanTitle('Numb [Official Music Video 4K]'),
        equals('Numb'),
      );
      expect(
        LrcLibService.cleanTitle('In the End (Official HD Video)'),
        equals('In the End'),
      );
      expect(
        LrcLibService.cleanTitle('Starboy ft. Daft Punk (Official Audio)'),
        equals('Starboy'),
      );
      expect(
        LrcLibService.cleanTitle('Queen - Another One Bites the Dust (Remastered 2011)'),
        equals('Another One Bites the Dust'),
      );
      expect(
        LrcLibService.cleanTitle('Shape of You [Official Lyric Video]'),
        equals('Shape of You'),
      );
      expect(
        LrcLibService.cleanTitle('Blinding Lights (Visualizer)'),
        equals('Blinding Lights'),
      );
      expect(
        LrcLibService.cleanTitle('Ramz - Barking (Audio)'),
        equals('Barking'),
      );
      expect(
        LrcLibService.cleanTitle('Eminem - Houdini (Official Video)'),
        equals('Houdini'),
      );
      expect(
        LrcLibService.cleanTitle('Kendrick Lamar - HUMBLE.'),
        equals('HUMBLE.'),
      );
    });

    test('cleans artist names from Web Music channels', () {
      expect(
        LrcLibService.cleanArtist('The Weeknd - Topic'),
        equals('The Weeknd'),
      );
      expect(
        LrcLibService.cleanArtist('QueenVEVO'),
        equals('Queen'),
      );
      expect(
        LrcLibService.cleanArtist('Eminem ft. Rihanna'),
        equals('Eminem'),
      );
    });

    test('searchLyrics finds synced lyrics for YouTube title formats', () async {
      final result = await LrcLibService().searchLyrics(
        artist: 'Music Zone',
        title: 'Ramz - Barking (Audio)',
      );

      expect(result, isNotNull);
      expect(result!['value'], isNotNull);
      expect(result['value'].toString().toLowerCase(), contains('barkin'));
      expect(result['structuredLyrics'], isNotNull);
    });
  });
}
