import 'dart:async';
import 'dart:io';

import 'dart:ui' as ui;
import 'package:audio_service/audio_service.dart';
import 'package:musly/providers/auth_provider.dart';
import 'package:musly/services/audio_handler.dart';
import 'package:musly/services/android_auto_settings_service.dart';
import 'package:musly/services/storage_service.dart';
import 'package:musly/l10n/app_localizations.dart';
import 'package:flutter/foundation.dart';

import '../models/models.dart';
import 'offline_service.dart';
import 'subsonic_service.dart';

abstract class AndroidAutoDelegate {
  List<Song> get queue;
  int get currentIndex;
  Song? get currentSong;
  bool get isPlaying;
  List<Song> get randomSongs;

  Future<void> playSong(Song song, {List<Song>? playlist, int startIndex});
  Future<void> skipToIndex(int index);
  Future<void> play();
  Future<void> shuffleLibrary();
  Future<void> toggleStar(Song song);
}

abstract class AndroidAutoLibraryDelegate {
  List<Song> get cachedAllSongs;
  List<Album> get cachedAllAlbums;
  List<Artist> get artists;
  List<Playlist> get playlists;
  List<Genre> get richGenres;
  bool get isInitialized;
  bool get isServerOfflineMode;

  Future<void> initialize();
  Future<List<Song>> getAlbumSongs(String albumId);
  Future<List<Album>> getArtistAlbums(String artistId);
  Future<Playlist> getPlaylist(String playlistId);
  Future<List<Song>> getSongsByGenre(String genre);
  Future<SearchResult> search(String query);
  String getCoverArtUrl(String? coverArt);
}

class AndroidAutoService {
  final SubsonicService _subsonicService;
  final OfflineService _offlineService;

  AndroidAutoDelegate? _playerDelegate;
  AndroidAutoLibraryDelegate? _libraryDelegate;
  AuthProvider? _authProvider;

  static const _idRecent = 'AUTO_RECENT';
  static const _idFavorites = 'AUTO_FAVORITES';
  static const _idAlbums = 'AUTO_ALBUMS';
  static const _idArtists = 'AUTO_ARTISTS';
  static const _idPlaylists = 'AUTO_PLAYLISTS';
  static const _idGenres = 'AUTO_GENRES';
  static const _idRadio = 'AUTO_RADIO';
  static const _idDownloads = 'AUTO_DOWNLOADS';
  static const _idShuffle = 'AUTO_SHUFFLE';
  static const _idQueue = 'AUTO_QUEUE';

  static const _prefixAlbum = 'auto_album_';
  static const _prefixArtist = 'auto_artist_';
  static const _prefixPlaylist = 'auto_playlist_';
  static const _prefixGenre = 'auto_genre_';
  static const _prefixSong = 'auto_song_';
  static const _prefixRadio = 'auto_radio_';

  static const _artworkSize = 800;

  static const _contentStyleBrowsable = 'android.media.browse.CONTENT_STYLE_BROWSABLE_HINT';
  static const _contentStylePlayable = 'android.media.browse.CONTENT_STYLE_PLAYABLE_HINT';
  static const _contentStyleGrid = 2;
  static const _contentStyleList = 1;

  AndroidAutoService({
    required SubsonicService subsonicService,
    required OfflineService offlineService,
  })  : _subsonicService = subsonicService,
        _offlineService = offlineService;

  void setPlayerDelegate(AndroidAutoDelegate delegate) {
    _playerDelegate = delegate;
  }

  void setLibraryDelegate(AndroidAutoLibraryDelegate delegate) {
    _libraryDelegate = delegate;
  }

  void setAuthProvider(AuthProvider provider) {
    _authProvider = provider;
  }

  AppLocalizations get _l10n {
    return lookupAppLocalizations(ui.PlatformDispatcher.instance.locale);
  }

  bool get _isWebStream => _subsonicService.isYoutube;

