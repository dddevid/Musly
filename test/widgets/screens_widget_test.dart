import 'package:flutter_test/flutter_test.dart';
import 'package:musly/screens/all_songs_screen.dart';
import 'package:musly/screens/library_screen.dart';
import 'package:musly/screens/playlists_screen.dart';
import 'package:musly/screens/settings_screen.dart';

import '../test_helpers.dart';

void main() {
  group('Screen Widget Tests', () {
    testWidgets('LibraryScreen builds without exception', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestApp(child: const LibraryScreen()));
      await tester.pumpAndSettle();
      expect(find.byType(LibraryScreen), findsOneWidget);
    });

    testWidgets('AllSongsScreen builds without exception', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestApp(child: const AllSongsScreen()));
      await tester.pumpAndSettle();
      expect(find.byType(AllSongsScreen), findsOneWidget);
    });

    testWidgets('PlaylistsScreen builds without exception', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestApp(child: const PlaylistsScreen()));
      await tester.pumpAndSettle();
      expect(find.byType(PlaylistsScreen), findsOneWidget);
    });

    testWidgets('SettingsScreen builds without exception', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestApp(child: const SettingsScreen()));
      await tester.pumpAndSettle();
      expect(find.byType(SettingsScreen), findsOneWidget);
    });

    testWidgets('LibraryScreen filter chips are tappable', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestApp(child: const LibraryScreen()));
      await tester.pumpAndSettle();

      // Tap through available filters
      final filters = ['Faves', 'Albums', 'Artists', 'Songs'];
      for (final filter in filters) {
        final chip = find.text(filter);
        if (chip.evaluate().isNotEmpty) {
          await tester.tap(chip);
          await tester.pumpAndSettle();
        }
      }
      expect(find.byType(LibraryScreen), findsOneWidget);
    });

    testWidgets('AllSongsScreen sort button opens bottom sheet', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestApp(child: const AllSongsScreen()));
      await tester.pumpAndSettle();

      final sortButton = find.byTooltip('Sort');
      if (sortButton.evaluate().isNotEmpty) {
        await tester.tap(sortButton);
        await tester.pumpAndSettle();
        expect(find.text('Sort By'), findsOneWidget);
      }
    });
  });
}
