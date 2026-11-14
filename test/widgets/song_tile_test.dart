import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:musly/models/song.dart';
import 'package:musly/providers/player_provider.dart';
import 'package:musly/services/subsonic_service.dart';
import 'package:musly/services/storage_service.dart';
import 'package:musly/services/upnp_service.dart';
import 'package:musly/services/audio_handler.dart';
import 'package:musly/services/jukebox_service.dart';
import 'package:musly/services/transcoding_service.dart';
import 'package:musly/widgets/common/song_tile.dart';
import 'package:musly/widgets/common/album_artwork.dart';
import 'package:musly/widgets/common/animated_equalizer.dart';
import '../test_helpers.dart';
import '../bootstrap.dart';

import 'package:shared_preferences/shared_preferences.dart';

void main() {
  initializeTestEnvironment();
  group('SongTile', () {
    late SubsonicService subsonicService;
    late PlayerProvider playerProvider;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      subsonicService = SubsonicService();
      playerProvider = PlayerProvider(
        subsonicService,
        StorageService(),
        FakeCastService(),
        UpnpService(),
        MuslyAudioHandler(),
        JukeboxService(),
        TranscodingService(),
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

    testWidgets('should show AlbumArtwork with centered AnimatedEqualizer overlay when playing with showArtwork', (tester) async {
      final song = Song(
        id: '1',
        title: 'Playing Song',
        artist: 'Test Artist',
        album: 'Test Album',
        coverArt: 'cover_1',
      );

      // Set song as current playing song
      playerProvider.playSong(song, playlist: [song], startIndex: 0);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<SubsonicService>.value(value: subsonicService),
            ChangeNotifierProvider<PlayerProvider>.value(value: playerProvider),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: SongTile(song: song, showArtwork: true),
            ),
          ),
        ),
      );

      // Flush internal timers from playSong
      await tester.pump(const Duration(seconds: 2));

      expect(find.byType(AlbumArtwork), findsOneWidget);
      expect(find.byType(AnimatedEqualizer), findsOneWidget);
      expect(find.byType(Stack), findsWidgets);
    });

    testWidgets('AnimatedEqualizer maintains stable height of 16.0 during animation', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: AnimatedEqualizer(
                color: Colors.white,
                isPlaying: true,
              ),
            ),
          ),
        ),
      );

      final initialSize = tester.getSize(find.byType(AnimatedEqualizer));
      expect(initialSize.height, 16.0);

      // Advance frames to let animations progress
      await tester.pump(const Duration(milliseconds: 150));
      final sizeMidway = tester.getSize(find.byType(AnimatedEqualizer));
      expect(sizeMidway.height, 16.0);

      await tester.pump(const Duration(milliseconds: 200));
      final sizeLater = tester.getSize(find.byType(AnimatedEqualizer));
      expect(sizeLater.height, 16.0);
    });

    testWidgets('SongTile shows Remove from Playlist when onRemoveFromPlaylist is provided (#276)', (tester) async {
      bool removed = false;
      final song = Song(
        id: '1',
        title: 'Playlist Song',
        artist: 'Test Artist',
      );

      await tester.pumpWidget(
        createTestApp(
          child: SongTile(
            song: song,
            onRemoveFromPlaylist: () {
              removed = true;
            },
          ),
        ),
      );

      // Open options modal by tapping trailing button
      await tester.tap(find.byIcon(Icons.more_horiz));
      await tester.pumpAndSettle();

      // Find remove from playlist option
      final removeOption = find.text('Remove from Playlist');
      expect(removeOption, findsOneWidget);

      await tester.tap(removeOption);
      await tester.pumpAndSettle();

      expect(removed, isTrue);
    });
  });
}