  Future<List<MediaItem>> getChildren(
    String parentId, [
    Map<String, dynamic>? options,
  ]) async {
    try {
      switch (parentId) {
        case AudioService.browsableRootId:
          return await _buildRootItems();

        case AudioService.recentRootId:
        case _idRecent:
          return await _buildRecentItems();

        case _idFavorites:
          return await _buildFavoritesItems();

        case _idAlbums:
          return await _buildAlbumItems();

        case _idArtists:
          return await _buildArtistItems();

        case _idPlaylists:
          return await _buildPlaylistItems();

        case _idGenres:
          return await _buildGenreItems();

        case _idRadio:
          return await _buildRadioItems();

        case _idDownloads:
          return await _buildDownloadItems();

        case _idQueue:
          return await _buildQueueItems();

        default:
          if (parentId.startsWith(_prefixAlbum)) {
            return await _buildAlbumSongItems(parentId.substring(_prefixAlbum.length));
          }
          if (parentId.startsWith(_prefixArtist)) {
            return await _buildArtistAlbumItems(parentId.substring(_prefixArtist.length));
          }
          if (parentId.startsWith(_prefixPlaylist)) {
            return await _buildPlaylistSongItems(parentId.substring(_prefixPlaylist.length));
          }
          if (parentId.startsWith(_prefixGenre)) {
            return await _buildGenreSongItems(Uri.decodeComponent(parentId.substring(_prefixGenre.length)));
          }
          return const [];
      }
    } catch (e, st) {
      debugPrint('[AndroidAutoService] getChildren($parentId) error: $e\n$st');
      return const [];
    }
  }

  Future<List<MediaItem>> search(String query) async {
    if (query.trim().isEmpty) return const [];
    try {
      await _ensureLibraryReady();
      final lib = _libraryDelegate;
      if (lib == null) return const [];

      if (_offlineService.isOfflineMode) {
        final ids = _offlineService.getDownloadedSongIds().toSet();
        final q = query.toLowerCase();
        final hits = lib.cachedAllSongs
            .where((s) =>
                ids.contains(s.id) &&
                (s.title.toLowerCase().contains(q) ||
                    (s.artist?.toLowerCase().contains(q) ?? false) ||
                    (s.album?.toLowerCase().contains(q) ?? false)))
            .take(30)
            .toList();
        return hits.map(_songToMediaItem).toList();
      }

      final result = await lib.search(query).timeout(const Duration(seconds: 15));
      return result.songs.take(30).map(_songToMediaItem).toList();
    } catch (e) {
      debugPrint('[AndroidAutoService] search error: $e');
      return const [];
    }
  }

  Future<void> playFromMediaId(String mediaId) async {
    try {
      final player = _playerDelegate;
      if (player == null) return;

      if (mediaId == _idShuffle) {
        await player.shuffleLibrary();
        return;
      }

      if (mediaId.startsWith(_prefixSong)) {
        final songId = mediaId.substring(_prefixSong.length);
        await _playBySongId(songId);
        return;
      }

      if (mediaId.startsWith(_prefixRadio)) {
        final stationId = mediaId.substring(_prefixRadio.length);
        await _playRadioStation(stationId);
        return;
      }

      await _playBySongId(mediaId);
    } catch (e) {
      debugPrint('[AndroidAutoService] playFromMediaId($mediaId) error: $e');
    }
  }

  Future<void> playFromSearch(String query) async {
    try {
      final player = _playerDelegate;
      if (player == null) return;

      if (query.trim().isEmpty) {
        final current = player.currentSong;
        if (current != null) {
          await player.play();
          return;
        }
        await _playRandomSong();
        return;
      }

      final results = await search(query).timeout(const Duration(seconds: 15));
      if (results.isEmpty) {
        debugPrint('[AndroidAutoService] playFromSearch: no results for "$query"');
        return;
      }

      final lib = _libraryDelegate;
      final firstId = results.first.id;
      final songId = firstId.startsWith(_prefixSong) ? firstId.substring(_prefixSong.length) : firstId;
      final allSongs = lib?.cachedAllSongs ?? [];
      final song = allSongs.firstWhere(
        (s) => s.id == songId,
        orElse: () => _mediaItemToSong(results.first),
      );

      final playlist = results
          .map((item) {
            final id = item.id.startsWith(_prefixSong) ? item.id.substring(_prefixSong.length) : item.id;
            return allSongs.firstWhere(
              (s) => s.id == id,
              orElse: () => _mediaItemToSong(item),
            );
          })
          .toList();

      await player.playSong(song, playlist: playlist, startIndex: 0);
    } catch (e) {
      debugPrint('[AndroidAutoService] playFromSearch error: $e');
    }
  }

