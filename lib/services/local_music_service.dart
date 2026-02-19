import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:audio_metadata_reader/audio_metadata_reader.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/song.dart';
import '../models/album.dart';
import '../models/artist.dart';

/// Service for managing local music files on device
class LocalMusicService extends ChangeNotifier {
  static final LocalMusicService _instance = LocalMusicService._internal();
  factory LocalMusicService() => _instance;
  LocalMusicService._internal();

  SharedPreferences? _prefs;
  bool _isInitialized = false;
  bool _isScanning = false;
  double _scanProgress = 0.0;
  String _scanStatus = '';

  // Cover art cache: albumId → absolute path to saved .jpg file
  final Map<String, String> _albumArtCache = {};
  String? _artCacheDir;

  final List<Song> _songs = [];
  final List<Album> _albums = [];
  final List<Artist> _artists = [];

  // Supported audio extensions
  static const _supportedExtensions = {
    '.mp3',
    '.flac',
    '.m4a',
    '.ogg',
    '.opus',
    '.wav',
    '.aac',
    '.wma',
  };

  // Default scan directories
  static const _defaultScanPaths = [
    '/storage/emulated/0/Music',
    '/storage/emulated/0/Download',
    '/storage/emulated/0/Downloads',
  ];

  List<Song> get songs => List.unmodifiable(_songs);
  List<Album> get albums => List.unmodifiable(_albums);
  List<Artist> get artists => List.unmodifiable(_artists);
  bool get isScanning => _isScanning;
  double get scanProgress => _scanProgress;
  String get scanStatus => _scanStatus;
  int get songCount => _songs.length;
  bool get isEmpty => _songs.isEmpty;

  // Excluded folders key
  static const String _excludedFoldersKey = 'local_excluded_folders';

  /// Get list of excluded folders
  List<String> get excludedFolders {
    return _prefs?.getStringList(_excludedFoldersKey) ?? [];
  }

  /// Add folder to exclusion list
  Future<void> addExcludedFolder(String folderPath) async {
    final folders = excludedFolders;
    if (!folders.contains(folderPath)) {
      folders.add(folderPath);
      await _prefs?.setStringList(_excludedFoldersKey, folders);
      notifyListeners();
    }
  }

  /// Remove folder from exclusion list
  Future<void> removeExcludedFolder(String folderPath) async {
    final folders = excludedFolders;
    folders.remove(folderPath);
    await _prefs?.setStringList(_excludedFoldersKey, folders);
    notifyListeners();
  }

  /// Clear all excluded folders
  Future<void> clearExcludedFolders() async {
    await _prefs?.remove(_excludedFoldersKey);
    notifyListeners();
  }

  /// Initialize the service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _prefs = await SharedPreferences.getInstance();

      // Set up cover-art cache directory
      final appDir = await getApplicationDocumentsDirectory();
      _artCacheDir = '${appDir.path}/art_cache';
      await Directory(_artCacheDir!).create(recursive: true);

