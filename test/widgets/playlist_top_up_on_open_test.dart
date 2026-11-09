import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
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

/// Every download fails at once: no server is involved. Records which songs
/// the download queue asked for.
class _FailingDownloads extends SubsonicService {
  final List<String> requested = [];

  @override
  String getDownloadUrl(String id) {
    requested.add(id);
    throw Exception('no server in tests');
  }
}

/// Holds getPlaylist open until the test completes it, so the screen can be
/// closed while the fetch is in flight.
class _SlowLibraryProvider extends LibraryProvider {
  _SlowLibraryProvider(SubsonicService service)
      : super(service, MuslyAudioHandler());

  final fetch = Completer<Playlist>();

  @override
  Future<Playlist> getPlaylist(String playlistId) => fetch.future;

  // The real one writes to sqflite, which the test environment lacks.
  @override
  Future<void> cacheSongsLocally(List<Song> songs) async {}
}

/// Its song cache write fails, as a database error would.
class _BrokenCacheLibraryProvider extends _SlowLibraryProvider {
  _BrokenCacheLibraryProvider(super.service);

  @override
  Future<void> cacheSongsLocally(List<Song> songs) async {
    throw Exception('database is locked');
  }
}

/// Waits for the top-up's downloads to finish. The queue runs partly in real
/// time (the download delays) and partly in the test's fake-async zone (where
/// it was started), so alternate real waits with pumps.
Future<void> _downloadsSettled(
    WidgetTester tester, _FailingDownloads svc) async {
  final offline = OfflineService();
  for (var i = 0; i < 100; i++) {
    if (svc.requested.isNotEmpty &&
        offline.queuedPlaylistIds.value.isEmpty &&
        !offline.isBackgroundDownloadActive) {
      break;
    }
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

  testWidgets('closing a playlist before it loads still tops it up',
      (tester) async {
    offline.setOfflineMode(false);
    offline.queuedPlaylistIds.value = {};
    offline.downloadedPlaylistIds.value = {'p1'};
    offline.downloadedSongIds.value = {'a'};

    final svc = _FailingDownloads();
    final library = _SlowLibraryProvider(svc);

    await tester.pumpWidget(createTestApp(
      subsonicService: svc,
      libraryProvider: library,
      child: const PlaylistScreen(playlistId: 'p1', playlistName: 'P1'),
    ));

    // The user backs out while the fetch is still running.
    await tester.pumpWidget(createTestApp(
      subsonicService: svc,
      libraryProvider: library,
      child: const SizedBox(),
    ));

    library.fetch.complete(Playlist(
      id: 'p1',
      name: 'P1',
      songs: [
        Song(id: 'a', title: 'A'),
        Song(id: 'b', title: 'B'),
      ],
    ));
    await _downloadsSettled(tester, svc);

    // The screen is gone, but the download it found missing is still wanted.
    expect(svc.requested.toSet(), {'b'});
  });

  testWidgets('a failed song cache write after a top-up is caught',
      (tester) async {
    offline.setOfflineMode(false);
    offline.queuedPlaylistIds.value = {};
    offline.downloadedPlaylistIds.value = {'p1'};
    offline.downloadedSongIds.value = {'a'};

    final svc = _FailingDownloads();
    final library = _BrokenCacheLibraryProvider(svc);

    await tester.pumpWidget(createTestApp(
      subsonicService: svc,
      libraryProvider: library,
      child: const PlaylistScreen(playlistId: 'p1', playlistName: 'P1'),
    ));

    library.fetch.complete(Playlist(
      id: 'p1',
      name: 'P1',
      // With no cover art the open screen would generate one on disk.
      coverArt: 'cover-p1',
      songs: [
        Song(id: 'a', title: 'A'),
        Song(id: 'b', title: 'B'),
      ],
    ));
    await _downloadsSettled(tester, svc);

    // The top-up still went ahead, and the error did not escape: an uncaught
    // async error fails a testWidgets test.
    expect(svc.requested.toSet(), {'b'});
  });
}