  Future<List<MediaItem>> _buildRootItems() async {
    final player = _playerDelegate;
    final settings = AndroidAutoSettingsService();
    await settings.initialize();

    final desiredServerId = settings.getServerId();
    if (desiredServerId != null && _authProvider != null) {
      final config = _subsonicService.config;
      if (config != null) {
        final currentId = '${config.serverFamily}_${config.serverUrl}_${config.username}';
        if (currentId != desiredServerId) {
          debugPrint('[AndroidAutoService] Switching server to $desiredServerId');
          final parts = desiredServerId.split('_');
          if (parts.length >= 3) {
            final family = parts[0];
            final url = parts[1];
            final username = parts.sublist(2).join('_');
            
            final profiles = await StorageService().getSavedProfiles();
            final targetConfig = profiles.where((p) => '${p.serverFamily}_${p.serverUrl}_${p.username}' == desiredServerId).firstOrNull;
            
            if (targetConfig != null) {
              await _authProvider!.switchProfile(targetConfig);
            }
          }
        }
      }
    }
    
    final items = <MediaItem>[];

    if (player != null && player.currentSong != null) {
      items.add(_browsableItem(
        id: AudioService.recentRootId,
        title: _l10n.androidAutoNowPlaying,
        iconUri: _androidResourceUri('ic_auto_now_playing'),
        extras: {
          _contentStyleBrowsable: _contentStyleList,
          _contentStylePlayable: _contentStyleList,
        },
      ));
    }

    if (settings.getShowRecent()) {
      items.add(_browsableItem(
        id: _idRecent,
        title: _l10n.androidAutoRecent,
        iconUri: _androidResourceUri('ic_auto_recent'),
        extras: {
          _contentStyleBrowsable: _contentStyleList,
          _contentStylePlayable: _contentStyleList,
        },
      ));
    }

    if (!_isWebStream && settings.getShowFavorites()) {
      items.add(_browsableItem(
        id: _idFavorites,
        title: _l10n.androidAutoFavorites,
        iconUri: _androidResourceUri('ic_auto_favorites'),
        extras: {
          _contentStyleBrowsable: _contentStyleList,
          _contentStylePlayable: _contentStyleList,
        },
      ));
    }

    if (settings.getShowAlbums()) {
      items.add(_browsableItem(
        id: _idAlbums,
        title: _l10n.androidAutoAlbums,
        iconUri: _androidResourceUri('ic_auto_albums'),
        extras: {
          _contentStyleBrowsable: _contentStyleGrid,
          _contentStylePlayable: _contentStyleList,
        },
      ));
    }

    if (settings.getShowArtists()) {
      items.add(_browsableItem(
        id: _idArtists,
        title: _l10n.androidAutoArtists,
        iconUri: _androidResourceUri('ic_auto_artists'),
        extras: {
          _contentStyleBrowsable: _contentStyleList,
          _contentStylePlayable: _contentStyleList,
        },
      ));
    }

    if (settings.getShowPlaylists()) {
      items.add(_browsableItem(
        id: _idPlaylists,
        title: _l10n.androidAutoPlaylists,
        iconUri: _androidResourceUri('ic_auto_playlists'),
        extras: {
          _contentStyleBrowsable: _contentStyleGrid,
          _contentStylePlayable: _contentStyleList,
        },
      ));
    }

    if (!_isWebStream) {
      if (settings.getShowGenres()) {
        items.add(_browsableItem(
          id: _idGenres,
          title: _l10n.androidAutoGenres,
          iconUri: _androidResourceUri('ic_auto_genres'),
          extras: {
            _contentStyleBrowsable: _contentStyleList,
            _contentStylePlayable: _contentStyleList,
          },
        ));
      }

      if (settings.getShowRadio()) {
        items.add(_browsableItem(
          id: _idRadio,
          title: _l10n.androidAutoRadio,
          iconUri: _androidResourceUri('ic_auto_radio'),
          extras: {
            _contentStyleBrowsable: _contentStyleList,
            _contentStylePlayable: _contentStyleList,
          },
        ));
      }

      if (settings.getShowDownloads()) {
        items.add(_browsableItem(
          id: _idDownloads,
          title: _l10n.androidAutoDownloads,
          iconUri: _androidResourceUri('ic_auto_downloads'),
          extras: {
            _contentStyleBrowsable: _contentStyleList,
            _contentStylePlayable: _contentStyleList,
          },
        ));
      }
    }

    items.add(MediaItem(
      id: _idShuffle,
      title: _l10n.androidAutoShuffle,
      playable: true,
      artUri: _androidResourceUri('ic_auto_shuffle'),
    ));

    if (player != null && player.queue.isNotEmpty) {
      items.add(_browsableItem(
        id: _idQueue,
        title: '${_l10n.androidAutoQueue} (${player.queue.length})',
        iconUri: _androidResourceUri('ic_auto_queue'),
        extras: {
          _contentStyleBrowsable: _contentStyleList,
          _contentStylePlayable: _contentStyleList,
        },
      ));
    }

    return items;
  }

