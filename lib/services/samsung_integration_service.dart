import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../models/song.dart';

class SamsungFeatures {
  final bool isEdgePanelSupported;
  final bool isEdgeLightingSupported;
  final bool isGoodLockSupported;
  final bool isDexSupported;
  final bool isDexMode;
  final bool isSamsungMusicInstalled;
  final bool isOneUIVersion;
  final String oneUIVersion;
  final bool isRoutinesSupported;

  SamsungFeatures({
    required this.isEdgePanelSupported,
    required this.isEdgeLightingSupported,
    required this.isGoodLockSupported,
    required this.isDexSupported,
    required this.isDexMode,
    required this.isSamsungMusicInstalled,
    required this.isOneUIVersion,
    required this.oneUIVersion,
    required this.isRoutinesSupported,
  });

  factory SamsungFeatures.empty() {
    return SamsungFeatures(
      isEdgePanelSupported: false,
      isEdgeLightingSupported: false,
      isGoodLockSupported: false,
      isDexSupported: false,
      isDexMode: false,
      isSamsungMusicInstalled: false,
      isOneUIVersion: false,
      oneUIVersion: '',
      isRoutinesSupported: false,
    );
  }

  factory SamsungFeatures.fromMap(Map<String, dynamic> map) {
    return SamsungFeatures(
      isEdgePanelSupported: map['isEdgePanelSupported'] as bool? ?? false,
      isEdgeLightingSupported: map['isEdgeLightingSupported'] as bool? ?? false,
      isGoodLockSupported: map['isGoodLockSupported'] as bool? ?? false,
      isDexSupported: map['isDexSupported'] as bool? ?? false,
      isDexMode: map['isDexMode'] as bool? ?? false,
      isSamsungMusicInstalled: map['isSamsungMusicInstalled'] as bool? ?? false,
      isOneUIVersion: map['isOneUIVersion'] as bool? ?? false,
      oneUIVersion: map['oneUIVersion'] as String? ?? '',
      isRoutinesSupported: map['isRoutinesSupported'] as bool? ?? false,
    );
  }

  @override
  String toString() {
    return 'SamsungFeatures(edgePanel: $isEdgePanelSupported, edgeLighting: $isEdgeLightingSupported, '
        'dex: $isDexSupported/$isDexMode, oneUI: $oneUIVersion)';
  }
}

class SamsungIntegrationService {
  static final SamsungIntegrationService _instance =
      SamsungIntegrationService._internal();
  factory SamsungIntegrationService() => _instance;
  SamsungIntegrationService._internal();

  static const MethodChannel _methodChannel = MethodChannel(
    'com.devid.musly/samsung_integration',
  );
  static const EventChannel _eventChannel = EventChannel(
    'com.devid.musly/samsung_integration_events',
  );

  StreamSubscription? _eventSubscription;
  bool _isInitialized = false;
  bool _isSamsungDevice = false;
  SamsungFeatures _features = SamsungFeatures.empty();

  VoidCallback? onDexModeEnter;
  VoidCallback? onDexModeExit;
  VoidCallback? onEdgePanelOpened;
  Function(String action)? onEdgePanelAction;
  VoidCallback? onRoutineTrigger;

  bool get isSamsungDevice => _isSamsungDevice;
  SamsungFeatures get features => _features;
  bool get isDexMode => _features.isDexMode;
  bool get isEdgePanelSupported => _features.isEdgePanelSupported;

  Future<void> initialize() async {
    if (defaultTargetPlatform != TargetPlatform.android) return;
    if (_isInitialized) return;

    try {
      final isSamsung = await _methodChannel.invokeMethod<bool>(
        'isSamsungDevice',
      );
      _isSamsungDevice = isSamsung ?? false;

      if (!_isSamsungDevice) {
        debugPrint('Not a Samsung device, skipping Samsung integration');
        return;
      }

      _eventSubscription = _eventChannel.receiveBroadcastStream().listen(
        _handleEvent,
        onError: _handleError,
      );

      final featuresMap = await _methodChannel.invokeMethod<Map>('initialize');
      if (featuresMap != null) {
        _features = SamsungFeatures.fromMap(
          Map<String, dynamic>.from(featuresMap),
        );
      }

      _isInitialized = true;
      debugPrint('SamsungIntegrationService initialized: $_features');
    } catch (e) {
      debugPrint('Error initializing SamsungIntegrationService: $e');
    }
  }

