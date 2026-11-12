import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:musly/models/playlist.dart';
import 'package:musly/models/song.dart';
import 'package:musly/providers/library_provider.dart';
import 'package:musly/screens/detail/playlist_screen.dart';
import 'package:musly/services/audio_handler.dart';
import 'package:musly/services/offline_service.dart';
import 'package:musly/services/subsonic_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../bootstrap.dart';
import '../test_helpers.dart';

/// Every download fails at once: no server is involved.
class _FailingDownloads extends SubsonicService {
  final List<String> requested = [];

  @override
  String getDownloadUrl(String id) {
    requested.add(id);
    throw Exception('no server in tests');
  }
}

class _Library extends LibraryProvider {
  _Library(SubsonicService service) : super(service, MuslyAudioHandler());

  @override
  Future<Playlist> getPlaylist(String playlistId) async => Playlist(
        id: playlistId,
        name: 'P1',
        // With no cover art the open screen would generate one on disk.
        coverArt: 'cover-p1',
        songs: [Song(id: 'a', title: 'A'), Song(id: 'b', title: 'B')],
      );

  // The real one writes to sqflite, which the test environment lacks.
  @override
  Future<void> cacheSongsLocally(List<Song> songs) async {}
}

/// Alternates real waits with pumps: the download queue runs partly in real
/// time and partly in the test's fake-async zone.
Future<void> _settle(WidgetTester tester, bool Function() done) async {
  for (var i = 0; i < 100 && !done(); i++) {
    await tester
        .runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
    await tester.pump();
  }
}

void main() {
  initializeTestEnvironment();

  final offline = OfflineService();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await offline.initialize();
  });

  tearDownAll(() {
    // bootstrap.dart mocks path_provider to '.', so initialize() creates an
    // offline_music directory in the working tree. Do not leave it behind.
    final dir = Directory('./offline_music');
    if (dir.existsSync()) dir.deleteSync(recursive: true);
  });

  testWidgets('downloading a playlist stores its tracks for offline use',
      (tester) async {
    offline.setOfflineMode(false);
    offline.queuedPlaylistIds.value = {};
    offline.downloadedPlaylistIds.value = {};
    offline.downloadedSongIds.value = {};

    final svc = _FailingDownloads();
    await tester.pumpWidget(createTestApp(
      subsonicService: svc,
      libraryProvider: _Library(svc),
      child: const PlaylistScreen(playlistId: 'p1', playlistName: 'P1'),
    ));
    await tester.pump();

    await tester.tap(find.byTooltip('Download playlist'));
    // Wait for the queued downloads to run (and fail) so none outlive the
    // test.
    await _settle(
        tester,
        () =>
            svc.requested.isNotEmpty &&
            offline.queuedPlaylistIds.value.isEmpty &&
            !offline.isBackgroundDownloadActive);

    expect(offline.getPlaylistTracks('p1')?.map((s) => s.id), ['a', 'b']);
  });
}
