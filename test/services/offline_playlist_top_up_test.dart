import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:musly/models/song.dart';
import 'package:musly/services/offline_service.dart';
import 'package:musly/services/subsonic_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../bootstrap.dart';

/// _processQueue drops a playlist's track list the moment it completes, and
/// resumeIncompleteDownloads only walks playlists still in the queue. So a
/// finished playlist was never looked at again: add a track to a playlist you
/// had already downloaded and that track never downloaded.
///
/// Every download here fails at once: no server is involved, and the failure
/// path is the one that matters most (see "a failed top-up ...").
class _FailingDownloads extends SubsonicService {
  final List<String> requested = [];

  @override
  String getDownloadUrl(String id) {
    requested.add(id);
    throw Exception('no server in tests');
  }
}

Song _song(String id) => Song(id: id, title: 'Title $id');

void main() {
  initializeTestEnvironment();

  final offline = OfflineService();
  late _FailingDownloads svc;

  Future<void> queueDrained() async {
    for (var i = 0; i < 100; i++) {
      if (offline.queuedPlaylistIds.value.isEmpty &&
          !offline.isBackgroundDownloadActive) {
        return;
      }
      await Future<void>.delayed(const Duration(milliseconds: 20));
    }
    fail('download queue did not drain');
  }

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    // initialize() repopulates the notifiers from prefs, so run it once up
    // front rather than lazily in the middle of a test.
    await offline.initialize();
  });

  setUp(() {
    // OfflineService is a singleton; give each test a known state.
    svc = _FailingDownloads();
    offline.setOfflineMode(false);
    offline.queuedPlaylistIds.value = {};
    offline.downloadedPlaylistIds.value = {'p1'};
    offline.downloadedSongIds.value = {'a'};
  });

  tearDown(queueDrained);

  tearDownAll(() {
    // bootstrap.dart mocks path_provider to '.', so initialize() creates an
    // offline_music directory in the working tree. Do not leave it behind.
    final dir = Directory('./offline_music');
    if (dir.existsSync()) dir.deleteSync(recursive: true);
  });

  test('a track added to a downloaded playlist is downloaded', () async {
    final queued = await offline.topUpDownloadedPlaylist(
        'p1', [_song('a'), _song('b')], svc);
    await queueDrained();

    expect(queued, isTrue);
    // A set: the download service retries a failed song once.
    expect(svc.requested.toSet(), {'b'},
        reason: 'only the missing track is fetched');
  });

  test('a failed top-up leaves the playlist listed as downloaded', () async {
    // Record every change, not just the end state: dropping p1 and adding it
    // back later would still hide the playlist offline in between.
    final seen = <Set<String>>[];
    void record() => seen.add({...offline.downloadedPlaylistIds.value});
    offline.downloadedPlaylistIds.addListener(record);
    addTearDown(() => offline.downloadedPlaylistIds.removeListener(record));

    await offline.topUpDownloadedPlaylist('p1', [_song('a'), _song('b')], svc);
    await queueDrained();

    // The offline views list playlists from downloadedPlaylistIds. Unmarking
    // it before the new track arrived would make a playlist that is almost
    // entirely on disk vanish offline whenever that download failed.
    expect(seen, everyElement(contains('p1')));
    expect(offline.downloadedPlaylistIds.value, contains('p1'));
  });

  test('a playlist the user never downloaded is left alone', () async {
    offline.downloadedPlaylistIds.value = {};

    final queued = await offline.topUpDownloadedPlaylist(
        'p1', [_song('a'), _song('b')], svc);

    expect(queued, isFalse);
    expect(offline.queuedPlaylistIds.value, isEmpty);
  });

  test('a playlist with every track on disk queues nothing', () async {
    final queued =
        await offline.topUpDownloadedPlaylist('p1', [_song('a')], svc);

    expect(queued, isFalse);
    expect(offline.queuedPlaylistIds.value, isEmpty);
  });

  test('reopening while a top-up is queued adds no second job', () async {
    offline.queuedPlaylistIds.value = {'p1'};

    final queued = await offline.topUpDownloadedPlaylist(
        'p1', [_song('a'), _song('b')], svc);

    expect(queued, isFalse);
    offline.queuedPlaylistIds.value = {};
  });

  test('a playlist sharing an id with another download is left alone',
      () async {
    // Albums are queued through queuePlaylistDownload too, and profiles share
    // one set, so 'p1' may be an album or another server's playlist. None of
    // this playlist's tracks are on disk, so it is not the one downloaded.
    final queued = await offline.topUpDownloadedPlaylist(
        'p1', [_song('x'), _song('y')], svc);

    expect(queued, isFalse);
    expect(svc.requested, isEmpty);
  });

  test('nothing is queued in offline mode', () async {
    offline.setOfflineMode(true);

    final queued = await offline.topUpDownloadedPlaylist(
        'p1', [_song('a'), _song('b')], svc);

    expect(queued, isFalse);
    expect(svc.requested, isEmpty);
  });
}
