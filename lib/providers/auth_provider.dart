import 'package:flutter/material.dart';
import '../models/server_config.dart';
import '../services/services.dart';

enum AuthState {
  unknown,
  unauthenticated,
  authenticating,
  authenticated,
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

    final success = await _subsonicService.ping();
    if (success) {
      _state = AuthState.authenticated;
    } else {
      _state = AuthState.unauthenticated;
    }
    notifyListeners();
  }

  Future<bool> login({
    required String serverUrl,
    required String username,
    required String password,
    bool useLegacyAuth = false,
  }) async {
    _state = AuthState.authenticating;
    _error = null;
    notifyListeners();

    final config = ServerConfig(
      serverUrl: serverUrl,
      username: username,
      password: password,
      useLegacyAuth: useLegacyAuth,
    );

    _subsonicService.configure(config);

    try {
      final success = await _subsonicService.ping();
      if (success) {
        _config = config;
        await _storageService.saveServerConfig(config);
        _state = AuthState.authenticated;
        notifyListeners();
        return true;
      } else {
        _error = 'Failed to connect to server';
        _state = AuthState.error;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = e.toString();
      _state = AuthState.error;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _storageService.clearServerConfig();
    _config = null;
    _state = AuthState.unauthenticated;
    notifyListeners();
  }
}