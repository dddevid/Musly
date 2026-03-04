import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../models/song.dart';

class AndroidSystemService {
  static final AndroidSystemService _instance =
      AndroidSystemService._internal();
  factory AndroidSystemService() => _instance;
  AndroidSystemService._internal();

  static const MethodChannel _methodChannel = MethodChannel(
    'com.devid.musly/android_system',
  );
  static const EventChannel _eventChannel = EventChannel(
    'com.devid.musly/android_system_events',
  );

  StreamSubscription? _eventSubscription;
  bool _isInitialized = false;

  VoidCallback? onPlay;
  VoidCallback? onPause;
  VoidCallback? onStop;
  VoidCallback? onSkipNext;
  VoidCallback? onSkipPrevious;
  VoidCallback? onHeadsetHook;
  VoidCallback? onHeadsetDoubleClick;
  Function(Duration position)? onSeekTo;

  VoidCallback? onAudioFocusGain;
  VoidCallback? onAudioFocusLoss;
  VoidCallback? onAudioFocusLossTransient;
  VoidCallback? onAudioFocusLossTransientCanDuck;

  VoidCallback? onBecomingNoisy;

  bool _showOnLockScreen = true;
  bool _handleAudioFocus = true;
  bool _handleMediaButtons = true;
  bool _showInQuickSettings = true;
  bool _colorizeNotification = true;

  bool get showOnLockScreen => _showOnLockScreen;
  bool get handleAudioFocus => _handleAudioFocus;
  bool get handleMediaButtons => _handleMediaButtons;
  bool get showInQuickSettings => _showInQuickSettings;
  bool get colorizeNotification => _colorizeNotification;

  Future<void> initialize() async {
    if (defaultTargetPlatform != TargetPlatform.android) return;
    if (_isInitialized) return;

    try {
      _eventSubscription = _eventChannel.receiveBroadcastStream().listen(
        _handleEvent,
        onError: _handleError,
      );

      await _methodChannel.invokeMethod('initialize', {
        'showOnLockScreen': _showOnLockScreen,
        'handleAudioFocus': _handleAudioFocus,
        'handleMediaButtons': _handleMediaButtons,
        'showInQuickSettings': _showInQuickSettings,
        'colorizeNotification': _colorizeNotification,
      });

      _isInitialized = true;
      debugPrint('AndroidSystemService initialized');
    } catch (e) {
      debugPrint('Error initializing AndroidSystemService: $e');
    }
  }

  void _handleEvent(dynamic event) {
    if (event is! Map) return;

    final command = event['command'] as String?;
    debugPrint('Android System event received: $command');

    switch (command) {
      case 'play':
        onPlay?.call();
        break;
      case 'pause':
        onPause?.call();
        break;
      case 'stop':
        onStop?.call();
        break;
      case 'skipNext':
        onSkipNext?.call();
        break;
      case 'skipPrevious':
        onSkipPrevious?.call();
        break;
      case 'seekTo':
        final position = event['position'] as int?;
        if (position != null) {
          onSeekTo?.call(Duration(milliseconds: position));
        }
        break;
      case 'headsetHook':
        onHeadsetHook?.call();
        break;
      case 'headsetDoubleClick':
        onHeadsetDoubleClick?.call();
        break;
      case 'audioFocusGain':
        onAudioFocusGain?.call();
        break;
      case 'audioFocusLoss':
        onAudioFocusLoss?.call();
        break;
      case 'audioFocusLossTransient':
        onAudioFocusLossTransient?.call();
        break;
      case 'audioFocusLossTransientCanDuck':
        onAudioFocusLossTransientCanDuck?.call();
        break;
      case 'becomingNoisy':
        onBecomingNoisy?.call();
        break;
    }
  }

