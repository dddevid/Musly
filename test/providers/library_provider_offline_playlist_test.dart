import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musly/models/playlist.dart';
import 'package:musly/models/song.dart';
import 'package:musly/providers/library_provider.dart';
import 'package:musly/services/audio_handler.dart';
import 'package:musly/services/offline_service.dart';
import 'package:musly/services/subsonic_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../bootstrap.dart';

/// The playlist list endpoint returns playlists without their tracks, so a
/// playlist the user downloaded but has not opened since the cache was last
/// rewritten is cached with no songs. Offline it must still list its tracks,
/// from the offline store.
class _Server extends SubsonicService {
  bool reachable = true;
  List<Song> tracks = [Song(id: 'a', title: 'A'), Song(id: 'b', title: 'B')];

  @override
  Future<List<Playlist>> getPlaylists() async =>
      [Playlist(id: 'p1', name: 'P1', songCount: 2)];

  @override
  Future<Playlist> getPlaylist(String id) async {
    if (!reachable) throw const SocketException('Network is unreachable');
    return Playlist(
        id: id, name: 'P1', songCount: tracks.length, songs: tracks);
  }
}

List<String>? _ids(Playlist p) => p.songs?.map((s) => s.id).toList();

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
  late _Server server;
  late LibraryProvider library;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await offline.deleteAllDownloads();
    await offline.initialize();
    offline.setOfflineMode(false);
    offline.queuedPlaylistIds.value = {};
    offline.downloadedPlaylistIds.value = {};
    offline.downloadedSongIds.value = {};

    server = _Server();
    library = LibraryProvider(server, MuslyAudioHandler());
    // Caches P1 as the list endpoint returns it: no tracks.
    await library.loadPlaylists();
  });

  tearDownAll(() => appDir.deleteSync(recursive: true));

  test('offline mode lists a downloaded playlist\'s stored tracks', () async {
    await offline.rememberPlaylistTracks('p1', server.tracks);
    library.setServerOfflineMode(true);

    final playlist = await library.getPlaylist('p1');

    expect(_ids(playlist), ['a', 'b']);
  });

  test('an unreachable server falls back to the stored tracks', () async {
    // The connection dropped while the app was open: not in offline mode.
    await offline.rememberPlaylistTracks('p1', server.tracks);
    server.reachable = false;

    final playlist = await library.getPlaylist('p1');

    expect(_ids(playlist), ['a', 'b']);
  });

  test('opening a downloaded playlist online stores its tracks', () async {
    // Downloaded before track lists were kept.
    offline.downloadedPlaylistIds.value = {'p1'};
    offline.downloadedSongIds.value = {'a', 'b'};

    await library.getPlaylist('p1');

    expect(offline.getPlaylistTracks('p1')?.map((s) => s.id), ['a', 'b']);
  });
}
