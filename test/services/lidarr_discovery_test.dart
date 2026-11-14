import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:musly/services/lidarr_service.dart';
import 'package:musly/services/discovery_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LidarrService tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('singleton instance identity', () {
      final s1 = LidarrService();
      final s2 = LidarrService();
      expect(identical(s1, s2), isTrue);
    });

    test('persists and updates settings properly', () async {
      final service = LidarrService();
      await service.initialize();

      expect(service.isEnabled, isFalse);
      expect(service.enabledNotifier.value, isFalse);
      expect(service.host, equals('http://localhost:8686'));
      expect(service.apiKey, isEmpty);

      await service.setEnabled(true);
      expect(service.isEnabled, isTrue);
      expect(service.enabledNotifier.value, isTrue);

      await service.setHost('http://192.168.1.50:8686/');
      expect(service.host, equals('http://192.168.1.50:8686'));
      expect(service.hostNotifier.value, equals('http://192.168.1.50:8686'));

      await service.setApiKey('test-key-123');
      expect(service.apiKey, equals('test-key-123'));
      expect(service.apiKeyNotifier.value, equals('test-key-123'));

      await service.setQualityProfileId(2);
      expect(service.qualityProfileId, equals(2));

      await service.setRootFolderPath('/data/music');
      expect(service.rootFolderPath, equals('/data/music'));
    });

    test('testConnection returns false for missing host or key', () async {
      final service = LidarrService();
      final res = await service.testConnection(testHost: '', testApiKey: '');
      expect(res['success'], isFalse);
    });
  });

  group('DiscoveryService & Models tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('singleton instance identity and settings', () async {
      final s1 = DiscoveryService();
      final s2 = DiscoveryService();
      expect(identical(s1, s2), isTrue);

      await s1.initialize();
      expect(s1.isEnabled, isTrue);

      await s1.setEnabled(false);
      expect(s1.isEnabled, isFalse);
      expect(s1.enabledNotifier.value, isFalse);
    });

    test('blank queries return empty lists without network calls', () async {
      final service = DiscoveryService();
      expect(await service.searchMusicBrainzReleases('   '), isEmpty);
      expect(await service.searchMusicBrainzArtists('   '), isEmpty);
      expect(await service.getSimilarArtists('   '), isEmpty);
      expect(await service.getArtistReleases(''), isEmpty);
    });

    test('DiscoveryRelease parses MusicBrainz JSON correctly', () {
      final json = {
        'id': 'mbid-123-abc',
        'title': 'Random Access Memories',
        'first-release-date': '2013-05-17',
        'primary-type': 'Album',
        'artist-credit': [
          {'name': 'Daft Punk'}
        ],
      };

      final release = DiscoveryRelease.fromMusicBrainz(json);
      expect(release.id, equals('mbid-123-abc'));
      expect(release.title, equals('Random Access Memories'));
      expect(release.artist, equals('Daft Punk'));
      expect(release.releaseDate, equals('2013-05-17'));
      expect(release.primaryType, equals('Album'));
      expect(
        release.coverUrl,
        equals('https://coverartarchive.org/release-group/mbid-123-abc/front-250.jpg'),
      );
    });

    test('DiscoveryArtist parses MusicBrainz JSON correctly', () {
      final json = {
        'id': 'artist-mbid-456',
        'name': 'Daft Punk',
        'country': 'FR',
        'tags': [
          {'name': 'electronic'},
          {'name': 'french touch'}
        ],
      };

      final artist = DiscoveryArtist.fromMusicBrainz(json);
      expect(artist.id, equals('artist-mbid-456'));
      expect(artist.name, equals('Daft Punk'));
      expect(artist.country, equals('FR'));
      expect(artist.tags, containsAll(['electronic', 'french touch']));
    });
  });
}
