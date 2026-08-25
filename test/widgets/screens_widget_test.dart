import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musly/screens/media/song_collection_screen.dart';
import 'package:musly/screens/main/library_screen.dart';
import 'package:musly/screens/media/playlists_screen.dart';
import 'package:musly/screens/settings/settings_screen.dart';
import 'package:musly/screens/player/now_playing_screen.dart';
import 'package:musly/models/lyric_line.dart';

import '../test_helpers.dart';
import '../bootstrap.dart';

void main() {
  initializeTestEnvironment();
  group('Screen Widget Tests', () {
    testWidgets('LibraryScreen builds without exception', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestApp(child: const LibraryScreen()));
      await tester.pump();
      expect(find.byType(LibraryScreen), findsOneWidget);
    });

    testWidgets('AllSongsScreen builds without exception', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestApp(child: const AllSongsScreen()));
      await tester.pump();
      expect(find.byType(AllSongsScreen), findsOneWidget);
    });

    testWidgets('PlaylistsScreen builds without exception', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestApp(child: const PlaylistsScreen()));
      await tester.pump();
      expect(find.byType(PlaylistsScreen), findsOneWidget);
    });

    testWidgets('SettingsScreen builds without exception', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestApp(child: const SettingsScreen()));
      await tester.pump();
      expect(find.byType(SettingsScreen), findsOneWidget);
    });

    testWidgets('NowPlayingScreen builds without exception in portrait', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestApp(
        child: NowPlayingScreen(
          image: const AssetImage('assets/logo.png'),
          title: 'Test Title',
          artist: 'Test Artist',
          heroTag: 'test_hero',
          lyrics: [
            LyricLine(startTime: Duration.zero, text: 'Test Line'),
          ],
        ),
      ));
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.byType(NowPlayingScreen), findsOneWidget);
    });

    testWidgets('NowPlayingScreen builds without overflow in landscape mode (Issue #234)', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(850, 400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestApp(
        child: NowPlayingScreen(
          image: const AssetImage('assets/logo.png'),
          title: 'Test Title',
          artist: 'Test Artist',
          heroTag: 'test_hero',
          lyrics: [
            LyricLine(startTime: Duration.zero, text: 'Test Line'),
          ],
        ),
      ));
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.byType(NowPlayingScreen), findsOneWidget);
      // Ensure no exceptions or overflows occurred
      expect(tester.takeException(), isNull);
    });
  });
}
