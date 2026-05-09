/// Test configuration loader for Navidrome integration tests.
///
/// Reads the server URL from (in order of priority):
///   1. `NAVIDROME_TEST_URL` environment variable
///   2. `test_server_config.json` in the project root
///   3. Default fallback `http://localhost:4533`
///
/// Usage:
///   flutter test --dart-define=NAVIDROME_TEST_URL=http://192.168.1.100:4533
///
/// Or create `test_server_config.json`:
///   {"url": "http://192.168.1.100:4533", "username": "admin", "password": "admin"}

import 'dart:convert';
import 'dart:io';

class TestConfig {
  static String? _cachedUrl;
  static Map<String, dynamic>? _cachedJson;

  static String get serverUrl {
    if (_cachedUrl != null) return _cachedUrl!;

    // 1. Environment variable (supports dart-define and shell env)
    const envUrl = String.fromEnvironment('NAVIDROME_TEST_URL');
    if (envUrl.isNotEmpty) {
      _cachedUrl = envUrl;
      return _cachedUrl!;
    }

    // 2. Config file in project root
    final configFile = File('test_server_config.json');
    if (configFile.existsSync()) {
      try {
        final json = jsonDecode(configFile.readAsStringSync())
            as Map<String, dynamic>;
        _cachedJson = json;
        final url = json['url'] as String?;
        if (url != null && url.isNotEmpty) {
          _cachedUrl = url;
          return _cachedUrl!;
        }
      } catch (e) {
        stderr.writeln('[TestConfig] Error reading test_server_config.json: $e');
      }
    }

    // 3. Default fallback
    _cachedUrl = 'http://localhost:4533';
    return _cachedUrl!;
  }

  static Map<String, dynamic> get configJson {
    if (_cachedJson != null) return _cachedJson!;

    const envUrl = String.fromEnvironment('NAVIDROME_TEST_URL');
    if (envUrl.isNotEmpty) {
      _cachedJson = {'url': envUrl, 'username': '', 'password': ''};
      return _cachedJson!;
    }

    final configFile = File('test_server_config.json');
    if (configFile.existsSync()) {
      try {
        _cachedJson =
            jsonDecode(configFile.readAsStringSync()) as Map<String, dynamic>;
        return _cachedJson!;
      } catch (e) {
        stderr.writeln('[TestConfig] Error reading config: $e');
      }
    }

    _cachedJson = {'url': 'http://localhost:4533', 'username': '', 'password': ''};
    return _cachedJson!;
  }

  static bool get isConfigured {
    const envUrl = String.fromEnvironment('NAVIDROME_TEST_URL');
    if (envUrl.isNotEmpty) return true;
    return File('test_server_config.json').existsSync();
  }

  static void printInstructions() {
    stdout.writeln('╔══════════════════════════════════════════════════════════════╗');
    stdout.writeln('║  Navidrome Test Server Not Configured                       ║');
    stdout.writeln('╠══════════════════════════════════════════════════════════════╣');
    stdout.writeln('║  To run integration tests against a real Navidrome server:   ║');
    stdout.writeln('║                                                              ║');
    stdout.writeln('║  1. Create test_server_config.json in the project root:      ║');
    stdout.writeln('║     {                                                        ║');
    stdout.writeln('║       "url": "http://YOUR_NAVIDROME_IP:4533",                ║');
    stdout.writeln('║       "username": "your_user",                               ║');
    stdout.writeln('║       "password": "your_pass"                                ║');
    stdout.writeln('║     }                                                        ║');
    stdout.writeln('║                                                              ║');
    stdout.writeln('║  2. Or pass via dart-define:                                 ║');
    stdout.writeln('║     flutter test --dart-define=NAVIDROME_TEST_URL=...        ║');
    stdout.writeln('║                                                              ║');
    stdout.writeln('║  Tests that require a real server will be SKIPPED.            ║');
    stdout.writeln('╚══════════════════════════════════════════════════════════════╝');
  }
}
