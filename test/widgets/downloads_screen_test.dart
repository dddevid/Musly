import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musly/models/song.dart';
import 'package:musly/providers/library_provider.dart';
import 'package:musly/screens/media/downloads_screen.dart';
import 'package:musly/services/audio_handler.dart';
import 'package:musly/services/offline_service.dart';
import 'package:musly/services/subsonic_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../bootstrap.dart';
import '../test_helpers.dart';

/// The app never registers OfflineService with Provider (it is a singleton),
/// and neither does createTestApp. The Downloads screen looked it up with
/// Provider.of, which threw, so it always showed "No downloaded songs yet".

/// A library that already knows two songs, as one loaded from the local
/// database does.
class _KnownSongsLibrary extends LibraryProvider {
  _KnownSongsLibrary(SubsonicService service)
      : super(service, MuslyAudioHandler());

  @override
  List<Song> get cachedAllSongs => [
        Song(id: 'a', title: 'Downloaded Song'),
        Song(id: 'b', title: 'Streamed Song'),
      ];
}

/// The screen awaits real file I/O (OfflineService.initialize lists the
/// download directory), which completes outside the test's fake-async zone.
/// Alternate real waits with pumps until [done] holds.
Future<void> _settle(WidgetTester tester, bool Function() done) async {
  for (var i = 0; i < 100 && !done(); i++) {
    await tester
        .runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
    await tester.pump();
  }
}

void main() {
  initializeTestEnvironment();

  // Its own app documents directory: test files run concurrently, and the
  // '.' that bootstrap.dart returns would be shared with other suites.
  late Directory appDir;
  setUpAll(() {
    appDir = Directory.systemTemp.createTempSync('musly_test_');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (_) async => appDir.path,
    );
  });

  setUpAll(() async {
    // Once, before OfflineService first reads prefs: the singleton keeps the
    // SharedPreferences instance it got first, so a later reset never
    // reaches it.
    SharedPreferences.setMockInitialValues({
      'offline_downloaded_songs': ['a'],
    });
    await OfflineService().initialize();
  });

  tearDownAll(() => appDir.deleteSync(recursive: true));

  testWidgets('the Downloads screen lists downloaded songs', (tester) async {
    final svc = SubsonicService();

    await tester.pumpWidget(createTestApp(
      subsonicService: svc,
      libraryProvider: _KnownSongsLibrary(svc),
      child: const DownloadsScreen(),
    ));
    await _settle(
        tester, () => find.text('Downloaded Song').evaluate().isNotEmpty);

    expect(find.text('Downloaded Song'), findsOneWidget);
    expect(find.text('Streamed Song'), findsNothing);
    expect(find.text('No downloaded songs yet'), findsNothing);
  });
}
