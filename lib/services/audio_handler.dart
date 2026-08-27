import 'dart:async';
import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:rxdart/rxdart.dart';

class MuslyAudioHandler extends BaseAudioHandler with SeekHandler {
  final AudioPlayer _player = AudioPlayer(
    handleAudioSessionActivation: false,
    handleInterruptions: false,
  );
  static const _pitchChannel = MethodChannel('com.devid.musly/pitch');

  static const mediaIdRecent = 'RECENT';
  static const mediaIdAlbums = 'ALBUMS';
  static const mediaIdArtists = 'ARTISTS';
  static const mediaIdPlaylists = 'PLAYLISTS';
  static const _albumPrefix = 'album_';
  static const _artistPrefix = 'artist_';
  static const _playlistPrefix = 'playlist_';

  AudioPlayer get player => _player;

  Future<void> Function()? onPlay;
  Future<void> Function()? onPause;
  Future<void> Function()? onStop;
  Future<void> Function()? onSkipNext;
  Future<void> Function()? onSkipPrevious;
  Future<void> Function(Duration)? onSeekTo;
  Future<void> Function()? onTogglePlayPause;

  Future<List<Map<String, dynamic>>> Function()? onGetRecentSongs;
  Future<List<Map<String, dynamic>>> Function()? onGetLibraryAlbums;
  Future<List<Map<String, dynamic>>> Function()? onGetLibraryArtists;
  Future<List<Map<String, dynamic>>> Function()? onGetLibraryPlaylists;
  Future<List<Map<String, String>>> Function(String albumId)? onGetAlbumSongs;
  Future<List<Map<String, String>>> Function(String artistId)?
      onGetArtistAlbums;
  Future<List<Map<String, String>>> Function(String playlistId)?
      onGetPlaylistSongs;
  Future<List<Map<String, String>>> Function(String query)? onSearch;
  Future<void> Function(String mediaId)? onPlayFromMediaId;
  Future<void> Function(String query)? onPlayFromSearch;

  void Function(int volumePercent)? onSetRemoteVolume;

  bool Function()? onIsYoutubeMode;

  final Map<String, BehaviorSubject<Map<String, dynamic>>> _childrenSubjects =
      {};

  bool _remotePlayback = false;
  int _remoteVolume = 50;
  static const _remoteMaxVolume = 100;
  static const _remoteVolumeStep = 5;

  StreamSubscription<PlaybackEvent>? _localStateSub;

  MuslyAudioHandler() {
    // listen()+add() rather than pipe(): pipe() is addStream() on the rxdart
    // Subject, which makes every other playbackState.add() in this class throw
    // "You cannot add items while items are being added from addStream". That
    // silently broke updateRemotePlaybackState(), so the media session could
    // never follow Cast/DLNA — notification, lock screen and head-unit controls
    // stayed pinned to the idle local player and pause did nothing. The gate
    // stops that idle player from overwriting remote state.
    _localStateSub = _player.playbackEventStream.listen((event) {
      if (_remotePlayback) return;
      playbackState.add(_buildPlaybackState(event));
    });

    if (!kIsWeb && Platform.isAndroid) {
      androidPlaybackInfo.add(LocalAndroidPlaybackInfo());
    }
  }

  /// True while local player events are still being mirrored into the session.
  bool get isMirroringLocalState => _localStateSub != null;

