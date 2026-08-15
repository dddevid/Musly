import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:musly/models/server_config.dart';
import 'package:musly/services/subsonic_service.dart';

void main() {
  group('SubsonicService', () {
    late SubsonicService service;

    setUp(() {
      TestWidgetsFlutterBinding.ensureInitialized();
      SharedPreferences.setMockInitialValues({});
      service = SubsonicService();
    });

    test('should initialize without configuration', () {
      expect(service.isConfigured, false);
      expect(service.config, isNull);
    });

    test('should configure with ServerConfig', () async {
      final config = ServerConfig(
        serverUrl: 'https://demo.navidrome.org',
        username: 'demo',
        password: 'demo',
      );

      await service.configure(config);

      expect(service.isConfigured, true);
      expect(service.config, isNotNull);
      expect(service.config?.serverUrl, config.serverUrl);
    });

    test('should build cover art URL', () async {
      final config = ServerConfig(
        serverUrl: 'https://demo.navidrome.org',
        username: 'demo',
        password: 'demo',
      );

      await service.configure(config);

      final url = service.getCoverArtUrl('art123', size: 300);

      expect(url, contains('https://demo.navidrome.org/rest/getCoverArt'));
      expect(url, contains('id=art123'));
      expect(url, contains('size=300'));
    });

    test('should return empty URL when coverArt is null', () async {
      final config = ServerConfig(
        serverUrl: 'https://demo.navidrome.org',
        username: 'demo',
        password: 'demo',
      );

      await service.configure(config);

      final url = service.getCoverArtUrl(null);
      expect(url, '');
    });

    test('should build stream URL', () async {
      final config = ServerConfig(
        serverUrl: 'https://demo.navidrome.org',
        username: 'demo',
        password: 'demo',
      );

      await service.configure(config);

      final url = service.getStreamUrl('song123');

      expect(url, contains('https://demo.navidrome.org/rest/stream'));
      expect(url, contains('id=song123'));
    });

    test('should include maxBitRate in stream URL when specified', () async {
      final config = ServerConfig(
        serverUrl: 'https://demo.navidrome.org',
        username: 'demo',
        password: 'demo',
      );

      await service.configure(config);

      final url = service.getStreamUrl('song123', maxBitRate: 320);

      expect(url, contains('maxBitRate=320'));
    });

    test('should throw when not configured', () {
      expect(() => service.getCoverArtUrl('art123'), returnsNormally);
      expect(() => service.getStreamUrl('song123'), throwsException);
    });
  });
}