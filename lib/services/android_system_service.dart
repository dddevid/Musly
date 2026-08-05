import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../models/song.dart';

/// Result of a native audio-focus request.
///
/// [delayed] means the OS will asynchronously deliver focus later (fired as
/// an `onAudioFocusGain` event) once the current holder yields — common when
/// audio routing needs to be renegotiated, e.g. over Android Auto.
enum AudioFocusResult { granted, delayed, failed }

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
  Function(Duration interval)? onSeekForward;
  Function(Duration interval)? onSeekBackward;

  VoidCallback? onAudioFocusGain;
  VoidCallback? onAudioFocusLoss;
  VoidCallback? onAudioFocusLossTransient;
  VoidCallback? onAudioFocusLossTransientCanDuck;

  VoidCallback? onBecomingNoisy;

  bool _showOnLockScreen = true;
  // On Android this plugin is the single source of truth for audio focus
  // (audio_session's own focus path is bypassed — see audio_handler.dart).
  // On iOS this flag is accepted but ignored by iOSSystemPlugin, which
  // always activates/deactivates AVAudioSession unconditionally.
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
    if (defaultTargetPlatform != TargetPlatform.android &&
        defaultTargetPlatform != TargetPlatform.iOS) {
      return;
    }
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
      debugPrint(
        defaultTargetPlatform == TargetPlatform.iOS
            ? 'iOSSystemPlugin initialized'
            : 'AndroidSystemService initialized',
      );
    } catch (e) {
      debugPrint('Error initializing system service: $e');
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
      case 'seekForward':
        final fwdInterval = event['interval'] as int?;
        onSeekForward?.call(Duration(milliseconds: fwdInterval ?? 15000));
        break;
      case 'seekBackward':
        final bwdInterval = event['interval'] as int?;
        onSeekBackward?.call(Duration(milliseconds: bwdInterval ?? 15000));
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
    // On iOS, MPNowPlayingInfoCenter is maintained by the audio_service plugin
    // (MuslyAudioHandler.updateNowPlaying).  Calling iOSSystemPlugin here as
    // well would write conflicting data to the same API, so we bail out early.
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return;
    }

    if (defaultTargetPlatform != TargetPlatform.android) {
      return;
    }

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
    if (defaultTargetPlatform != TargetPlatform.android) {
      return;
    }

    try {
      await _methodChannel.invokeMethod('setNotificationColor', {
        'color': argbColor,
      });
    } catch (e) {
      debugPrint('Error setting notification color: $e');
    }
  }

  /// Requests real Android audio focus (iOS: activates the audio session).
  /// Returns [AudioFocusResult.delayed] when the OS will grant focus later —
  /// callers must wait for [onAudioFocusGain] before actually starting audio.
  /// On error, fails closed to [AudioFocusResult.failed] rather than assuming
  /// success.
  Future<AudioFocusResult> requestAudioFocus() async {
    if (defaultTargetPlatform != TargetPlatform.android &&
        defaultTargetPlatform != TargetPlatform.iOS) {
      return AudioFocusResult.granted;
    }

    try {
      final result = await _methodChannel.invokeMethod('requestAudioFocus');
      if (result is String) {
        switch (result) {
          case 'granted':
            return AudioFocusResult.granted;
          case 'delayed':
            return AudioFocusResult.delayed;
          default:
            return AudioFocusResult.failed;
        }
      }
      // iOSSystemPlugin returns a raw bool.
      if (result is bool) {
        return result ? AudioFocusResult.granted : AudioFocusResult.failed;
      }
      return AudioFocusResult.failed;
    } catch (e) {
      debugPrint('Error requesting audio focus: $e');
      return AudioFocusResult.failed;
    }
  }

  Future<void> abandonAudioFocus() async {
    if (defaultTargetPlatform != TargetPlatform.android &&
        defaultTargetPlatform != TargetPlatform.iOS) {
      return;
    }

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
    if (defaultTargetPlatform != TargetPlatform.android &&
        defaultTargetPlatform != TargetPlatform.iOS) {
      return;
    }

    if (showOnLockScreen != null) _showOnLockScreen = showOnLockScreen;
    if (handleAudioFocus != null) _handleAudioFocus = handleAudioFocus;
    if (handleMediaButtons != null) _handleMediaButtons = handleMediaButtons;
    if (showInQuickSettings != null) _showInQuickSettings = showInQuickSettings;
    if (colorizeNotification != null) {
      _colorizeNotification = colorizeNotification;
    }

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
    if (defaultTargetPlatform != TargetPlatform.android &&
        defaultTargetPlatform != TargetPlatform.iOS) {
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

  Future<void> dispose() async {
    if (defaultTargetPlatform != TargetPlatform.android) {
      return;
    }

    _eventSubscription?.cancel();
    _isInitialized = false;
    try {
      await _methodChannel.invokeMethod('dispose');
    } catch (e) {
      debugPrint('Error disposing AndroidSystemService: $e');
    }
  }
}