  void _handleEvent(dynamic event) {
    if (event is! Map) return;

    final eventType = event['event'] as String?;
    debugPrint('Samsung event received: $eventType');

    switch (eventType) {
      case 'dexModeEnter':
        _features = SamsungFeatures(
          isEdgePanelSupported: _features.isEdgePanelSupported,
          isEdgeLightingSupported: _features.isEdgeLightingSupported,
          isGoodLockSupported: _features.isGoodLockSupported,
          isDexSupported: _features.isDexSupported,
          isDexMode: true,
          isSamsungMusicInstalled: _features.isSamsungMusicInstalled,
          isOneUIVersion: _features.isOneUIVersion,
          oneUIVersion: _features.oneUIVersion,
          isRoutinesSupported: _features.isRoutinesSupported,
        );
        onDexModeEnter?.call();
        break;
      case 'dexModeExit':
        _features = SamsungFeatures(
          isEdgePanelSupported: _features.isEdgePanelSupported,
          isEdgeLightingSupported: _features.isEdgeLightingSupported,
          isGoodLockSupported: _features.isGoodLockSupported,
          isDexSupported: _features.isDexSupported,
          isDexMode: false,
          isSamsungMusicInstalled: _features.isSamsungMusicInstalled,
          isOneUIVersion: _features.isOneUIVersion,
          oneUIVersion: _features.oneUIVersion,
          isRoutinesSupported: _features.isRoutinesSupported,
        );
        onDexModeExit?.call();
        break;
      case 'edgePanelOpened':
        onEdgePanelOpened?.call();
        break;
      case 'edgePanelAction':
        final action = event['action'] as String?;
        if (action != null) {
          onEdgePanelAction?.call(action);
        }
        break;
      case 'routineTrigger':
        onRoutineTrigger?.call();
        break;
    }
  }

  void _handleError(dynamic error) {
    debugPrint('Samsung event error: $error');
  }

  Future<void> updatePlaybackState({
    required String? songId,
    required String title,
    required String artist,
    required String album,
    String? artworkUrl,
    required Duration duration,
    required Duration position,
    required bool isPlaying,
  }) async {
    if (defaultTargetPlatform != TargetPlatform.android) return;
    if (!_isSamsungDevice) return;

    try {
      await _methodChannel.invokeMethod('updatePlaybackState', {
        'songId': songId,
        'title': title,
        'artist': artist,
        'album': album,
        'artworkUrl': artworkUrl,
        'duration': duration.inMilliseconds,
        'position': position.inMilliseconds,
        'playing': isPlaying,
      });
    } catch (e) {
      debugPrint('Error updating Samsung playback state: $e');
    }
  }

  Future<void> updateFromSong({
    required Song song,
    required String? artworkUrl,
    required Duration duration,
    required Duration position,
    required bool isPlaying,
  }) async {
    await updatePlaybackState(
      songId: song.id,
      title: song.title,
      artist: song.artist ?? 'Unknown Artist',
      album: song.album ?? 'Unknown Album',
      artworkUrl: artworkUrl,
      duration: duration,
      position: position,
      isPlaying: isPlaying,
    );
  }

  Future<void> showEdgeLighting({
    required String title,
    required String subtitle,
    int? color,
    int durationMs = 3000,
  }) async {
    if (defaultTargetPlatform != TargetPlatform.android) return;
    if (!_isSamsungDevice || !_features.isEdgeLightingSupported) return;

    try {
      await _methodChannel.invokeMethod('showEdgeLighting', {
        'title': title,
        'subtitle': subtitle,
        'color': color,
        'durationMs': durationMs,
      });
    } catch (e) {
      debugPrint('Error showing Edge Lighting: $e');
    }
  }

  Future<void> updateEdgePanel({
    required String title,
    required String artist,
    String? artworkUrl,
    required bool isPlaying,
  }) async {
    if (defaultTargetPlatform != TargetPlatform.android) return;
    if (!_isSamsungDevice || !_features.isEdgePanelSupported) return;

    try {
      await _methodChannel.invokeMethod('updateEdgePanel', {
        'title': title,
        'artist': artist,
        'artworkUrl': artworkUrl,
        'playing': isPlaying,
      });
    } catch (e) {
      debugPrint('Error updating Edge Panel: $e');
    }
  }

