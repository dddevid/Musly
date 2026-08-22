import 'package:flutter_test/flutter_test.dart';
import 'package:musly/screens/media/song_collection_screen.dart';
import 'package:musly/screens/main/library_screen.dart';
import 'package:musly/screens/media/playlists_screen.dart';
import 'package:musly/screens/settings/settings_screen.dart';

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
  });
}