  /// Stop mirroring the local player into the media session.
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
    try {
      switch (parentMediaId) {
        case AudioService.browsableRootId:
          return _rootItems();
        case AudioService.recentRootId:
        case mediaIdRecent:
          return _songItems(await onGetRecentSongs?.call() ?? const []);
        case mediaIdAlbums:
          return _albumItems(await onGetLibraryAlbums?.call() ?? const []);
        case mediaIdArtists:
          return _artistItems(await onGetLibraryArtists?.call() ?? const []);
        case mediaIdPlaylists:
          return _playlistItems(
            await onGetLibraryPlaylists?.call() ?? const [],
          );
      }
      if (parentMediaId.startsWith(_albumPrefix)) {
        final albumId = parentMediaId.substring(_albumPrefix.length);
        return _songItems(await onGetAlbumSongs?.call(albumId) ?? const []);
      }
      if (parentMediaId.startsWith(_artistPrefix)) {
        final artistId = parentMediaId.substring(_artistPrefix.length);
        return _albumItems(
          await onGetArtistAlbums?.call(artistId) ?? const [],
        );
      }
      if (parentMediaId.startsWith(_playlistPrefix)) {
        final playlistId = parentMediaId.substring(_playlistPrefix.length);
        return _songItems(
          await onGetPlaylistSongs?.call(playlistId) ?? const [],
        );
      }
    } catch (e, st) {
      debugPrint('AudioHandler: getChildren($parentMediaId) failed: $e\n$st');
    }
    return const [];
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
        const [mediaIdRecent, mediaIdAlbums, mediaIdArtists, mediaIdPlaylists];
    for (final parent in targets) {
      _childrenSubjects[parent]?.add(<String, dynamic>{});
    }
  }

  @override
  Future<List<MediaItem>> search(
    String query, [
    Map<String, dynamic>? extras,
  ]) async {
    try {
      final results = await onSearch?.call(query) ?? const [];
      return _songItems(results);
    } catch (e, st) {
      debugPrint('AudioHandler: search("$query") failed: $e\n$st');
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
      await onPlayFromMediaId?.call(mediaId);
    } catch (e, st) {
      debugPrint('AudioHandler: playFromMediaId($mediaId) failed: $e\n$st');

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
      await onPlayFromSearch?.call(query.trim());
    } catch (e, st) {
      debugPrint('AudioHandler: playFromSearch("$query") failed: $e\n$st');
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
          MediaAction.playFromMediaId,
          MediaAction.playFromSearch,
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

  List<MediaItem> _rootItems() {
    final isYoutube = onIsYoutubeMode?.call() ?? false;

    if (isYoutube) {
      return const [
        MediaItem(
          id: mediaIdRecent,
          title: 'Recent',
          playable: false,
        ),
        MediaItem(
          id: mediaIdPlaylists,
          title: 'Playlists',
          playable: false,
        ),
      ];
    }
    return const [
      MediaItem(
        id: mediaIdRecent,
        title: 'Recent',
        playable: false,
      ),
      MediaItem(
        id: mediaIdAlbums,
        title: 'Albums',
        playable: false,
      ),
      MediaItem(
        id: mediaIdArtists,
        title: 'Artists',
        playable: false,
      ),
      MediaItem(
        id: mediaIdPlaylists,
        title: 'Playlists',
        playable: false,
      ),
    ];
  }

  List<MediaItem> _songItems(List<Map<String, dynamic>> songs) {
    return songs
        .map(
          (song) => MediaItem(
            id: (song['id'] as String?) ?? '',
            title: (song['title'] as String?) ?? '',
            artist: song['artist'] as String?,
            album: song['album'] as String?,
            artUri: _tryParseUri(song['artworkUrl'] as String?),
            duration: _parseDurationSeconds(song['duration']),
          ),
        )
        .where((item) => item.id.isNotEmpty)
        .toList();
  }

  List<MediaItem> _albumItems(List<Map<String, dynamic>> albums) {
    return albums
        .map(
          (album) => MediaItem(
            id: '$_albumPrefix${album['id']}',
            title: (album['name'] as String?) ?? '',
            artist: album['artist'] as String?,
            artUri: _tryParseUri(album['artworkUrl'] as String?),
            playable: false,
          ),
        )
        .toList();
  }

  List<MediaItem> _artistItems(List<Map<String, dynamic>> artists) {
    return artists
        .map(
          (artist) => MediaItem(
            id: '$_artistPrefix${artist['id']}',
            title: (artist['name'] as String?) ?? '',
            displaySubtitle: '${artist['albumCount'] ?? 0} albums',
            playable: false,
          ),
        )
        .toList();
  }

  List<MediaItem> _playlistItems(List<Map<String, dynamic>> playlists) {
    return playlists
        .map(
          (playlist) => MediaItem(
            id: '$_playlistPrefix${playlist['id']}',
            title: (playlist['name'] as String?) ?? '',
            displaySubtitle: '${playlist['songCount'] ?? 0} songs',
            artUri: _tryParseUri(playlist['artworkUrl'] as String?),
            playable: false,
          ),
        )
        .toList();
  }

  static Uri? _tryParseUri(String? url) {
    if (url == null || url.isEmpty) return null;
    if (url.startsWith('file://')) return Uri.parse(url);
    if (url.startsWith('/') || (url.length > 2 && url[1] == ':')) {
      return Uri.file(url);
    }
    return Uri.tryParse(url);
  }

  static Duration? _parseDurationSeconds(dynamic value) {
    final seconds = switch (value) {
      int v => v,
      String v => int.tryParse(v),
      _ => null,
    };
    if (seconds == null || seconds <= 0) return null;
    return Duration(seconds: seconds);
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
  Future<void> androidAdjustRemoteVolume(
    AndroidVolumeDirection direction,
  ) async {
    if (!_remotePlayback || direction.index == 0) return;
    _remoteVolume = (_remoteVolume + direction.index * _remoteVolumeStep)
        .clamp(0, _remoteMaxVolume);
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
    final artUri = _tryParseUri(artworkUrl);
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
      },
      androidCompactActionIndices: const [0, 1, 2],
      processingState: processingStateMap[_player.processingState] ??
          AudioProcessingState.idle,
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
      debugPrint('PitchPlugin error: $e');
      return false;
    }
  }

  @override
  Future<void> customAction(String name, [Map<String, dynamic>? extras]) async {
    if (name == 'dispose') {
      // Before _player.dispose(): AudioPlayer.dispose() does not cancel our
      // own subscription to its event stream.
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
        },
      ),
    );
  }

  return MuslyAudioHandler();
}
