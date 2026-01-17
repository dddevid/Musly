import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
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
          final song = _processAudioFile(file);
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

  /// Parse song info from filename
  /// Attempts to extract artist and title from common naming patterns:
  /// - "Artist - Title.mp3"
  /// - "01. Artist - Title.mp3"
  /// - "Title.mp3"
  Song _processAudioFile(File file) {
    final fileName = path.basenameWithoutExtension(file.path);
    final parentDir = path.basename(path.dirname(file.path));
    final grandParentDir = path.basename(path.dirname(path.dirname(file.path)));

    String title = fileName;
    String artist = 'Unknown Artist';
    String albumName = parentDir;
    int? trackNumber;

    // Try to parse "Artist - Title" pattern
    if (fileName.contains(' - ')) {
      final parts = fileName.split(' - ');
      if (parts.length >= 2) {
        artist = parts[0].trim();
        title = parts.sublist(1).join(' - ').trim();
      }
    }

    // Try to extract track number from "01. Title" or "01 Title"
    final trackMatch = RegExp(r'^(\d{1,2})[.\s]+(.+)$').firstMatch(title);
    if (trackMatch != null) {
      trackNumber = int.tryParse(trackMatch.group(1) ?? '');
      title = trackMatch.group(2)?.trim() ?? title;
    }

    // Clean up common patterns
    title = title
        .replaceAll(RegExp(r'\[.*?\]'), '') // Remove [brackets]
        .replaceAll(RegExp(r'\(.*?\)'), '') // Remove (parentheses)
        .trim();

    // Use grandparent directory as artist if we don't have one
    if (artist == 'Unknown Artist' && grandParentDir.isNotEmpty) {
      // Check if grandparent looks like an artist name
      if (!grandParentDir.toLowerCase().contains('music') &&
          !grandParentDir.toLowerCase().contains('download')) {
        artist = grandParentDir;
      }
    }

    // Create unique ID based on file path
    final id = 'local_${file.path.hashCode.abs()}';
    final albumId = 'local_album_${albumName.hashCode.abs()}';
    final artistId = 'local_artist_${artist.hashCode.abs()}';

    return Song(
      id: id,
      title: title,
      artist: artist,
      album: albumName,
      albumId: albumId,
      artistId: artistId,
      track: trackNumber,
      path: file.path,
      isLocal: true,
    );
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

  Future<void> _cacheLibrary() async {
    await _prefs?.setInt('local_song_count', _songs.length);
  }

  Future<void> _loadCachedLibrary() async {
    final cachedCount = _prefs?.getInt('local_song_count') ?? 0;
    if (cachedCount > 0) {
      // Auto-scan in background after delay
      Future.delayed(const Duration(seconds: 2), () => scanForMusic());
    }
  }

  /// Clear all local music data
  Future<void> clearLibrary() async {
    _songs.clear();
    _albums.clear();
    _artists.clear();
    await _prefs?.remove('local_song_count');
    notifyListeners();
  }
}
