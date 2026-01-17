import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Bitrate options for transcoding
class TranscodeBitrate {
  static const int original = 0; // No transcoding
  static const int kbps64 = 64;
  static const int kbps128 = 128;
  static const int kbps192 = 192;
  static const int kbps256 = 256;
  static const int kbps320 = 320;

  static const List<int> options = [
    original,
    kbps64,
    kbps128,
    kbps192,
    kbps256,
    kbps320,
  ];

  static String getLabel(int bitrate) {
    if (bitrate == original) return 'Original (No Transcoding)';
    return '${bitrate} kbps';
  }
}

/// Transcoding format options
class TranscodeFormat {
  static const String original = 'raw'; // No transcoding
  static const String mp3 = 'mp3';
  static const String opus = 'opus';
  static const String aac = 'aac';

  static const List<String> options = [original, mp3, opus, aac];

  static String getLabel(String format) {
    switch (format) {
      case original:
        return 'Original';
      case mp3:
        return 'MP3';
      case opus:
        return 'Opus';
      case aac:
        return 'AAC';
      default:
        return format.toUpperCase();
    }
  }
}

/// Connection type for transcoding settings
enum ConnectionType { wifi, mobile }

/// Service for managing transcoding settings
class TranscodingService extends ChangeNotifier {
  static const String _wifiBitrateKey = 'transcoding_wifi_bitrate';
  static const String _mobileBitrateKey = 'transcoding_mobile_bitrate';
  static const String _formatKey = 'transcoding_format';
  static const String _enabledKey = 'transcoding_enabled';
  static const String _connectionTypeKey = 'transcoding_connection_type';

  int _wifiBitrate = TranscodeBitrate.original;
  int _mobileBitrate = TranscodeBitrate.kbps192;
  String _format = TranscodeFormat.mp3;
  bool _enabled = false;
  ConnectionType _currentConnectionType = ConnectionType.wifi;

  int get wifiBitrate => _wifiBitrate;
  int get mobileBitrate => _mobileBitrate;
  String get format => _format;
  bool get enabled => _enabled;
  ConnectionType get currentConnectionType => _currentConnectionType;

  TranscodingService() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _wifiBitrate = prefs.getInt(_wifiBitrateKey) ?? TranscodeBitrate.original;
    _mobileBitrate =
        prefs.getInt(_mobileBitrateKey) ?? TranscodeBitrate.kbps192;
    _format = prefs.getString(_formatKey) ?? TranscodeFormat.mp3;
    _enabled = prefs.getBool(_enabledKey) ?? false;
    final connectionIndex = prefs.getInt(_connectionTypeKey) ?? 0;
    _currentConnectionType = ConnectionType.values[connectionIndex];
    notifyListeners();
  }

  Future<void> setEnabled(bool value) async {
    _enabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, value);
    notifyListeners();
  }

  Future<void> setWifiBitrate(int bitrate) async {
    _wifiBitrate = bitrate;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_wifiBitrateKey, bitrate);
    notifyListeners();
  }

  Future<void> setMobileBitrate(int bitrate) async {
    _mobileBitrate = bitrate;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_mobileBitrateKey, bitrate);
    notifyListeners();
  }

  Future<void> setFormat(String format) async {
    _format = format;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_formatKey, format);
    notifyListeners();
  }

  Future<void> setConnectionType(ConnectionType type) async {
    _currentConnectionType = type;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_connectionTypeKey, type.index);
    notifyListeners();
  }

  /// Get the current bitrate based on connection type
  int? getCurrentBitrate() {
    if (!_enabled) return null;

    final bitrate = _currentConnectionType == ConnectionType.wifi
        ? _wifiBitrate
        : _mobileBitrate;

    return bitrate == TranscodeBitrate.original ? null : bitrate;
  }

  /// Get the current format (null means no transcoding)
  String? getCurrentFormat() {
    if (!_enabled) return null;
    return _format == TranscodeFormat.original ? null : _format;
  }
}
