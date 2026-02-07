import 'package:flutter_test/flutter_test.dart';
import 'package:musly/models/song.dart';
import 'package:musly/providers/player_provider.dart';
import 'package:musly/services/subsonic_service.dart';
import 'package:musly/services/storage_service.dart';
import '../test_helpers.dart';

void main() {
  group('PlayerProvider', () {
    late SubsonicService subsonicService;
    late PlayerProvider playerProvider;

    setUp(() {
      subsonicService = SubsonicService();
      subsonicService = SubsonicService();
      playerProvider = PlayerProvider(
        subsonicService,
        StorageService(),
        FakeCastService(),
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
  });
}
