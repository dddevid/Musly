import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';

enum ReplayGainMode {
  
  off,

  track,

  album,
}

class ReplayGainService {
  static const String _keyReplayGainMode = 'replay_gain_mode';
  static const String _keyPreampGain = 'replay_gain_preamp';
  static const String _keyPreventClipping = 'replay_gain_prevent_clipping';
  static const String _keyFallbackGain = 'replay_gain_fallback';

  static final ReplayGainService _instance = ReplayGainService._internal();
  factory ReplayGainService() => _instance;
  ReplayGainService._internal();

  SharedPreferences? _prefs;

  Future<void> initialize() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  ReplayGainMode getMode() {
    final modeIndex = _prefs?.getInt(_keyReplayGainMode) ?? 0;
    return ReplayGainMode.values[modeIndex.clamp(
      0,
      ReplayGainMode.values.length - 1,
    )];
  }

  Future<void> setMode(ReplayGainMode mode) async {
    await initialize();
    await _prefs!.setInt(_keyReplayGainMode, mode.index);
  }

  double getPreampGain() {
    return _prefs?.getDouble(_keyPreampGain) ?? 0.0;
  }

  Future<void> setPreampGain(double gain) async {
    await initialize();
    await _prefs!.setDouble(_keyPreampGain, gain.clamp(-15.0, 15.0));
  }

  bool getPreventClipping() {
    return _prefs?.getBool(_keyPreventClipping) ?? true;
  }

  Future<void> setPreventClipping(bool prevent) async {
    await initialize();
    await _prefs!.setBool(_keyPreventClipping, prevent);
  }

  double getFallbackGain() {
    return _prefs?.getDouble(_keyFallbackGain) ?? -6.0;
  }

  Future<void> setFallbackGain(double gain) async {
    await initialize();
    await _prefs!.setDouble(_keyFallbackGain, gain.clamp(-15.0, 0.0));
  }

  double calculateVolumeMultiplier({
    double? trackGain,
    double? albumGain,
    double? trackPeak,
    double? albumPeak,
  }) {
    final mode = getMode();

    if (mode == ReplayGainMode.off) {
      return 1.0;
    }

    double? gainDb;
    double? peak;

    if (mode == ReplayGainMode.album && albumGain != null) {
      gainDb = albumGain;
      peak = albumPeak;
    } else if (trackGain != null) {
      
      gainDb = trackGain;
      peak = trackPeak;
    }

    if (gainDb == null) {
      gainDb = getFallbackGain();
      peak = null;
    }

    final preamp = getPreampGain();
    final totalGainDb = gainDb + preamp;

    double multiplier = pow(10, totalGainDb / 20).toDouble();

    if (getPreventClipping() && peak != null && peak > 0) {
      
      final maxMultiplier = 1.0 / peak;
      multiplier = min(multiplier, maxMultiplier);
    }

    return multiplier.clamp(0.0, 1.0);
  }

  String getModeDescription() {
    switch (getMode()) {
      case ReplayGainMode.off:
        return 'Off';
      case ReplayGainMode.track:
        return 'Track';
      case ReplayGainMode.album:
        return 'Album';
    }
  }
}
