import 'package:flutter_test/flutter_test.dart';
import 'package:musly/models/server_config.dart';

void main() {
  group('ServerConfig', () {
    test('should create a valid ServerConfig', () {
      final config = ServerConfig(
        serverUrl: 'https://example.com',
        username: 'testuser',
        password: 'testpass',
      );

      expect(config.serverUrl, 'https://example.com');
      expect(config.username, 'testuser');
      expect(config.password, 'testpass');
      expect(config.useLegacyAuth, false);
    });

    test('should validate config', () {
      final validConfig = ServerConfig(
        serverUrl: 'https://example.com',
        username: 'testuser',
        password: 'testpass',
      );

      expect(validConfig.isValid, true);

      final invalidConfig1 = ServerConfig(
        serverUrl: '',
        username: 'testuser',
        password: 'testpass',
      );

      expect(invalidConfig1.isValid, false);

      final invalidConfig2 = ServerConfig(
        serverUrl: 'https://example.com',
        username: '',
        password: 'testpass',
      );

      expect(invalidConfig2.isValid, false);
    });

    test('should normalize URL correctly', () {
      final config1 = ServerConfig(
        serverUrl: 'example.com',
        username: 'user',
        password: 'pass',
      );
      expect(config1.normalizedUrl, 'https://example.com');

      final config2 = ServerConfig(
        serverUrl: 'http://example.com/',
        username: 'user',
        password: 'pass',
      );
      expect(config2.normalizedUrl, 'http://example.com');

      final config3 = ServerConfig(
        serverUrl: 'https://example.com',
        username: 'user',
        password: 'pass',
      );
      expect(config3.normalizedUrl, 'https://example.com');
    });

    test('should convert to and from JSON', () {
      final config = ServerConfig(
        serverUrl: 'https://example.com',
        username: 'testuser',
        password: 'testpass',
        useLegacyAuth: true,
      );

      final json = config.toJson();
      final restored = ServerConfig.fromJson(json);

      expect(restored.serverUrl, config.serverUrl);
      expect(restored.username, config.username);
      expect(restored.password, config.password);
      expect(restored.useLegacyAuth, config.useLegacyAuth);
    });
  });
}