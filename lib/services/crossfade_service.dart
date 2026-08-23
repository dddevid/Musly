import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service managing track-to-track audio crossfade transitions (0s to 12s).
class CrossfadeService {
  static const String _keyCrossfadeSeconds = 'crossfade_seconds';

  static final CrossfadeService _instance = CrossfadeService._internal();
  factory CrossfadeService() => _instance;
  CrossfadeService._internal();

  SharedPreferences? _prefs;

  final ValueNotifier<int> crossfadeSecondsNotifier = ValueNotifier<int>(0);

  Future<void> initialize() async {
    _prefs ??= await SharedPreferences.getInstance();
    crossfadeSecondsNotifier.value = getCrossfadeSeconds();
  }

  int getCrossfadeSeconds() {
    return _prefs?.getInt(_keyCrossfadeSeconds) ?? 0;
  }

  Future<void> setCrossfadeSeconds(int seconds) async {
    await initialize();
    final clamped = seconds.clamp(0, 12);
    await _prefs!.setInt(_keyCrossfadeSeconds, clamped);
    crossfadeSecondsNotifier.value = clamped;
  }

  bool get isEnabled => crossfadeSecondsNotifier.value > 0;
}
