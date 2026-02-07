import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class PlayerUiSettingsService {
  static const String _keyShowVolumeSlider = 'player_show_volume_slider';
  static const String _keyShowStarRatings = 'player_show_star_ratings';

  static final PlayerUiSettingsService _instance =
      PlayerUiSettingsService._internal();
  factory PlayerUiSettingsService() => _instance;
  PlayerUiSettingsService._internal();

  SharedPreferences? _prefs;

  final ValueNotifier<bool> showStarRatingsNotifier = ValueNotifier(false);

  Future<void> initialize() async {
    _prefs ??= await SharedPreferences.getInstance();
    showStarRatingsNotifier.value = getShowStarRatings();
  }

  Future<void> setShowVolumeSlider(bool show) async {
    await initialize();
    await _prefs!.setBool(_keyShowVolumeSlider, show);
  }

  bool getShowVolumeSlider() {
    return _prefs?.getBool(_keyShowVolumeSlider) ?? true;
  }

  Future<void> setShowStarRatings(bool show) async {
    await initialize();
    await _prefs!.setBool(_keyShowStarRatings, show);
    showStarRatingsNotifier.value = show;
  }

  bool getShowStarRatings() {
    return _prefs?.getBool(_keyShowStarRatings) ?? false;
  }
}
