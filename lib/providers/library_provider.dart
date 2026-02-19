import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import '../services/services.dart';
import '../services/android_auto_service.dart';
import '../services/local_music_service.dart';

class LibraryProvider extends ChangeNotifier {
  final SubsonicService _subsonicService;
  final AndroidAutoService _androidAutoService = AndroidAutoService();

  bool _localOnlyMode = false;
  LocalMusicService? _localMusicService;

  List<Artist> _artists = [];
  List<Album> _recentAlbums = [];
  List<Album> _frequentAlbums = [];
  List<Album> _newestAlbums = [];
  List<Album> _randomAlbums = [];
  List<Playlist> _playlists = [];
  List<Song> _randomSongs = [];
  List<String> _genres = [];
  SearchResult? _starred;

  List<Album> _cachedAllAlbums = [];
  List<Song> _cachedAllSongs = [];
  List<Playlist> _cachedPlaylists = [];
  DateTime? _lastCacheUpdate;

  bool _isLoading = false;
  bool _isInitialized = false;
  String? _error;

  static const String _allAlbumsCacheKey = 'cached_all_albums';
  static const String _allSongsCacheKey = 'cached_all_songs';
  static const String _playlistsCacheKey = 'cached_playlists';
  static const String _lastUpdateKey = 'last_cache_update';

  LibraryProvider(this._subsonicService);
  SubsonicService get subsonicService => _subsonicService;

  /// Call this to enable local-only mode backed by LocalMusicService
  void setLocalMusicService(LocalMusicService service) {
    // Remove old listener if switching service
    _localMusicService?.removeListener(_onLocalMusicServiceChanged);
    _localMusicService = service;
    _localOnlyMode = true;
    _isInitialized = false; // Force re-init with new data
    service.addListener(_onLocalMusicServiceChanged);
  }

  void _onLocalMusicServiceChanged() {
    if (_localOnlyMode &&
        _localMusicService != null &&
        !_localMusicService!.isScanning) {
      // Scan just finished – reload library data
      _cachedAllSongs = List.from(_localMusicService!.songs);
      _cachedAllAlbums = List.from(_localMusicService!.albums);
      _artists = List.from(_localMusicService!.artists);
      _randomSongs = _cachedAllSongs.take(50).toList();
      _recentAlbums = _cachedAllAlbums.take(20).toList();
      _isInitialized = true;
      _isLoading = false;
      notifyListeners();
    }
  }

  void setLocalOnlyMode(bool enabled) {
    _localOnlyMode = enabled;
    _isInitialized = false;
    notifyListeners();
  }

  bool get isLocalOnlyMode => _localOnlyMode;

  String getCoverArtUrl(String? coverArt) {
    return _subsonicService.getCoverArtUrl(coverArt, size: 300);
  }

  List<Artist> get artists => _artists;
  List<Album> get recentAlbums => _recentAlbums;
  List<Album> get frequentAlbums => _frequentAlbums;
  List<Album> get newestAlbums => _newestAlbums;
  List<Album> get randomAlbums => _randomAlbums;
  List<Playlist> get playlists => _playlists;
  List<Song> get randomSongs => _randomSongs;
  List<String> get genres => _genres;
  SearchResult? get starred => _starred;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  String? get error => _error;

  List<Album> get cachedAllAlbums => _cachedAllAlbums;
  List<Song> get cachedAllSongs => _cachedAllSongs;

