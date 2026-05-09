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
      authProvider.dispose();
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

    test('config getter should reflect internal state', () {
      expect(authProvider.config, isNull);
      authProvider.enterOfflineMode();
      expect(authProvider.config, isNotNull);
    });

    test('logout should reset to unauthenticated', () {
      authProvider.enterOfflineMode();
      expect(authProvider.state, AuthState.offlineMode);

      authProvider.logout();
      expect(authProvider.state, AuthState.unauthenticated);
      expect(authProvider.isAuthenticated, false);
    });

    test('should handle rapid state transitions without error', () {
      authProvider.enterOfflineMode();
      authProvider.logout();
      authProvider.enterOfflineMode();
      authProvider.logout();
      expect(authProvider.state, AuthState.unauthenticated);
    });

    test('notifyListeners should not throw after dispose', () {
      authProvider.dispose();
      expect(() => authProvider.state, returnsNormally);
    });
  });
}
