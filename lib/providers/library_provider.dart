import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import '../services/services.dart';
import '../services/audio_handler.dart';
import '../services/local_music_service.dart';
import 'package:musly/widgets/common/album_artwork.dart';

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
    // Serve the Android Auto browse tree: audio_service pulls these lists on
    // demand, including from the headless engine when the car connects while
    // the app UI has never been opened.
    _audioHandler.onGetRecentSongs = _recentSongsForAuto;
    _audioHandler.onGetLibraryAlbums = _albumsForAuto;
    _audioHandler.onGetLibraryArtists = _artistsForAuto;
    _audioHandler.onGetLibraryPlaylists = _playlistsForAuto;
    // Tell the audio handler whether we are in Web Stream mode so it can
    // adapt the Android Auto root browse tree accordingly.
    _audioHandler.onIsYoutubeMode = () => _subsonicService.isYoutube;
  }
  SubsonicService get subsonicService => _subsonicService;

  void setLocalMusicService(LocalMusicService service,
      {bool mergeWithServer = false}) {
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
      // Local only mode - use only local library
      _cachedAllSongs = List.from(_localMusicService!.songs);
      _cachedAllAlbums = List.from(_localMusicService!.albums);
      _artists = List.from(_localMusicService!.artists);
      _randomSongs = _cachedAllSongs.take(50).toList();
      _recentAlbums = _cachedAllAlbums.take(20).toList();
      _isInitialized = true;
      _isLoading = false;
      notifyListeners();
    } else if (_mergeLocalLibrary) {
      // Merge mode - just notify that local library changed
      // The getters will handle the merging
      notifyListeners();
    }
  }

  /// Toggle merging local library with server library
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

  bool get isLocalOnlyMode => _localOnlyMode;
  bool get isServerOfflineMode => _serverOfflineMode;
  bool get mergeLocalLibrary => _mergeLocalLibrary;

  void setServerOfflineMode(bool offline) {
    _serverOfflineMode = offline;
  }

  String getCoverArtUrl(String? coverArt) {
    return _subsonicService.getCoverArtUrl(coverArt, size: 300);
  }

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

  List<Album> get cachedAllAlbums {
    if (!_mergeLocalLibrary ||
        _localMusicService == null ||
        _localMusicService!.isEmpty) {
      return _cachedAllAlbums;
    }
    // Merge server albums with local albums
    final localAlbums = _localMusicService!.albums;
    final merged = [..._cachedAllAlbums];
    for (final localAlbum in localAlbums) {
      // Avoid duplicates by checking ID
      if (!merged.any((a) => a.id == localAlbum.id)) {
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
    // Merge server songs with local songs
    final localSongs = _localMusicService!.songs;
    final merged = [..._cachedAllSongs];
    for (final localSong in localSongs) {
      // Avoid duplicates by checking ID
      if (!merged.any((s) => s.id == localSong.id)) {
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
    // Merge server artists with local artists
    final localArtists = _localMusicService!.artists;
    final merged = [..._artists];
    for (final localArtist in localArtists) {
      // Avoid duplicates by checking ID
      if (!merged.any((a) => a.id == localArtist.id)) {
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
            onTimeout: () {
              debugPrint(
                'Server initialization timed out - continuing in local mode',
              );
              throw TimeoutException('Server not responding');
            },
          );
        } catch (serverError) {
          debugPrint('Server initialization skipped: $serverError');
        }
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
            .map((p) => Playlist.fromJson(p as Map<String, dynamic>))
            .toList();
        _playlists = _cachedPlaylists;
      }

      if (_subsonicService.isYoutube) {
        _cachedAllAlbums = [];
        _cachedAllSongs = [];
        _artists = [];
        _recentAlbums = [];
        return;
      }

      final artistsJson = prefs.getString(_artistsCacheKey);
      if (artistsJson != null) {
        final List<dynamic> artistsList = json.decode(artistsJson);
        _artists = artistsList
            .map((a) => Artist.fromJson(a as Map<String, dynamic>))
            .toList();
      }

      if (loadFullLibrary) {
        try {
          _cachedAllAlbums = await _db.getAllAlbums();
          _cachedAllSongs = await _db.getAllSongs();
        } catch (e) {
          debugPrint('Error loading library from DB: $e');
        }
      }

      final lastUpdate = prefs.getInt(_lastUpdateKey);
      if (lastUpdate != null) {
        _lastCacheUpdate = DateTime.fromMillisecondsSinceEpoch(lastUpdate);
      }
    } catch (e) {
      debugPrint('Error loading cached data: $e');
    }
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

      // Clear DB before refresh so we don't accumulate stale data.
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
        // Jellyfin/Emby: fetch all songs in O(1) API call.
        try {
          final allSongs = await _subsonicService.getAllSongs();
          for (final song in allSongs) {
            seenSongIds.add(song.id);
          }
          await _db.insertSongsBatch(allSongs);
        } catch (e) {
          debugPrint(
              'Jellyfin getAllSongs failed, falling back to album traversal: $e');
        }
      }

      var failedAlbumLoads = 0;
      if (seenSongIds.isEmpty) {
        // Subsonic or Jellyfin fallback: iterate albums from DB
        // instead of holding the entire album list in RAM.
        final albumCount = await _db.getAlbumCount();
        const albumBatchSize = 50;
        for (int aOffset = 0;
            aOffset < albumCount;
            aOffset += albumBatchSize) {
          final albums =
              await _db.getAlbumsPaginated(limit: albumBatchSize, offset: aOffset);
          for (final album in albums) {
            try {
              final albumSongs =
                  await _subsonicService.getAlbumSongs(album.id);
              final newSongs = albumSongs.where((s) => seenSongIds.add(s.id)).toList();
              if (newSongs.isNotEmpty) {
                await _db.insertSongsBatch(newSongs);
              }
            } catch (e) {
              failedAlbumLoads++;
              debugPrint('Error loading album ${album.id}: $e');
            }
          }
        }
      }

      _cachedAllAlbums = allAlbums;
      _cachedAllSongs = await _db.getAllSongs();
      _lastCacheUpdate = DateTime.now();

      await _saveCachedData();
      notifyListeners();
      debugPrint(
        'Background refresh complete: ${allAlbums.length} albums, '
        '${_cachedAllSongs.length} songs '
        '(${failedAlbumLoads > 0 ? "$failedAlbumLoads album(s) failed, " : ""}kept what succeeded).',
      );
    } catch (e) {
      debugPrint('Error refreshing all data: $e');
    }
  }

  Future<void> _saveCachedData() async {
    try {
      if (!_subsonicService.isYoutube) {
        // Persist large collections (songs/albums) to SQLite instead of
        // SharedPreferences JSON to avoid OutOfMemoryError with 100k+ tracks.
        await _db.insertAlbumsBatch(_cachedAllAlbums);
        await _db.insertSongsBatch(_cachedAllSongs);
      }

      final prefs = await SharedPreferences.getInstance();

      // Playlists are small enough to keep in SharedPreferences
      final playlistsJson = json.encode(
        _cachedPlaylists.map((p) => p.toJson()).toList(),
      );
      await prefs.setString(_playlistsCacheKey, playlistsJson);

      if (!_subsonicService.isYoutube && _artists.isNotEmpty) {
        final artistsJson = json.encode(
          _artists.map((a) => a.toJson()).toList(),
        );
        await prefs.setString(_artistsCacheKey, artistsJson);
      }

      await prefs.setInt(
        _lastUpdateKey,
        _lastCacheUpdate?.millisecondsSinceEpoch ??
            DateTime.now().millisecondsSinceEpoch,
      );
    } catch (e) {
      debugPrint('Error saving cached data: $e');
    }
  }

  /// Make sure the library is loaded before serving Android Auto browse
  /// requests (the headless engine starts with an empty provider).
  Future<void> _ensureInitializedForAuto() async {
    if (_isInitialized) return;
    if (!_isLoading) {
      try {
        await initialize();
      } catch (e) {
        debugPrint('LibraryProvider: initialize for Android Auto failed: $e');
      }
      return;
    }
    // Another initialize() is already in flight; wait for it (bounded to 8s).
    // Keeping this short so Auto doesn't show a spinner indefinitely if the
    // server is unreachable or authentication is pending.
    for (var i = 0; i < 40 && _isLoading && !_isInitialized; i++) {
      await Future.delayed(const Duration(milliseconds: 200));
    }
    if (!_isInitialized) {
      debugPrint(
        'LibraryProvider: timed out waiting for initialization in Android Auto; '
        'returning cached data (if any).',
      );
    }
  }

  Future<Set<String>> _downloadedSongIdsForAuto() async {
    final offlineService = OfflineService();
    await offlineService.initialize();
    return offlineService.getDownloadedSongIds().toSet();
  }

  Future<List<Map<String, dynamic>>> _recentSongsForAuto() async {
    await _ensureInitializedForAuto();
    // In Web Stream mode there is no classic "recent albums" concept;
    // use the locally cached songs from the SQLite DB (populated by previous
    // sessions) as the "Recent" section so the browse tree is not empty.
    var songs = _subsonicService.isYoutube
        ? (_cachedAllSongs.isNotEmpty ? _cachedAllSongs : _randomSongs)
        : _randomSongs;
    if (_serverOfflineMode) {
      final downloadedIds = await _downloadedSongIdsForAuto();
      songs =
          _cachedAllSongs.where((s) => downloadedIds.contains(s.id)).toList();
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
          .where((s) => downloadedIds.contains(s.id))
          .map((s) => s.albumId)
          .whereType<String>()
          .toSet();
      albums = _cachedAllAlbums
          .where((a) => albumIdsWithDownloads.contains(a.id))
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
          .where((s) => downloadedIds.contains(s.id))
          .map((s) => s.artistId)
          .whereType<String>()
          .toSet();
      artists = _artists
          .where((a) => artistIdsWithDownloads.contains(a.id))
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
            (p) => p.songs?.any((s) => downloadedIds.contains(s.id)) ?? false,
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
    _lastCacheUpdate = null; // force full re-sync
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
      await _db.clearServerData();
    } catch (_) {}
    notifyListeners();
    await initialize();

    // Force immediate full background refresh if server is reachable and not Web Stream.
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
    } catch (e) {
      debugPrint('Error loading artists: $e');
    }
  }

  Future<void> loadRecentAlbums() async {
    if (_serverOfflineMode) return;
    try {
      final fetched = await _subsonicService.getAlbumList(
        type: 'recent',
        size: 20,
      );
      // Only replace the list when the server actually returned results.
      // On Navidrome, type=recent returns [] if nothing has been played
      // recently, which would wipe the cached albums shown in the UI.
      if (fetched.isNotEmpty) {
        _recentAlbums = fetched;
      }
      notifyListeners();
      _audioHandler
          .notifyAutoChildrenChanged([MuslyAudioHandler.mediaIdAlbums]);
    } catch (e) {
      debugPrint('Error loading recent albums: $e');
    }
  }

  Future<void> loadFrequentAlbums() async {
    if (_serverOfflineMode) return;
    try {
      _frequentAlbums = await _subsonicService.getAlbumList(
        type: 'frequent',
        size: 20,
      );
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading frequent albums: $e');
    }
  }

  Future<void> loadNewestAlbums() async {
    if (_serverOfflineMode) return;
    try {
      _newestAlbums = await _subsonicService.getAlbumList(
        type: 'newest',
        size: 20,
      );
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading newest albums: $e');
    }
  }

  Future<void> loadRandomAlbums() async {
    if (_serverOfflineMode) return;
    try {
      _randomAlbums = await _subsonicService.getAlbumList(
        type: 'random',
        size: 20,
      );
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading random albums: $e');
    }
  }

  Future<void> loadPlaylists() async {
    if (_serverOfflineMode) return;
    try {
      final newPlaylists = await _subsonicService.getPlaylists();

      final List<Playlist> mergedPlaylists = [];

      for (final newPlaylist in newPlaylists) {
        final cachedIndex = _cachedPlaylists.indexWhere(
          (p) => p.id == newPlaylist.id,
        );
        if (cachedIndex != -1) {
          final cachedFn = _cachedPlaylists[cachedIndex];

          if (cachedFn.songs != null && cachedFn.songs!.isNotEmpty) {
            mergedPlaylists.add(newPlaylist.copyWith(songs: cachedFn.songs));
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
    } catch (e) {
      debugPrint('Error loading playlists: $e');
      if (_playlists.isEmpty && _cachedPlaylists.isNotEmpty) {
        _playlists = _cachedPlaylists;
        notifyListeners();
      }
    }
  }

  Future<void> loadRandomSongs() async {
    if (_serverOfflineMode) return;
    try {
      _randomSongs = await _subsonicService.getRandomSongs(size: 50);
      notifyListeners();
      _audioHandler
          .notifyAutoChildrenChanged([MuslyAudioHandler.mediaIdRecent]);
    } catch (e) {
      debugPrint('Error loading random songs: $e');
    }
  }

  Future<void> loadGenres() async {
    if (_serverOfflineMode) return;
    try {
      _richGenres = await _subsonicService.getGenres();
      _genres = _richGenres.map((g) => g.value).toList();
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading genres: $e');
    }
  }

  Future<void> loadStarred() async {
    if (_serverOfflineMode) return;
    try {
      _starred = await _subsonicService.getStarred();
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading starred: $e');
    }
  }

  Future<List<Album>> getArtistAlbums(String artistId) async {
    if (_localOnlyMode && _localMusicService != null) {
      return _localMusicService!.getAlbumsByArtist(artistId);
    }
    try {
      return await _subsonicService.getArtistAlbums(artistId);
    } catch (e) {
      debugPrint('Error loading artist albums: $e');
      return [];
    }
  }

  Future<List<Song>> getAlbumSongs(String albumId) async {
    if (_localOnlyMode && _localMusicService != null) {
      return _localMusicService!.getSongsByAlbum(albumId);
    }
    try {
      return await _subsonicService.getAlbumSongs(albumId);
    } catch (e) {
      debugPrint('Error loading album songs: $e');
      return [];
    }
  }

  Future<Playlist> getPlaylist(String playlistId) async {
    if (_serverOfflineMode) {
      final cached = _playlists.firstWhere(
        (p) => p.id == playlistId,
        orElse: () => _cachedPlaylists.firstWhere(
          (p) => p.id == playlistId,
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
      debugPrint('Error loading playlist details: $e');

      final cachedPlaylist = _playlists.firstWhere(
        (p) => p.id == playlistId,
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
    final q = query.toLowerCase();
    final songs = _cachedAllSongs
        .where(
          (s) =>
              s.title.toLowerCase().contains(q) ||
              (s.artist?.toLowerCase().contains(q) ?? false) ||
              (s.album?.toLowerCase().contains(q) ?? false),
        )
        .take(50)
        .toList();
    final artists = _artists
        .where((a) => a.name.toLowerCase().contains(q))
        .take(20)
        .toList();
    final albums = _cachedAllAlbums
        .where(
          (a) =>
              a.name.toLowerCase().contains(q) ||
              (a.artist?.toLowerCase().contains(q) ?? false),
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
    } catch (e) {
      debugPrint('Error loading songs by genre: $e');
      return [];
    }
  }

  Future<List<Album>> getAlbumsByGenre(String genre) async {
    try {
      return await _subsonicService.getAlbumsByGenre(genre);
    } catch (e) {
      debugPrint('Error loading albums by genre: $e');
      return [];
    }
  }

  Future<List<Song>> getAllSongs() async {
    try {
      final allArtists = await _subsonicService.getArtists();

      final List<Song> allSongs = [];

      for (final artist in allArtists) {
        try {
          final artistAlbums = await _subsonicService.getArtistAlbums(
            artist.id,
          );
          for (final album in artistAlbums) {
            try {
              final songs = await _subsonicService.getAlbumSongs(album.id);
              allSongs.addAll(songs);
            } catch (e) {
              debugPrint('Error loading album ${album.id}: $e');
            }
          }
        } catch (e) {
          debugPrint('Error loading albums for artist ${artist.name}: $e');
        }
      }

      return allSongs;
    } catch (e) {
      debugPrint('Error loading all songs: $e');
      return [];
    }
  }

  Future<List<Album>> getAllAlbums() async {
    try {
      final allArtists = await _subsonicService.getArtists();

      final List<Album> allAlbums = [];

      for (final artist in allArtists) {
        try {
          final artistAlbums = await _subsonicService.getArtistAlbums(
            artist.id,
          );
          allAlbums.addAll(artistAlbums);
        } catch (e) {
          debugPrint('Error loading albums for artist ${artist.name}: $e');
        }
      }

      return allAlbums;
    } catch (e) {
      debugPrint('Error loading all albums: $e');
      return [];
    }
  }

  @override
  void dispose() {
    _localMusicService?.removeListener(_onLocalMusicServiceChanged);
    super.dispose();
  }
}
