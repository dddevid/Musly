import 'package:flutter_test/flutter_test.dart';
import 'package:musly/models/song.dart';

void main() {
  group('Song', () {
    test('should create a Song from JSON', () {
      final json = {
        'id': '123',
        'title': 'Test Song',
        'album': 'Test Album',
        'artist': 'Test Artist',
        'duration': 180,
        'track': 5,
      };

      final song = Song.fromJson(json);

      expect(song.id, '123');
      expect(song.title, 'Test Song');
      expect(song.album, 'Test Album');
      expect(song.artist, 'Test Artist');
      expect(song.duration, 180);
      expect(song.track, 5);
    });

    test('should handle missing fields in JSON', () {
      final json = {'id': '123', 'title': 'Test Song'};

      final song = Song.fromJson(json);

      expect(song.id, '123');
      expect(song.title, 'Test Song');
      expect(song.album, isNull);
      expect(song.artist, isNull);
      expect(song.duration, isNull);
      expect(song.created, isNull);
    });

    test('should parse created field from JSON', () {
      final json = {
        'id': '123',
        'title': 'Test Song',
        'created': '2026-03-18T13:37:27.257653751Z',
      };

      final song = Song.fromJson(json);

      expect(song.created, isNotNull);
      expect(song.created!.year, 2026);
      expect(song.created!.month, 3);
      expect(song.created!.day, 18);
    });

    test('should convert Song to JSON', () {
      final song = Song(
        id: '123',
        title: 'Test Song',
        album: 'Test Album',
        artist: 'Test Artist',
        duration: 180,
        track: 5,
      );

      final json = song.toJson();

      expect(json['id'], '123');
      expect(json['title'], 'Test Song');
      expect(json['album'], 'Test Album');
      expect(json['artist'], 'Test Artist');
      expect(json['duration'], 180);
      expect(json['track'], 5);
    });

    test('should format duration correctly', () {
      final song1 = Song(id: '1', title: 'Song 1', duration: 180);
      expect(song1.formattedDuration, '3:00');

      final song2 = Song(id: '2', title: 'Song 2', duration: 65);
      expect(song2.formattedDuration, '1:05');

      final song3 = Song(id: '3', title: 'Song 3', duration: null);
      expect(song3.formattedDuration, '0:00');
    });
  });
}