import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:audio_metadata_reader/audio_metadata_reader.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/song.dart';
import '../models/album.dart';
import '../models/artist.dart';
import 'library_database_service.dart';

class LocalMusicService extends ChangeNotifier {
  static final LocalMusicService _instance = LocalMusicService._internal();
  factory LocalMusicService() => _instance;
  LocalMusicService._internal();

  SharedPreferences? _prefs;
  final LibraryDatabaseService _db = LibraryDatabaseService();
  bool _isInitialized = false;
  bool _isScanning = false;
  double _scanProgress = 0.0;
  String _scanStatus = '';

  final Map<String, String> _albumArtCache = {};
  String? _artCacheDir;

  final List<Song> _songs = [];
  final List<Album> _albums = [];
  final List<Artist> _artists = [];

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

  static const _defaultScanPaths = [
    '/storage/emulated/0/Music',
    '/storage/emulated/0/Download',
    '/storage/emulated/0/Downloads',
  ];

  static const String _customScanPathsKey = 'local_custom_scan_paths';

  List<Song> get songs => List.unmodifiable(_songs);
  List<Album> get albums => List.unmodifiable(_albums);
  List<Artist> get artists => List.unmodifiable(_artists);
  bool get isScanning => _isScanning;
  double get scanProgress => _scanProgress;
  String get scanStatus => _scanStatus;
  int get songCount => _songs.length;
  bool get isEmpty => _songs.isEmpty;

  static const String _excludedFoldersKey = 'local_excluded_folders';

  List<String> get excludedFolders {
    return _prefs?.getStringList(_excludedFoldersKey) ?? [];
  }

  /// Get custom scan paths from SharedPreferences
  List<String> get customScanPaths {
    return _prefs?.getStringList(_customScanPathsKey) ?? [];
  }

  /// Add a custom scan path
  Future<bool> addCustomScanPath(String path) async {
    if (_prefs == null) return false;

    final currentPaths = customScanPaths;
    if (currentPaths.contains(path)) return true;

    // Verify the path exists
    final dir = Directory(path);
    if (!await dir.exists()) return false;

    currentPaths.add(path);
    final success =
        await _prefs!.setStringList(_customScanPathsKey, currentPaths);
    if (success) {
      notifyListeners();
    }
    return success;
  }

  /// Remove a custom scan path
  Future<bool> removeCustomScanPath(String path) async {
    if (_prefs == null) return false;

    final currentPaths = customScanPaths;
    if (!currentPaths.contains(path)) return true;

    currentPaths.remove(path);
    final success =
        await _prefs!.setStringList(_customScanPathsKey, currentPaths);
    if (success) {
      notifyListeners();
    }
    return success;
  }

  /// Clear all custom scan paths
  Future<bool> clearCustomScanPaths() async {
    if (_prefs == null) return false;

    final success = await _prefs!.remove(_customScanPathsKey);
    notifyListeners();
    return success;
  }

  /// Get all scan paths (default + custom)
  List<String> get allScanPaths {
    final custom = customScanPaths;
    if (custom.isEmpty) return _getDefaultScanPaths();
    return [..._getDefaultScanPaths(), ...custom];
  }

  Future<void> addExcludedFolder(String folderPath) async {
    final folders = excludedFolders;
    if (!folders.contains(folderPath)) {
      folders.add(folderPath);
      await _prefs?.setStringList(_excludedFoldersKey, folders);
      notifyListeners();
    }
  }

  Future<void> removeExcludedFolder(String folderPath) async {
    final folders = excludedFolders;
    folders.remove(folderPath);
    await _prefs?.setStringList(_excludedFoldersKey, folders);
    notifyListeners();
  }

