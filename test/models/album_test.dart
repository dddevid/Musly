import 'package:flutter_test/flutter_test.dart';
import 'package:musly/models/album.dart';

void main() {
  group('Album', () {
    test('should create an Album from JSON', () {
      final json = {
        'id': '456',
        'name': 'Test Album',
        'artist': 'Test Artist',
        'songCount': 12,
        'duration': 3600,
        'year': 2023,
      };

      final album = Album.fromJson(json);

      expect(album.id, '456');
      expect(album.name, 'Test Album');
      expect(album.artist, 'Test Artist');
      expect(album.songCount, 12);
      expect(album.duration, 3600);
      expect(album.year, 2023);
    });

    test('should handle missing fields in JSON', () {
      final json = {'id': '456', 'name': 'Test Album'};

      final album = Album.fromJson(json);

      expect(album.id, '456');
      expect(album.name, 'Test Album');
      expect(album.artist, isNull);
      expect(album.songCount, isNull);
    });

    test('should format duration correctly', () {
      final album1 = Album(id: '1', name: 'Album 1', duration: 180);
      expect(album1.formattedDuration, '3:00');

      final album2 = Album(id: '2', name: 'Album 2', duration: 3600);
      expect(album2.formattedDuration, '60:00');

      final album3 = Album(id: '3', name: 'Album 3', duration: null);
      expect(album3.formattedDuration, '');
    });
  });
}