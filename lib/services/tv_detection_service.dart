import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Service responsible for detecting whether Musly is running on a Smart TV,
/// Android TV, or standard Android TV Box, and providing remote control configurations.
class TvDetectionService with ChangeNotifier {
  static final TvDetectionService _instance = TvDetectionService._internal();
  factory TvDetectionService() => _instance;
  TvDetectionService._internal();

  static const MethodChannel _channel = MethodChannel('com.devid.musly/tv_mode');

  bool _isTvMode = false;
  bool _initialized = false;

  /// Whether current device is a TV, TV Box, or running in 10-foot UI TV mode.
  bool get isTvMode => _isTvMode;

  /// Whether TV detection has run at startup.
  bool get isInitialized => _initialized;

  /// Initialize TV detection via native Android channels and display heuristics.
  Future<bool> initialize({bool? forceTvMode}) async {
    if (forceTvMode != null) {
      _isTvMode = forceTvMode;
      _initialized = true;
      notifyListeners();
      return _isTvMode;
    }

    if (kIsWeb) {
      _isTvMode = false;
      _initialized = true;
      return false;
    }

    try {
      if (Platform.isAndroid) {
        final bool? nativeTv = await _channel.invokeMethod<bool>('isTvDevice');
        if (nativeTv == true) {
          _isTvMode = true;
          _initialized = true;
          debugPrint('[TvDetectionService] 📺 Android TV / TV Box detected natively');
          notifyListeners();
          return true;
        }
      }
    } catch (e) {
      debugPrint('[TvDetectionService] Native TV check error: $e');
    }

    _initialized = true;
    notifyListeners();
    return _isTvMode;
  }

  /// Manually toggle TV mode override (e.g. from developer/display settings).
  void setTvMode(bool enabled) {
    _isTvMode = enabled;
    notifyListeners();
  }
}