  void _handleError(dynamic error) {
    debugPrint('Android System event error: $error');
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
    int? trackNumber,
    int? totalTracks,
    String? genre,
    int? year,
  }) async {
    if (defaultTargetPlatform != TargetPlatform.android) return;

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
        'trackNumber': trackNumber,
        'totalTracks': totalTracks,
        'genre': genre,
        'year': year,
      });
    } catch (e) {
      debugPrint('Error updating Android system playback state: $e');
    }
  }

  Future<void> updateFromSong({
    required Song song,
    required String? artworkUrl,
    required Duration duration,
    required Duration position,
    required bool isPlaying,
    int? currentIndex,
    int? queueLength,
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
      trackNumber: currentIndex != null ? currentIndex + 1 : song.track,
      totalTracks: queueLength,
      genre: song.genre,
      year: song.year,
    );
  }

  Future<void> setNotificationColor(int argbColor) async {
    if (defaultTargetPlatform != TargetPlatform.android) return;

    try {
      await _methodChannel.invokeMethod('setNotificationColor', {
        'color': argbColor,
      });
    } catch (e) {
      debugPrint('Error setting notification color: $e');
    }
  }

  Future<bool> requestAudioFocus() async {
    if (defaultTargetPlatform != TargetPlatform.android) return true;

    try {
      final result = await _methodChannel.invokeMethod<bool>(
        'requestAudioFocus',
      );
      return result ?? false;
    } catch (e) {
      debugPrint('Error requesting audio focus: $e');
      return false;
    }
  }

  Future<void> abandonAudioFocus() async {
    if (defaultTargetPlatform != TargetPlatform.android) return;

    try {
      await _methodChannel.invokeMethod('abandonAudioFocus');
    } catch (e) {
      debugPrint('Error abandoning audio focus: $e');
    }
  }

  Future<void> updateSettings({
    bool? showOnLockScreen,
    bool? handleAudioFocus,
    bool? handleMediaButtons,
    bool? showInQuickSettings,
    bool? colorizeNotification,
  }) async {
    if (defaultTargetPlatform != TargetPlatform.android) return;

    if (showOnLockScreen != null) _showOnLockScreen = showOnLockScreen;
    if (handleAudioFocus != null) _handleAudioFocus = handleAudioFocus;
    if (handleMediaButtons != null) _handleMediaButtons = handleMediaButtons;
    if (showInQuickSettings != null) _showInQuickSettings = showInQuickSettings;
    if (colorizeNotification != null)
      _colorizeNotification = colorizeNotification;

    try {
      await _methodChannel.invokeMethod('updateSettings', {
        'showOnLockScreen': _showOnLockScreen,
        'handleAudioFocus': _handleAudioFocus,
        'handleMediaButtons': _handleMediaButtons,
        'showInQuickSettings': _showInQuickSettings,
        'colorizeNotification': _colorizeNotification,
      });
    } catch (e) {
      debugPrint('Error updating Android system settings: $e');
    }
  }

  Future<Map<String, dynamic>> getSystemInfo() async {
    if (defaultTargetPlatform != TargetPlatform.android) {
      return {};
    }

    try {
      final result = await _methodChannel.invokeMethod<Map>('getSystemInfo');
      return Map<String, dynamic>.from(result ?? {});
    } catch (e) {
      debugPrint('Error getting system info: $e');
      return {};
    }
  }

  Future<bool> isSamsungDevice() async {
    if (defaultTargetPlatform != TargetPlatform.android) return false;

    try {
      final result = await _methodChannel.invokeMethod<bool>('isSamsungDevice');
      return result ?? false;
    } catch (e) {
      debugPrint('Error checking Samsung device: $e');
      return false;
    }
  }

  Future<int> getAndroidSdkVersion() async {
    if (defaultTargetPlatform != TargetPlatform.android) return 0;

    try {
      final result = await _methodChannel.invokeMethod<int>(
        'getAndroidSdkVersion',
      );
      return result ?? 0;
    } catch (e) {
      debugPrint('Error getting Android SDK version: $e');
      return 0;
    }
  }

  Future<void> setRemotePlayback({
    required bool isRemote,
    int volume = 50,
  }) async {
    if (defaultTargetPlatform != TargetPlatform.android) return;
    try {
      await _methodChannel.invokeMethod('setRemotePlayback', {
        'isRemote': isRemote,
        'volume': volume,
      });
    } catch (e) {
      debugPrint('Error setting remote playback: $e');
    }
  }

  Future<void> updateRemoteVolume(int volume) async {
    if (defaultTargetPlatform != TargetPlatform.android) return;
    try {
      await _methodChannel.invokeMethod('updateRemoteVolume', {
        'volume': volume,
      });
    } catch (e) {
      debugPrint('Error updating remote volume: $e');
    }
  }

  Future<void> dispose() async {
    if (defaultTargetPlatform != TargetPlatform.android) return;

    _eventSubscription?.cancel();
    _isInitialized = false;
    try {
      await _methodChannel.invokeMethod('dispose');
    } catch (e) {
      debugPrint('Error disposing AndroidSystemService: $e');
    }
  }
}
