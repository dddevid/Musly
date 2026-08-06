import 'dart:async';
import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:rxdart/rxdart.dart';

/// Background-service audio handler (iOS + Android).
///
/// Wraps [AudioPlayer] (just_audio) and bridges the [audio_service] protocol
/// so that:
///   • iOS lock-screen controls (play/pause/skip/seek) call back to
///     [PlayerProvider] without going through the custom iOSSystemPlugin
///     MPRemoteCommandCenter registration.
///   • [MPNowPlayingInfoCenter] is updated automatically by the audio_service
///     iOS plugin whenever [mediaItem] changes.
///   • On Android, audio_service hosts the MediaBrowserService used by
///     Android Auto: the browse tree, voice/keyboard search and playback
///     commands are served by this handler, even when the app UI has never
///     been opened (audio_service spawns a headless Flutter engine and runs
///     `main()`).
///
/// [PlayerProvider] receives this handler and uses [player] directly for all
/// just_audio operations.  It calls [updateNowPlaying] whenever the current
/// song changes to push metadata up to the lock screen / Control Center /
/// Android Auto.
class MuslyAudioHandler extends BaseAudioHandler with SeekHandler {
  // On Android, audio focus is owned entirely by AndroidSystemPlugin.kt (see
  // PlayerProvider._ensureAudioFocus). just_audio's own automatic
  // audio_session activation/interruption handling is disabled here so it
  // can't silently gate play() on a failed focus request, or fire a second,
  // conflicting pause() on interruption/headphone-unplug. iOS/desktop/web
  // keep the defaults (audio_session drives Control Center/lock-screen
  // interruptions there).
  static bool get _ownsFocusNatively => !kIsWeb && Platform.isAndroid;

  final AudioPlayer _player = AudioPlayer(
    handleAudioSessionActivation: !_ownsFocusNatively,
    handleInterruptions: !_ownsFocusNatively,
  );
  static const _pitchChannel = MethodChannel('com.devid.musly/pitch');

  // ---------------------------------------------------------------------------
  // Android Auto browse tree media IDs.
  // Kept identical to the legacy MusicService scheme so play-from-media-id
  // handling in PlayerProvider keeps working unchanged.
  // ---------------------------------------------------------------------------
  static const mediaIdRecent = 'RECENT';
  static const mediaIdAlbums = 'ALBUMS';
  static const mediaIdArtists = 'ARTISTS';
  static const mediaIdPlaylists = 'PLAYLISTS';
  static const _albumPrefix = 'album_';
  static const _artistPrefix = 'artist_';
  static const _playlistPrefix = 'playlist_';

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

  // ---------------------------------------------------------------------------
  // Android Auto callbacks.
  // Browse data getters are wired by LibraryProvider; song-level getters,
  // search and playback are wired by PlayerProvider. All of them exchange the
  // same map shapes used by the legacy AndroidAutoService bridge:
  //   songs:     {id, title, artist, album, artworkUrl}
  //   albums:    {id, name, artist, artworkUrl}
  //   artists:   {id, name, albumCount}
  //   playlists: {id, name, songCount, artworkUrl}
  // ---------------------------------------------------------------------------
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

  /// Called when a remote-volume change is requested from the media session
  /// (Android Auto / Bluetooth volume keys while casting or on UPnP).
  /// The argument is a volume percentage (0–100).
  void Function(int volumePercent)? onSetRemoteVolume;

  final Map<String, BehaviorSubject<Map<String, dynamic>>> _childrenSubjects =
      {};

  // Remote (UPnP/Cast) volume state mirrored into the media session.
  bool _remotePlayback = false;
  int _remoteVolume = 50;
  static const _remoteMaxVolume = 100;
  static const _remoteVolumeStep = 5;

  MuslyAudioHandler() {
    // Forward just_audio playback events → audio_service playback state.
    // This drives the iOS Control Center / lock screen widget and the
    // Android media notification automatically.
    _player.playbackEventStream.map(_buildPlaybackState).pipe(playbackState);
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
  // Android Auto: browse tree
  // ---------------------------------------------------------------------------

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

  /// Tell subscribed media browsers (Android Auto) that the children of the
  /// given parents changed, so they re-query [getChildren]. With no argument,
  /// all four top-level categories are refreshed.
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
    } catch (e) {
      debugPrint('AudioHandler: search("$query") failed: $e');
      return const [];
    }
  }

  @override
  Future<void> playFromMediaId(
    String mediaId, [
    Map<String, dynamic>? extras,
  ]) async {
    await onPlayFromMediaId?.call(mediaId);
  }

  @override
  Future<void> playFromSearch(
    String query, [
    Map<String, dynamic>? extras,
  ]) async {
    await onPlayFromSearch?.call(query.trim());
  }

  List<MediaItem> _rootItems() {
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

  // ---------------------------------------------------------------------------
  // Remote playback volume (UPnP / Cast) mirrored into the media session so
  // hardware volume keys and Android Auto control the remote renderer.
  // ---------------------------------------------------------------------------

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
      // Replace the stale remote playback state immediately instead of
      // waiting for the local player to emit its next playback event.
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
      if (artworkUrl.startsWith('/') || (artworkUrl.length > 2 && artworkUrl[1] == ':')) {
        artUri = Uri.file(artworkUrl);
      } else {
        artUri = Uri.tryParse(artworkUrl);
      }
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

  /// Pushes an explicit playback state while rendering on a remote target
  /// (UPnP / Cast / jukebox), where the local just_audio player is paused and
  /// would otherwise report "paused" to the media session and Android Auto.
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
        MediaAction.playFromMediaId,
        MediaAction.playFromSearch,
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

  /// Propagates speed+pitch to the native player via platform channel.
  /// Returns true if the native plugin succeeded.
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
      await _player.dispose();
    }
  }
}

/// Initialises [audio_service] and returns the singleton [MuslyAudioHandler].
/// Call this once from [main()] before [runApp()].
///
/// On iOS and Android, AudioService.init() is called so the audio engine runs
/// as a proper background service. On Android this also registers the
/// MediaBrowserService that Android Auto connects to: when Auto starts with
/// the app closed, audio_service spawns a headless Flutter engine, runs
/// main(), and this handler serves the browse tree, search and playback.
/// On desktop/web the handler is created directly (audio_service has no
/// backend there).
Future<MuslyAudioHandler> initAudioService() async {
  if (!kIsWeb && (Platform.isIOS || Platform.isAndroid)) {
    return AudioService.init(
      builder: () => MuslyAudioHandler(),
      config: const AudioServiceConfig(
        androidNotificationChannelId: 'com.devid.musly.channel.audio',
        androidNotificationChannelName: 'Musly',
        // With androidStopForegroundOnPause=false the service never leaves
        // the foreground, so androidNotificationOngoing would have no
        // effect (audio_service asserts against combining the two).
        androidNotificationOngoing: false,
        androidStopForegroundOnPause: false,
        androidNotificationIcon: 'mipmap/ic_launcher',
        notificationColor: Color(0xFF1DB954),
        preloadArtwork: false,
        androidBrowsableRootExtras: {
          'android.media.browse.SEARCH_SUPPORTED': true,
        },
      ),
    );
  }
  // Desktop / web: no AudioService wrapper needed.
  return MuslyAudioHandler();
}
