import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musly/models/song.dart';
import 'package:musly/services/offline_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../bootstrap.dart';

/// A downloaded playlist opened with no connection showed "No songs in this
/// playlist": its track list came only from LibraryProvider's playlist cache,
/// which holds tracks only if the playlist was opened online since that cache
/// was last rewritten. The offline store dropped the list the moment the
/// download finished. It now keeps the track list of each playlist download.

Song _song(String id) => Song(id: id, title: 'Title $id');

List<String>? _ids(List<Song>? songs) => songs?.map((s) => s.id).toList();

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

  final offline = OfflineService();

  setUpAll(() async {
    // Once: the singleton keeps the SharedPreferences instance it got first,
    // so a later setMockInitialValues never reaches it. Tests reset its state
    // through deleteAllDownloads instead.
    SharedPreferences.setMockInitialValues({});
    await offline.initialize();
  });

  setUp(() async {
    await offline.deleteAllDownloads();
    await offline.initialize();
    offline.setOfflineMode(false);
    offline.queuedPlaylistIds.value = {};
    offline.downloadedPlaylistIds.value = {};
    offline.downloadedSongIds.value = {};
  });

  tearDownAll(() => appDir.deleteSync(recursive: true));

  test('a downloaded playlist\'s tracks survive a restart', () async {
    await offline.rememberPlaylistTracks('p1', [_song('a'), _song('b')]);

    // A fresh launch reads the store back from prefs.
    await offline.initialize();

    expect(_ids(offline.getPlaylistTracks('p1')), ['a', 'b']);
  });

  test('a playlist that was never downloaded has no stored tracks', () {
    expect(offline.getPlaylistTracks('p1'), isNull);
  });

  group('refreshPlaylistTracks', () {
    test('keeps a stored playlist current', () async {
      offline.downloadedSongIds.value = {'a'};
      await offline.rememberPlaylistTracks('p1', [_song('a'), _song('b')]);

      await offline.refreshPlaylistTracks('p1', [_song('a'), _song('c')]);

      expect(_ids(offline.getPlaylistTracks('p1')), ['a', 'c']);
    });

    test('stores a playlist downloaded before track lists were kept', () async {
      offline.downloadedPlaylistIds.value = {'p1'};
      offline.downloadedSongIds.value = {'a'};

      await offline.refreshPlaylistTracks('p1', [_song('a'), _song('b')]);

      expect(_ids(offline.getPlaylistTracks('p1')), ['a', 'b']);
    });

    test('ignores a playlist that is not downloaded', () async {
      offline.downloadedSongIds.value = {'a'};

      await offline.refreshPlaylistTracks('p1', [_song('a')]);

      expect(offline.getPlaylistTracks('p1'), isNull);
    });

    test('a different playlist with the same id does not overwrite it',
        () async {
      // Another server profile (or an album) with this id: none of its
      // tracks are on disk.
      offline.downloadedSongIds.value = {'a', 'b'};
      await offline.rememberPlaylistTracks('p1', [_song('a'), _song('b')]);

      await offline.refreshPlaylistTracks('p1', [_song('x'), _song('y')]);

      expect(_ids(offline.getPlaylistTracks('p1')), ['a', 'b']);
    });

    test('ignores a downloaded id with none of its tracks on disk', () async {
      // Albums share downloadedPlaylistIds, so a downloaded album whose id
      // matches this playlist's must not make it look downloaded.
      offline.downloadedPlaylistIds.value = {'p1'};
      offline.downloadedSongIds.value = {'album-track'};

      await offline.refreshPlaylistTracks('p1', [_song('a'), _song('b')]);

      expect(offline.getPlaylistTracks('p1'), isNull);
    });
  });

  test('one damaged stored playlist does not cost the others', () async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('offline_playlist_tracks',
        '{"p1": [1], "p2": [{"id": "a", "title": "A"}]}');

    await offline.initialize();

    expect(offline.getPlaylistTracks('p1'), isNull);
    expect(_ids(offline.getPlaylistTracks('p2')), ['a']);
  });

  test('removing a playlist download forgets its tracks', () async {
    await offline.rememberPlaylistTracks('p1', [_song('a')]);

    await offline.cancelPlaylistDownload('p1');
    await offline.initialize();

    expect(offline.getPlaylistTracks('p1'), isNull);
  });

  test('deleting all downloads forgets every playlist\'s tracks', () async {
    await offline.rememberPlaylistTracks('p1', [_song('a')]);

    await offline.deleteAllDownloads();
    expect(offline.getPlaylistTracks('p1'), isNull);

    // Nor does a restart bring them back.
    await offline.initialize();
    expect(offline.getPlaylistTracks('p1'), isNull);
  });
}
