import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';

/// ReplayGain mode for volume normalization
enum ReplayGainMode {
  /// ReplayGain is disabled
  off,

  /// Use track gain (normalize each track individually)
  track,

  /// Use album gain (normalize to album level, preserving relative track loudness)
  album,
}

/// Service for managing ReplayGain settings and calculating volume adjustments.
///
/// ReplayGain is a standard for normalizing audio playback volume based on
/// loudness metadata stored in audio files. This helps prevent songs from
/// being too loud or too quiet compared to each other.
class ReplayGainService {
  static const String _keyReplayGainMode = 'replay_gain_mode';
  static const String _keyPreampGain = 'replay_gain_preamp';
  static const String _keyPreventClipping = 'replay_gain_prevent_clipping';
  static const String _keyFallbackGain = 'replay_gain_fallback';

  static final ReplayGainService _instance = ReplayGainService._internal();
  factory ReplayGainService() => _instance;
  ReplayGainService._internal();

  SharedPreferences? _prefs;

  /// Initialize the service
  Future<void> initialize() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  /// Get the current ReplayGain mode
  ReplayGainMode getMode() {
    final modeIndex = _prefs?.getInt(_keyReplayGainMode) ?? 0;
    return ReplayGainMode.values[modeIndex.clamp(
      0,
      ReplayGainMode.values.length - 1,
    )];
  }

  /// Set the ReplayGain mode
  Future<void> setMode(ReplayGainMode mode) async {
    await initialize();
    await _prefs!.setInt(_keyReplayGainMode, mode.index);
  }

  /// Get the preamp gain in dB (applied on top of ReplayGain)
  /// Range: -15.0 to +15.0 dB, default: 0.0
  double getPreampGain() {
    return _prefs?.getDouble(_keyPreampGain) ?? 0.0;
  }

  /// Set the preamp gain in dB
  Future<void> setPreampGain(double gain) async {
    await initialize();
    await _prefs!.setDouble(_keyPreampGain, gain.clamp(-15.0, 15.0));
  }

  /// Get whether to prevent clipping (limit gain to avoid distortion)
  bool getPreventClipping() {
    return _prefs?.getBool(_keyPreventClipping) ?? true;
  }

  /// Set whether to prevent clipping
  Future<void> setPreventClipping(bool prevent) async {
    await initialize();
    await _prefs!.setBool(_keyPreventClipping, prevent);
  }

  /// Get the fallback gain in dB (used when no ReplayGain data is available)
  /// Range: -15.0 to 0.0 dB, default: -6.0 dB (a safe reduction for loud tracks)
  double getFallbackGain() {
    return _prefs?.getDouble(_keyFallbackGain) ?? -6.0;
  }

  /// Set the fallback gain in dB
  Future<void> setFallbackGain(double gain) async {
    await initialize();
    await _prefs!.setDouble(_keyFallbackGain, gain.clamp(-15.0, 0.0));
  }

  /// Calculate the volume multiplier for a song based on ReplayGain data.
  ///
  /// [trackGain] - The track's ReplayGain value in dB (from song metadata)
  /// [albumGain] - The album's ReplayGain value in dB (from song metadata)
  /// [trackPeak] - The track's peak value (0.0 to 1.0+, from song metadata)
  /// [albumPeak] - The album's peak value (0.0 to 1.0+, from song metadata)
  ///
  /// Returns a volume multiplier (0.0 to 1.0) to apply to playback.
  double calculateVolumeMultiplier({
    double? trackGain,
    double? albumGain,
    double? trackPeak,
    double? albumPeak,
  }) {
    final mode = getMode();

    // If ReplayGain is disabled, return full volume
    if (mode == ReplayGainMode.off) {
      return 1.0;
    }

    // Select the appropriate gain value based on mode
    double? gainDb;
    double? peak;

    if (mode == ReplayGainMode.album && albumGain != null) {
      gainDb = albumGain;
      peak = albumPeak;
    } else if (trackGain != null) {
      // Use track gain, or fallback to track if album mode but no album gain
      gainDb = trackGain;
      peak = trackPeak;
    }

    // If no ReplayGain data available, use fallback gain
    if (gainDb == null) {
      gainDb = getFallbackGain();
      peak = null;
    }

    // Add preamp gain
    final preamp = getPreampGain();
    final totalGainDb = gainDb + preamp;

    // Convert dB to linear multiplier: multiplier = 10^(dB/20)
    double multiplier = pow(10, totalGainDb / 20).toDouble();

    // Prevent clipping if enabled and peak data is available
    if (getPreventClipping() && peak != null && peak > 0) {
      // Calculate the maximum multiplier that won't cause clipping
      final maxMultiplier = 1.0 / peak;
      multiplier = min(multiplier, maxMultiplier);
    }

    // Clamp to valid range (0.0 to 1.0 - we never amplify above original)
    // Note: ReplayGain can theoretically increase volume, but for safety
    // we cap at 1.0 to prevent any clipping on the output
    return multiplier.clamp(0.0, 1.0);
  }

  /// Get a human-readable description of the current mode
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