      await _loadCachedLibrary();
      _isInitialized = true;
    } catch (e) {
      debugPrint('Error initializing LocalMusicService: $e');
    }
  }

  /// Request storage permission
  Future<bool> requestPermission() async {
    if (Platform.isAndroid) {
      if (await Permission.manageExternalStorage.isGranted) {
        return true;
      }

      // Try audio permission first (Android 13+)
      var status = await Permission.audio.request();
      if (status.isGranted) return true;

      // Fall back to storage permission
      status = await Permission.storage.request();
      if (status.isGranted) return true;

      // Try manage external storage
      status = await Permission.manageExternalStorage.request();
      return status.isGranted;
    }

    if (Platform.isIOS) {
      return true;
    }

    // Desktop platforms don't need permission
    return true;
  }

  /// Scan device for audio files
  Future<void> scanForMusic({List<String>? customPaths}) async {
    if (_isScanning) return;

    final hasPermission = await requestPermission();
    if (!hasPermission) {
      _scanStatus = 'Permission denied';
      notifyListeners();
      return;
    }

    _isScanning = true;
    _scanProgress = 0.0;
    _scanStatus = 'Scanning for music...';
    notifyListeners();

    try {
      final paths = customPaths ?? _getDefaultScanPaths();
      final audioFiles = <File>[];

      // Collect all audio files
      for (final dirPath in paths) {
        final dir = Directory(dirPath);
        if (await dir.exists()) {
          await _collectAudioFiles(dir, audioFiles);
        }
      }

      _scanStatus = 'Found ${audioFiles.length} files, processing...';
      notifyListeners();

      // Clear existing data
      _songs.clear();
      _albums.clear();
      _artists.clear();

      // Process files
      final totalFiles = audioFiles.length;
      for (var i = 0; i < totalFiles; i++) {
        final file = audioFiles[i];
        try {
          final song = await _processAudioFile(file);
          _songs.add(song);
        } catch (e) {
          debugPrint('Error processing ${file.path}: $e');
        }

        _scanProgress = (i + 1) / totalFiles;
        if (i % 10 == 0) {
          _scanStatus = 'Processing: ${i + 1} / $totalFiles';
          notifyListeners();
        }
      }

      // Build album and artist lists
      _buildAlbumsAndArtists();

      // Cache the library
      await _cacheLibrary();

      _scanStatus = 'Found ${_songs.length} songs';
    } catch (e) {
      _scanStatus = 'Error: $e';
      debugPrint('Scan error: $e');
    } finally {
      _isScanning = false;
      _scanProgress = 1.0;
      notifyListeners();
    }
  }

  List<String> _getDefaultScanPaths() {
    if (Platform.isAndroid) {
      return _defaultScanPaths;
    } else if (Platform.isWindows) {
      final userProfile = Platform.environment['USERPROFILE'] ?? '';
      return ['$userProfile\\Music', '$userProfile\\Downloads'];
    } else if (Platform.isMacOS || Platform.isLinux) {
      final home = Platform.environment['HOME'] ?? '';
      return ['$home/Music', '$home/Downloads'];
    }
    return [];
  }

  Future<void> _collectAudioFiles(Directory dir, List<File> files) async {
    try {
      final excluded = excludedFolders;

      await for (final entity in dir.list(
        recursive: true,
        followLinks: false,
      )) {
        // Skip excluded folders
        if (excluded.any((ex) => entity.path.startsWith(ex))) {
          continue;
        }

        if (entity is File) {
          final ext = path.extension(entity.path).toLowerCase();
          if (_supportedExtensions.contains(ext)) {
            files.add(entity);
          }
        }
      }
    } catch (e) {
      debugPrint('Error listing directory ${dir.path}: $e');
    }
  }

  /// Read audio metadata and produce a Song object.
  /// Falls back to filename parsing when the tag library can't read the file.
  Future<Song> _processAudioFile(File file) async {
    final fileName = path.basenameWithoutExtension(file.path);
    final parentDir = path.basename(path.dirname(file.path));
    final grandParentDir = path.basename(path.dirname(path.dirname(file.path)));

    // --- defaults (filename-based) ---
    String title = fileName;
    String? artist;
    String albumName = parentDir;
    int? trackNumber;
    int? yearVal;
    String? genre;
    int? duration;
    int? bitRate;
    String? coverArtPath;

    // --- try reading ID3 / Vorbis / ILST / RIFF tags ---
    try {
      final metadata = readMetadata(file, getImage: _artCacheDir != null);

      if (metadata.title?.isNotEmpty == true) title = metadata.title!.trim();
      if (metadata.artist?.isNotEmpty == true) artist = metadata.artist!.trim();
      if (metadata.album?.isNotEmpty == true)
        albumName = metadata.album!.trim();
      trackNumber = metadata.trackNumber;
      yearVal = metadata.year?.year != 0 ? metadata.year?.year : null;
      genre = metadata.genres.isNotEmpty ? metadata.genres.first : null;
      duration = metadata.duration?.inSeconds;
      bitRate = metadata.bitrate;

      // Cover art – save once per album to avoid repeated file writes
      if (metadata.pictures.isNotEmpty && _artCacheDir != null) {
        final albumId = 'local_album_${albumName.hashCode.abs()}';
        if (_albumArtCache.containsKey(albumId)) {
          coverArtPath = _albumArtCache[albumId];
        } else {
          final pic = metadata.pictures.first;
          final ext = _mimeToExt(pic.mimetype);
          final artFile = File('$_artCacheDir/$albumId$ext');
          try {
            await artFile.writeAsBytes(pic.bytes as Uint8List);
            coverArtPath = artFile.path;
            _albumArtCache[albumId] = coverArtPath!;
          } catch (e) {
            debugPrint('Art write failed: $e');
          }
        }
      }
    } catch (_) {
      // Tag library can't read this file – fall back to filename parsing
    }

    // --- filename-based fallback for missing fields ---
    if (artist == null) {
      if (fileName.contains(' - ')) {
        final parts = fileName.split(' - ');
        if (parts.length >= 2) {
          final rawArtist = parts[0].trim();
          // Strip leading track-number from artist candidate
          final noNum = RegExp(r'^(\d{1,2})[.\s]+(.+)$').firstMatch(rawArtist);
          artist = noNum != null ? noNum.group(2)!.trim() : rawArtist;
          title = parts.sublist(1).join(' - ').trim();
        }
      }

      // Still no artist? try grandparent directory
      if (artist == null &&
          grandParentDir.isNotEmpty &&
          !grandParentDir.toLowerCase().contains('music') &&
          !grandParentDir.toLowerCase().contains('download')) {
        artist = grandParentDir;
      }
    }

    // Strip leading track-number from title if metadata didn't provide one
    if (trackNumber == null) {
      final trackMatch = RegExp(r'^(\d{1,2})[.\s]+(.+)$').firstMatch(title);
      if (trackMatch != null) {
        trackNumber = int.tryParse(trackMatch.group(1) ?? '');
        title = trackMatch.group(2)!.trim();
      }
    }

    // Clean up bracketed noise in title
    title = title
        .replaceAll(RegExp(r'\[.*?\]'), '')
        .replaceAll(RegExp(r'\(.*?\)'), '')
        .trim();
    if (title.isEmpty) title = fileName;

    final resolvedArtist = artist ?? 'Unknown Artist';
    final albumId = 'local_album_${albumName.hashCode.abs()}';
    final artistId = 'local_artist_${resolvedArtist.hashCode.abs()}';

    return Song(
      id: 'local_${file.path.hashCode.abs()}',
      title: title,
      artist: resolvedArtist,
      artistId: artistId,
      album: albumName,
      albumId: albumId,
      track: trackNumber,
      year: yearVal,
      genre: genre,
      duration: duration,
      bitRate: bitRate,
      coverArt: coverArtPath, // absolute local path, or null
      path: file.path,
      isLocal: true,
    );
  }

  /// Map MIME type to file extension for cover art files.
  String _mimeToExt(String? mime) {
    switch (mime) {
      case 'image/png':
        return '.png';
      case 'image/webp':
        return '.webp';
      default:
        return '.jpg';
    }
  }

  void _buildAlbumsAndArtists() {
    final albumMap = <String, List<Song>>{};
    final artistMap = <String, List<Song>>{};

    for (final song in _songs) {
      // Group by album
      final albumKey = song.albumId ?? song.album ?? 'Unknown';
      albumMap.putIfAbsent(albumKey, () => []).add(song);

      // Group by artist
      final artistKey = song.artistId ?? song.artist ?? 'Unknown';
      artistMap.putIfAbsent(artistKey, () => []).add(song);
    }

    // Build albums
    for (final entry in albumMap.entries) {
      final songs = entry.value;
      final firstSong = songs.first;
      _albums.add(
        Album(
          id: entry.key,
          name: firstSong.album ?? 'Unknown Album',
          artist: firstSong.artist ?? 'Unknown Artist',
          artistId: firstSong.artistId,
          songCount: songs.length,
          year: firstSong.year,
          isLocal: true,
        ),
      );
    }

    // Build artists
    for (final entry in artistMap.entries) {
      final songs = entry.value;
      final firstSong = songs.first;
      final uniqueAlbums = songs.map((s) => s.albumId).toSet();
      _artists.add(
        Artist(
          id: entry.key,
          name: firstSong.artist ?? 'Unknown Artist',
          albumCount: uniqueAlbums.length,
          isLocal: true,
        ),
      );
    }

    // Sort
    _songs.sort((a, b) => a.title.compareTo(b.title));
    _albums.sort((a, b) => a.name.compareTo(b.name));
    _artists.sort((a, b) => a.name.compareTo(b.name));
  }

  /// Get songs by album
  List<Song> getSongsByAlbum(String albumId) {
    return _songs.where((s) => s.albumId == albumId).toList();
  }

  /// Get songs by artist
  List<Song> getSongsByArtist(String artistId) {
    return _songs.where((s) => s.artistId == artistId).toList();
  }

  /// Get albums by artist
  List<Album> getAlbumsByArtist(String artistId) {
    final artistSongs = getSongsByArtist(artistId);
    final albumIds = artistSongs.map((s) => s.albumId).toSet();
    return _albums.where((a) => albumIds.contains(a.id)).toList();
  }

  /// Get file URL for local song
  String getStreamUrl(String songId) {
    final song = _songs.firstWhere(
      (s) => s.id == songId,
      orElse: () => throw Exception('Local song not found'),
    );
    return 'file://${song.path}';
  }

  Future<File> _getCacheFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/local_music_cache.json');
  }

  Future<void> _cacheLibrary() async {
    try {
      final file = await _getCacheFile();
      final data = {
        'version': 1,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'songs': _songs.map((s) => s.toJson()).toList(),
      };
      await file.writeAsString(json.encode(data));
      await _prefs?.setInt('local_song_count', _songs.length);
    } catch (e) {
      debugPrint('Error caching local library: $e');
    }
  }

  Future<void> _loadCachedLibrary() async {
    try {
      final file = await _getCacheFile();
      if (!await file.exists()) {
        return; // No cache – scan triggered by MainScreen on first launch
      }

      final content = await file.readAsString();
      final data = json.decode(content) as Map<String, dynamic>;

      final timestamp = data['timestamp'] as int? ?? 0;
      final age = DateTime.now().millisecondsSinceEpoch - timestamp;
      const maxAge = 7 * 24 * 60 * 60 * 1000; // 7 days in ms

      final cachedSongs = (data['songs'] as List<dynamic>)
          .map((s) => Song.fromJson(s as Map<String, dynamic>))
          .toList();

      if (cachedSongs.isEmpty) return;

      _songs.clear();
      _songs.addAll(cachedSongs);
      _buildAlbumsAndArtists();
      notifyListeners();
      debugPrint('Loaded ${_songs.length} songs from local cache.');

      // If cache is stale, trigger a background rescan
      if (age > maxAge) {
        debugPrint('Local music cache is stale, rescanning in background...');
        Future.delayed(const Duration(seconds: 3), () => scanForMusic());
      }
    } catch (e) {
      debugPrint('Error loading local music cache, will rescan: $e');
      try {
        final file = await _getCacheFile();
        if (await file.exists()) await file.delete();
      } catch (_) {}
    }
  }

  /// Clear all local music data
  Future<void> clearLibrary() async {
    _songs.clear();
    _albums.clear();
    _artists.clear();
    _albumArtCache.clear();
    await _prefs?.remove('local_song_count');
    try {
      final file = await _getCacheFile();
      if (await file.exists()) await file.delete();
    } catch (e) {
      debugPrint('Error deleting local music cache: $e');
    }
    // Delete cached cover-art images
    if (_artCacheDir != null) {
      try {
        final dir = Directory(_artCacheDir!);
        if (await dir.exists()) {
          await for (final entity in dir.list()) {
            await entity.delete();
          }
        }
      } catch (e) {
        debugPrint('Error clearing art cache: $e');
      }
    }
    notifyListeners();
  }
}