  Future<bool> registerWithRoutines() async {
    if (defaultTargetPlatform != TargetPlatform.android) return false;
    if (!_isSamsungDevice || !_features.isRoutinesSupported) return false;

    try {
      final result = await _methodChannel.invokeMethod<bool>(
        'registerWithRoutines',
      );
      return result ?? false;
    } catch (e) {
      debugPrint('Error registering with Routines: $e');
      return false;
    }
  }

  Future<void> optimizeForDex(bool enable) async {
    if (defaultTargetPlatform != TargetPlatform.android) return;
    if (!_isSamsungDevice || !_features.isDexSupported) return;

    try {
      await _methodChannel.invokeMethod('optimizeForDex', {'enable': enable});
    } catch (e) {
      debugPrint('Error optimizing for DeX: $e');
    }
  }

  Future<Map<String, dynamic>> getSamsungMusicCompatibility() async {
    if (defaultTargetPlatform != TargetPlatform.android) {
      return {'installed': false};
    }
    if (!_isSamsungDevice) {
      return {'installed': false};
    }

    try {
      final result = await _methodChannel.invokeMethod<Map>(
        'getSamsungMusicCompatibility',
      );
      return Map<String, dynamic>.from(result ?? {'installed': false});
    } catch (e) {
      debugPrint('Error getting Samsung Music compatibility: $e');
      return {'installed': false};
    }
  }

  Future<bool> registerAsDefaultMusicPlayer() async {
    if (defaultTargetPlatform != TargetPlatform.android) return false;
    if (!_isSamsungDevice) return false;

    try {
      final result = await _methodChannel.invokeMethod<bool>(
        'registerAsDefaultMusicPlayer',
      );
      return result ?? false;
    } catch (e) {
      debugPrint('Error registering as default music player: $e');
      return false;
    }
  }

  Future<void> configureSamsungAudio({
    bool? adaptiveSound,
    bool? dolbyAtmos,
    bool? uhqUpscaler,
  }) async {
    if (defaultTargetPlatform != TargetPlatform.android) return;
    if (!_isSamsungDevice) return;

    try {
      await _methodChannel.invokeMethod('configureSamsungAudio', {
        if (adaptiveSound != null) 'adaptiveSound': adaptiveSound,
        if (dolbyAtmos != null) 'dolbyAtmos': dolbyAtmos,
        if (uhqUpscaler != null) 'uhqUpscaler': uhqUpscaler,
      });
    } catch (e) {
      debugPrint('Error configuring Samsung audio: $e');
    }
  }

  Future<Map<String, dynamic>> getSamsungAudioSettings() async {
    if (defaultTargetPlatform != TargetPlatform.android) {
      return {};
    }
    if (!_isSamsungDevice) {
      return {};
    }

    try {
      final result = await _methodChannel.invokeMethod<Map>(
        'getSamsungAudioSettings',
      );
      return Map<String, dynamic>.from(result ?? {});
    } catch (e) {
      debugPrint('Error getting Samsung audio settings: $e');
      return {};
    }
  }

  Future<void> updateSoundAssistant({
    required String title,
    required String artist,
    String? artworkUrl,
    required bool isPlaying,
  }) async {
    if (defaultTargetPlatform != TargetPlatform.android) return;
    if (!_isSamsungDevice) return;

    try {
      await _methodChannel.invokeMethod('updateSoundAssistant', {
        'title': title,
        'artist': artist,
        'artworkUrl': artworkUrl,
        'playing': isPlaying,
      });
    } catch (e) {
      debugPrint('Error updating Sound Assistant: $e');
    }
  }

  Future<void> dispose() async {
    if (defaultTargetPlatform != TargetPlatform.android) return;

    _eventSubscription?.cancel();
    _isInitialized = false;
    try {
      await _methodChannel.invokeMethod('dispose');
    } catch (e) {
      debugPrint('Error disposing SamsungIntegrationService: $e');
    }
  }
}