  int get _maxItemsPerCategory => AndroidAutoSettingsService().getMaxItems();

  Future<List<MediaItem>> _buildRecentItems() async {
    await _ensureLibraryReady();
    final lib = _libraryDelegate;
    if (lib == null) return const [];

    var songs = lib.cachedAllSongs.isNotEmpty ? lib.cachedAllSongs : _playerDelegate?.randomSongs ?? [];

    if (lib.isServerOfflineMode) {
      final ids = await _getDownloadedIds();
      songs = songs.where((s) => ids.contains(s.id)).toList();
    }

    return songs.take(_maxItemsPerCategory).map(_songToMediaItem).toList();
  }

  Future<List<MediaItem>> _buildFavoritesItems() async {
    await _ensureLibraryReady();
    final lib = _libraryDelegate;
    if (lib == null) return const [];

    final starred = lib.cachedAllSongs.where((s) => s.starred == true).toList();
    if (starred.isEmpty) {
      return [
        MediaItem(
          id: 'auto_empty_favorites',
          title: _l10n.androidAutoEmptyFavorites,
          playable: false,
        ),
      ];
    }
    return starred.take(_maxItemsPerCategory).map(_songToMediaItem).toList();
  }

  Future<List<MediaItem>> _buildAlbumItems() async {
    await _ensureLibraryReady();
    final lib = _libraryDelegate;
    if (lib == null) return const [];

    var albums = lib.cachedAllAlbums;

    if (lib.isServerOfflineMode) {
      final ids = await _getDownloadedIds();
      final albumIds = lib.cachedAllSongs
          .where((s) => ids.contains(s.id))
          .map((s) => s.albumId)
          .whereType<String>()
          .toSet();
      albums = albums.where((a) => albumIds.contains(a.id)).toList();
    }

    return albums.take(_maxItemsPerCategory).map(_albumToMediaItem).toList();
  }

  Future<List<MediaItem>> _buildArtistItems() async {
    await _ensureLibraryReady();
    final lib = _libraryDelegate;
    if (lib == null) return const [];

    var artistList = lib.artists;

    if (lib.isServerOfflineMode) {
      final ids = await _getDownloadedIds();
      final artistIds = lib.cachedAllSongs
          .where((s) => ids.contains(s.id))
          .map((s) => s.artistId)
          .whereType<String>()
          .toSet();
      artistList = artistList.where((a) => artistIds.contains(a.id)).toList();
    }

    return artistList.take(_maxItemsPerCategory).map(_artistToMediaItem).toList();
  }

  Future<List<MediaItem>> _buildPlaylistItems() async {
    await _ensureLibraryReady();
    final lib = _libraryDelegate;
    if (lib == null) return const [];

    var playlistList = lib.playlists;

    if (lib.isServerOfflineMode) {
      final ids = await _getDownloadedIds();
      playlistList = playlistList
          .where((p) => p.songs?.any((s) => ids.contains(s.id)) ?? false)
          .toList();
    }

    return playlistList.take(_maxItemsPerCategory).map(_playlistToMediaItem).toList();
  }

