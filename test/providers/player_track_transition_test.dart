import 'package:flutter_test/flutter_test.dart';
import 'package:musly/models/song.dart';
import 'package:musly/providers/player_provider.dart';
import 'package:musly/services/audio_handler.dart';
import 'package:musly/services/jukebox_service.dart';
import 'package:musly/services/storage_service.dart';
import 'package:musly/services/subsonic_service.dart';
import 'package:musly/services/transcoding_service.dart';
import 'package:musly/services/upnp_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../bootstrap.dart';
import '../test_helpers.dart';

/// A track change owes the same work no matter which transport drove it:
/// invalidate the artwork cache, re-resolve it, reset scrobble tracking, send
/// the "now playing" scrobble, re-apply ReplayGain, and update every service
/// and the media session.
///
/// The UPnP renderer's gapless auto-advance used to reimplement that transition
/// and do only the media-session update. Because the app hands the next track
/// off with SetNextAVTransportURI, the renderer drives *most* transitions in a
/// DLNA session — so in practice a DLNA session scrobbled only its first track
/// and the lock screen kept showing a cover from several songs ago.
///
/// These tests pin the shared path so the two transports cannot drift again.
void main() {
  initializeTestEnvironment();

  late PlayerProvider player;
  late MuslyAudioHandler handler;

  Song song(String id) => Song(
        id: id,
        title: 'Title $id',
        artist: 'Artist $id',
        album: 'Album $id',
        coverArt: 'art-$id',
        duration: 120,
      );

  /// Local songs resolve their artwork to a file URI without needing a server,
  /// which is what lets the artwork test assert on a real value.
  Song localSong(String id) => Song(
        id: id,
        title: 'Title $id',
        artist: 'Artist $id',
        album: 'Album $id',
        coverArt: '/tmp/cover-$id.jpg',
        path: '/tmp/$id.mp3',
        isLocal: true,
        duration: 120,
      );

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    handler = MuslyAudioHandler();
    player = PlayerProvider(
      SubsonicService(),
      StorageService(),
      FakeCastService(),
      UpnpService(),
      handler,
      JukeboxService(),
      TranscodingService(),
    );
  });

  tearDown(() => player.dispose());

  test('adoptTrackAt moves the current track to the requested index', () async {
    player.queue.addAll([song('a'), song('b'), song('c')]);

    await player.adoptTrackAt(1);

    expect(player.currentIndex, 1);
    expect(player.currentSong?.id, 'b');
  });

  test('adoptTrackAt republishes metadata for the adopted track', () async {
    player.queue.addAll([song('a'), song('b')]);

    await player.adoptTrackAt(0);
    expect(handler.mediaItem.value?.id, 'a');

    await player.adoptTrackAt(1);

    // The media session is what the lock screen and head unit read. If the
    // auto-advance path skips this, they stay pinned to the previous track.
    expect(handler.mediaItem.value?.id, 'b');
    expect(handler.mediaItem.value?.title, 'Title b');
  });

  test('adoptTrackAt does not carry artwork across a track change', () async {
    // Local songs deliberately: _resolveArtworkUrl resolves those straight to
    // a file URI, so the artwork is non-null without a configured server. With
    // remote songs getCoverArtUrl returns '' and artUri is null on both sides,
    // which would make this assertion silently vacuous.
    player.queue.addAll([localSong('a'), localSong('b')]);

    await player.adoptTrackAt(0);
    final firstArt = handler.mediaItem.value?.artUri?.toString();
    expect(firstArt, isNotNull, reason: 'guard against a vacuous comparison');

    await player.adoptTrackAt(1);
    final secondArt = handler.mediaItem.value?.artUri?.toString();

    // The cache was keyed by nothing, so any transition that did not
    // explicitly clear it handed back the previous song's cover.
    expect(secondArt, isNotNull);
    expect(secondArt, isNot(firstArt),
        reason: 'song b must not inherit song a\'s resolved cover');
    expect(secondArt, contains('cover-b'));
  });

  test('adoptTrackAt updates the queue position before it awaits', () async {
    player.queue.addAll([song('a'), song('b'), song('c')]);
    await player.adoptTrackAt(0);

    // Deliberately not awaited. The UPnP caller pre-queues the *following*
    // track for gapless playback immediately after calling this, and it reads
    // the new position to do so. adoptTrackAt then awaits artwork and
    // ReplayGain, which can take seconds on a cold cache — so if the position
    // were only assigned after those, the renderer would reach the end of the
    // current track before SetNextAVTransportURI arrived, land on a track the
    // app does not recognise, and freeze the queue position.
    final pending = player.adoptTrackAt(1);

    expect(player.currentIndex, 1);
    expect(player.currentSong?.id, 'b');

    await pending;
  });

  test('adoptTrackAt ignores an out-of-range index', () async {
    player.queue.addAll([song('a')]);
    await player.adoptTrackAt(0);

    await player.adoptTrackAt(5);
    expect(player.currentSong?.id, 'a', reason: 'no change on bad index');

    await player.adoptTrackAt(-1);
    expect(player.currentSong?.id, 'a', reason: 'no change on negative index');
  });

  test('retireCurrentTrack is safe with nothing playing', () {
    // The UPnP path calls this before the first adopt, when there may be no
    // outgoing track at all.
    expect(player.retireCurrentTrack, returnsNormally);
  });

  test('retireCurrentTrack leaves the current track in place', () async {
    player.queue.addAll([song('a'), song('b')]);
    await player.adoptTrackAt(0);

    player.retireCurrentTrack();

    // Retiring reports the outgoing play; advancing is adoptTrackAt's job.
    // Conflating them is how the UPnP path ended up doing neither.
    expect(player.currentSong?.id, 'a');
  });
}
