import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/models.dart';
import '../services/audio_handler.dart';
import '../services/local_music_service.dart';
import '../services/services.dart';
import '../widgets/common/album_artwork.dart';

class LibraryProvider extends ChangeNotifier {
  final SubsonicService _subsonicService;
  final MuslyAudioHandler _audioHandler;

  bool _localOnlyMode = false;
  bool _serverOfflineMode = false;
  bool _mergeLocalLibrary = false;
  LocalMusicService? _localMusicService;
  final LibraryDatabaseService _db = LibraryDatabaseService();

  List<Artist> _artists = [];
  List<Album> _recentAlbums = [];
  List<Album> _frequentAlbums = [];
  List<Album> _newestAlbums = [];
  List<Album> _randomAlbums = [];
  List<Playlist> _playlists = [];
  List<Song> _randomSongs = [];
  List<String> _genres = [];
  List<Genre> _richGenres = [];
  SearchResult? _starred;

  List<Album> _cachedAllAlbums = [];
  List<Song> _cachedAllSongs = [];
  List<Playlist> _cachedPlaylists = [];
  DateTime? _lastCacheUpdate;

  bool _isLoading = false;
  bool _isInitialized = false;
  String? _error;

  static const String _playlistsCacheKey = 'cached_playlists';
  static const String _artistsCacheKey = 'cached_artists';
  static const String _lastUpdateKey = 'last_cache_update';

  LibraryProvider(this._subsonicService, this._audioHandler) {
    _audioHandler.onGetRecentSongs = _recentSongsForAuto;
    _audioHandler.onGetLibraryAlbums = _albumsForAuto;
    _audioHandler.onGetLibraryArtists = _artistsForAuto;
    _audioHandler.onGetLibraryPlaylists = _playlistsForAuto;
    _audioHandler.onIsYoutubeMode = () => _subsonicService.isYoutube;
  }

  SubsonicService get subsonicService => _subsonicService;
  bool get isLocalOnlyMode => _localOnlyMode;
  bool get isServerOfflineMode => _serverOfflineMode;
  bool get mergeLocalLibrary => _mergeLocalLibrary;
  List<Album> get recentAlbums => _recentAlbums;
  List<Album> get frequentAlbums => _frequentAlbums;
  List<Album> get newestAlbums => _newestAlbums;
  List<Album> get randomAlbums => _randomAlbums;
  List<Playlist> get playlists => _playlists;
  List<Song> get randomSongs => _randomSongs;
  List<String> get genres => _genres;
  List<Genre> get richGenres => _richGenres;
  SearchResult? get starred => _starred;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  String? get error => _error;

  void setLocalMusicService(
    LocalMusicService service, {
    bool mergeWithServer = false,
  }) {
    _localMusicService?.removeListener(_onLocalMusicServiceChanged);
    _localMusicService = service;
    _localOnlyMode = !mergeWithServer;
    _mergeLocalLibrary = mergeWithServer;
    _isInitialized = false;
    service.addListener(_onLocalMusicServiceChanged);
    if (mergeWithServer) {
      _onLocalMusicServiceChanged();
    }
  }

  void _onLocalMusicServiceChanged() {
    if (_localMusicService == null || _localMusicService!.isScanning) return;

    if (_localOnlyMode) {
      _cachedAllSongs = List.from(_localMusicService!.songs);
      _cachedAllAlbums = List.from(_localMusicService!.albums);
      _artists = List.from(_localMusicService!.artists);
      _randomSongs = _cachedAllSongs.take(50).toList();
      _recentAlbums = _cachedAllAlbums.take(20).toList();
      _isInitialized = true;
      _isLoading = false;
      notifyListeners();
    } else if (_mergeLocalLibrary) {
      notifyListeners();
    }
  }

  void setMergeLocalLibrary(bool enabled) {
    if (_mergeLocalLibrary == enabled) return;
    _mergeLocalLibrary = enabled;
    notifyListeners();
  }

