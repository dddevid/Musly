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
import 'package:musly/widgets/now_playing/queue_view.dart';
import 'package:musly/l10n/app_localizations.dart';
import '../test_helpers.dart';
import '../bootstrap.dart';

import 'package:shared_preferences/shared_preferences.dart';

void main() {
  initializeTestEnvironment();
  group('QueueView Widget Tests', () {
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

    testWidgets('renders empty queue message when queue is empty', (tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<SubsonicService>.value(value: subsonicService),
            ChangeNotifierProvider<PlayerProvider>.value(value: playerProvider),
          ],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(body: QueueView()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No songs in queue'), findsOneWidget);
    });

    testWidgets('renders ReorderableListView with drag handles and more_vert buttons', (tester) async {
      final song1 = Song(id: '1', title: 'Song One', artist: 'Artist One', duration: 180);
      final song2 = Song(id: '2', title: 'Song Two', artist: 'Artist Two', duration: 200);

      playerProvider.addToQueue(song1);
      playerProvider.addToQueue(song2);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<SubsonicService>.value(value: subsonicService),
            ChangeNotifierProvider<PlayerProvider>.value(value: playerProvider),
          ],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(body: QueueView()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ReorderableListView), findsOneWidget);
      expect(find.text('Up Next'), findsOneWidget);
      expect(find.text('Song One'), findsOneWidget);
      expect(find.text('Song Two'), findsOneWidget);
      expect(find.byIcon(Icons.more_vert_rounded), findsNWidgets(2));
      expect(find.byIcon(Icons.drag_handle_rounded), findsNWidgets(2));
    });
  });
}
