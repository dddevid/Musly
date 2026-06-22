import 'dart:io';
import 'package:flutter/services.dart';

/// Detects Dolby Atmos device support and exposes it to the UI.
class DolbyAtmosService {
  static const _channel = MethodChannel('com.devid.musly/dolbyatmos');

  bool? _supported;
  bool? _enabled;

  /// Whether the current device supports Dolby Atmos audio playback.
  /// Returns null until the first platform check completes.
  bool? get isSupported => _supported;

  /// Whether Dolby Atmos is currently enabled on the device.
  bool? get isEnabled => _enabled;

  /// Query the platform for Dolby Atmos capabilities.
  /// Safe to call multiple times; caches the result.
  Future<void> checkDeviceSupport() async {
    if (!Platform.isAndroid) {
      _supported = false;
      _enabled = false;
      return;
    }
    try {
      final supported = await _channel.invokeMethod<bool>('isSupported');
      final enabled = await _channel.invokeMethod<bool>('isEnabled');
      _supported = supported ?? false;
      _enabled = enabled ?? false;
    } catch (e) {
      _supported = false;
      _enabled = false;
    }
  }
}