  void setLocalOnlyMode(bool enabled) {
    if (!enabled && _localOnlyMode) {
      _localMusicService?.removeListener(_onLocalMusicServiceChanged);
      _localMusicService = null;
      _cachedAllSongs = [];
      _cachedAllAlbums = [];
      _artists = [];
      _randomSongs = [];
      _recentAlbums = [];
      _playlists = [];
      _cachedPlaylists = [];
    }
    _localOnlyMode = enabled;
    _isInitialized = false;
    notifyListeners();
  }

  void setServerOfflineMode(bool offline) {
    _serverOfflineMode = offline;
  }

  String getCoverArtUrl(String? coverArt) {
    return _subsonicService.getCoverArtUrl(coverArt, size: 300);
  }

  List<Album> get cachedAllAlbums {
    if (!_mergeLocalLibrary ||
        _localMusicService == null ||
        _localMusicService!.isEmpty) {
      return _cachedAllAlbums;
    }
    final localAlbums = _localMusicService!.albums;
    final merged = [..._cachedAllAlbums];
    for (final localAlbum in localAlbums) {
      if (!merged.any((album) => album.id == localAlbum.id)) {
        merged.add(localAlbum);
      }
    }
    return merged;
  }

  List<Song> get cachedAllSongs {
    if (!_mergeLocalLibrary ||
        _localMusicService == null ||
        _localMusicService!.isEmpty) {
      return _cachedAllSongs;
    }
    final localSongs = _localMusicService!.songs;
    final merged = [..._cachedAllSongs];
    for (final localSong in localSongs) {
      if (!merged.any((song) => song.id == localSong.id)) {
        merged.add(localSong);
      }
    }
    return merged;
  }

  List<Artist> get artists {
    if (!_mergeLocalLibrary ||
        _localMusicService == null ||
        _localMusicService!.isEmpty) {
      return _artists;
    }
    final localArtists = _localMusicService!.artists;
    final merged = [..._artists];
    for (final localArtist in localArtists) {
      if (!merged.any((artist) => artist.id == localArtist.id)) {
        merged.add(localArtist);
      }
    }
    return merged;
  }

