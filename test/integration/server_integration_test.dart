import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import '../test_config.dart';

/// Live-server integration tests for Navidrome.
///
/// If no server is configured these tests are automatically skipped
/// so the suite still passes in CI / local without a server.
void main() {
  final serverUrl = TestConfig.serverUrl;
  final isLive = TestConfig.isConfigured;

  group('Navidrome Server Integration', () {
    setUpAll(() {
      if (!isLive) {
        TestConfig.printInstructions();
      }
    });

    test('server is reachable', () async {
      if (!isLive) {
        markTestSkipped('No Navidrome server configured');
        return;
      }
      final uri = Uri.parse(serverUrl);
      try {
        final response = await http.get(uri).timeout(const Duration(seconds: 10));
        expect(response.statusCode, anyOf(200, 401, 302, 404));
      } on SocketException catch (_) {
        fail('Cannot reach Navidrome at $serverUrl');
      }
    });

    test('subsonic ping endpoint responds', () async {
      if (!isLive) {
        markTestSkipped('No Navidrome server configured');
        return;
      }
      final config = TestConfig.configJson;
      final uri = Uri.parse('$serverUrl/rest/ping.view').replace(
        queryParameters: {
          'u': config['username'] ?? 'admin',
          'p': config['password'] ?? 'admin',
          'v': '1.16.1',
          'c': 'musly-test',
          'f': 'json',
        },
      );
      final response = await http.get(uri).timeout(const Duration(seconds: 10));
      expect(response.statusCode, 200);
      expect(response.body.contains('"status"'), true,
          reason: 'Response should contain Subsonic status field');
    });

    test('getAlbumList2 endpoint returns JSON', () async {
      if (!isLive) {
        markTestSkipped('No Navidrome server configured');
        return;
      }
      final config = TestConfig.configJson;
      final uri = Uri.parse('$serverUrl/rest/getAlbumList2').replace(
        queryParameters: {
          'u': config['username'] ?? 'admin',
          'p': config['password'] ?? 'admin',
          'v': '1.16.1',
          'c': 'musly-test',
          'f': 'json',
          'type': 'random',
          'size': '1',
        },
      );
      final response = await http.get(uri).timeout(const Duration(seconds: 15));
      expect(response.statusCode, 200);
      expect(response.headers['content-type'], contains('json'));
    });
  });
}
