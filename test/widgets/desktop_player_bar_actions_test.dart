import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:musly/models/song.dart';
import 'package:musly/models/server_config.dart';
import 'package:musly/providers/player_provider.dart';
import 'package:musly/providers/library_provider.dart';
import 'package:musly/services/subsonic_service.dart';
import 'package:musly/services/storage_service.dart';
import 'package:musly/services/upnp_service.dart';
import 'package:musly/services/audio_handler.dart';
import 'package:musly/services/jukebox_service.dart';
import 'package:musly/services/transcoding_service.dart';
import 'package:musly/services/tv_detection_service.dart';
import 'package:musly/widgets/navigation/desktop_player_bar.dart';
import 'package:musly/widgets/modals/song_options_modal.dart';
import 'package:musly/screens/player/now_playing_screen.dart';
import 'package:musly/services/offline_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../test_helpers.dart';
import '../bootstrap.dart';

void main() {
  initializeTestEnvironment();

  group('DesktopPlayerBar Actions Tests', () {
    late SubsonicService subsonicService;
    late PlayerProvider playerProvider;
    late LibraryProvider libraryProvider;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      subsonicService = SubsonicService();
      await subsonicService.configure(ServerConfig(
        serverUrl: 'https://demo.navidrome.org',
        username: 'user',
        password: 'password',
      ));
      final storageService = StorageService();
      playerProvider = PlayerProvider(
        subsonicService,
        storageService,
        FakeCastService(),
        UpnpService(),
        MuslyAudioHandler(),
        JukeboxService(),
        TranscodingService(),
      );
      libraryProvider = LibraryProvider(
        subsonicService,
        MuslyAudioHandler(),
      );
    });

    tearDownAll(() {
      TestWidgetsFlutterBinding.instance.platformDispatcher.views.first
          .resetPhysicalSize();
      TestWidgetsFlutterBinding.instance.platformDispatcher.views.first
          .resetDevicePixelRatio();
    });

    testWidgets(
        'renders favorite, add to playlist, and more options buttons for current song',
        (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;

      final song = Song(
        id: 'test_song_1',
        title: 'Test Song Title',
        artist: 'Test Artist',
        duration: 210,
      );

      libraryProvider.setServerOfflineMode(true);
      playerProvider.playSong(song);

      await tester.pumpWidget(
        createTestApp(
          playerProvider: playerProvider,
          libraryProvider: libraryProvider,
          subsonicService: subsonicService,
          child: ChangeNotifierProvider<TvDetectionService>(
            create: (_) => TvDetectionService(),
            child: const SizedBox(
              height: 90,
              child: DesktopPlayerBar(),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(seconds: 1));

      expect(find.byType(DesktopPlayerBar), findsOneWidget);
      expect(find.text('Test Song Title'), findsOneWidget);
      expect(find.text('Test Artist'), findsOneWidget);

      expect(find.byIcon(Icons.favorite_border_rounded), findsOneWidget);
      expect(find.byIcon(Icons.playlist_add_rounded), findsOneWidget);
      expect(find.byIcon(Icons.more_horiz), findsOneWidget);

      await tester.tap(find.byIcon(Icons.more_horiz));
      await tester.pumpAndSettle();

      expect(find.byType(SongOptionsModal), findsOneWidget);
      expect(find.text('Add to Playlist'), findsOneWidget);

      Navigator.pop(tester.element(find.byType(SongOptionsModal)));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.playlist_add_rounded));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Add to Playlist'), findsWidgets);
      Navigator.pop(tester.element(find.text('Add to Playlist').first));
      await tester.pumpAndSettle();

      // Tapping track info opens NowPlayingScreen (#278)
      OfflineService().setOfflineMode(true);
      await tester.tap(find.text('Test Song Title'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(NowPlayingScreen), findsOneWidget);

      Navigator.pop(tester.element(find.byType(NowPlayingScreen)));
      await tester.pump();
      await tester.pump(const Duration(seconds: 3));
      OfflineService().setOfflineMode(false);
    });
  });
}
