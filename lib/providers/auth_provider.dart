import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import '../models/server_config.dart';
import '../services/services.dart';

enum AuthState {
  unknown,
  unauthenticated,
  authenticating,
  authenticated,
  offlineMode, 
  serverUnreachable, 
  error,
}

class AuthProvider extends ChangeNotifier {
  final SubsonicService _subsonicService;
  final StorageService _storageService;

  AuthState _state = AuthState.unknown;
  String? _error;
  ServerConfig? _config;
  bool _hasOfflineContent = false;

  AuthProvider(this._subsonicService, this._storageService) {
    _loadSavedConfig();
  }

  AuthState get state => _state;
  String? get error => _error;
  ServerConfig? get config => _config;
  bool get isAuthenticated => _state == AuthState.authenticated;
  bool get hasOfflineContent => _hasOfflineContent;

  Future<void> _loadSavedConfig() async {
    final config = await _storageService.getServerConfig();
    if (config != null && config.isValid) {
      _config = config;

      if (config.serverType == 'local') {
        OfflineService().setOfflineMode(true);
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
    debugPrint('[Auth] _verifyConnection: pinging ${_config?.serverUrl}');
    _state = AuthState.authenticating;
    notifyListeners();

    PingResult? pingResult;
    const maxAttempts = 3;
    for (int attempt = 1; attempt <= maxAttempts; attempt++) {
      pingResult = await _subsonicService.pingWithError().timeout(
        const Duration(seconds: 10),
        onTimeout: () => PingResult(success: false, error: 'Connection timed out'),
      );
      if (pingResult.success) break;
      debugPrint('[Auth] Ping attempt $attempt/$maxAttempts failed: ${pingResult.error}');
      if (attempt < maxAttempts) {
        await Future.delayed(const Duration(seconds: 2));
      }
    }
    if (pingResult!.success) {
      debugPrint('[Auth] Ping OK — type=${pingResult.serverType} version=${pingResult.serverVersion}');
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
      debugPrint('[Auth] State: authenticating → authenticated');
      _state = AuthState.authenticated;
      
      final offlineService = OfflineService();
      await offlineService.initialize();
      offlineService
          .flushPendingScrobbles(_subsonicService)
          .catchError(
            (e) => debugPrint('Error flushing pending scrobbles: $e'),
          );
    } else {
      debugPrint('[Auth] Ping failed: ${pingResult.error}');
      
      final offlineService = OfflineService();
      await offlineService.initialize();
      _hasOfflineContent = offlineService.getDownloadedCount() > 0;
      debugPrint('[Auth] State: authenticating → serverUnreachable (offlineContent=$_hasOfflineContent)');
      _state = AuthState.serverUnreachable;
    }
    notifyListeners();
  }

  void enterOfflineMode() {
    OfflineService().setOfflineMode(true);
    _state = AuthState.offlineMode;
    notifyListeners();
  }

  Future<void> retryConnection() async {
    if (_config == null) return;
    _subsonicService.configure(_config!);
    await _verifyConnection();
  }

  Future<void> disconnect() async {
    _config = null;
    _state = AuthState.unauthenticated;
    await _storageService.clearAll();
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
    debugPrint('[Auth] login: user=$username server=$serverUrl legacy=$useLegacyAuth selfSigned=$allowSelfSignedCertificates');
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
        debugPrint('[Auth] Login OK — type=${pingResult.serverType} version=${pingResult.serverVersion}');
        debugPrint('[Auth] State: authenticating → authenticated');
        final updatedConfig = config.copyWith(
          serverType: pingResult.serverType,
          serverVersion: pingResult.serverVersion,
        );
        _config = updatedConfig;
        await _storageService.saveServerConfig(updatedConfig);
        _state = AuthState.authenticated;
        notifyListeners();
        
        final offlineService = OfflineService();
        await offlineService.initialize();
        offlineService
            .flushPendingScrobbles(_subsonicService)
            .catchError(
              (e) => debugPrint('Error flushing pending scrobbles: $e'),
            );
        return true;
      } else {
        _error = _formatError(pingResult.error ?? 'Failed to connect to server');
        debugPrint('[Auth] Login failed: $_error');
        debugPrint('[Auth] State: authenticating → error');
        _state = AuthState.error;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = _formatError(e);
      debugPrint('[Auth] Login exception: $e');
      debugPrint('[Auth] State: authenticating → error (formatted: $_error)');
      _state = AuthState.error;
      notifyListeners();
      return false;
    }
  }

  String _formatError(dynamic error) {
    final errorStr = error.toString();
    if (errorStr.contains('SocketException') ||
        errorStr.contains('Connection refused') ||
        errorStr.contains('Connection failed') ||
        errorStr.contains('connection errored') ||
        errorStr.contains('Cannot connect')) {
      return 'Cannot connect to server. Check the URL and your internet connection.';
    } else if (errorStr.contains('HandshakeException') ||
        errorStr.contains('CERTIFICATE_VERIFY_FAILED') ||
        errorStr.contains('SSL certificate')) {
      return 'SSL certificate error. Enable "Allow Self-Signed Certificates" for custom CA servers.';
    } else if (errorStr.contains('TimeoutException') ||
        errorStr.contains('timed out')) {
      return 'Connection timed out. Check your server URL.';
    } else if (errorStr.contains('FormatException')) {
      return 'Invalid server URL format.';
    } else if (errorStr.contains('401') || errorStr.contains('Unauthorized') ||
        errorStr.contains('Invalid username or password')) {
      return 'Invalid username or password.';
    } else if (errorStr.contains('404') || errorStr.contains('Not Found') ||
        errorStr.contains('Server not found')) {
      return 'Server not found. Check your URL path.';
    } else {
      
      return errorStr
          .replaceAll('Exception:', '')
          .replaceAll('Network error:', '')
          .replaceAll('This indicates an error which most likely cannot be solved by the library.', '')
          .trim();
    }
  }

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

  Future<void> updateSelectedMusicFolderIds(List<String> ids) async {
    if (_config == null) return;
    final updated = _config!.copyWith(selectedMusicFolderIds: ids);
    _config = updated;
    _subsonicService.configure(updated);
    await _storageService.saveServerConfig(updated);
    notifyListeners();
  }

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
