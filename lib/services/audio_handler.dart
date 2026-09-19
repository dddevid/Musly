import 'dart:async';
import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:rxdart/rxdart.dart';

import 'android_auto_service.dart';

class MuslyAudioHandler extends BaseAudioHandler with SeekHandler {
  final AudioPlayer _player = AudioPlayer(
    handleAudioSessionActivation: false,
    handleInterruptions: false,
  );
  static const _pitchChannel = MethodChannel('com.devid.musly/pitch');

  static const mediaIdRecent = 'AUTO_RECENT';
  static const mediaIdAlbums = 'AUTO_ALBUMS';
  static const mediaIdArtists = 'AUTO_ARTISTS';
  static const mediaIdPlaylists = 'AUTO_PLAYLISTS';
  static const mediaIdFavorites = 'AUTO_FAVORITES';
  static const mediaIdGenres = 'AUTO_GENRES';
  static const mediaIdRadio = 'AUTO_RADIO';
  static const mediaIdDownloads = 'AUTO_DOWNLOADS';
  static const mediaIdQueue = 'AUTO_QUEUE';

  AudioPlayer get player => _player;

  AndroidAutoService? _autoService;

  Future<void> Function()? onPlay;
  Future<void> Function()? onPause;
  Future<void> Function()? onStop;
  Future<void> Function()? onSkipNext;
  Future<void> Function()? onSkipPrevious;
  Future<void> Function(Duration)? onSeekTo;
  Future<void> Function()? onTogglePlayPause;
  void Function(int volumePercent)? onSetRemoteVolume;

  final Map<String, BehaviorSubject<Map<String, dynamic>>> _childrenSubjects = {};

  bool _remotePlayback = false;
  int _remoteVolume = 50;
  static const _remoteMaxVolume = 100;
  static const _remoteVolumeStep = 5;

  StreamSubscription<PlaybackEvent>? _localStateSub;

  MuslyAudioHandler() {
    _localStateSub = _player.playbackEventStream.listen((event) {
      if (_remotePlayback) return;
      playbackState.add(_buildPlaybackState(event));
    });

    if (!kIsWeb && Platform.isAndroid) {
      androidPlaybackInfo.add(LocalAndroidPlaybackInfo());
    }
  }

  void setAutoService(AndroidAutoService service) {
    _autoService = service;
  }

  bool get isMirroringLocalState => _localStateSub != null;

