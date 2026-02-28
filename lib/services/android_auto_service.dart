import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../models/song.dart';
import '../models/album.dart';
import '../models/artist.dart';
import '../models/playlist.dart';

class AndroidAutoService {
  static final AndroidAutoService _instance = AndroidAutoService._internal();
  factory AndroidAutoService() => _instance;
  AndroidAutoService._internal();

  static const MethodChannel _methodChannel = MethodChannel(
    'com.devid.musly/android_auto',
  );
  static const EventChannel _eventChannel = EventChannel(
    'com.devid.musly/android_auto_events',
  );

  StreamSubscription? _eventSubscription;

  VoidCallback? onPlay;
  VoidCallback? onPause;
  VoidCallback? onStop;
  VoidCallback? onSkipNext;
  VoidCallback? onSkipPrevious;
  Function(Duration position)? onSeekTo;
  Function(String mediaId)? onPlayFromMediaId;
  Function(int volume)? onSetVolume;

  Future<List<Map<String, String>>> Function(String albumId)? onGetAlbumSongs;
  Future<List<Map<String, String>>> Function(String artistId)?
  onGetArtistAlbums;
  Future<List<Map<String, String>>> Function(String playlistId)?
  onGetPlaylistSongs;

  Future<void> initialize() async {
    if (defaultTargetPlatform != TargetPlatform.android) return;

    try {
      _eventSubscription = _eventChannel.receiveBroadcastStream().listen(
        _handleEvent,
        onError: _handleError,
      );

      await _methodChannel.invokeMethod('startService');
      debugPrint('AndroidAutoService initialized');
    } catch (e) {
      debugPrint('Error initializing AndroidAutoService: $e');
    }
  }

  void _handleEvent(dynamic event) {
    if (event is! Map) return;

    final command = event['command'] as String?;
    debugPrint('AndroidAuto command received: $command');

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
      case 'playFromMediaId':
        final mediaId = event['mediaId'] as String?;
        if (mediaId != null) {
          onPlayFromMediaId?.call(mediaId);
        }
        break;
      case 'setVolume':
        final volume = event['volume'] as int?;
        if (volume != null) {
          onSetVolume?.call(volume);
        }
        break;
      case 'getAlbumSongs':
        final albumId = event['albumId'] as String?;
        if (albumId != null) {
          _handleGetAlbumSongs(albumId);
        }
        break;
      case 'getArtistAlbums':
        final artistId = event['artistId'] as String?;
        if (artistId != null) {
          _handleGetArtistAlbums(artistId);
        }
        break;
      case 'getPlaylistSongs':
        final playlistId = event['playlistId'] as String?;
        if (playlistId != null) {
          _handleGetPlaylistSongs(playlistId);
        }
        break;
    }
  }

  Future<void> _handleGetAlbumSongs(String albumId) async {
    if (onGetAlbumSongs == null) return;
    try {
      final songs = await onGetAlbumSongs!(albumId);
      await _methodChannel.invokeMethod('updateAlbumSongs', {
        'albumId': albumId,
        'songs': songs,
      });
    } catch (e) {
      debugPrint('Error getting album songs: $e');
    }
  }

  Future<void> _handleGetArtistAlbums(String artistId) async {
    if (onGetArtistAlbums == null) return;
    try {
      final albums = await onGetArtistAlbums!(artistId);
      await _methodChannel.invokeMethod('updateArtistAlbums', {
        'artistId': artistId,
        'albums': albums,
      });
    } catch (e) {
      debugPrint('Error getting artist albums: $e');
    }
  }

  Future<void> _handleGetPlaylistSongs(String playlistId) async {
    if (onGetPlaylistSongs == null) return;
    try {
      final songs = await onGetPlaylistSongs!(playlistId);
      await _methodChannel.invokeMethod('updatePlaylistSongs', {
        'playlistId': playlistId,
        'songs': songs,
      });
    } catch (e) {
      debugPrint('Error getting playlist songs: $e');
    }
  }

  void _handleError(dynamic error) {
    debugPrint('AndroidAuto event error: $error');
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
      debugPrint('Error updating playback state: $e');
    }
  }

  Future<void> updateRecentSongs(
    List<Song> songs,
    String Function(String?) getCoverArtUrl,
  ) async {
    if (defaultTargetPlatform != TargetPlatform.android) return;

    try {
      final songList = songs
          .take(50)
          .map(
            (song) => {
              'id': song.id,
              'title': song.title,
              'artist': song.artist ?? '',
              'album': song.album ?? '',
              'artworkUrl': getCoverArtUrl(song.coverArt),
              'duration': song.duration ?? 0,
            },
          )
          .toList();

      await _methodChannel.invokeMethod('updateRecentSongs', {
        'songs': songList,
      });
    } catch (e) {
      debugPrint('Error updating recent songs: $e');
    }
  }

  Future<void> updateAlbums(
    List<Album> albums,
    String Function(String?) getCoverArtUrl,
  ) async {
    if (defaultTargetPlatform != TargetPlatform.android) return;

    try {
      final albumList = albums
          .take(100)
          .map(
            (album) => {
              'id': album.id,
              'name': album.name,
              'artist': album.artist ?? '',
              'artworkUrl': getCoverArtUrl(album.coverArt),
            },
          )
          .toList();

      await _methodChannel.invokeMethod('updateAlbums', {'albums': albumList});
    } catch (e) {
      debugPrint('Error updating albums: $e');
    }
  }

  Future<void> updateArtists(List<Artist> artists) async {
    if (defaultTargetPlatform != TargetPlatform.android) return;

    try {
      final artistList = artists
          .take(100)
          .map(
            (artist) => {
              'id': artist.id,
              'name': artist.name,
              'albumCount': artist.albumCount,
            },
          )
          .toList();

      await _methodChannel.invokeMethod('updateArtists', {
        'artists': artistList,
      });
    } catch (e) {
      debugPrint('Error updating artists: $e');
    }
  }

  Future<void> updatePlaylists(
    List<Playlist> playlists,
    String Function(String?) getCoverArtUrl,
  ) async {
    if (defaultTargetPlatform != TargetPlatform.android) return;

    try {
      final playlistList = playlists
          .take(50)
          .map(
            (playlist) => {
              'id': playlist.id,
              'name': playlist.name,
              'songCount': playlist.songCount,
              'artworkUrl': getCoverArtUrl(playlist.coverArt),
            },
          )
          .toList();

      await _methodChannel.invokeMethod('updatePlaylists', {
        'playlists': playlistList,
      });
    } catch (e) {
      debugPrint('Error updating playlists: $e');
    }
  }

  Future<void> dispose() async {
    if (defaultTargetPlatform != TargetPlatform.android) return;

    _eventSubscription?.cancel();
    try {
      await _methodChannel.invokeMethod('stopService');
    } catch (e) {
      debugPrint('Error stopping AndroidAutoService: $e');
    }
  }
}
