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

    setUp(() {
      subsonicService = SubsonicService();
      storageService = StorageService();
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
  });

  group('AuthProvider.savedConfigLoaded', () {
    // PlayerProvider holds back a media command that starts the app until this
    // completes, so it must complete in every startup path and must not wait
    // for the server to answer a ping, which can take up to 30 s offline.

    test('completes when no server is saved', () async {
      SharedPreferences.setMockInitialValues({});
      final subsonic = SubsonicService();
      final auth = AuthProvider(subsonic, StorageService());

      await auth.savedConfigLoaded.timeout(const Duration(seconds: 5));

      expect(subsonic.config, isNull);
      auth.dispose();
    });

    test('completes once the saved server is configured, before the ping',
        () async {
      SharedPreferences.setMockInitialValues({});
      await StorageService().saveServerConfig(ServerConfig(
        serverUrl: 'http://music.test',
        username: 'user',
        password: 'pass',
      ));
      final subsonic = SubsonicService();
      final auth = AuthProvider(subsonic, StorageService());

      await auth.savedConfigLoaded.timeout(const Duration(seconds: 2));

      expect(subsonic.config?.serverUrl, 'http://music.test');
      expect(auth.state, AuthState.authenticating,
          reason: 'waited for the ping to finish before completing');
      auth.dispose();
    });

    test('does not wait for an unreachable LAN address', () async {
      // Away from home (in the car) the saved LAN address does not answer,
      // and SubsonicService.configure() probes it for up to 3 s.
      SharedPreferences.setMockInitialValues({});
      await StorageService().saveServerConfig(ServerConfig(
        serverUrl: 'http://music.test',
        lanUrl: 'http://10.255.255.1:4533',
        username: 'user',
        password: 'pass',
      ));
      final subsonic = SubsonicService();
      final auth = AuthProvider(subsonic, StorageService());

      final watch = Stopwatch()..start();
      await auth.savedConfigLoaded.timeout(const Duration(seconds: 5));

      expect(watch.elapsedMilliseconds, lessThan(1000),
          reason: 'waited for the LAN probe');
      expect(subsonic.config?.serverUrl, 'http://music.test');
      auth.dispose();
    });
  });
}