  Future<void> initialize() async {
    if (_isInitialized) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      if (_localOnlyMode && _localMusicService != null) {
        _cachedAllSongs = List.from(_localMusicService!.songs);
        _cachedAllAlbums = List.from(_localMusicService!.albums);
        _artists = List.from(_localMusicService!.artists);
        _randomSongs = _cachedAllSongs.take(50).toList();
        _recentAlbums = _cachedAllAlbums.take(20).toList();
        _isInitialized = true;
        _isLoading = false;
        notifyListeners();
        return;
      }

      await _loadCachedData(loadFullLibrary: true);

      if (_recentAlbums.isEmpty && _cachedAllAlbums.isNotEmpty) {
        _recentAlbums = _cachedAllAlbums.take(20).toList();
      }
      if (_randomSongs.isEmpty && _cachedAllSongs.isNotEmpty) {
        _randomSongs = _cachedAllSongs.take(50).toList();
      }
      if (_playlists.isEmpty && _cachedPlaylists.isNotEmpty) {
        _playlists = _cachedPlaylists;
      }

      _audioHandler.notifyAutoChildrenChanged();

      if (!_serverOfflineMode) {
        try {
          await Future.wait([
            loadRecentAlbums(),
            loadRandomSongs(),
            loadPlaylists(),
            loadArtists(),
          ]).timeout(
            const Duration(seconds: 5),
            onTimeout: () => throw TimeoutException('Server not responding'),
          );
        } catch (_) {}
      }

      _isInitialized = true;
      _preloadCoverArt();
      _scheduleBackgroundRefresh();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> ensureLibraryLoaded() async {
    if (_cachedAllSongs.isNotEmpty) return;

    if (_localOnlyMode && _localMusicService != null) {
      _cachedAllSongs = List.from(_localMusicService!.songs);
      _cachedAllAlbums = List.from(_localMusicService!.albums);
      _artists = List.from(_localMusicService!.artists);
      _randomSongs = _cachedAllSongs.take(50).toList();
      _recentAlbums = _cachedAllAlbums.take(20).toList();
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();

    await _loadCachedData(loadFullLibrary: true);

    if (_cachedAllSongs.isEmpty) {
      await _refreshAllDataInBackground();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _loadCachedData({bool loadFullLibrary = false}) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final playlistsJson = prefs.getString(_playlistsCacheKey);
      if (playlistsJson != null) {
        final List<dynamic> playlistsList = json.decode(playlistsJson);
        _cachedPlaylists = playlistsList
            .map((playlistMap) =>
                Playlist.fromJson(playlistMap as Map<String, dynamic>))
            .toList();
        _playlists = _cachedPlaylists;
      }

      if (_subsonicService.isYoutube) {
        _cachedAllAlbums = [];
        _cachedAllSongs = await _db.getAllSongs();
        _cachedPlaylists = await _subsonicService.getPlaylists();
        _playlists = _cachedPlaylists;

        final songMap = {for (final song in _cachedAllSongs) song.id: song};
        for (final playlist in _playlists) {
          if (playlist.songs != null) {
            for (final song in playlist.songs!) {
              songMap[song.id] = song;
            }
          }
        }
        _cachedAllSongs = songMap.values.toList();

        final artistMap = <String, int>{};
        for (final song in _cachedAllSongs) {
          if (song.artist != null &&
              song.artist!.isNotEmpty &&
              song.artist != 'Unknown') {
            artistMap[song.artist!] = (artistMap[song.artist!] ?? 0) + 1;
          }
        }
        _artists = artistMap.keys
            .map((name) => Artist(id: 'yt-$name', name: name))
            .toList();

        if (_randomSongs.isEmpty && _cachedAllSongs.isNotEmpty) {
          _randomSongs = _cachedAllSongs.take(50).toList();
        } else if (_cachedAllSongs.isEmpty) {
          Future.microtask(() => loadRandomSongs());
        }
        return;
      }

      final artistsJson = prefs.getString(_artistsCacheKey);
      if (artistsJson != null) {
        final List<dynamic> artistsList = json.decode(artistsJson);
        _artists = artistsList
            .map((artistMap) =>
                Artist.fromJson(artistMap as Map<String, dynamic>))
            .toList();
      }

      if (loadFullLibrary) {
        try {
          _cachedAllAlbums = await _db.getAllAlbums();
          _cachedAllSongs = await _db.getAllSongs();
        } catch (_) {}
      }

      final lastUpdate = prefs.getInt(_lastUpdateKey);
      if (lastUpdate != null) {
        _lastCacheUpdate = DateTime.fromMillisecondsSinceEpoch(lastUpdate);
      }
    } catch (_) {}
  }

  void _scheduleBackgroundRefresh() {
    if (_cachedAllSongs.isEmpty || _subsonicService.isYoutube) return;

    final shouldRefresh = _lastCacheUpdate == null ||
        DateTime.now().difference(_lastCacheUpdate!) > const Duration(hours: 6);

    if (shouldRefresh) {
      Future.delayed(const Duration(seconds: 5), () {
        _refreshAllDataInBackground();
      });
    }
  }

  Future<void> _refreshAllDataInBackground() async {
    if (_subsonicService.isYoutube) return;
    try {
      const pageSize = 500;
      int offset = 0;
      final List<Album> allAlbums = [];
      final seenSongIds = <String>{};

      await _db.clearServerData();

      while (true) {
        final page = await _subsonicService.getAlbumList(
          type: 'alphabeticalByName',
          size: pageSize,
          offset: offset,
        );
        if (page.isEmpty) break;
        allAlbums.addAll(page);
        await _db.insertAlbumsBatch(page);
        if (page.length < pageSize) break;
        offset += pageSize;
      }

      if (_subsonicService.isJellyfin) {
        try {
          final allSongs = await _subsonicService.getAllSongs();
          for (final song in allSongs) {
            seenSongIds.add(song.id);
          }
          await _db.insertSongsBatch(allSongs);
        } catch (_) {}
      }

      if (seenSongIds.isEmpty) {
        final albumCount = await _db.getAlbumCount();
        const albumBatchSize = 50;
        for (int batchOffset = 0;
            batchOffset < albumCount;
            batchOffset += albumBatchSize) {
          final albums = await _db.getAlbumsPaginated(
            limit: albumBatchSize,
            offset: batchOffset,
          );
          for (final album in albums) {
            try {
              final albumSongs = await _subsonicService.getAlbumSongs(album.id);
              final newSongs =
                  albumSongs.where((song) => seenSongIds.add(song.id)).toList();
              if (newSongs.isNotEmpty) {
                await _db.insertSongsBatch(newSongs);
              }
            } catch (_) {}
          }
        }
      }

      _cachedAllAlbums = allAlbums;
      _cachedAllSongs = await _db.getAllSongs();
      _lastCacheUpdate = DateTime.now();

      await _saveCachedData();
      notifyListeners();
    } catch (_) {}
  }

  Future<void> _saveCachedData() async {
    try {
      if (!_subsonicService.isYoutube) {
        await _db.insertAlbumsBatch(_cachedAllAlbums);
        await _db.insertSongsBatch(_cachedAllSongs);
      }

      final prefs = await SharedPreferences.getInstance();
      final playlistsJson = json.encode(
        _cachedPlaylists.map((playlist) => playlist.toJson()).toList(),
      );
      await prefs.setString(_playlistsCacheKey, playlistsJson);

      if (!_subsonicService.isYoutube && _artists.isNotEmpty) {
        final artistsJson = json.encode(
          _artists.map((artist) => artist.toJson()).toList(),
        );
        await prefs.setString(_artistsCacheKey, artistsJson);
      }

      await prefs.setInt(
        _lastUpdateKey,
        _lastCacheUpdate?.millisecondsSinceEpoch ??
            DateTime.now().millisecondsSinceEpoch,
      );
    } catch (_) {}
  }

  Future<void> _ensureInitializedForAuto() async {
    if (_isInitialized) return;
    if (!_isLoading) {
      try {
        await initialize();
      } catch (_) {}
      return;
    }

    for (var i = 0; i < 40 && _isLoading && !_isInitialized; i++) {
      await Future.delayed(const Duration(milliseconds: 200));
    }
  }

  Future<Set<String>> _downloadedSongIdsForAuto() async {
    final offlineService = OfflineService();
    await offlineService.initialize();
    return offlineService.getDownloadedSongIds().toSet();
  }

  Future<List<Map<String, dynamic>>> _recentSongsForAuto() async {
    await _ensureInitializedForAuto();
    var songs = _subsonicService.isYoutube
        ? (_cachedAllSongs.isNotEmpty ? _cachedAllSongs : _randomSongs)
        : _randomSongs;
    if (_serverOfflineMode) {
      final downloadedIds = await _downloadedSongIdsForAuto();
      songs = _cachedAllSongs
          .where((song) => downloadedIds.contains(song.id))
          .toList();
    }
    return songs
        .take(50)
        .map(
          (song) => <String, dynamic>{
            'id': song.id,
            'title': song.title,
            'artist': song.artist ?? '',
            'album': song.album ?? '',
            'artworkUrl': getCoverArtUrl(song.coverArt),
            'duration': song.duration ?? 0,
          },
        )
        .toList();
  }

  Future<List<Map<String, dynamic>>> _albumsForAuto() async {
    await _ensureInitializedForAuto();
    var albums = _recentAlbums;
    if (_serverOfflineMode) {
      final downloadedIds = await _downloadedSongIdsForAuto();
      final albumIdsWithDownloads = _cachedAllSongs
          .where((song) => downloadedIds.contains(song.id))
          .map((song) => song.albumId)
          .whereType<String>()
          .toSet();
      albums = _cachedAllAlbums
          .where((album) => albumIdsWithDownloads.contains(album.id))
          .toList();
    }
    return albums
        .take(100)
        .map(
          (album) => <String, dynamic>{
            'id': album.id,
            'name': album.name,
            'artist': album.artist ?? '',
            'artworkUrl': getCoverArtUrl(album.coverArt),
          },
        )
        .toList();
  }

  Future<List<Map<String, dynamic>>> _artistsForAuto() async {
    await _ensureInitializedForAuto();
    var artists = _artists;
    if (_serverOfflineMode) {
      final downloadedIds = await _downloadedSongIdsForAuto();
      final artistIdsWithDownloads = _cachedAllSongs
          .where((song) => downloadedIds.contains(song.id))
          .map((song) => song.artistId)
          .whereType<String>()
          .toSet();
      artists = _artists
          .where((artist) => artistIdsWithDownloads.contains(artist.id))
          .toList();
    }
    return artists
        .take(100)
        .map(
          (artist) => <String, dynamic>{
            'id': artist.id,
            'name': artist.name,
            'albumCount': artist.albumCount,
          },
        )
        .toList();
  }

  Future<List<Map<String, dynamic>>> _playlistsForAuto() async {
    await _ensureInitializedForAuto();
    var playlists = _playlists;
    if (_serverOfflineMode) {
      final downloadedIds = await _downloadedSongIdsForAuto();
      playlists = _playlists
          .where(
            (playlist) =>
                playlist.songs
                    ?.any((song) => downloadedIds.contains(song.id)) ??
                false,
          )
          .toList();
    }
    return playlists
        .take(50)
        .map(
          (playlist) => <String, dynamic>{
            'id': playlist.id,
            'name': playlist.name,
            'songCount': playlist.songCount,
            'artworkUrl': getCoverArtUrl(playlist.coverArt),
          },
        )
        .toList();
  }

  void _preloadCoverArt() {
    Future.microtask(() async {
      final allAlbums = [..._recentAlbums, ..._randomAlbums];
      for (final album in allAlbums.take(20)) {
        if (album.coverArt != null) {
          try {
            final url = _subsonicService.getCoverArtUrl(
              album.coverArt,
              size: 300,
            );
            if (url.isNotEmpty) {
              _subsonicService.getCoverArtUrl(album.coverArt, size: 300);
            }
          } catch (_) {}
        }
      }
    });
  }

  Future<void> refresh() async {
    _isInitialized = false;
    _lastCacheUpdate = null;
    _artists = [];
    _cachedAllAlbums = [];
    _cachedAllSongs = [];
    _recentAlbums = [];
    _frequentAlbums = [];
    _newestAlbums = [];
    _randomAlbums = [];
    _playlists = [];
    _cachedPlaylists = [];
    _randomSongs = [];
    _richGenres = [];
    _genres = [];
    _starred = null;
    ImageUrlCache.clear();
    try {
      if (!_subsonicService.isYoutube) {
        await _db.clearServerData();
      }
    } catch (_) {}
    notifyListeners();
    await initialize();

    if (!_serverOfflineMode && !_localOnlyMode && !_subsonicService.isYoutube) {
      _refreshAllDataInBackground();
    }
  }

  Future<void> loadArtists() async {
    if (_serverOfflineMode) return;
    try {
      _artists = await _subsonicService.getArtists();
      notifyListeners();
      _audioHandler
          .notifyAutoChildrenChanged([MuslyAudioHandler.mediaIdArtists]);
      _saveCachedData();
    } catch (_) {}
  }

  Future<void> loadRecentAlbums() async {
    if (_serverOfflineMode) return;
    try {
      final fetched = await _subsonicService.getAlbumList(
        type: 'recent',
        size: 20,
      );
      if (fetched.isNotEmpty) {
        _recentAlbums = fetched;
      }
      notifyListeners();
      _audioHandler
          .notifyAutoChildrenChanged([MuslyAudioHandler.mediaIdAlbums]);
    } catch (_) {}
  }

  Future<void> loadFrequentAlbums() async {
    if (_serverOfflineMode) return;
    try {
      _frequentAlbums = await _subsonicService.getAlbumList(
        type: 'frequent',
        size: 20,
      );
      notifyListeners();
    } catch (_) {}
  }

  Future<void> loadNewestAlbums() async {
    if (_serverOfflineMode) return;
    try {
      _newestAlbums = await _subsonicService.getAlbumList(
        type: 'newest',
        size: 20,
      );
      notifyListeners();
    } catch (_) {}
  }

  Future<void> loadRandomAlbums() async {
    if (_serverOfflineMode) return;
    try {
      _randomAlbums = await _subsonicService.getAlbumList(
        type: 'random',
        size: 20,
      );
      notifyListeners();
    } catch (_) {}
  }

  Future<void> loadPlaylists() async {
    if (_serverOfflineMode) return;
    try {
      final newPlaylists = await _subsonicService.getPlaylists();
      final List<Playlist> mergedPlaylists = [];

      for (final newPlaylist in newPlaylists) {
        final cachedIndex = _cachedPlaylists.indexWhere(
          (playlist) => playlist.id == newPlaylist.id,
        );
        if (cachedIndex != -1) {
          final cached = _cachedPlaylists[cachedIndex];
          if (cached.songs != null && cached.songs!.isNotEmpty) {
            mergedPlaylists.add(newPlaylist.copyWith(songs: cached.songs));
            continue;
          }
        }
        mergedPlaylists.add(newPlaylist);
      }

      _playlists = mergedPlaylists;
      _cachedPlaylists = _playlists;
      _saveCachedData();
      notifyListeners();
      _audioHandler
          .notifyAutoChildrenChanged([MuslyAudioHandler.mediaIdPlaylists]);
    } catch (_) {
      if (_playlists.isEmpty && _cachedPlaylists.isNotEmpty) {
        _playlists = _cachedPlaylists;
        notifyListeners();
      }
    }
  }

  Future<void> loadRandomSongs() async {
    if (_serverOfflineMode) return;
    try {
      final songs = await _subsonicService.getRandomSongs(size: 50);
      _randomSongs = songs;
      if (_subsonicService.isYoutube && songs.isNotEmpty) {
        final existingMap = {for (final song in _cachedAllSongs) song.id: song};
        for (final song in songs) {
          existingMap[song.id] = song;
        }
        _cachedAllSongs = existingMap.values.toList();

        final artistMap = <String, int>{};
        for (final song in _cachedAllSongs) {
          if (song.artist != null &&
              song.artist!.isNotEmpty &&
              song.artist != 'Unknown') {
            artistMap[song.artist!] = (artistMap[song.artist!] ?? 0) + 1;
          }
        }
        _artists = artistMap.keys
            .map((name) => Artist(id: 'yt-$name', name: name))
            .toList();
      }
      notifyListeners();
      _audioHandler
          .notifyAutoChildrenChanged([MuslyAudioHandler.mediaIdRecent]);
    } catch (_) {}
  }

  Future<void> loadGenres() async {
    if (_serverOfflineMode) return;
    try {
      _richGenres = await _subsonicService.getGenres();
      _genres = _richGenres.map((genre) => genre.value).toList();
      notifyListeners();
    } catch (_) {}
  }

  Future<void> loadStarred() async {
    if (_serverOfflineMode) return;
    try {
      _starred = await _subsonicService.getStarred();
      notifyListeners();
    } catch (_) {}
  }

  Future<List<Album>> getArtistAlbums(String artistId) async {
    if (_localOnlyMode && _localMusicService != null) {
      return _localMusicService!.getAlbumsByArtist(artistId);
    }
    try {
      return await _subsonicService.getArtistAlbums(artistId);
    } catch (_) {
      return [];
    }
  }

  Future<List<Song>> getAlbumSongs(String albumId) async {
    if (_localOnlyMode && _localMusicService != null) {
      return _localMusicService!.getSongsByAlbum(albumId);
    }
    try {
      return await _subsonicService.getAlbumSongs(albumId);
    } catch (_) {
      return [];
    }
  }

  Future<Playlist> getPlaylist(String playlistId) async {
    if (_serverOfflineMode) {
      final cached = _playlists.firstWhere(
        (playlist) => playlist.id == playlistId,
        orElse: () => _cachedPlaylists.firstWhere(
          (playlist) => playlist.id == playlistId,
          orElse: () => throw Exception('Playlist not available offline'),
        ),
      );
      return cached;
    }

    try {
      final playlist = await _subsonicService.getPlaylist(playlistId);
      final index = _playlists.indexWhere((p) => p.id == playlistId);
      if (index != -1) {
        _playlists[index] = playlist;
      } else {
        _playlists.add(playlist);
      }

      _cachedPlaylists = List.from(_playlists);
      _saveCachedData();
      notifyListeners();
      return playlist;
    } catch (e) {
      final cachedPlaylist = _playlists.firstWhere(
        (playlist) => playlist.id == playlistId,
        orElse: () => throw e,
      );

      if (cachedPlaylist.songs != null && cachedPlaylist.songs!.isNotEmpty) {
        return cachedPlaylist;
      }

      rethrow;
    }
  }

  Future<void> createPlaylist(String name, {List<String>? songIds}) async {
    await _subsonicService.createPlaylist(name: name, songIds: songIds);
    await loadPlaylists();
  }

  Future<void> deletePlaylist(String playlistId) async {
    await _subsonicService.deletePlaylist(playlistId);
    await loadPlaylists();
  }

  Future<void> addSongToPlaylist(String playlistId, String songId) async {
    await _subsonicService.updatePlaylist(
      playlistId: playlistId,
      songIdsToAdd: [songId],
    );
  }

  Future<SearchResult> search(String query) async {
    if (_localOnlyMode) {
      return _searchLocal(query);
    }
    return await _subsonicService.search(query);
  }

  SearchResult _searchLocal(String query) {
    final lowerQuery = query.toLowerCase();
    final songs = _cachedAllSongs
        .where(
          (song) =>
              song.title.toLowerCase().contains(lowerQuery) ||
              (song.artist?.toLowerCase().contains(lowerQuery) ?? false) ||
              (song.album?.toLowerCase().contains(lowerQuery) ?? false),
        )
        .take(50)
        .toList();
    final artists = _artists
        .where((artist) => artist.name.toLowerCase().contains(lowerQuery))
        .take(20)
        .toList();
    final albums = _cachedAllAlbums
        .where(
          (album) =>
              album.name.toLowerCase().contains(lowerQuery) ||
              (album.artist?.toLowerCase().contains(lowerQuery) ?? false),
        )
        .take(20)
        .toList();
    return SearchResult(songs: songs, artists: artists, albums: albums);
  }

  Future<void> star({String? songId, String? albumId, String? artistId}) async {
    await _subsonicService.star(
      id: songId,
      albumId: albumId,
      artistId: artistId,
    );
    await loadStarred();
  }

  Future<void> unstar({
    String? songId,
    String? albumId,
    String? artistId,
  }) async {
    await _subsonicService.unstar(
      id: songId,
      albumId: albumId,
      artistId: artistId,
    );
    await loadStarred();
  }

  Future<List<Song>> getSongsByGenre(String genre) async {
    try {
      return await _subsonicService.getSongsByGenre(genre);
    } catch (_) {
      return [];
    }
  }

  Future<List<Album>> getAlbumsByGenre(String genre) async {
    try {
      return await _subsonicService.getAlbumsByGenre(genre);
    } catch (_) {
      return [];
    }
  }

  Future<List<Song>> getAllSongs() async {
    try {
      final allArtists = await _subsonicService.getArtists();
      final List<Song> allSongs = [];

      for (final artist in allArtists) {
        try {
          final artistAlbums =
              await _subsonicService.getArtistAlbums(artist.id);
          for (final album in artistAlbums) {
            try {
              final songs = await _subsonicService.getAlbumSongs(album.id);
              allSongs.addAll(songs);
            } catch (_) {}
          }
        } catch (_) {}
      }

      return allSongs;
    } catch (_) {
      return [];
    }
  }

  Future<List<Album>> getAllAlbums() async {
    try {
      final allArtists = await _subsonicService.getArtists();
      final List<Album> allAlbums = [];

      for (final artist in allArtists) {
        try {
          final artistAlbums =
              await _subsonicService.getArtistAlbums(artist.id);
          allAlbums.addAll(artistAlbums);
        } catch (_) {}
      }

      return allAlbums;
    } catch (_) {
      return [];
    }
  }

  @override
  void dispose() {
    _localMusicService?.removeListener(_onLocalMusicServiceChanged);
    super.dispose();
  }
}