  Future<void> initialize() async {
    if (_isInitialized) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      if (_localOnlyMode && _localMusicService != null) {
        // Local-only: populate from LocalMusicService
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

      await _loadCachedData(loadFullLibrary: false);

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
        // Server not configured or error - that's ok for local mode
        debugPrint('Server initialization skipped: $serverError');
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

    // In local-only mode, songs come from LocalMusicService, not Subsonic
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

      if (loadFullLibrary) {
        final albumsJson = prefs.getString(_allAlbumsCacheKey);
        if (albumsJson != null) {
          final List<dynamic> albumsList = json.decode(albumsJson);
          _cachedAllAlbums = albumsList
              .map((a) => Album.fromJson(a as Map<String, dynamic>))
              .toList();
        }

        final songsJson = prefs.getString(_allSongsCacheKey);
        if (songsJson != null) {
          final List<dynamic> songsList = json.decode(songsJson);
          _cachedAllSongs = songsList
              .map((s) => Song.fromJson(s as Map<String, dynamic>))
              .toList();
        }

        final playlistsJson = prefs.getString(_playlistsCacheKey);
        if (playlistsJson != null) {
          final List<dynamic> playlistsList = json.decode(playlistsJson);
          _cachedPlaylists = playlistsList
              .map((p) => Playlist.fromJson(p as Map<String, dynamic>))
              .toList();
          _playlists = _cachedPlaylists;
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
    // Only schedule if we already have data loaded, otherwise wait for explicit load
    if (_cachedAllSongs.isEmpty) return;

    final shouldRefresh =
        _lastCacheUpdate == null ||
        DateTime.now().difference(_lastCacheUpdate!) > const Duration(hours: 6);

    if (shouldRefresh) {
      Future.delayed(const Duration(seconds: 5), () {
        _refreshAllDataInBackground();
      });
    }
  }

  Future<void> _refreshAllDataInBackground() async {
    try {
      final allArtists = await _subsonicService.getArtists();
      final List<Album> allAlbums = [];
      final List<Song> allSongs = [];

      for (final artist in allArtists) {
        try {
          final albums = await _subsonicService.getArtistAlbums(artist.id);
          allAlbums.addAll(albums);

          for (final album in albums) {
            try {
              final songs = await _subsonicService.getAlbumSongs(album.id);
              allSongs.addAll(songs);
            } catch (e) {
              debugPrint('Error loading album: $e');
            }
          }
        } catch (e) {
          debugPrint('Error loading artist: $e');
        }
      }

      _cachedAllAlbums = allAlbums;
      _cachedAllSongs = allSongs;
      _lastCacheUpdate = DateTime.now();

      await _saveCachedData();
      notifyListeners();
    } catch (e) {
      debugPrint('Error refreshing all data: $e');
    }
  }

  Future<void> _saveCachedData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final albumsJson = json.encode(
        _cachedAllAlbums.map((a) => a.toJson()).toList(),
      );
      await prefs.setString(_allAlbumsCacheKey, albumsJson);

      final songsJson = json.encode(
        _cachedAllSongs.map((s) => s.toJson()).toList(),
      );
      await prefs.setString(_allSongsCacheKey, songsJson);

      final playlistsJson = json.encode(
        _cachedPlaylists.map((p) => p.toJson()).toList(),
      );
      await prefs.setString(_playlistsCacheKey, playlistsJson);

      await prefs.setInt(
        _lastUpdateKey,
        _lastCacheUpdate?.millisecondsSinceEpoch ??
            DateTime.now().millisecondsSinceEpoch,
      );
    } catch (e) {
      debugPrint('Error saving cached data: $e');
    }
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
          } catch (e) {}
        }
      }
    });
  }

  Future<void> refresh() async {
    _isInitialized = false;
    await initialize();
  }

  Future<void> loadArtists() async {
    try {
      _artists = await _subsonicService.getArtists();
      notifyListeners();
      _androidAutoService.updateArtists(_artists);
    } catch (e) {
      debugPrint('Error loading artists: $e');
    }
  }

  Future<void> loadRecentAlbums() async {
    try {
      _recentAlbums = await _subsonicService.getAlbumList(
        type: 'recent',
        size: 20,
      );
      notifyListeners();
      _androidAutoService.updateAlbums(_recentAlbums, getCoverArtUrl);
    } catch (e) {
      debugPrint('Error loading recent albums: $e');
    }
  }

  Future<void> loadFrequentAlbums() async {
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
    try {
      final newPlaylists = await _subsonicService.getPlaylists();

      // Merge with cached playlists to preserve song data
      // New playlists (metadata only) + Cached playlists (with songs)
      final List<Playlist> mergedPlaylists = [];

      for (final newPlaylist in newPlaylists) {
        final cachedIndex = _cachedPlaylists.indexWhere(
          (p) => p.id == newPlaylist.id,
        );
        if (cachedIndex != -1) {
          final cachedFn = _cachedPlaylists[cachedIndex];
          // If cached has songs and (timestamp matches or unchanged), keep songs
          // Subsonic playlists usually have a 'changed' field.
          // If available, check it. If not, we opt to keep cached songs to allow offline play
          // unless the user explicitly refreshes deep (which we don't have a button for yet).
          if (cachedFn.songs != null && cachedFn.songs!.isNotEmpty) {
            // If the server says songCount is different, we might be stale.
            // But for offline support, stale is better than empty.
            // We reuse the cached songs until getPlaylist(id) is called again.
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
      _androidAutoService.updatePlaylists(_playlists, getCoverArtUrl);
    } catch (e) {
      debugPrint('Error loading playlists: $e');
      if (_playlists.isEmpty && _cachedPlaylists.isNotEmpty) {
        _playlists = _cachedPlaylists;
        notifyListeners();
      }
    }
  }

  Future<void> loadRandomSongs() async {
    try {
      _randomSongs = await _subsonicService.getRandomSongs(size: 50);
      notifyListeners();
      _androidAutoService.updateRecentSongs(_randomSongs, getCoverArtUrl);
    } catch (e) {
      debugPrint('Error loading random songs: $e');
    }
  }

  Future<void> loadGenres() async {
    try {
      _genres = await _subsonicService.getGenres();
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading genres: $e');
    }
  }

  Future<void> loadStarred() async {
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
    // Local-only mode
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
    try {
      final playlist = await _subsonicService.getPlaylist(playlistId);

      // Update cache with detailed playlist (including songs)
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

      // Try to find in cache
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
