import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_platform_interface/just_audio_platform_interface.dart';
import 'package:musly/models/radio_station.dart';
import 'package:musly/models/server_config.dart';
import 'package:musly/models/song.dart';
import 'package:musly/providers/player_provider.dart';
import 'package:musly/services/audio_handler.dart';
import 'package:musly/services/jukebox_service.dart';
import 'package:musly/services/offline_service.dart';
import 'package:musly/services/storage_service.dart';
import 'package:musly/services/subsonic_service.dart';
import 'package:musly/services/transcoding_service.dart';
import 'package:musly/services/upnp_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../bootstrap.dart';
import '../fake_just_audio_platform.dart';
import '../test_helpers.dart';

/// A media button can be what starts the app. A car head unit or a watch
/// pressing play while Musly isn't running makes Android start the process
/// just to deliver that press, and audio_service hands it to the handler as
/// soon as PlayerProvider has wired its callbacks. On a Pixel that was 49 ms
/// before the saved queue finished restoring, so play() found no current song,
/// skipped loading one, and played an empty player. just_audio then reported
/// playing, so the next press toggled to pause: the head unit looked dead
/// until the app was opened by hand.
void main() {
  initializeTestEnvironment();

  late Directory tmp;
  late FakeJustAudioPlatform platform;
  late MuslyAudioHandler handler;
  late PlayerProvider player;
  late SubsonicService subsonic;

  Song localSong(String id) => Song(
        id: id,
        title: 'Title $id',
        artist: 'Artist $id',
        album: 'Album $id',
        path: '${tmp.path}/$id.mp3',
        isLocal: true,
        duration: 120,
      );

  Song streamedSong(String id) => Song(
        id: id,
        title: 'Title $id',
        artist: 'Artist $id',
        album: 'Album $id',
        duration: 120,
      );

  /// Saves a two-song queue positioned on the second song, as a previous
  /// session would have left it.
  void seedSavedQueue(
      {bool local = true, Map<String, Object> extra = const {}}) {
    final songs = local
        ? [localSong('a'), localSong('b')]
        : [streamedSong('a'), streamedSong('b')];
    for (final s in songs.where((s) => s.isLocal)) {
      File(s.path!).writeAsBytesSync([0]);
    }
    SharedPreferences.setMockInitialValues({
      'persistent_queue': jsonEncode(songs.map((s) => s.toJson()).toList()),
      'persistent_queue_index': 1,
      'persistent_queue_song_id': 'b',
      'persistent_queue_position_ms': 0,
    });
  }

  /// Builds the provider the way main() does on a cold start.
  void coldStart() {
    handler = MuslyAudioHandler();
    subsonic = SubsonicService();
    player = PlayerProvider(
      subsonic,
      StorageService(),
      FakeCastService(),
      UpnpService(),
      handler,
      JukeboxService(),
      TranscodingService(),
    );
  }

  /// Lets the restore, the press and the load run to completion. A press is
  /// not awaited: just_audio completes play() only once playback stops.
  Future<void> settle() async {
    for (var i = 0; i < 20; i++) {
      await pumpEventQueue();
    }
  }

  /// True when the player is playing a loaded track, not an empty player.
  bool playingALoadedTrack() =>
      handler.player.playing &&
      handler.player.audioSource != null &&
      handler.player.processingState != ProcessingState.idle;

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('musly_cold_start');
    platform = FakeJustAudioPlatform();
    JustAudioPlatform.instance = platform;
    seedSavedQueue();
  });

  tearDown(() async {
    // PlayerProvider.dispose() stops the player and disposes it without
    // waiting, and just_audio 0.9.46 then completes its platform future with
    // itself. Stop it here first so dispose() has nothing left to tear down.
    await handler.player.stop();
    await settle();
    player.dispose();
    tmp.deleteSync(recursive: true);
  });

  test('a play/pause button that starts the app plays the restored track',
      () async {
    coldStart();

    // Delivered before the queue restore completes, as on the device.
    unawaited(handler.click(MediaButton.media));
    await settle();

    expect(player.currentSong?.id, 'b');
    expect(playingALoadedTrack(), isTrue,
        reason: 'played an empty player instead of the restored track');
    expect(platform.players.single.loads, isNotEmpty);
  });

  test('a play command that starts the app plays the restored track', () async {
    coldStart();

    // The lock-screen card, Gadgetbridge and Android Auto send play directly.
    unawaited(handler.play());
    await settle();

    expect(playingALoadedTrack(), isTrue,
        reason: 'played an empty player instead of the restored track');
  });

  test('a press that starts the app waits for the saved server', () async {
    // A streamed track needs the server config, which AuthProvider loads
    // from storage at the same time as the queue; on the device it landed
    // after the restore and the load failed with "Server not configured".
    seedSavedQueue(local: false);
    final serverConfigLoaded = Completer<void>();
    coldStart();
    player.setServerConfigLoaded(serverConfigLoaded.future);

    unawaited(handler.click(MediaButton.media));
    await settle();
    expect(handler.player.playing, isFalse,
        reason: 'acted before the server config was loaded');

    await subsonic.configure(ServerConfig(
      serverUrl: 'http://music.test',
      username: 'user',
      password: 'pass',
    ));
    serverConfigLoaded.complete();
    await settle();

    expect(playingALoadedTrack(), isTrue,
        reason: 'did not play the restored track once the server was known');
  });

  /// Every URI the app handed the player, flattening gapless playlists.
  List<String> loadedUris() {
    final uris = <String>[];
    void walk(AudioSourceMessage m) {
      if (m is UriAudioSourceMessage) uris.add(m.uri);
      if (m is ConcatenatingAudioSourceMessage) m.children.forEach(walk);
    }

    platform.players.expand((p) => p.loads).forEach(walk);
    return uris;
  }

  // Commands held at startup are released together, so a later one runs
  // while an earlier play() is still loading the track. The last one wins.

  test('play then pause at startup leaves the player paused', () async {
    coldStart();

    unawaited(handler.play());
    unawaited(handler.pause());
    await settle();

    expect(handler.player.playing, isFalse,
        reason: 'the track loaded and played after the pause');
  });

  test('two play/pause presses at startup leave the player paused', () async {
    coldStart();

    unawaited(handler.click(MediaButton.media));
    unawaited(handler.click(MediaButton.media));
    await settle();

    expect(handler.player.playing, isFalse,
        reason: 'the first press loaded and played after the second');
  });

  // A press that cannot play anything must leave the player paused. If the
  // player is left "playing" with nothing loaded, the session shows a pause
  // button that does nothing, and every play/pause press from a car or watch
  // (audio_service turns both keys into a toggle) has nothing to toggle.

  test('a press with no saved queue leaves the player paused', () async {
    SharedPreferences.setMockInitialValues({});
    coldStart();

    for (var press = 1; press <= 2; press++) {
      unawaited(handler.click(MediaButton.media));
      await settle();
      expect(handler.player.playing, isFalse,
          reason: 'press $press left an empty player "playing"');
    }
  });

  test('a press whose track fails to load leaves the player paused', () async {
    platform.failLoads = true;
    coldStart();

    for (var press = 1; press <= 2; press++) {
      unawaited(handler.click(MediaButton.media));
      await settle();
      expect(handler.player.playing, isFalse,
          reason: 'press $press left the player "playing" after a failed load');
    }
  });

  test('play after stop resumes a radio station', () async {
    // A radio station has no current song, so play() loads nothing itself;
    // just_audio reloads the stream when play() is called on the stopped
    // player. The guard against playing an empty player must not block that.
    SharedPreferences.setMockInitialValues({});
    coldStart();
    await settle();
    unawaited(player.playRadioStation(RadioStation(
      id: 'r1',
      name: 'Radio',
      streamUrl: 'http://radio.test/stream',
    )));
    await settle();
    expect(playingALoadedTrack(), isTrue, reason: 'radio did not start');

    await player.stop();
    await settle();
    unawaited(handler.click(MediaButton.media));
    await settle();

    expect(playingALoadedTrack(), isTrue,
        reason: 'play after stop did not resume the radio station');
  });

  test('a press that starts the app plays a downloaded track from disk',
      () async {
    // OfflineService fills its list of downloaded songs at startup too, by
    // scanning its folder; until it has, a downloaded track is streamed
    // instead, which fails offline. bootstrap.dart mocks path_provider to
    // ".", so the folder is ./offline_music; files under 64 KiB are ignored.
    final downloaded = File('./offline_music/b.mp3')
      ..createSync(recursive: true)
      ..writeAsBytesSync(List.filled(65536, 0));
    addTearDown(() => downloaded.parent.deleteSync(recursive: true));
    // OfflineService is a singleton; start from what a new process knows.
    OfflineService().downloadedSongIds.value = {};
    seedSavedQueue(local: false);
    coldStart();
    await subsonic.configure(ServerConfig(
      serverUrl: 'http://music.test',
      username: 'user',
      password: 'pass',
    ));

    unawaited(handler.click(MediaButton.media));
    await settle();

    expect(loadedUris(), isNotEmpty);
    expect(loadedUris().last, endsWith('offline_music/b.mp3'),
        reason: 'streamed a track that is downloaded');
  });
}
