import 'dart:convert';
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
    
    // Save password securely
    if (config.password.isNotEmpty) {
      await _safeSecureWrite('server_pwd_active', config.password);
    }
    
    // Strip password from plain text storage
    final map = config.toJson();
    map['password'] = ''; 
    await prefs.setString(_serverConfigKey, json.encode(map));
  }

  Future<ServerConfig?> getServerConfig() async {
    final prefs = await _prefs;
    final configJson = prefs.getString(_serverConfigKey);
    if (configJson != null) {
      final map = json.decode(configJson);
      
      // Load password from secure storage
      final securePwd = await _safeSecureRead('server_pwd_active');
      
      // Migrate existing plaintext password to secure storage if found
      if (securePwd == null && map['password'] != null && map['password'].toString().isNotEmpty) {
        await _safeSecureWrite('server_pwd_active', map['password']);
      } else if (securePwd != null) {
        map['password'] = securePwd;
      }
      
      return ServerConfig.fromJson(map);
    }
    return null;
  }

  Future<void> clearServerConfig() async {
    final prefs = await _prefs;
    await prefs.remove(_serverConfigKey);
    await _safeSecureDelete('server_pwd_active');
  }

  Future<List<ServerConfig>> getSavedProfiles() async {
    final prefs = await _prefs;
    final jsonStr = prefs.getString(_serverProfilesKey);
    if (jsonStr == null) return [];
    
    final list = jsonDecode(jsonStr) as List<dynamic>;
    final profiles = <ServerConfig>[];
    
    for (int i = 0; i < list.length; i++) {
      final map = list[i] as Map<String, dynamic>;
      // Read secure password for each profile using its index or unique key
      final securePwd = await _safeSecureRead('server_profile_pwd_$i');
      if (securePwd == null && map['password'] != null && map['password'].toString().isNotEmpty) {
        await _safeSecureWrite('server_profile_pwd_$i', map['password']);
      } else if (securePwd != null) {
        map['password'] = securePwd;
      }
      profiles.add(ServerConfig.fromJson(map));
    }
    return profiles;
  }

  Future<void> saveProfile(ServerConfig config) async {
    final profiles = await getSavedProfiles();
    final idx = profiles.indexWhere(
      (p) => p.serverUrl == config.serverUrl && p.username == config.username,
    );
    
    if (idx >= 0) {
      profiles[idx] = config;
      if (config.password.isNotEmpty) {
        await _safeSecureWrite('server_profile_pwd_$idx', config.password);
      }
    } else {
      profiles.add(config);
      if (config.password.isNotEmpty) {
        await _safeSecureWrite('server_profile_pwd_${profiles.length - 1}', config.password);
      }
    }
    
    final prefs = await _prefs;
    final safeProfiles = profiles.map((p) {
      final map = p.toJson();
      map['password'] = '';
      return map;
    }).toList();
    
    await prefs.setString(_serverProfilesKey, jsonEncode(safeProfiles));
  }

  Future<void> deleteProfile(ServerConfig config) async {
    final profiles = await getSavedProfiles();
    final idx = profiles.indexWhere(
      (p) => p.serverUrl == config.serverUrl && p.username == config.username,
    );
    
    if (idx >= 0) {
      profiles.removeAt(idx);
      await _safeSecureDelete('server_profile_pwd_$idx');
      
      // Shift remaining secure passwords to match new indices
      for (int i = idx; i < profiles.length; i++) {
        final nextPwd = await _safeSecureRead('server_profile_pwd_${i + 1}');
        if (nextPwd != null) {
          await _safeSecureWrite('server_profile_pwd_$i', nextPwd);
        } else {
          await _safeSecureDelete('server_profile_pwd_$i');
        }
      }
      // Delete the last one since we shifted everything down
      await _safeSecureDelete('server_profile_pwd_${profiles.length}');
      
      final prefs = await _prefs;
      final safeProfiles = profiles.map((p) {
        final map = p.toJson();
        map['password'] = '';
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
    return prefs.getBool(_lrcLibFallbackKey) ?? false;
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
    return prefs.getBool('discord_rpc_enabled') ?? false; 
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

  Future<void> clearAll() async {
    final prefs = await _prefs;
    await prefs.clear();
    await _safeSecureDeleteAll();
  }
}

