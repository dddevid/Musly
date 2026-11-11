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
    //
    // Every server here is a local one that answers, so each test can let
    // startup finish and dispose its provider before the next test starts.

    // StorageService is a singleton that keeps the SharedPreferences instance
    // it first got, so each test points it at fresh, empty preferences.
    Future<void> freshPreferences() async {
      SharedPreferences.setMockInitialValues({});
      await StorageService().init();
    }

    setUp(freshPreferences);
    tearDown(freshPreferences);

    /// Requests the local servers have received and not yet answered.
    var openRequests = 0;

    /// Serves a Subsonic server on this machine that answers the ping after
    /// [answerAfter].
    Future<String> server({Duration answerAfter = Duration.zero}) async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(() => server.close(force: true));
      server.listen((request) async {
        openRequests++;
        await Future<void>.delayed(answerAfter);
        request.response
          ..headers.contentType = ContentType.json
          ..write('{"subsonic-response":{"status":"ok","version":"1.16.1"}}');
        await request.response.close();
        openRequests--;
      });
      return 'http://127.0.0.1:${server.port}';
    }

    /// Waits until startup has finished with the server, then disposes [auth].
    /// A ping still in flight would save the config into the next test.
    Future<void> finishStartup(AuthProvider auth) async {
      final deadline = DateTime.now().add(const Duration(seconds: 5));
      while (auth.state == AuthState.unknown ||
          auth.state == AuthState.authenticating ||
          openRequests > 0) {
        if (DateTime.now().isAfter(deadline)) fail('startup did not finish');
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
      await Future<void>.delayed(const Duration(milliseconds: 100));
      await pumpEventQueue();
      auth.dispose();
    }

    test('completes when no server is saved', () async {
      final subsonic = SubsonicService();
      final auth = AuthProvider(subsonic, StorageService());

      await auth.savedConfigLoaded.timeout(const Duration(seconds: 5));

      expect(subsonic.config, isNull);
      await finishStartup(auth);
    });

    test('completes once the saved server is configured, before the ping',
        () async {
      final url = await server(answerAfter: const Duration(milliseconds: 500));
      await StorageService().saveServerConfig(ServerConfig(
        serverUrl: url,
        username: 'user',
        password: 'pass',
      ));
      final subsonic = SubsonicService();
      final auth = AuthProvider(subsonic, StorageService());

      await auth.savedConfigLoaded.timeout(const Duration(seconds: 2));

      expect(subsonic.config?.serverUrl, url);
      expect(auth.state, AuthState.authenticating,
          reason: 'waited for the ping to finish before completing');
      await finishStartup(auth);
    });

    test('waits for the LAN check, then uses the LAN address', () async {
      // A restored track must stream from the same address as any other
      // track. At home the server URL may not work from inside the network.
      final lanUrl =
          await server(answerAfter: const Duration(milliseconds: 300));
      final saved = ServerConfig(
        serverUrl: await server(),
        lanUrl: lanUrl,
        username: 'user',
        password: 'pass',
      );
      await StorageService().saveServerConfig(saved);
      final subsonic = SubsonicService();
      final auth = AuthProvider(subsonic, StorageService());

      await auth.savedConfigLoaded.timeout(const Duration(seconds: 5));

      expect(subsonic.activeBaseUrl, saved.normalizedLanUrl,
          reason: 'completed before the LAN check');
      await finishStartup(auth);
    });

    test('a profile switch during the LAN check is kept', () async {
      // Android Auto can switch to its own server preference while the saved
      // server's LAN address is still being checked.
      final lanUrl =
          await server(answerAfter: const Duration(milliseconds: 1000));
      await StorageService().saveServerConfig(ServerConfig(
        serverUrl: await server(),
        lanUrl: lanUrl,
        username: 'user',
        password: 'pass',
      ));
      final subsonic = SubsonicService();
      final auth = AuthProvider(subsonic, StorageService());
      final other = ServerConfig(
        serverUrl: await server(),
        username: 'user',
        password: 'pass',
      );

      await Future<void>.delayed(const Duration(milliseconds: 300));
      final switched = auth.switchProfile(other);
      await auth.savedConfigLoaded.timeout(const Duration(seconds: 5));
      await switched;
      await finishStartup(auth);

      expect(auth.config?.serverUrl, other.serverUrl,
          reason: 'startup put the saved server back over the switch');
      expect(subsonic.config?.serverUrl, other.serverUrl);
    });
  });
}
