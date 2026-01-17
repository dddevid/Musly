import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import '../services/services.dart';
import '../services/android_auto_service.dart';

class LibraryProvider extends ChangeNotifier {
  final SubsonicService _subsonicService;
  final AndroidAutoService _androidAutoService = AndroidAutoService();

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
  DateTime? _lastCacheUpdate;

  bool _isLoading = false;
  bool _isInitialized = false;
  String? _error;

  static const String _allAlbumsCacheKey = 'cached_all_albums';
  static const String _allSongsCacheKey = 'cached_all_songs';
  static const String _lastUpdateKey = 'last_cache_update';

  LibraryProvider(this._subsonicService);
  SubsonicService get subsonicService => _subsonicService;

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
      await _loadCachedData();

      // Try to load from server - will fail gracefully if not configured
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

  Future<void> _loadCachedData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

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

      final lastUpdate = prefs.getInt(_lastUpdateKey);
      if (lastUpdate != null) {
        _lastCacheUpdate = DateTime.fromMillisecondsSinceEpoch(lastUpdate);
      }

      if (_cachedAllAlbums.isEmpty || _cachedAllSongs.isEmpty) {
        await _refreshAllDataInBackground();
      }
    } catch (e) {
      debugPrint('Error loading cached data: $e');
    }
  }

  void _scheduleBackgroundRefresh() {
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
      _playlists = await _subsonicService.getPlaylists();
      notifyListeners();
      _androidAutoService.updatePlaylists(_playlists, getCoverArtUrl);
    } catch (e) {
      debugPrint('Error loading playlists: $e');
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
    try {
      return await _subsonicService.getArtistAlbums(artistId);
    } catch (e) {
      debugPrint('Error loading artist albums: $e');
      return [];
    }
  }

  Future<List<Song>> getAlbumSongs(String albumId) async {
    try {
      return await _subsonicService.getAlbumSongs(albumId);
    } catch (e) {
      debugPrint('Error loading album songs: $e');
      return [];
    }
  }

  Future<Playlist> getPlaylist(String playlistId) async {
    return await _subsonicService.getPlaylist(playlistId);
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
    return await _subsonicService.search(query);
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
}