  Future<List<MediaItem>> _buildGenreItems() async {
    await _ensureLibraryReady();
    final lib = _libraryDelegate;
    if (lib == null) return const [];

    final genres = lib.richGenres;
    return genres.take(_maxItemsPerCategory).map((g) => _browsableItem(
      id: '$_prefixGenre${Uri.encodeComponent(g.value)}',
      title: g.value,
      displaySubtitle: '${g.songCount} brani',
      iconUri: _androidResourceUri('ic_auto_genres'),
    )).toList();
  }

  Future<List<MediaItem>> _buildRadioItems() async {
    try {
      final stations = await _subsonicService.getInternetRadioStations();
      if (stations.isEmpty) {
        return [
          MediaItem(
            id: 'auto_empty_radio',
            title: _l10n.androidAutoEmptyRadio,
            playable: false,
          ),
        ];
      }
      return stations.take(_maxItemsPerCategory).map((station) => MediaItem(
        id: '$_prefixRadio${station.id}',
        title: station.name,
        displaySubtitle: station.homePageUrl,
        playable: true,
      )).toList();
    } catch (e) {
      debugPrint('[AndroidAutoService] _buildRadioItems error: $e');
      return const [];
    }
  }

  Future<List<MediaItem>> _buildDownloadItems() async {
    await _offlineService.initialize();
    final ids = _offlineService.getDownloadedSongIds().toSet();
    final lib = _libraryDelegate;
    if (lib == null || ids.isEmpty) {
      return [
        MediaItem(
          id: 'auto_empty_downloads',
          title: _l10n.androidAutoEmptyDownloads,
          playable: false,
        ),
      ];
    }

    final downloaded = lib.cachedAllSongs.where((s) => ids.contains(s.id)).toList();
    return downloaded.take(_maxItemsPerCategory).map((song) {
      final localCover = _offlineService.getLocalCoverArtPath(song.id);
      final artUri = localCover != null && File(localCover).existsSync()
          ? Uri.file(localCover)
          : _tryArtUri(lib.getCoverArtUrl(song.coverArt));
      return MediaItem(
        id: '$_prefixSong${song.id}',
        title: song.title,
        artist: song.artist,
        album: song.album,
        artUri: artUri,
        duration: song.duration != null ? Duration(seconds: song.duration!) : null,
        playable: true,
      );
    }).toList();
  }

  Future<List<MediaItem>> _buildQueueItems() async {
    final player = _playerDelegate;
    if (player == null || player.queue.isEmpty) return const [];

    final lib = _libraryDelegate;
    return player.queue.asMap().entries.map((entry) {
      final i = entry.key;
      final song = entry.value;
      final artUrl = lib?.getCoverArtUrl(song.coverArt) ?? '';
      return MediaItem(
        id: '$_prefixSong${song.id}',
        title: i == player.currentIndex ? '▶ ${song.title}' : song.title,
        artist: song.artist,
        album: song.album,
        artUri: _tryArtUri(artUrl),
        duration: song.duration != null ? Duration(seconds: song.duration!) : null,
        playable: true,
        extras: {'queueIndex': i},
      );
    }).toList();
  }

  Future<List<MediaItem>> _buildAlbumSongItems(String albumId) async {
    final lib = _libraryDelegate;
    if (lib == null) return const [];
    try {
      if (lib.isServerOfflineMode) {
        final ids = await _getDownloadedIds();
        final songs = lib.cachedAllSongs
            .where((s) => s.albumId == albumId && ids.contains(s.id))
            .toList();
        if (songs.isNotEmpty) return songs.map(_songToMediaItem).toList();
      }
      final songs = await lib.getAlbumSongs(albumId);
      return songs.map(_songToMediaItem).toList();
    } catch (e) {
      debugPrint('[AndroidAutoService] _buildAlbumSongItems($albumId) error: $e');
      return const [];
    }
  }

  Future<List<MediaItem>> _buildArtistAlbumItems(String artistId) async {
    final lib = _libraryDelegate;
    if (lib == null) return const [];
    try {
      if (lib.isServerOfflineMode) {
        final ids = await _getDownloadedIds();
        final albumIds = lib.cachedAllSongs
            .where((s) => s.artistId == artistId && ids.contains(s.id))
            .map((s) => s.albumId)
            .whereType<String>()
            .toSet();
        final albums = lib.cachedAllAlbums.where((a) => albumIds.contains(a.id)).toList();
        if (albums.isNotEmpty) return albums.map(_albumToMediaItem).toList();
      }
      final albums = await lib.getArtistAlbums(artistId);
      return albums.map(_albumToMediaItem).toList();
    } catch (e) {
      debugPrint('[AndroidAutoService] _buildArtistAlbumItems($artistId) error: $e');
      return const [];
    }
  }