  Future<void> clearExcludedFolders() async {
    await _prefs?.remove(_excludedFoldersKey);
    notifyListeners();
  }

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _prefs = await SharedPreferences.getInstance();
    } catch (e) {
      debugPrint('LocalMusicService: failed to get SharedPreferences: $e');
    }

    try {
      final appDir = await getApplicationDocumentsDirectory();
      _artCacheDir = '${appDir.path}/art_cache';
      await Directory(_artCacheDir!).create(recursive: true);
    } catch (e) {
      debugPrint(
        'LocalMusicService: could not create art_cache directory (falling back to in-memory only): $e',
      );
      _artCacheDir = null;
    }

    try {
      await _loadCachedLibrary();
    } catch (e) {
      debugPrint('LocalMusicService: failed to load cached library: $e');
    }

    _isInitialized = true;
  }

  Future<bool> requestPermission() async {
    if (Platform.isAndroid) {
      if (await Permission.manageExternalStorage.isGranted) {
        return true;
      }

      var status = await Permission.audio.request();
      if (status.isGranted) return true;

      status = await Permission.storage.request();
      if (status.isGranted) return true;

      status = await Permission.manageExternalStorage.request();
      return status.isGranted;
    }

    if (Platform.isIOS) {
      final status = await Permission.mediaLibrary.request();

      debugPrint('iOS mediaLibrary permission: $status');
      return true;
    }

    return true;
  }

  /// Pick a directory to add as a custom scan path
  Future<String?> pickMusicDirectory() async {
    if (Platform.isAndroid || Platform.isIOS) {
      // For Android, try to use file_picker with directory selection
      try {
        final result = await FilePicker.platform.getDirectoryPath(
          dialogTitle: 'Select Music Folder',
        );
        if (result != null) {
          final added = await addCustomScanPath(result);
          if (added) {
            return result;
          }
        }
      } catch (e) {
        debugPrint('Error picking directory: $e');
      }
    }
    return null;
  }

  Future<int> pickAndAddFiles() async {
    if (!Platform.isIOS) return 0;

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: [
        'mp3',
        'flac',
        'm4a',
        'aac',
        'wav',
        'ogg',
        'opus',
        'wma'
      ],
      allowMultiple: true,
      withData: false,
      withReadStream: false,
    );

    if (result == null || result.files.isEmpty) return 0;

    final docsDir = await getApplicationDocumentsDirectory();
    final musicDir = Directory('${docsDir.path}/Music');
    if (!await musicDir.exists()) await musicDir.create(recursive: true);

    final before = _songs.length;

    for (final pf in result.files) {
      final srcPath = pf.path;
      if (srcPath == null) continue;
      final srcFile = File(srcPath);
      if (!await srcFile.exists()) continue;

      final destPath = '${musicDir.path}/${pf.name}';
      final destFile = File(destPath);
      File fileToProcess;
      try {
        if (!await destFile.exists()) {
          await srcFile.copy(destPath);
        }
        fileToProcess = destFile;
      } catch (e) {
        debugPrint(
            'Failed to copy picked file to sandbox: $e — using original path');
        fileToProcess = srcFile;
      }

      final id = 'local_${destPath.hashCode.abs()}';
      if (_songs.any((s) => s.id == id)) continue;

      try {
        final song = await _processAudioFile(fileToProcess);
        _songs.add(song);
      } catch (e) {
        debugPrint('Error processing picked file $destPath: $e');
      }
    }

    if (_songs.length != before) {
      _buildAlbumsAndArtists();
      await _cacheLibrary();
      notifyListeners();
    }

    return _songs.length - before;
  }

  Future<void> scanForMusic({List<String>? overridePaths}) async {
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
      final paths = overridePaths ?? allScanPaths;
      final audioFiles = <File>[];

      for (final dirPath in paths) {
        final dir = Directory(dirPath);
        if (await dir.exists()) {
          await _collectAudioFiles(dir, audioFiles);
        }
      }

      _scanStatus = 'Found ${audioFiles.length} files, processing...';
      notifyListeners();

      _songs.clear();
      _albums.clear();
      _artists.clear();

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

      _buildAlbumsAndArtists();

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
    } else if (Platform.isIOS) {
      final docs = _artCacheDir != null
          ? path.join(path.dirname(path.dirname(_artCacheDir!)), 'Music')
          : null;
      if (docs != null) return [docs];
      return [];
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

  Future<Song> _processAudioFile(File file) async {
    final fileName = path.basenameWithoutExtension(file.path);
    final parentDir = path.basename(path.dirname(file.path));
    final grandParentDir = path.basename(path.dirname(path.dirname(file.path)));

    String title = fileName;
    String? artist;
    String albumName = parentDir;
    int? trackNumber;
    int? yearVal;
    String? genre;
    int? duration;
    int? bitRate;
    String? coverArtPath;

    try {
      final metadata = readMetadata(file, getImage: _artCacheDir != null);

      if (metadata.title?.isNotEmpty == true) title = metadata.title!.trim();
      if (metadata.artist?.isNotEmpty == true) artist = metadata.artist!.trim();
      if (metadata.album?.isNotEmpty == true) {
        albumName = metadata.album!.trim();
      }
      trackNumber = metadata.trackNumber;
      yearVal = metadata.year?.year != 0 ? metadata.year?.year : null;
      genre = metadata.genres.isNotEmpty ? metadata.genres.first : null;
      duration = metadata.duration?.inSeconds;
      bitRate = metadata.bitrate;

      if (metadata.pictures.isNotEmpty && _artCacheDir != null) {
        final albumId = 'local_album_${albumName.hashCode.abs()}';
        if (_albumArtCache.containsKey(albumId)) {
          coverArtPath = _albumArtCache[albumId];
        } else {
          final pic = metadata.pictures.first;
          final ext = _mimeToExt(pic.mimetype);
          final artFile = File('$_artCacheDir/$albumId$ext');
          try {
            await artFile.writeAsBytes(pic.bytes);
            coverArtPath = artFile.path;
            _albumArtCache[albumId] = coverArtPath;
          } catch (e) {
            debugPrint('Art write failed: $e');
          }
        }
      }
    } catch (e) {
      debugPrint('Metadata read failed for ${file.path}: $e');
    }

    // Fallback: look for folder art in the parent directory.
    if (coverArtPath == null && _artCacheDir != null) {
      final albumId = 'local_album_${albumName.hashCode.abs()}';
      if (_albumArtCache.containsKey(albumId)) {
        coverArtPath = _albumArtCache[albumId];
      } else {
        final parent = file.parent;
        final candidates = [
          'cover.jpg',
          'folder.jpg',
          'albumart.jpg',
          'front.jpg',
          'Cover.jpg',
          'Folder.jpg',
          'AlbumArt.jpg',
          'Front.jpg',
          'cover.png',
          'folder.png',
        ];
        for (final candidate in candidates) {
          final candidateFile = File('${parent.path}/$candidate');
          if (await candidateFile.exists()) {
            // Copy to cache so we have a stable path across sessions.
            final ext = path.extension(candidateFile.path).toLowerCase();
            final dest =
                File('$_artCacheDir/$albumId${ext.isEmpty ? '.jpg' : ext}');
            try {
              await candidateFile.copy(dest.path);
              coverArtPath = dest.path;
              _albumArtCache[albumId] = coverArtPath;
            } catch (e) {
              // If copy fails, just use the original path directly.
              coverArtPath = candidateFile.path;
              _albumArtCache[albumId] = coverArtPath;
            }
            break;
          }
        }
      }
    }

    if (artist == null) {
      if (fileName.contains(' - ')) {
        final parts = fileName.split(' - ');
        if (parts.length >= 2) {
          final rawArtist = parts[0].trim();

          final noNum = RegExp(r'^(\d{1,2})[.\s]+(.+)$').firstMatch(rawArtist);
          artist = noNum != null ? noNum.group(2)!.trim() : rawArtist;
          title = parts.sublist(1).join(' - ').trim();
        }
      }

      if (artist == null &&
          grandParentDir.isNotEmpty &&
          !grandParentDir.toLowerCase().contains('music') &&
          !grandParentDir.toLowerCase().contains('download')) {
        artist = grandParentDir;
      }
    }

    if (trackNumber == null) {
      final trackMatch = RegExp(r'^(\d{1,2})[.\s]+(.+)$').firstMatch(title);
      if (trackMatch != null) {
        trackNumber = int.tryParse(trackMatch.group(1) ?? '');
        title = trackMatch.group(2)!.trim();
      }
    }

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
      coverArt: coverArtPath,
      path: file.path,
      isLocal: true,
    );
  }

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
      final albumKey = song.albumId ?? song.album ?? 'Unknown';
      albumMap.putIfAbsent(albumKey, () => []).add(song);

      final artistKey = song.artistId ?? song.artist ?? 'Unknown';
      artistMap.putIfAbsent(artistKey, () => []).add(song);
    }

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

    // Sort songs by album name, then by track number (natural album order).
    _songs.sort((a, b) {
      final albumCmp = (a.album ?? '').compareTo(b.album ?? '');
      if (albumCmp != 0) return albumCmp;
      final trackA = a.track ?? 9999;
      final trackB = b.track ?? 9999;
      return trackA.compareTo(trackB);
    });

    // Sort albums: newest first (year desc), then name (A-Z).
    _albums.sort((a, b) {
      if (a.year != null && b.year != null) {
        final yearCmp = b.year!.compareTo(a.year!);
        if (yearCmp != 0) return yearCmp;
      }
      if (a.year != null && b.year == null) return -1;
      if (a.year == null && b.year != null) return 1;
      return a.name.compareTo(b.name);
    });

    _artists.sort((a, b) => a.name.compareTo(b.name));
  }

  List<Song> getSongsByAlbum(String albumId) {
    return _songs.where((s) => s.albumId == albumId).toList();
  }

  List<Song> getSongsByArtist(String artistId) {
    return _songs.where((s) => s.artistId == artistId).toList();
  }

  List<Album> getAlbumsByArtist(String artistId) {
    final artistSongs = getSongsByArtist(artistId);
    final albumIds = artistSongs.map((s) => s.albumId).toSet();
    return _albums.where((a) => albumIds.contains(a.id)).toList();
  }

  String getStreamUrl(String songId) {
    final song = _songs.firstWhere(
      (s) => s.id == songId,
      orElse: () => throw Exception('Local song not found'),
    );
    return 'file://${song.path}';
  }

  Future<void> _cacheLibrary() async {
    try {
      // Save songs/albums/artists to SQLite to avoid OOM with huge libraries
      await _db.insertSongsBatch(_songs);
      await _db.insertAlbumsBatch(_albums);
      await _db.insertArtistsBatch(_artists);

      // Album art cache is small; keep in SharedPreferences
      await _prefs?.setString(
        'local_album_art_cache',
        json.encode(_albumArtCache),
      );
      await _prefs?.setInt('local_song_count', _songs.length);
    } catch (e) {
      debugPrint('Error caching local library: $e');
    }
  }

  Future<void> _loadCachedLibrary() async {
    try {
      var cachedSongs = await _db.getLocalSongs();

      // Restore album art cache from SharedPreferences
      final artCacheJson = _prefs?.getString('local_album_art_cache');
      if (artCacheJson != null) {
        final artMap = json.decode(artCacheJson) as Map<String, dynamic>;
        _albumArtCache.clear();
        for (final entry in artMap.entries) {
          if (entry.value is String && File(entry.value).existsSync()) {
            _albumArtCache[entry.key] = entry.value;
          }
        }
      }

      if (cachedSongs.isEmpty) return;

      if (Platform.isIOS) {
        final docsDir = await getApplicationDocumentsDirectory();
        final musicDirPath = '${docsDir.path}/Music';

        final remapped = <Song>[];
        for (final song in cachedSongs) {
          if (song.path == null) continue;
          final filename = path.basename(song.path!);
          final sandboxPath = '$musicDirPath/$filename';
          if (await File(sandboxPath).exists()) {
            final fixedSong = song.copyWith(
              path: sandboxPath,
              id: 'local_${sandboxPath.hashCode.abs()}',
            );
            remapped.add(fixedSong);
          } else {
            debugPrint(
                'Dropping cached song (file missing in sandbox): $filename');
          }
        }
        if (remapped.isEmpty) return;
        _songs.clear();
        _songs.addAll(remapped);
        _buildAlbumsAndArtists();
        notifyListeners();
        debugPrint(
            'Loaded ${_songs.length} songs from local cache (iOS paths remapped).');

        await _cacheLibrary();
        return;
      }

      _songs.clear();
      _songs.addAll(cachedSongs);
      _buildAlbumsAndArtists();
      notifyListeners();
      debugPrint('Loaded ${_songs.length} songs from local cache (DB).');
    } catch (e) {
      debugPrint('Error loading local music cache, will rescan: $e');
    }
  }

  Future<void> clearLibrary() async {
    _songs.clear();
    _albums.clear();
    _artists.clear();
    _albumArtCache.clear();
    await _prefs?.remove('local_song_count');
    try {
      // Delete legacy JSON cache file if it exists
      final docsDir = await getApplicationDocumentsDirectory();
      final legacyFile = File('${docsDir.path}/local_music_cache.json');
      if (await legacyFile.exists()) await legacyFile.delete();
    } catch (e) {
      debugPrint('Error deleting legacy local music cache: $e');
    }
    try {
      await _db.clearAll();
    } catch (e) {
      debugPrint('Error clearing local DB: $e');
    }

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
