import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/server_config.dart';

class StorageService {
  static const String _serverConfigKey = 'server_config';
  static const String _lastPlayedKey = 'last_played';
  static const String _queueKey = 'queue';
  static const String _queueIndexKey = 'queue_index';
  static const String _shuffleModeKey = 'shuffle_mode';
  static const String _repeatModeKey = 'repeat_mode';

  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  Future<void> saveServerConfig(ServerConfig config) async {
    final prefs = await _prefs;
    await prefs.setString(_serverConfigKey, json.encode(config.toJson()));
  }

  Future<ServerConfig?> getServerConfig() async {
    final prefs = await _prefs;
    final configJson = prefs.getString(_serverConfigKey);
    if (configJson != null) {
      return ServerConfig.fromJson(json.decode(configJson));
    }
    return null;
  }

  Future<void> clearServerConfig() async {
    final prefs = await _prefs;
    await prefs.remove(_serverConfigKey);
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

  Future<void> saveDiscordRpcEnabled(bool enabled) async {
    final prefs = await _prefs;
    await prefs.setBool('discord_rpc_enabled', enabled);
  }

  Future<bool> getDiscordRpcEnabled() async {
    final prefs = await _prefs;
    return prefs.getBool('discord_rpc_enabled') ?? true; // Default to true
  }

  Future<void> clearAll() async {
    final prefs = await _prefs;
    await prefs.clear();
  }
}
