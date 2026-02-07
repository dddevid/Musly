import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:musly/models/song.dart';
import 'package:musly/providers/player_provider.dart';
import 'package:musly/services/subsonic_service.dart';
import 'package:musly/services/storage_service.dart';
import 'package:musly/widgets/song_tile.dart';
import '../test_helpers.dart';

void main() {
  group('SongTile', () {
    late SubsonicService subsonicService;
    late PlayerProvider playerProvider;

    setUp(() {
      subsonicService = SubsonicService();
      subsonicService = SubsonicService();
      playerProvider = PlayerProvider(
        subsonicService,
        StorageService(),
        FakeCastService(),
      );
    });

    tearDown(() {
      playerProvider.dispose();
    });

    testWidgets('should display song information', (tester) async {
      final song = Song(
        id: '1',
        title: 'Test Song',
        artist: 'Test Artist',
        album: 'Test Album',
        duration: 180,
      );

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<SubsonicService>.value(value: subsonicService),
            ChangeNotifierProvider<PlayerProvider>.value(value: playerProvider),
          ],
          child: MaterialApp(
            home: Scaffold(body: SongTile(song: song, showArtist: true)),
          ),
        ),
      );

      expect(find.text('Test Song'), findsOneWidget);
      expect(find.text('Test Artist'), findsOneWidget);
    });

    testWidgets('should show duration when enabled', (tester) async {
      final song = Song(
        id: '1',
        title: 'Test Song',
        artist: 'Test Artist',
        duration: 180,
      );

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<SubsonicService>.value(value: subsonicService),
            ChangeNotifierProvider<PlayerProvider>.value(value: playerProvider),
          ],
          child: MaterialApp(
            home: Scaffold(body: SongTile(song: song, showDuration: true)),
          ),
        ),
      );

      expect(find.text('3:00'), findsOneWidget);
    });

    testWidgets('should show album when enabled', (tester) async {
      final song = Song(
        id: '1',
        title: 'Test Song',
        artist: 'Test Artist',
        album: 'Test Album',
      );

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<SubsonicService>.value(value: subsonicService),
            ChangeNotifierProvider<PlayerProvider>.value(value: playerProvider),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: SongTile(song: song, showArtist: true, showAlbum: true),
            ),
          ),
        ),
      );

      expect(find.textContaining('Test Artist'), findsOneWidget);
      expect(find.textContaining('Test Album'), findsOneWidget);
    });
  });
}
