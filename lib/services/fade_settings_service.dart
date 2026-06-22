import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class FadeSettingsService {
  static const String _keyFadeEnabled = 'fade_enabled';
  static const String _keyFadeDurationMs = 'fade_duration_ms';

  static final FadeSettingsService _instance = FadeSettingsService._internal();
  factory FadeSettingsService() => _instance;
  FadeSettingsService._internal();

  SharedPreferences? _prefs;

  final ValueNotifier<bool> fadeEnabledNotifier = ValueNotifier(false);
  final ValueNotifier<int> fadeDurationMsNotifier = ValueNotifier(300);

  Future<void> initialize() async {
    _prefs ??= await SharedPreferences.getInstance();
    fadeEnabledNotifier.value = getFadeEnabled();
    fadeDurationMsNotifier.value = getFadeDurationMs();
  }

  Future<void> setFadeEnabled(bool enabled) async {
    await initialize();
    await _prefs!.setBool(_keyFadeEnabled, enabled);
    fadeEnabledNotifier.value = enabled;
  }

  bool getFadeEnabled() {
    return _prefs?.getBool(_keyFadeEnabled) ?? false;
  }

  Future<void> setFadeDurationMs(int durationMs) async {
    await initialize();
    await _prefs!.setInt(_keyFadeDurationMs, durationMs);
    fadeDurationMsNotifier.value = durationMs;
  }

  int getFadeDurationMs() {
    return _prefs?.getInt(_keyFadeDurationMs) ?? 300;
  }

  void dispose() {
    fadeEnabledNotifier.dispose();
    fadeDurationMsNotifier.dispose();
  }
}
