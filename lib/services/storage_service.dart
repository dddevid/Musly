import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';
import '../models/server_config.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  SharedPreferences? _prefsInstance;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  static const String _serverConfigKey = 'server_config';
  static const String _serverProfilesKey = 'server_profiles';
  static const String _lastPlayedKey = 'last_played';
  static const String _queueKey = 'queue';
  static const String _queueIndexKey = 'queue_index';
  static const String _shuffleModeKey = 'shuffle_mode';
  static const String _repeatModeKey = 'repeat_mode';
  static const String _gaplessPlaybackKey = 'gapless_playback';
  static const String _lrcLibFallbackKey = 'lrclib_fallback';
  static const String _volumeKey = 'volume';

  String _profileKey(ServerConfig config) {
    final raw = '${config.serverFamily}_${config.serverUrl}_${config.username}_${config.name ?? ""}';
    return md5.convert(utf8.encode(raw)).toString();
  }

  Future<String?> _safeSecureRead(String key) async {
    try {
      return await _secureStorage.read(key: key);
    } on PlatformException catch (e) {
      if (e.code == '-34018' || e.message?.contains('entitlement') == true) {
        final prefs = await _prefs;
        return prefs.getString('fallback_secure_$key');
      }
      return null;
    }
  }

  Future<void> _safeSecureWrite(String key, String value) async {
    try {
      await _secureStorage.write(key: key, value: value);
    } on PlatformException catch (e) {
      if (e.code == '-34018' || e.message?.contains('entitlement') == true) {
        final prefs = await _prefs;
        await prefs.setString('fallback_secure_$key', value);
      }
    }
  }

  Future<void> _safeSecureDelete(String key) async {
    try {
      await _secureStorage.delete(key: key);
    } on PlatformException catch (e) {
      if (e.code == '-34018' || e.message?.contains('entitlement') == true) {
        final prefs = await _prefs;
        await prefs.remove('fallback_secure_$key');
      }
    }
  }

  Future<void> _safeSecureDeleteAll() async {
    try {
      await _secureStorage.deleteAll();
    } on PlatformException catch (_) {
      // Ignored for fallback
    }
  }

  Future<void> init() async {
    _prefsInstance = await SharedPreferences.getInstance();
  }

  Future<SharedPreferences> get _prefs async {
    _prefsInstance ??= await SharedPreferences.getInstance();
    return _prefsInstance!;
  }

  Future<void> saveServerConfig(ServerConfig config) async {
    final prefs = await _prefs;
    
    // Save secrets securely
    if (config.password.isNotEmpty) {
      await _safeSecureWrite('server_pwd_active', config.password);
    }
    if (config.apiToken != null && config.apiToken!.isNotEmpty) {
      await _safeSecureWrite('server_token_active', config.apiToken!);
    }
    if (config.clientCertificatePassword != null && config.clientCertificatePassword!.isNotEmpty) {
      await _safeSecureWrite('server_cert_pwd_active', config.clientCertificatePassword!);
    }
    
    // Strip secrets from plain text storage
    final map = config.toJson();
    map['password'] = ''; 
    map['apiToken'] = null;
    map['clientCertificatePassword'] = null;
    await prefs.setString(_serverConfigKey, json.encode(map));
  }

  Future<ServerConfig?> getServerConfig() async {
    final prefs = await _prefs;
    final configJson = prefs.getString(_serverConfigKey);
    if (configJson != null) {
      final map = json.decode(configJson) as Map<String, dynamic>;
      
      // Load secrets from secure storage
      final securePwd = await _safeSecureRead('server_pwd_active');
      final secureToken = await _safeSecureRead('server_token_active');
      final secureCertPwd = await _safeSecureRead('server_cert_pwd_active');
      
      // Migrate existing plaintext secrets to secure storage if found
      if (securePwd == null && map['password'] != null && map['password'].toString().isNotEmpty) {
        await _safeSecureWrite('server_pwd_active', map['password'].toString());
      } else if (securePwd != null) {
        map['password'] = securePwd;
      }

      if (secureToken == null && map['apiToken'] != null && map['apiToken'].toString().isNotEmpty) {
        await _safeSecureWrite('server_token_active', map['apiToken'].toString());
      } else if (secureToken != null) {
        map['apiToken'] = secureToken;
      }

      if (secureCertPwd == null && map['clientCertificatePassword'] != null && map['clientCertificatePassword'].toString().isNotEmpty) {
        await _safeSecureWrite('server_cert_pwd_active', map['clientCertificatePassword'].toString());
      } else if (secureCertPwd != null) {
        map['clientCertificatePassword'] = secureCertPwd;
      }
      
      final config = ServerConfig.fromJson(map);
      if (!kIsWeb && Platform.isIOS && config.isYoutube) {
        return null;
      }
      return config;
    }
    return null;
  }

  Future<void> clearServerConfig() async {
    final prefs = await _prefs;
    await prefs.remove(_serverConfigKey);
    await _safeSecureDelete('server_pwd_active');
    await _safeSecureDelete('server_token_active');
    await _safeSecureDelete('server_cert_pwd_active');
  }

  Future<List<ServerConfig>> getSavedProfiles() async {
    final prefs = await _prefs;
    final jsonStr = prefs.getString(_serverProfilesKey);
    if (jsonStr == null) return [];
    
    final list = jsonDecode(jsonStr) as List<dynamic>;
    final profiles = <ServerConfig>[];
    
    for (int i = 0; i < list.length; i++) {
      final map = Map<String, dynamic>.from(list[i] as Map);
      final pTemp = ServerConfig.fromJson(map);
      final pKey = _profileKey(pTemp);

      // 1. Password
      String? securePwd = await _safeSecureRead('server_profile_pwd_$pKey');
      if (securePwd == null) {
        // Check legacy key without profile name
        final legacyRaw = '${pTemp.serverFamily}_${pTemp.serverUrl}_${pTemp.username}';
        final legacyKey = md5.convert(utf8.encode(legacyRaw)).toString();
        securePwd = await _safeSecureRead('server_profile_pwd_$legacyKey');
        if (securePwd != null) {
          await _safeSecureWrite('server_profile_pwd_$pKey', securePwd);
        }
      }
      if (securePwd == null) {
        // Check legacy index key
        securePwd = await _safeSecureRead('server_profile_pwd_$i');
        if (securePwd != null) {
          await _safeSecureWrite('server_profile_pwd_$pKey', securePwd);
          await _safeSecureDelete('server_profile_pwd_$i');
        }
      }
      if (securePwd == null && map['password'] != null && map['password'].toString().isNotEmpty) {
        await _safeSecureWrite('server_profile_pwd_$pKey', map['password'].toString());
      } else if (securePwd != null) {
        map['password'] = securePwd;
      }

      // 2. API Token
      String? secureToken = await _safeSecureRead('server_profile_token_$pKey');
      if (secureToken == null) {
        final legacyRaw = '${pTemp.serverFamily}_${pTemp.serverUrl}_${pTemp.username}';
        final legacyKey = md5.convert(utf8.encode(legacyRaw)).toString();
        secureToken = await _safeSecureRead('server_profile_token_$legacyKey');
        if (secureToken != null) {
          await _safeSecureWrite('server_profile_token_$pKey', secureToken);
        }
      }
      if (secureToken == null && map['apiToken'] != null && map['apiToken'].toString().isNotEmpty) {
        await _safeSecureWrite('server_profile_token_$pKey', map['apiToken'].toString());
      } else if (secureToken != null) {
        map['apiToken'] = secureToken;
      }

      // 3. Client Certificate Password
      String? secureCertPwd = await _safeSecureRead('server_profile_cert_pwd_$pKey');
      if (secureCertPwd == null) {
        final legacyRaw = '${pTemp.serverFamily}_${pTemp.serverUrl}_${pTemp.username}';
        final legacyKey = md5.convert(utf8.encode(legacyRaw)).toString();
        secureCertPwd = await _safeSecureRead('server_profile_cert_pwd_$legacyKey');
        if (secureCertPwd != null) {
          await _safeSecureWrite('server_profile_cert_pwd_$pKey', secureCertPwd);
        }
      }
      if (secureCertPwd == null && map['clientCertificatePassword'] != null && map['clientCertificatePassword'].toString().isNotEmpty) {
        await _safeSecureWrite('server_profile_cert_pwd_$pKey', map['clientCertificatePassword'].toString());
      } else if (secureCertPwd != null) {
        map['clientCertificatePassword'] = secureCertPwd;
      }

      final cfg = ServerConfig.fromJson(map);
      if (!kIsWeb && Platform.isIOS && cfg.isYoutube) {
        continue;
      }
      profiles.add(cfg);
    }
    return profiles;
  }

  Future<void> saveProfile(ServerConfig config) async {
    if (!kIsWeb && Platform.isIOS && config.isYoutube) {
      return;
    }
    final profiles = await getSavedProfiles();
    final idx = profiles.indexWhere(
      (p) =>
          (config.isYoutube && p.isYoutube) ||
          (p.serverFamily == config.serverFamily &&
           p.serverUrl == config.serverUrl &&
           p.username == config.username &&
           (config.name == null || config.name!.isEmpty || p.name == config.name)),
    );
    
    final pKey = _profileKey(config);
    if (config.password.isNotEmpty) {
      await _safeSecureWrite('server_profile_pwd_$pKey', config.password);
    }
    if (config.apiToken != null && config.apiToken!.isNotEmpty) {
      await _safeSecureWrite('server_profile_token_$pKey', config.apiToken!);
    }
    if (config.clientCertificatePassword != null && config.clientCertificatePassword!.isNotEmpty) {
      await _safeSecureWrite('server_profile_cert_pwd_$pKey', config.clientCertificatePassword!);
    }

    if (idx >= 0) {
      profiles[idx] = config;
    } else {
      profiles.add(config);
    }
    
    final prefs = await _prefs;
    final safeProfiles = profiles.map((p) {
      final map = p.toJson();
      map['password'] = '';
      map['apiToken'] = null;
      map['clientCertificatePassword'] = null;
      return map;
    }).toList();
    
    await prefs.setString(_serverProfilesKey, jsonEncode(safeProfiles));
  }

  Future<bool> hasYoutubeProfile() async {
    if (!kIsWeb && Platform.isIOS) return false;
    final profiles = await getSavedProfiles();
    return profiles.any((p) => p.isYoutube);
  }

  Future<void> deleteProfile(ServerConfig config) async {
    final profiles = await getSavedProfiles();
    final idx = profiles.indexWhere(
      (p) =>
          (config.isYoutube && p.isYoutube) ||
          (p.serverFamily == config.serverFamily &&
           p.serverUrl == config.serverUrl &&
           p.username == config.username &&
           (config.name == null || config.name!.isEmpty || p.name == config.name)),
    );
    
    if (idx >= 0) {
      final removed = profiles.removeAt(idx);
      final pKey = _profileKey(removed);
      await _safeSecureDelete('server_profile_pwd_$pKey');
      await _safeSecureDelete('server_profile_token_$pKey');
      await _safeSecureDelete('server_profile_cert_pwd_$pKey');
      
      final prefs = await _prefs;
      final safeProfiles = profiles.map((p) {
        final map = p.toJson();
        map['password'] = '';
        map['apiToken'] = null;
        map['clientCertificatePassword'] = null;
        return map;
      }).toList();
      await prefs.setString(_serverProfilesKey, jsonEncode(safeProfiles));
    }
  }

  Future<void> saveLastPlayed(String songId) async {
    final prefs = await _prefs;
    await prefs.setString(_lastPlayedKey, songId);
  }

  Future<String?> getLastPlayed() async {
    final prefs = await _prefs;
    return prefs.getString(_lastPlayedKey);
  }

  Future<void> saveQueue(List<Map<String, dynamic>> queue) async {
    final prefs = await _prefs;
    await prefs.setString(_queueKey, json.encode(queue));
  }

  Future<List<Map<String, dynamic>>> getQueue() async {
    final prefs = await _prefs;
    final queueJson = prefs.getString(_queueKey);
    if (queueJson != null) {
      final list = json.decode(queueJson) as List;
      return list.cast<Map<String, dynamic>>();
    }
    return [];
  }

  Future<void> saveQueueIndex(int index) async {
    final prefs = await _prefs;
    await prefs.setInt(_queueIndexKey, index);
  }

  Future<int> getQueueIndex() async {
    final prefs = await _prefs;
    return prefs.getInt(_queueIndexKey) ?? 0;
  }

  Future<void> saveShuffleMode(bool enabled) async {
    final prefs = await _prefs;
    await prefs.setBool(_shuffleModeKey, enabled);
  }

  Future<bool> getShuffleMode() async {
    final prefs = await _prefs;
    return prefs.getBool(_shuffleModeKey) ?? false;
  }

  Future<void> saveRepeatMode(int mode) async {
    final prefs = await _prefs;
    await prefs.setInt(_repeatModeKey, mode);
  }

  Future<int> getRepeatMode() async {
    final prefs = await _prefs;
    return prefs.getInt(_repeatModeKey) ?? 0;
  }

  Future<void> saveGaplessPlayback(bool enabled) async {
    final prefs = await _prefs;
    await prefs.setBool(_gaplessPlaybackKey, enabled);
  }

  Future<bool> getGaplessPlayback() async {
    final prefs = await _prefs;
    return prefs.getBool(_gaplessPlaybackKey) ?? true;
  }

  Future<void> saveLrcLibFallback(bool enabled) async {
    final prefs = await _prefs;
    await prefs.setBool(_lrcLibFallbackKey, enabled);
  }

  Future<bool> getLrcLibFallback() async {
    final prefs = await _prefs;
    return prefs.getBool(_lrcLibFallbackKey) ?? true;
  }

  Future<void> saveVolume(double volume) async {
    final prefs = await _prefs;
    await prefs.setDouble(_volumeKey, volume);
  }

  Future<double> getVolume() async {
    final prefs = await _prefs;
    return prefs.getDouble(_volumeKey) ?? 1.0;
  }

  Future<void> saveDiscordRpcEnabled(bool enabled) async {
    final prefs = await _prefs;
    await prefs.setBool('discord_rpc_enabled', enabled);
  }

  Future<bool> getDiscordRpcEnabled() async {
    final prefs = await _prefs;
    return prefs.getBool('discord_rpc_enabled') ?? true; 
  }

  Future<void> saveDiscordRpcStateStyle(String style) async {
    final prefs = await _prefs;
    await prefs.setString('discord_rpc_state_style', style);
  }

  Future<String> getDiscordRpcStateStyle() async {
    final prefs = await _prefs;
    return prefs.getString('discord_rpc_state_style') ?? 'artist';
  }

  Future<String> getOrCreateSubsonicSalt() async {
    final prefs = await _prefs;
    String? salt = prefs.getString('subsonic_client_salt');
    if (salt == null || salt.isEmpty) {
      salt = const Uuid().v4().substring(0, 16);
      await prefs.setString('subsonic_client_salt', salt);
    }
    return salt;
  }

  Future<void> saveLastSelectedFamily(String family) async {
    final prefs = await _prefs;
    await prefs.setString('last_selected_server_family', family);
  }

  Future<String?> getLastSelectedFamily() async {
    final prefs = await _prefs;
    return prefs.getString('last_selected_server_family');
  }

  Future<void> saveHideWindowTitlebar(bool hide) async {
    final prefs = await _prefs;
    await prefs.setBool('hide_window_titlebar', hide);
  }

  Future<bool> getHideWindowTitlebar() async {
    final prefs = await _prefs;
    return prefs.getBool('hide_window_titlebar') ?? false;
  }

  Future<bool> isOnboardingCompleted() async {
    final prefs = await _prefs;
    return prefs.getBool('onboarding_completed') ?? false;
  }

  Future<void> setOnboardingCompleted(bool completed) async {
    final prefs = await _prefs;
    await prefs.setBool('onboarding_completed', completed);
  }

  Future<void> clearAll() async {
    final prefs = await _prefs;
    await prefs.clear();
    await _safeSecureDeleteAll();
  }
}

