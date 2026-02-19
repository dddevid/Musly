import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import '../models/server_config.dart';
import '../services/services.dart';
import '../services/offline_service.dart';

enum AuthState {
  unknown,
  unauthenticated,
  authenticating,
  authenticated,
  offlineMode, // Server unreachable but has downloaded content
  error,
}

class AuthProvider extends ChangeNotifier {
  final SubsonicService _subsonicService;
  final StorageService _storageService;

  AuthState _state = AuthState.unknown;
  String? _error;
  ServerConfig? _config;

  AuthProvider(this._subsonicService, this._storageService) {
    _loadSavedConfig();
  }

  AuthState get state => _state;
  String? get error => _error;
  ServerConfig? get config => _config;
  bool get isAuthenticated => _state == AuthState.authenticated;

  Future<void> _loadSavedConfig() async {
    final config = await _storageService.getServerConfig();
    if (config != null && config.isValid) {
      _config = config;

      // Local-only mode: skip server ping entirely
      if (config.serverType == 'local') {
        _state = AuthState.offlineMode;
        notifyListeners();
        return;
      }

      _subsonicService.configure(config);
      await _verifyConnection();
    } else {
      _state = AuthState.unauthenticated;
      notifyListeners();
    }
  }

  Future<void> _verifyConnection() async {
    _state = AuthState.authenticating;
    notifyListeners();

    final pingResult = await _subsonicService.pingWithError();
    if (pingResult.success) {
      if (_config != null) {
        final updatedConfig = _config!.copyWith(
          serverType: pingResult.serverType,
          serverVersion: pingResult.serverVersion,
        );
        if (updatedConfig.serverType != _config!.serverType ||
            updatedConfig.serverVersion != _config!.serverVersion) {
          _config = updatedConfig;
          await _storageService.saveServerConfig(updatedConfig);
        }
      }
      _state = AuthState.authenticated;
    } else {
      // Check if we have offline content
      final offlineService = OfflineService();
      await offlineService.initialize();
      final downloadedCount = offlineService.getDownloadedCount();

      if (downloadedCount > 0) {
        // Allow offline mode if we have downloaded content
        _state = AuthState.offlineMode;
        _error = 'Server unreachable. Playing offline content only.';
      } else {
        _state = AuthState.unauthenticated;
      }
    }
    notifyListeners();
  }

  Future<bool> login({
    required String serverUrl,
    required String username,
    required String password,
    bool useLegacyAuth = false,
    bool allowSelfSignedCertificates = false,
    String? customCertificatePath,
    String? clientCertificatePath,
    String? clientCertificatePassword,
  }) async {
    _state = AuthState.authenticating;
    _error = null;
    notifyListeners();

    final config = ServerConfig(
      serverUrl: serverUrl,
      username: username,
      password: password,
      useLegacyAuth: useLegacyAuth,
      allowSelfSignedCertificates: allowSelfSignedCertificates,
      customCertificatePath: customCertificatePath,
      clientCertificatePath: clientCertificatePath,
      clientCertificatePassword: clientCertificatePassword,
    );

    _subsonicService.configure(config);

    try {
      final pingResult = await _subsonicService.pingWithError();
      if (pingResult.success) {
        final updatedConfig = config.copyWith(
          serverType: pingResult.serverType,
          serverVersion: pingResult.serverVersion,
        );
        _config = updatedConfig;
        await _storageService.saveServerConfig(updatedConfig);
        _state = AuthState.authenticated;
        notifyListeners();
        return true;
      } else {
        _error = pingResult.error ?? 'Failed to connect to server';
        _state = AuthState.error;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = _formatError(e);
      _state = AuthState.error;
      notifyListeners();
      return false;
    }
  }

  String _formatError(dynamic error) {
    final errorStr = error.toString();
    if (errorStr.contains('SocketException') ||
        errorStr.contains('Connection refused')) {
      return 'Cannot connect to server. Check the URL and your internet connection.';
    } else if (errorStr.contains('HandshakeException') ||
        errorStr.contains('CERTIFICATE_VERIFY_FAILED')) {
      return 'SSL certificate error. Enable "Allow Self-Signed Certificates" for custom CA servers.';
    } else if (errorStr.contains('TimeoutException')) {
      return 'Connection timed out. Check your server URL.';
    } else if (errorStr.contains('FormatException')) {
      return 'Invalid server URL format.';
    } else if (errorStr.contains('401') || errorStr.contains('Unauthorized')) {
      return 'Invalid username or password.';
    } else if (errorStr.contains('404') || errorStr.contains('Not Found')) {
      return 'Server not found. Check your URL path.';
    } else {
      return errorStr.replaceAll('Exception:', '').trim();
    }
  }

  /// Set local-only mode (no server, just local files)
  Future<void> setLocalOnlyMode(bool enabled) async {
    if (enabled) {
      _config = ServerConfig(
        serverUrl: 'local',
        username: 'local',
        password: '',
        serverType: 'local',
      );
      await _storageService.saveServerConfig(_config!);
      _state = AuthState.offlineMode;
    } else {
      _config = null;
      _state = AuthState.unauthenticated;
      await _storageService.clearAll();
    }
    notifyListeners();
  }

  bool get isLocalOnlyMode => _config?.serverType == 'local';

  Future<void> logout() async {
    final offlineService = OfflineService();
    if (offlineService.isBackgroundDownloadActive) {
      offlineService.cancelBackgroundDownload();
    }

    await Future.wait([
      DefaultCacheManager().emptyCache(),
      BpmAnalyzerService().clearCache(),
      offlineService.deleteAllDownloads(),
      AndroidAutoService().dispose(),
      AndroidSystemService().dispose(),
      SamsungIntegrationService().dispose(),
      BluetoothAvrcpService().dispose(),
    ]);

    await _storageService.clearAll();

    _config = null;
    _state = AuthState.unauthenticated;
    notifyListeners();
  }
}
