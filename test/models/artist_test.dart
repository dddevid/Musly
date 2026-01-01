import 'package:flutter_test/flutter_test.dart';
import 'package:musly/models/artist.dart';

void main() {
  group('Artist', () {
    test('should create an Artist from JSON', () {
      final json = {
        'id': '789',
        'name': 'Test Artist',
        'albumCount': 10,
        'coverArt': 'art123',
      };

      final artist = Artist.fromJson(json);

      expect(artist.id, '789');
      expect(artist.name, 'Test Artist');
      expect(artist.albumCount, 10);
      expect(artist.coverArt, 'art123');
    });

    test('should handle missing fields in JSON', () {
      final json = {'id': '789', 'name': 'Test Artist'};

      final artist = Artist.fromJson(json);

      expect(artist.id, '789');
      expect(artist.name, 'Test Artist');
      expect(artist.albumCount, isNull);
      expect(artist.coverArt, isNull);
    });

    test('should convert Artist to JSON', () {
      final artist = Artist(
        id: '789',
        name: 'Test Artist',
        albumCount: 10,
        coverArt: 'art123',
      );

      final json = artist.toJson();

      expect(json['id'], '789');
      expect(json['name'], 'Test Artist');
      expect(json['albumCount'], 10);
      expect(json['coverArt'], 'art123');
    });
  });
}