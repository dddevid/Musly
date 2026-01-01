import 'package:shared_preferences/shared_preferences.dart';

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
}