  Future<void> cancelLocalStateMirror() async {
    await _localStateSub?.cancel();
    _localStateSub = null;
  }

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
  Future<void> onTaskRemoved() async {
    await stop();
    await super.onTaskRemoved();
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

  @override
  Future<List<MediaItem>> getChildren(
    String parentMediaId, [
    Map<String, dynamic>? options,
  ]) async {
    final service = _autoService;
    if (service == null) return const [];
    try {
      return await service.getChildren(parentMediaId, options);
    } catch (e, st) {
      debugPrint('[AudioHandler] getChildren($parentMediaId) error: $e\n$st');
      return const [];
    }
  }

  @override
  ValueStream<Map<String, dynamic>> subscribeToChildren(String parentMediaId) {
    return _childrenSubjects.putIfAbsent(
      parentMediaId,
      () => BehaviorSubject.seeded(<String, dynamic>{}),
    );
  }

  void notifyAutoChildrenChanged([List<String>? parents]) {
    final targets = parents ??
        [
          mediaIdRecent,
          mediaIdAlbums,
          mediaIdArtists,
          mediaIdPlaylists,
          mediaIdFavorites,
          mediaIdGenres,
          mediaIdRadio,
          mediaIdDownloads,
          mediaIdQueue,
        ];
    for (final parent in targets) {
      _childrenSubjects[parent]?.add(<String, dynamic>{});
    }
    _childrenSubjects[AudioService.browsableRootId]?.add(<String, dynamic>{});
  }

  @override
  Future<List<MediaItem>> search(
    String query, [
    Map<String, dynamic>? extras,
  ]) async {
    final service = _autoService;
    if (service == null) return const [];
    try {
      return await service.search(query);
    } catch (e, st) {
      debugPrint('[AudioHandler] search("$query") error: $e\n$st');
      return const [];
    }
  }

  @override
  Future<void> playFromMediaId(
    String mediaId, [
    Map<String, dynamic>? extras,
  ]) async {
    _pushLoadingState();
    try {
      await _autoService?.playFromMediaId(mediaId);
    } catch (e, st) {
      debugPrint('[AudioHandler] playFromMediaId($mediaId) error: $e\n$st');
      _pushIdleState();
    }
  }

  @override
  Future<void> playFromSearch(
    String query, [
    Map<String, dynamic>? extras,
  ]) async {
    _pushLoadingState();
    try {
      await _autoService?.playFromSearch(query.trim());
    } catch (e, st) {
      debugPrint('[AudioHandler] playFromSearch("$query") error: $e\n$st');
      _pushIdleState();
    }
  }

  void _pushLoadingState() {
    playbackState.add(
      playbackState.value.copyWith(
        processingState: AudioProcessingState.loading,
        playing: false,
        controls: const [
          MediaControl.skipToPrevious,
          MediaControl.play,
          MediaControl.skipToNext,
        ],
        systemActions: const {
          MediaAction.seek,
          MediaAction.seekForward,
          MediaAction.seekBackward,
          MediaAction.playFromMediaId,
          MediaAction.playFromSearch,
          MediaAction.setShuffleMode,
          MediaAction.setRepeatMode,
        },
        androidCompactActionIndices: const [0, 1, 2],
      ),
    );
  }

  void _pushIdleState() {
    playbackState.add(
      playbackState.value.copyWith(
        processingState: AudioProcessingState.idle,
        playing: false,
      ),
    );
  }

  void setRemotePlayback({required bool isRemote, int volume = 50}) {
    if (kIsWeb || !Platform.isAndroid) return;
    _remotePlayback = isRemote;
    if (isRemote) {
      _remoteVolume = volume.clamp(0, _remoteMaxVolume);
      androidPlaybackInfo.add(
        RemoteAndroidPlaybackInfo(
          volumeControlType: AndroidVolumeControlType.absolute,
          maxVolume: _remoteMaxVolume,
          volume: _remoteVolume,
        ),
      );
    } else {
      androidPlaybackInfo.add(LocalAndroidPlaybackInfo());
      playbackState.add(_buildPlaybackState(_player.playbackEvent));
    }
  }

  void updateRemoteVolume(int volume) {
    if (kIsWeb || !Platform.isAndroid || !_remotePlayback) return;
    _remoteVolume = volume.clamp(0, _remoteMaxVolume);
    androidPlaybackInfo.add(
      RemoteAndroidPlaybackInfo(
        volumeControlType: AndroidVolumeControlType.absolute,
        maxVolume: _remoteMaxVolume,
        volume: _remoteVolume,
      ),
    );
  }

  @override
  Future<void> androidSetRemoteVolume(int volumeIndex) async {
    if (!_remotePlayback) return;
    _remoteVolume = volumeIndex.clamp(0, _remoteMaxVolume);
    onSetRemoteVolume?.call(_remoteVolume);
  }

  @override
  Future<void> androidAdjustRemoteVolume(AndroidVolumeDirection direction) async {
    if (!_remotePlayback || direction.index == 0) return;
    _remoteVolume = (_remoteVolume + direction.index * _remoteVolumeStep).clamp(0, _remoteMaxVolume);
    updateRemoteVolume(_remoteVolume);
    onSetRemoteVolume?.call(_remoteVolume);
  }

  void updateNowPlaying({
    required String id,
    required String title,
    String? artist,
    String? album,
    String? artworkUrl,
    Duration? duration,
  }) {
    final artUri = artworkUrl != null && artworkUrl.isNotEmpty ? Uri.tryParse(artworkUrl) : null;
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

  void updateRemotePlaybackState({
    required bool playing,
    required Duration position,
  }) {
    playbackState.add(
      playbackState.value.copyWith(
        controls: [
          MediaControl.skipToPrevious,
          if (playing) MediaControl.pause else MediaControl.play,
          MediaControl.skipToNext,
        ],
        systemActions: const {
          MediaAction.seek,
          MediaAction.seekForward,
          MediaAction.seekBackward,
          MediaAction.playFromMediaId,
          MediaAction.playFromSearch,
          MediaAction.setShuffleMode,
          MediaAction.setRepeatMode,
        },
        androidCompactActionIndices: const [0, 1, 2],
        processingState: AudioProcessingState.ready,
        playing: playing,
        updatePosition: position,
      ),
    );
  }

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
        MediaAction.playFromMediaId,
        MediaAction.playFromSearch,
        MediaAction.setShuffleMode,
        MediaAction.setRepeatMode,
      },
      androidCompactActionIndices: const [0, 1, 2],
      processingState:
          processingStateMap[_player.processingState] ?? AudioProcessingState.idle,
      playing: _player.playing,
      updatePosition: _player.position,
      bufferedPosition: _player.bufferedPosition,
      speed: _player.speed,
      queueIndex: event.currentIndex,
    );
  }

  Future<bool> setPlaybackParameters(double speed, double pitch) async {
    try {
      final result = await _pitchChannel.invokeMethod('setPlaybackParameters', {
        'speed': speed,
        'pitch': pitch,
      });
      final success = (result?['success'] as bool?) ?? false;
      return success;
    } catch (e) {
      debugPrint('[AudioHandler] PitchPlugin error: $e');
      return false;
    }
  }

  @override
  Future<void> customAction(String name, [Map<String, dynamic>? extras]) async {
    if (name == 'dispose') {
      await cancelLocalStateMirror();
      for (final sub in _childrenSubjects.values) {
        await sub.close();
      }
      _childrenSubjects.clear();
      await _player.dispose();
    }
  }
}

Future<MuslyAudioHandler> initAudioService() async {
  if (!kIsWeb && (Platform.isIOS || Platform.isAndroid || Platform.isMacOS)) {
    return AudioService.init(
      builder: () => MuslyAudioHandler(),
      config: const AudioServiceConfig(
        androidNotificationChannelId: 'com.devid.musly.channel.audio',
        androidNotificationChannelName: 'Musly',
        androidNotificationOngoing: false,
        androidStopForegroundOnPause: false,
        androidNotificationIcon: 'mipmap/ic_launcher',
        notificationColor: Color(0xFF1DB954),
        preloadArtwork: true,
        androidBrowsableRootExtras: {
          'android.media.browse.SEARCH_SUPPORTED': true,
          'android.media.browse.CONTENT_STYLE_SUPPORTED': true,
          'android.media.browse.CONTENT_STYLE_BROWSABLE_HINT': 1,
          'android.media.browse.CONTENT_STYLE_PLAYABLE_HINT': 1,
        },
      ),
    );
  }

  return MuslyAudioHandler();
}
