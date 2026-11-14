import 'package:flutter_test/flutter_test.dart';
import 'package:musly/models/song.dart';
import 'package:musly/providers/player_provider.dart';
import 'package:musly/services/subsonic_service.dart';
import 'package:musly/services/storage_service.dart';
import 'package:musly/services/cast_service.dart';
import 'package:musly/services/upnp_service.dart';
import 'package:musly/services/audio_handler.dart';
import 'package:musly/services/jukebox_service.dart';
import 'package:musly/services/transcoding_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../test_helpers.dart';
import '../bootstrap.dart';

void main() {
  initializeTestEnvironment();
  group('PlayerProvider', () {
    late SubsonicService subsonicService;
    late PlayerProvider playerProvider;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      subsonicService = SubsonicService();
      playerProvider = PlayerProvider(
        subsonicService,
        StorageService(),
        FakeCastService(),
        UpnpService(),
        MuslyAudioHandler(),
        JukeboxService(),
        TranscodingService(),
      );
    });

    tearDown(() {
      playerProvider.dispose();
    });

    test('should initialize with empty queue', () {
      expect(playerProvider.queue, isEmpty);
      expect(playerProvider.currentIndex, -1);
      expect(playerProvider.isPlaying, false);
      expect(playerProvider.currentSong, isNull);
    });

    test('should toggle shuffle mode', () {
      expect(playerProvider.shuffleEnabled, false);

      playerProvider.toggleShuffle();
      expect(playerProvider.shuffleEnabled, true);

      playerProvider.toggleShuffle();
      expect(playerProvider.shuffleEnabled, false);
    });

    test('should cycle through repeat modes', () {
      expect(playerProvider.repeatMode, RepeatMode.off);

      playerProvider.toggleRepeat();
      expect(playerProvider.repeatMode, RepeatMode.all);

      playerProvider.toggleRepeat();
      expect(playerProvider.repeatMode, RepeatMode.one);

      playerProvider.toggleRepeat();
      expect(playerProvider.repeatMode, RepeatMode.off);
    });

    test('should add songs to queue', () {
      final song1 = Song(id: '1', title: 'Song 1');
      final song2 = Song(id: '2', title: 'Song 2');

      playerProvider.addToQueue(song1);
      expect(playerProvider.queue.length, 1);

      playerProvider.addToQueue(song2);
      expect(playerProvider.queue.length, 2);
      expect(playerProvider.queue[1].id, '2');
    });

    test('should clear queue', () {
      final song1 = Song(id: '1', title: 'Song 1');
      final song2 = Song(id: '2', title: 'Song 2');

      playerProvider.addToQueue(song1);
      playerProvider.addToQueue(song2);
      expect(playerProvider.queue.length, 2);

      playerProvider.clearQueue();
      expect(playerProvider.queue, isEmpty);
      expect(playerProvider.currentIndex, -1);
    });

    test('should check if has next/previous', () {
      final songs = [
        Song(id: '1', title: 'Song 1'),
        Song(id: '2', title: 'Song 2'),
        Song(id: '3', title: 'Song 3'),
      ];

      expect(playerProvider.hasNext, false);
      expect(playerProvider.hasPrevious, false);

      for (var song in songs) {
        playerProvider.addToQueue(song);
      }
    });

    test('should handle Cast connection and disconnection transitions cleanly', () async {
      final fakeCast = FakeCastService();
      final player = PlayerProvider(
        subsonicService,
        StorageService(),
        fakeCast,
        UpnpService(),
        MuslyAudioHandler(),
        JukeboxService(),
        TranscodingService(),
      );

      final song = Song(id: 'cast_1', title: 'Cast Track', artist: 'Artist');
      player.addToQueue(song);

      expect(player.isRemotePlayback, false);

      // Connect to Cast
      fakeCast.setMockConnected(true);
      await Future.delayed(const Duration(milliseconds: 10));

      expect(player.isRemotePlayback, true);

      // Multiple ticks while connected must NOT reset remote playback or loop
      fakeCast.setMockMediaState(CastMediaState(
        isPlaying: true,
        position: const Duration(seconds: 15),
        duration: const Duration(seconds: 180),
      ));
      await Future.delayed(const Duration(milliseconds: 10));

      expect(player.isRemotePlayback, true);
      expect(player.isPlaying, true);

      // Disconnect
      fakeCast.setMockConnected(false);
      await Future.delayed(const Duration(milliseconds: 10));

      expect(player.isRemotePlayback, false);
      expect(player.isPlaying, false);

      player.dispose();
    });

    test('should update playback speed and adapt pitch when pitch correction is toggled (#272)', () async {
      expect(playerProvider.playbackSpeed, 1.0);
      expect(playerProvider.pitch, 1.0);
      expect(playerProvider.pitchCorrection, true);

      // Changing speed with pitch correction on preserves pitch at 1.0
      await playerProvider.setPlaybackSpeed(1.5);
      expect(playerProvider.playbackSpeed, 1.5);
      expect(playerProvider.pitch, 1.0);

      // Toggling pitch correction off matches pitch with playback speed
      await playerProvider.togglePitchCorrection();
      expect(playerProvider.pitchCorrection, false);
      expect(playerProvider.pitch, 1.5);

      // Changing speed with pitch correction off updates pitch accordingly
      await playerProvider.setPlaybackSpeed(0.8);
      expect(playerProvider.playbackSpeed, 0.8);
      expect(playerProvider.pitch, 0.8);

      // Toggling pitch correction back on resets pitch to 1.0
      await playerProvider.togglePitchCorrection();
      expect(playerProvider.pitchCorrection, true);
      expect(playerProvider.pitch, 1.0);
    });
  });
}