  Future<List<MediaItem>> _buildPlaylistSongItems(String playlistId) async {
    final lib = _libraryDelegate;
    if (lib == null) return const [];
    try {
      if (lib.isServerOfflineMode) {
        final ids = await _getDownloadedIds();
        final cached = lib.playlists.firstWhere(
          (p) => p.id == playlistId,
          orElse: () => Playlist(
            id: playlistId,
            name: '',
            songCount: 0,
            duration: 0,
          ),
        );
        if (cached.songs != null && cached.songs!.isNotEmpty) {
          final offline = cached.songs!.where((s) => ids.contains(s.id)).toList();
          if (offline.isNotEmpty) return offline.map(_songToMediaItem).toList();
        }
      }
      final playlist = await lib.getPlaylist(playlistId);
      final songs = playlist.songs ?? [];
      return songs.map(_songToMediaItem).toList();
    } catch (e) {
      debugPrint('[AndroidAutoService] _buildPlaylistSongItems($playlistId) error: $e');
      return const [];
    }
  }

  Future<List<MediaItem>> _buildGenreSongItems(String genre) async {
    final lib = _libraryDelegate;
    if (lib == null) return const [];
    try {
      if (lib.isServerOfflineMode) {
        final ids = await _getDownloadedIds();
        final songs = lib.cachedAllSongs
            .where((s) => ids.contains(s.id) && s.genre?.toLowerCase() == genre.toLowerCase())
            .take(_maxItemsPerCategory)
            .toList();
        return songs.map(_songToMediaItem).toList();
      }
      final songs = await lib.getSongsByGenre(genre);
      return songs.take(_maxItemsPerCategory).map(_songToMediaItem).toList();
    } catch (e) {
      debugPrint('[AndroidAutoService] _buildGenreSongItems($genre) error: $e');
      return const [];
    }
  }

  Future<void> _playBySongId(String songId) async {
    final player = _playerDelegate;
    final lib = _libraryDelegate;
    if (player == null) return;

    final queueIdx = player.queue.indexWhere((s) => s.id == songId);
    if (queueIdx != -1) {
      await player.skipToIndex(queueIdx);
      return;
    }

    if (lib != null) {
      final allSongs = lib.cachedAllSongs;
      final idx = allSongs.indexWhere((s) => s.id == songId);
      if (idx != -1) {
        await player.playSong(allSongs[idx], playlist: allSongs, startIndex: idx);
        return;
      }
    }

    try {
      var song = _songCache[songId];
      if (song == null && lib != null) {
        final result = await lib.search(songId);
        if (result.songs.isNotEmpty) {
          song = result.songs.firstWhere((s) => s.id == songId, orElse: () => result.songs.first);
        }
      }

      if (song != null) {
        await player.playSong(song);
      } else if (_isWebStream) {
        final tempSong = Song(id: songId, title: _l10n.androidAutoLoading, artist: _l10n.androidAutoOnlineStream, duration: 0);
        await player.playSong(tempSong);
      }
    } catch (e) {
      debugPrint('[AndroidAutoService] _playBySongId($songId) error: $e');
    }
  }

  Future<void> _playRadioStation(String stationId) async {
    final player = _playerDelegate;
    if (player == null) return;
    try {
      final stations = await _subsonicService.getInternetRadioStations();
      final station = stations.firstWhere((s) => s.id == stationId, orElse: () => throw Exception('Station not found'));
      final radioSong = Song(
        id: 'radio_$stationId',
        title: station.name,
        artist: 'Radio',
        path: station.streamUrl,
        duration: 0,
      );
      await player.playSong(radioSong);
    } catch (e) {
      debugPrint('[AndroidAutoService] _playRadioStation($stationId) error: $e');
    }
  }

  Future<void> _playRandomSong() async {
    final player = _playerDelegate;
    final lib = _libraryDelegate;
    if (player == null) return;

    final songs = lib?.cachedAllSongs ?? player.randomSongs;
    if (songs.isEmpty) return;
    await player.shuffleLibrary();
  }

