import 'dart:async';
import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';

/// iOS/background-service audio handler.
///
/// Wraps [AudioPlayer] (just_audio) and bridges the [audio_service] protocol
/// so that:
///   • iOS lock-screen controls (play/pause/skip/seek) call back to
///     [PlayerProvider] without going through the custom iOSSystemPlugin
///     MPRemoteCommandCenter registration.
///   • [MPNowPlayingInfoCenter] is updated automatically by the audio_service
///     iOS plugin whenever [mediaItem] changes.
///   • On Android the existing notification/media-session stack is kept; the
///     handler provides a unified Dart abstraction over the raw [AudioPlayer].
///
/// [PlayerProvider] receives this handler and uses [player] directly for all
/// just_audio operations.  It calls [updateNowPlaying] whenever the current
/// song changes to push metadata up to the lock screen / Control Center.
class MuslyAudioHandler extends BaseAudioHandler with SeekHandler {
  final AudioPlayer _player = AudioPlayer();
  static const _pitchChannel = MethodChannel('com.devid.musly/pitch');

  /// Exposed so [PlayerProvider] can still call setUrl, play, pause, seek, etc.
  AudioPlayer get player => _player;

  // ---------------------------------------------------------------------------
  // Callbacks wired by PlayerProvider AFTER construction.
  // These ensure lock-screen / AirPods / Bluetooth commands reach the provider.
  // ---------------------------------------------------------------------------
  Future<void> Function()? onPlay;
  Future<void> Function()? onPause;
  Future<void> Function()? onStop;
  Future<void> Function()? onSkipNext;
  Future<void> Function()? onSkipPrevious;
  Future<void> Function(Duration)? onSeekTo;
  Future<void> Function()? onTogglePlayPause;

  MuslyAudioHandler() {
    // Forward just_audio playback events → audio_service playback state.
    // This drives the iOS Control Center / lock screen widget and the
    // Android media notification automatically.
    _player.playbackEventStream
        .map(_buildPlaybackState)
        .pipe(playbackState);
  }

  // ---------------------------------------------------------------------------
  // audio_service protocol — called by the system (lock screen, headphones …)
  // ---------------------------------------------------------------------------

  @override
  Future<void> play() => onPlay?.call() ?? _player.play();

  @override
  Future<void> pause() => onPause?.call() ?? _player.pause();

  @override
  Future<void> stop() async {
    await (onStop?.call() ?? _player.stop());
    await super.stop();
  }

  @override
  Future<void> skipToNext() => onSkipNext?.call() ?? Future.value();

  @override
  Future<void> skipToPrevious() => onSkipPrevious?.call() ?? Future.value();

  @override
  Future<void> seek(Duration position) =>
      onSeekTo?.call(position) ?? _player.seek(position);

  @override
  Future<void> click([MediaButton button = MediaButton.media]) async {
    switch (button) {
      case MediaButton.next:
        await skipToNext();
      case MediaButton.previous:
        await skipToPrevious();
      case MediaButton.media:
        await (onTogglePlayPause?.call() ??
            (_player.playing ? _player.pause() : _player.play()));
    }
  }

  // ---------------------------------------------------------------------------
  // Called by PlayerProvider to push metadata to the lock screen.
  // ---------------------------------------------------------------------------

  void updateNowPlaying({
    required String id,
    required String title,
    String? artist,
    String? album,
    String? artworkUrl,
    Duration? duration,
  }) {
    Uri? artUri;
    if (artworkUrl != null) {
      artUri = Uri.tryParse(artworkUrl);
    }
    mediaItem.add(
      MediaItem(
        id: id,
        title: title,
        artist: artist,
        album: album,
        artUri: artUri,
        duration: duration,
      ),
    );
  }

  void clearNowPlaying() {
    mediaItem.add(const MediaItem(id: '', title: ''));
  }

  // ---------------------------------------------------------------------------
  // Internal: map just_audio state → audio_service PlaybackState
  // ---------------------------------------------------------------------------

  PlaybackState _buildPlaybackState(PlaybackEvent event) {
    final processingStateMap = {
      ProcessingState.idle: AudioProcessingState.idle,
      ProcessingState.loading: AudioProcessingState.loading,
      ProcessingState.buffering: AudioProcessingState.buffering,
      ProcessingState.ready: AudioProcessingState.ready,
      ProcessingState.completed: AudioProcessingState.completed,
    };

    return PlaybackState(
      controls: [
        MediaControl.skipToPrevious,
        if (_player.playing) MediaControl.pause else MediaControl.play,
        MediaControl.skipToNext,
      ],
      systemActions: const {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
      },
      androidCompactActionIndices: const [0, 1, 2],
      processingState:
          processingStateMap[_player.processingState] ??
          AudioProcessingState.idle,
      playing: _player.playing,
      updatePosition: _player.position,
      bufferedPosition: _player.bufferedPosition,
      speed: _player.speed,
      queueIndex: event.currentIndex,
    );
  }

  // ---------------------------------------------------------------------------

  /// Propagates pitch changes to the native player via platform channel.
  Future<void> setPitch(double pitch) async {
    try {
      await _pitchChannel.invokeMethod('setPitch', {
        'pitch': pitch,
        'speed': _player.speed,
      });
    } catch (e) {
      debugPrint('PitchPlugin setPitch error: $e');
    }
  }

  @override
  Future<void> customAction(String name, [Map<String, dynamic>? extras]) async {
    if (name == 'dispose') {
      await _player.dispose();
    }
    if (name == 'setPitch') {
      final pitch = (extras?['pitch'] as num?)?.toDouble() ?? 1.0;
      await setPitch(pitch);
    }
  }
}

/// Initialises [audio_service] and returns the singleton [MuslyAudioHandler].
/// Call this once from [main()] before [runApp()].
///
/// On iOS, AudioService.init() is called so the audio engine runs as a proper
/// background service, driving the Control Center and lock screen.
/// On all other platforms (Android, desktop, web) the handler is created
/// directly — Android manages its own MediaBrowserServiceCompat (MusicService)
/// for Android Auto and we must not start a second service on top of it.
Future<MuslyAudioHandler> initAudioService() async {
  if (!kIsWeb && Platform.isIOS) {
    return AudioService.init(
      builder: () => MuslyAudioHandler(),
      config: const AudioServiceConfig(
        androidNotificationChannelId: 'com.devid.musly.channel.audio',
        androidNotificationChannelName: 'Musly',
        androidNotificationOngoing: true,
        androidStopForegroundOnPause: true,
        preloadArtwork: false,
      ),
    );
  }
  // Android / desktop / web: no AudioService wrapper needed.
  return MuslyAudioHandler();
}
