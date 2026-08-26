import 'dart:io';
import 'package:flutter/foundation.dart';
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
  bool get isLocalOnlyMode => _config?.serverType == 'local';

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

      await _subsonicService.configure(config);
      await _verifyConnection();
    } else {
      _state = AuthState.unauthenticated;
      notifyListeners();
    }
  }

  Future<void> _verifyConnection() async {
    _state = AuthState.authenticating;
    notifyListeners();

    PingResult? pingResult;
    const maxAttempts = 3;
    for (int attempt = 1; attempt <= maxAttempts; attempt++) {
      pingResult = await _subsonicService.pingWithError().timeout(
            const Duration(seconds: 10),
            onTimeout: () =>
                PingResult(success: false, error: 'Connection timed out'),
          );
      if (pingResult.success) break;
      if (attempt < maxAttempts) {
        await Future.delayed(const Duration(seconds: 2));
      }
    }

    if (pingResult != null && pingResult.success) {
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

      final offlineService = OfflineService();
      await offlineService.initialize();
      offlineService.flushPendingScrobbles(_subsonicService).catchError(
            (e) => debugPrint('Error flushing pending scrobbles: $e'),
          );
    } else {
      final offlineService = OfflineService();
      await offlineService.initialize();
      _hasOfflineContent = offlineService.getDownloadedCount() > 0;
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
    await _subsonicService.configure(_config!);
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
    String? profileName,
    String? lanUrl,
    String serverFamily = 'subsonic',
  }) async {
    _state = AuthState.authenticating;
    _error = null;
    notifyListeners();

    if (serverFamily == 'youtube') {
      serverUrl = 'https://music.youtube.com';
      if (username.isEmpty) username = 'Web Stream';
      if (password.isEmpty) password = 'youtube';
    }

    final isJellyfin = serverFamily == 'jellyfin';
    String? jellyfinToken;
    String? jellyfinUserId;

    if (isJellyfin) {
      final tempConfig = ServerConfig(
        serverUrl: serverUrl,
        username: username,
        password: password,
        allowSelfSignedCertificates: allowSelfSignedCertificates,
        serverFamily: 'jellyfin',
      );
      final jellyfinService = JellyfinService()..configure(tempConfig);
      final authResponse =
          await jellyfinService.authenticate(username, password);
      if (authResponse == null) {
        _error = 'Jellyfin authentication failed. Check your credentials.';
        _state = AuthState.error;
        notifyListeners();
        return false;
      }
      jellyfinToken = authResponse['AccessToken'] as String?;
      final user = authResponse['User'] as Map<String, dynamic>?;
      jellyfinUserId = user?['Id'] as String?;
      if (jellyfinToken == null || jellyfinUserId == null) {
        _error = 'Jellyfin returned an unexpected response.';
        _state = AuthState.error;
        notifyListeners();
        return false;
      }
    }

    final config = ServerConfig(
      serverUrl: serverUrl,
      lanUrl: lanUrl,
      username: username,
      password: password,
      useLegacyAuth: useLegacyAuth,
      allowSelfSignedCertificates: allowSelfSignedCertificates,
      customCertificatePath: customCertificatePath,
      clientCertificatePath: clientCertificatePath,
      clientCertificatePassword: clientCertificatePassword,
      name: profileName,
      serverFamily: serverFamily,
      apiToken: jellyfinToken,
      userId: jellyfinUserId,
    );

    await _subsonicService.configure(config);

    try {
      final pingResult = await _subsonicService.pingWithError();
      if (pingResult.success) {
        final updatedConfig = config.copyWith(
          serverType: pingResult.serverType,
          serverVersion: pingResult.serverVersion,
        );
        _config = updatedConfig;
        await _storageService.saveServerConfig(updatedConfig);
        await _storageService.saveLastSelectedFamily(serverFamily);
        _state = AuthState.authenticated;
        notifyListeners();

        try {
          await _storageService.saveProfile(updatedConfig);
        } catch (e) {
          debugPrint('Error saving profile: $e');
        }

        final offlineService = OfflineService();
        await offlineService.initialize();
        offlineService.flushPendingScrobbles(_subsonicService).catchError(
              (e) => debugPrint('Error flushing pending scrobbles: $e'),
            );
        return true;
      } else {
        _error =
            _formatError(pingResult.error ?? 'Failed to connect to server');
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
    final errorString = error.toString();
    if (errorString.contains('SocketException') ||
        errorString.contains('Connection refused') ||
        errorString.contains('Connection failed') ||
        errorString.contains('connection errored') ||
        errorString.contains('Cannot connect')) {
      return 'Cannot connect to server. Check the URL and your internet connection.';
    }
    if (errorString.contains('TlsException') ||
        errorString.contains('CERT_') ||
        errorString.contains('certificate') ||
        errorString.contains('Client Certificate')) {
      return 'Certificate or TLS error. Check your custom CA or client certificate file and password.';
    }
    if (errorString.contains('HandshakeException') ||
        errorString.contains('CERTIFICATE_VERIFY_FAILED') ||
        errorString.contains('SSL certificate')) {
      return 'SSL certificate error. Enable "Allow Self-Signed Certificates" for custom CA servers.';
    }
    if (errorString.contains('TimeoutException') ||
        errorString.contains('timed out')) {
      return 'Connection timed out. Check your server URL.';
    }
    if (errorString.contains('FormatException')) {
      return 'Invalid server URL format.';
    }
    if (errorString.contains('401') ||
        errorString.contains('Unauthorized') ||
        errorString.contains('Invalid username or password')) {
      return 'Invalid username or password.';
    }
    if (errorString.contains('404') ||
        errorString.contains('Not Found') ||
        errorString.contains('Server not found')) {
      return 'Server not found. Check your URL path.';
    }

    return errorString
        .replaceAll('Exception:', '')
        .replaceAll('Network error:', '')
        .replaceAll(
          'This indicates an error which most likely cannot be solved by the library.',
          '',
        )
        .trim();
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

  Future<List<ServerConfig>> getSavedProfiles() =>
      _storageService.getSavedProfiles();

  Future<bool> hasYoutubeProfile() async {
    if (_config?.isYoutube == true) return true;
    return await _storageService.hasYoutubeProfile();
  }

  Future<void> saveProfile(ServerConfig profile) async {
    await _storageService.saveProfile(profile);
    notifyListeners();
  }

  Future<void> deleteProfile(ServerConfig profile) async {
    await _storageService.deleteProfile(profile);
    notifyListeners();
  }

  Future<void> renameProfile(ServerConfig profile, String newName) async {
    final updated = profile.copyWith(name: newName);
    await _storageService.saveProfile(updated);
    if (_config?.serverUrl == profile.serverUrl &&
        _config?.username == profile.username &&
        _config?.serverFamily == profile.serverFamily) {
      _config = updated;
      await _storageService.saveServerConfig(updated);
    }
    notifyListeners();
  }

  Future<bool> connectYtStream() async {
    if (!kIsWeb && Platform.isIOS) {
      return false;
    }
    return await login(
      serverUrl: 'https://music.youtube.com',
      username: 'Web Stream',
      password: 'youtube',
      serverFamily: 'youtube',
      profileName: 'Web Stream',
    );
  }

  Future<void> switchProfile(ServerConfig profile) async {
    _config = profile;
    await _storageService.saveServerConfig(profile);
    await _storageService.saveLastSelectedFamily(profile.serverFamily);
    await _storageService.saveProfile(profile);
    await _subsonicService.configure(profile);
    await _verifyConnection();
    notifyListeners();
  }

  Future<void> updateSelectedMusicFolderIds(List<String> ids) async {
    if (_config == null) return;
    final updated = _config!.copyWith(selectedMusicFolderIds: ids);
    _config = updated;
    await _subsonicService.configure(updated);
    await _storageService.saveServerConfig(updated);
    notifyListeners();
  }

  Future<void> logout() async {
    final offlineService = OfflineService();
    if (offlineService.isBackgroundDownloadActive) {
      offlineService.cancelBackgroundDownload();
    }

    try {
      await DefaultCacheManager().emptyCache();
    } catch (_) {}
    try {
      await BpmAnalyzerService().clearCache();
    } catch (_) {}
    try {
      await offlineService.deleteAllDownloads();
    } catch (_) {}
    await _storageService.clearAll();

    _config = null;
    _state = AuthState.unauthenticated;
    notifyListeners();
  }
}