  Future<void> _ensureLibraryReady() async {
    final lib = _libraryDelegate;
    if (lib == null) return;
    if (lib.isInitialized) return;

    try {
      await lib.initialize();
    } catch (_) {}

    if (!lib.isInitialized) {
      for (var i = 0; i < 40 && !lib.isInitialized; i++) {
        await Future.delayed(const Duration(milliseconds: 200));
      }
    }
  }

  Future<Set<String>> _getDownloadedIds() async {
    await _offlineService.initialize();
    return _offlineService.getDownloadedSongIds().toSet();
  }

  final Map<String, Song> _songCache = {};

  MediaItem _songToMediaItem(Song song) {
    if (_songCache.length > 2000) _songCache.clear();
    _songCache[song.id] = song;
    final lib = _libraryDelegate;
    String? artUrl;

    if (song.isLocal) {
      if (song.coverArt != null) artUrl = Uri.file(song.coverArt!).toString();
    } else {
      final localCover = _offlineService.getLocalCoverArtPath(song.id);
      if (localCover != null && File(localCover).existsSync()) {
        artUrl = Uri.file(localCover).toString();
      } else if (lib != null) {
        artUrl = _subsonicService.getCoverArtUrl(song.coverArt, size: _artworkSize);
      }
    }

    return MediaItem(
      id: '$_prefixSong${song.id}',
      title: song.title,
      artist: song.artist,
      album: song.album,
      artUri: _tryArtUri(artUrl),
      duration: song.duration != null ? Duration(seconds: song.duration!) : null,
      playable: true,
      extras: {
        if (song.genre != null) 'genre': song.genre,
        if (song.year != null) 'year': song.year,
        if (song.track != null) 'trackNumber': song.track,
        'starred': song.starred ?? false,
      },
    );
  }

  MediaItem _albumToMediaItem(Album album) {
    final lib = _libraryDelegate;
    final artUrl = lib?.getCoverArtUrl(album.coverArt) ??
        _subsonicService.getCoverArtUrl(album.coverArt, size: _artworkSize);
    return MediaItem(
      id: '$_prefixAlbum${album.id}',
      title: album.name,
      artist: album.artist,
      artUri: _tryArtUri(artUrl),
      playable: false,
      extras: {
        if (album.year != null) 'year': album.year,
        'songCount': album.songCount,
      },
    );
  }

  MediaItem _artistToMediaItem(Artist artist) {
    return MediaItem(
      id: '$_prefixArtist${artist.id}',
      title: artist.name,
      displaySubtitle: artist.albumCount != null ? '${artist.albumCount} album' : null,
      playable: false,
    );
  }

  MediaItem _playlistToMediaItem(Playlist playlist) {
    final lib = _libraryDelegate;
    final artUrl = lib?.getCoverArtUrl(playlist.coverArt) ??
        _subsonicService.getCoverArtUrl(playlist.coverArt, size: _artworkSize);
    return MediaItem(
      id: '$_prefixPlaylist${playlist.id}',
      title: playlist.name,
      displaySubtitle: '${playlist.songCount} brani',
      artUri: _tryArtUri(artUrl),
      playable: false,
    );
  }

  MediaItem _browsableItem({
    required String id,
    required String title,
    String? displaySubtitle,
    Uri? iconUri,
    Map<String, dynamic>? extras,
  }) {
    return MediaItem(
      id: id,
      title: title,
      displaySubtitle: displaySubtitle,
      artUri: iconUri,
      playable: false,
      extras: extras,
    );
  }

  Song _mediaItemToSong(MediaItem item) {
    final rawId = item.id.startsWith(_prefixSong)
        ? item.id.substring(_prefixSong.length)
        : item.id;
    return Song(
      id: rawId,
      title: item.title,
      artist: item.artist,
      album: item.album,
      coverArt: item.artUri?.toString(),
      duration: item.duration?.inSeconds,
    );
  }

  static Uri? _tryArtUri(String? url) {
    if (url == null || url.isEmpty) return null;
    return Uri.tryParse(url);
  }

  static Uri _androidResourceUri(String drawableName) {
    return Uri.parse('android.resource://com.devid.musly/drawable/$drawableName');
  }
}
