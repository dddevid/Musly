import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:musly/models/server_config.dart';
import 'package:musly/providers/auth_provider.dart';
import 'package:musly/services/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../bootstrap.dart';

void main() {
  initializeTestEnvironment();

  group('AuthProvider', () {
    late SubsonicService subsonicService;
    late StorageService storageService;
    late AuthProvider authProvider;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      storageService = StorageService();
      await storageService.clearAll();
      subsonicService = SubsonicService();
      authProvider = AuthProvider(subsonicService, storageService);
    });

    tearDown(() {
      try {
        authProvider.dispose();
      } catch (_) {}
    });

    test('initial state should be unknown', () {
      expect(authProvider.state, AuthState.unknown);
      expect(authProvider.isAuthenticated, false);
      expect(authProvider.config, isNull);
    });

    test('enterOfflineMode should switch to offlineMode state', () {
      authProvider.enterOfflineMode();
      expect(authProvider.state, AuthState.offlineMode);
      expect(authProvider.state == AuthState.offlineMode, true);
    });

    test('config getter should be null when not configured', () {
      expect(authProvider.config, isNull);
      authProvider.enterOfflineMode();
      expect(authProvider.config, isNull);
    });

    test('logout should reset to unauthenticated', () async {
      authProvider.enterOfflineMode();
      expect(authProvider.state, AuthState.offlineMode);

      await authProvider.logout();
      expect(authProvider.state, AuthState.unauthenticated);
      expect(authProvider.isAuthenticated, false);
    }, skip: 'Requires path_provider native plugin');

    test('should handle rapid state transitions without error', () async {
      authProvider.enterOfflineMode();
      await authProvider.logout();
      authProvider.enterOfflineMode();
      await authProvider.logout();
      expect(authProvider.state, AuthState.unauthenticated);
    }, skip: 'Requires path_provider native plugin');

    test('notifyListeners should not throw after dispose', () {
      authProvider.dispose();
      expect(() => authProvider.state, returnsNormally);
    });

    test(
        'activeBaseUrl remains other profile address after saved-profile check completes',
        () async {
      final mockServer =
          await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      mockServer.listen((HttpRequest request) async {
        if (request.uri.path.contains('ping')) {
          if (request.uri.queryParameters['u'] == 'userA') {
            await Future.delayed(const Duration(milliseconds: 50));
          }
          request.response.statusCode = 200;
          request.response.headers.contentType = ContentType.json;
          request.response.write('{"subsonic-response":{"status":"ok"}}');
          await request.response.close();
        }
      });

      try {
        final profileA = ServerConfig(
          serverUrl: 'https://server-a.example.com',
          lanUrl: 'http://127.0.0.1:${mockServer.port}',
          username: 'userA',
          password: 'passwordA',
        );
        final profileB = ServerConfig(
          serverUrl: 'http://127.0.0.1:${mockServer.port}/profileB',
          username: 'userB',
          password: 'passwordB',
        );

        final lanCheckFuture = subsonicService.configure(profileA);
        await authProvider.switchProfile(profileB);
        await lanCheckFuture;

        expect(subsonicService.activeBaseUrl, profileB.normalizedUrl);
      } finally {
        await mockServer.close(force: true);
      }
    });

    test(
        'activeBaseUrl updates to LAN address when configuration has not changed',
        () async {
      final mockLanServer =
          await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      mockLanServer.listen((HttpRequest request) async {
        request.response.statusCode = 200;
        request.response.headers.contentType = ContentType.json;
        request.response.write('{"subsonic-response":{"status":"ok"}}');
        await request.response.close();
      });

      try {
        final profile = ServerConfig(
          serverUrl: 'https://server-a.example.com',
          lanUrl: 'http://127.0.0.1:${mockLanServer.port}',
          username: 'userA',
          password: 'passwordA',
        );

        await subsonicService.configure(profile);
        expect(subsonicService.activeBaseUrl, 'http://127.0.0.1:${mockLanServer.port}');
      } finally {
        await mockLanServer.close(force: true);
      }
    });
  });
}
