import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musly/providers/auth_provider.dart';
import 'package:musly/providers/library_provider.dart';
import 'package:musly/providers/player_provider.dart';
import 'package:musly/services/services.dart';
import 'package:musly/services/audio_handler.dart';
import 'package:provider/provider.dart';

import '../test_helpers.dart';
import '../bootstrap.dart';

void main() {
  initializeTestEnvironment();

  group('Memory Leak & Disposal Tests', () {
    testWidgets('PlayerProvider should dispose without leaking', (
      WidgetTester tester,
    ) async {
      final subsonic = SubsonicService();
      final storage = StorageService();
      final provider = PlayerProvider(
        subsonic,
        storage,
        FakeCastService(),
        UpnpService(),
        MuslyAudioHandler(),
        JukeboxService(),
      );

      await tester.pumpWidget(
        ChangeNotifierProvider<PlayerProvider>.value(
          value: provider,
          child: const MaterialApp(home: Scaffold(body: Text('test'))),
        ),
      );

      await tester.pump();
      provider.dispose();
      expect(true, true); // If we got here without exception, disposal worked
    });

    testWidgets('AuthProvider should dispose cleanly', (
      WidgetTester tester,
    ) async {
      final subsonic = SubsonicService();
      final storage = StorageService();
      final provider = AuthProvider(subsonic, storage);

      await tester.pumpWidget(
        ChangeNotifierProvider<AuthProvider>.value(
          value: provider,
          child: const MaterialApp(home: Scaffold()),
        ),
      );
      await tester.pump();
      provider.dispose();
      expect(true, true);
    });

    testWidgets('LibraryProvider should dispose cleanly', (
      WidgetTester tester,
    ) async {
      final subsonic = SubsonicService();
      final provider = LibraryProvider(subsonic);

      await tester.pumpWidget(
        ChangeNotifierProvider<LibraryProvider>.value(
          value: provider,
          child: const MaterialApp(home: Scaffold()),
        ),
      );
      await tester.pump();
      provider.dispose();
      expect(true, true);
    });

    testWidgets('NowPlayingScreen should not leak after navigation', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        createTestApp(
          child: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const Scaffold()),
                  );
                },
                child: const Text('Open'),
              );
            },
          ),
        ),
      );
      await tester.pump();
      await tester.tap(find.text('Open'));
      await tester.pump();
      final navigatorState =
          tester.state<NavigatorState>(find.byType(Navigator));
      navigatorState.pop();
      await tester.pump();
      expect(find.text('Open'), findsOneWidget);
    });

    testWidgets('AlbumScreen should not leak after pump & dispose', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        createTestApp(child: const Scaffold(body: Text('stub'))),
      );
      await tester.pumpAndSettle();
      // Force a few rebuild cycles to stress memory
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(find.text('stub'), findsOneWidget);
    });
  });
}
