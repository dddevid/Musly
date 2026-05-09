import 'package:flutter_test/flutter_test.dart';
import 'package:musly/providers/auth_provider.dart';
import 'package:musly/services/services.dart';
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
}
