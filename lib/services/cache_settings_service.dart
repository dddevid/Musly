import 'dart:io';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'bpm_analyzer_service.dart';

class CacheSettingsService {
  static const String _keyImageCacheEnabled = 'cache_images_enabled';
  static const String _keyMusicCacheEnabled = 'cache_music_enabled';
  static const String _keyBpmCacheEnabled = 'cache_bpm_enabled';

  static final CacheSettingsService _instance =
      CacheSettingsService._internal();
  factory CacheSettingsService() => _instance;
  CacheSettingsService._internal();

  SharedPreferences? _prefs;

  Future<void> initialize() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  Future<void> setImageCacheEnabled(bool enabled) async {
    await initialize();
    await _prefs!.setBool(_keyImageCacheEnabled, enabled);
  }

  bool getImageCacheEnabled() {
    return _prefs?.getBool(_keyImageCacheEnabled) ?? true;
  }

  Future<void> setMusicCacheEnabled(bool enabled) async {
    await initialize();
    await _prefs!.setBool(_keyMusicCacheEnabled, enabled);
  }

  bool getMusicCacheEnabled() {
    return _prefs?.getBool(_keyMusicCacheEnabled) ?? true;
  }

  Future<void> setBpmCacheEnabled(bool enabled) async {
    await initialize();
    await _prefs!.setBool(_keyBpmCacheEnabled, enabled);
  }

  bool getBpmCacheEnabled() {
    return _prefs?.getBool(_keyBpmCacheEnabled) ?? true;
  }

  Future<void> disableAllCaches() async {
    await Future.wait([
      setImageCacheEnabled(false),
      setMusicCacheEnabled(false),
      setBpmCacheEnabled(false),
    ]);
  }

  Future<void> enableAllCaches() async {
    await Future.wait([
      setImageCacheEnabled(true),
      setMusicCacheEnabled(true),
      setBpmCacheEnabled(true),
    ]);
  }

  bool areAllCachesDisabled() {
    return !getImageCacheEnabled() &&
        !getMusicCacheEnabled() &&
        !getBpmCacheEnabled();
  }

  bool areAllCachesEnabled() {
    return getImageCacheEnabled() &&
        getMusicCacheEnabled() &&
        getBpmCacheEnabled();
  }

  Future<int> getAudioCacheSizeBytes() async {
    int total = 0;
    try {
      final tempDir = await getTemporaryDirectory();
      final ytCacheDir = Directory('${tempDir.path}/musly_yt_cache');
      if (ytCacheDir.existsSync()) {
        await for (final entity
            in ytCacheDir.list(recursive: true, followLinks: false)) {
          if (entity is File) {
            try {
              total += await entity.length();
            } catch (_) {}
          }
        }
      }

      if (tempDir.existsSync()) {
        await for (final entity in tempDir.list(followLinks: false)) {
          if (entity is File && entity.path.contains('musly_stream_')) {
            try {
              total += await entity.length();
            } catch (_) {}
          }
        }
      }
    } catch (_) {}
    return total;
  }

  Future<int> getImageCacheSizeBytes() async {
    int total = 0;
    try {
      final tempDir = await getTemporaryDirectory();
      final imageCacheDir = Directory('${tempDir.path}/libCachedImageData');
      if (imageCacheDir.existsSync()) {
        await for (final entity
            in imageCacheDir.list(recursive: true, followLinks: false)) {
          if (entity is File) {
            try {
              total += await entity.length();
            } catch (_) {}
          }
        }
      }
    } catch (_) {}
    return total;
  }

  Future<int> getTotalCacheSizeBytes() async {
    final audio = await getAudioCacheSizeBytes();
    final image = await getImageCacheSizeBytes();
    return audio + image;
  }

  String formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
    var i = 0;
    double d = bytes.toDouble();
    while (d >= 1024 && i < suffixes.length - 1) {
      d /= 1024;
      i++;
    }
    return '${d.toStringAsFixed(d < 10 && i > 0 ? 1 : 0)} ${suffixes[i]}';
  }

  Future<void> clearAudioCache() async {
    try {
      final tempDir = await getTemporaryDirectory();
      final ytCacheDir = Directory('${tempDir.path}/musly_yt_cache');
      if (ytCacheDir.existsSync()) {
        await ytCacheDir.delete(recursive: true);
      }
      if (tempDir.existsSync()) {
        await for (final entity in tempDir.list(followLinks: false)) {
          if (entity is File && entity.path.contains('musly_stream_')) {
            try {
              await entity.delete();
            } catch (_) {}
          }
        }
      }
    } catch (_) {}
  }

  Future<void> clearImageCache() async {
    try {
      await DefaultCacheManager().emptyCache();
    } catch (_) {}
  }

  Future<void> clearAllCache() async {
    await Future.wait([
      clearAudioCache(),
      clearImageCache(),
      BpmAnalyzerService().clearCache(),
    ]);
  }
}
