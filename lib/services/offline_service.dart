import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../models/song.dart';
import '../models/playlist.dart';
import 'subsonic_service.dart';

class DownloadState {
  final bool isDownloading;
  final int currentProgress;
  final int totalCount;
  final int downloadedCount;

  DownloadState({
    this.isDownloading = false,
    this.currentProgress = 0,
    this.totalCount = 0,
    this.downloadedCount = 0,
  });

  DownloadState copyWith({
    bool? isDownloading,
    int? currentProgress,
    int? totalCount,
    int? downloadedCount,
  }) {
    return DownloadState(
      isDownloading: isDownloading ?? this.isDownloading,
      currentProgress: currentProgress ?? this.currentProgress,
      totalCount: totalCount ?? this.totalCount,
      downloadedCount: downloadedCount ?? this.downloadedCount,
    );
  }
}

class OfflineService {
  static final OfflineService _instance = OfflineService._internal();
  factory OfflineService() => _instance;
  OfflineService._internal();

  SharedPreferences? _prefs;
  String? _offlineDir;

  bool _offlineMode = false;
  bool get isOfflineMode => _offlineMode;
  void setOfflineMode(bool value) => _offlineMode = value;

  final ValueNotifier<DownloadState> downloadState = ValueNotifier(
    DownloadState(),
  );
  bool _isBackgroundDownloadActive = false;

  static const String _keyDownloadedSongs = 'offline_downloaded_songs';
  static const String _keyPendingScrobbles = 'pending_scrobbles';
  static const String _keyParallelDownloads = 'parallel_downloads_count';
  static const String _keyKeepScreenOn = 'offline_keep_screen_on';

  static const int _defaultParallelDownloads = 3;
  static const int _maxParallelDownloads = 5;

  Future<void> initialize() async {
    _prefs ??= await SharedPreferences.getInstance();
    final dir = await getApplicationDocumentsDirectory();
    _offlineDir = '${dir.path}/offline_music';

    final offlineDirectory = Directory(_offlineDir!);
    if (!await offlineDirectory.exists()) {
      await offlineDirectory.create(recursive: true);
    }
  }

  String _getSongPath(String songId) {
    return '$_offlineDir/$songId.mp3';
  }

  String _getLyricsPath(String songId) {
    return '$_offlineDir/$songId.lyrics.json';
  }

  String _getCoverArtPath(String songId) {
    return '$_offlineDir/$songId.jpg';
  }

  String? getLocalCoverArtPath(String songId) {
    if (_offlineDir == null) return null;
    final path = _getCoverArtPath(songId);
    if (File(path).existsSync()) return path;
    return null;
  }

  Future<void> saveLyrics(String songId, Map<String, dynamic> data) async {
    if (_offlineDir == null) await initialize();
    try {
      await File(_getLyricsPath(songId)).writeAsString(jsonEncode(data));
    } catch (e) {
      debugPrint('Error saving lyrics: $e');
    }
  }

  Future<Map<String, dynamic>?> getLocalLyrics(String songId) async {
    if (_offlineDir == null) await initialize();
    try {
      final file = File(_getLyricsPath(songId));
      if (!file.existsSync()) return null;
      return jsonDecode(await file.readAsString()) as Map<String, dynamic>?;
    } catch (e) {
      return null;
    }
  }

  bool isSongDownloaded(String songId) {
    if (_offlineDir == null) return false;
    final file = File(_getSongPath(songId));
    return file.existsSync();
  }

  List<String> getDownloadedSongIds() {
    return _prefs?.getStringList(_keyDownloadedSongs) ?? [];
  }

  int getDownloadedCount() {
    return getDownloadedSongIds().length;
  }

  Future<int> getDownloadedSize() async {
    if (_offlineDir == null) return 0;

    int totalSize = 0;
    final dir = Directory(_offlineDir!);
    if (await dir.exists()) {
      await for (final entity in dir.list()) {
        if (entity is File) {
          totalSize += await entity.length();
        }
      }
    }
    return totalSize;
  }

  String formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  Future<bool> downloadSong(
    Song song,
    SubsonicService subsonicService, {
    Function(double progress)? onProgress,
  }) async {
    if (_offlineDir == null) await initialize();

    try {
      final url = subsonicService.getStreamUrl(song.id);
      final filePath = _getSongPath(song.id);

      final dio = Dio();
      await dio.download(
        url,
        filePath,
        onReceiveProgress: (received, total) {
          if (total > 0 && onProgress != null) {
            onProgress(received / total);
          }
        },
      );

      final downloadedIds = getDownloadedSongIds();
      if (!downloadedIds.contains(song.id)) {
        downloadedIds.add(song.id);
        await _prefs?.setStringList(_keyDownloadedSongs, downloadedIds);
      }

      try {
        if (song.coverArt != null) {
          final coverUrl = subsonicService.getCoverArtUrl(song.coverArt, size: 600);
          if (coverUrl.isNotEmpty) {
            final dioCover = Dio();
            await dioCover.download(coverUrl, _getCoverArtPath(song.id));
          }
        }
      } catch (e) {
        debugPrint('Error downloading cover art for ${song.title}: $e');
      }
      try {
        final lyricsMap = <String, dynamic>{};
        final syncedLyrics = await subsonicService.getLyricsBySongId(song.id);
        if (syncedLyrics != null) lyricsMap['lyricsList'] = syncedLyrics;
        final plainLyrics = await subsonicService.getLyrics(
          artist: song.artist,
          title: song.title,
        );
        if (plainLyrics != null) lyricsMap['lyrics'] = plainLyrics;
        if (lyricsMap.isNotEmpty) await saveLyrics(song.id, lyricsMap);
      } catch (e) {
        debugPrint('Error downloading lyrics for ${song.title}: $e');
      }

      return true;
    } catch (e) {
      debugPrint('Error downloading song: $e');
      return false;
    }
  }

  Future<void> downloadSongs(
    List<Song> songs,
    SubsonicService subsonicService, {
    Function(int current, int total)? onProgress,
    Function(Song song, bool success)? onSongComplete,
    Function()? onComplete,
  }) async {
    if (_offlineDir == null) await initialize();

    for (int i = 0; i < songs.length; i++) {
      final song = songs[i];

      if (isSongDownloaded(song.id)) {
        onProgress?.call(i + 1, songs.length);
        onSongComplete?.call(song, true);
        continue;
      }

      final success = await downloadSong(song, subsonicService);
      onProgress?.call(i + 1, songs.length);
      onSongComplete?.call(song, success);
    }

    onComplete?.call();
  }

  /// Get the number of parallel downloads to use
  int getParallelDownloadsCount() {
    return _prefs?.getInt(_keyParallelDownloads) ?? _defaultParallelDownloads;
  }

  /// Set the number of parallel downloads (1 to _maxParallelDownloads)
  Future<void> setParallelDownloadsCount(int count) async {
    if (_prefs == null) await initialize();
    final clampedCount = count.clamp(1, _maxParallelDownloads);
    await _prefs?.setInt(_keyParallelDownloads, clampedCount);
  }

  Future<void> setKeepScreenOn(bool value) async {
    if (_prefs == null) await initialize();
    await _prefs?.setBool(_keyKeepScreenOn, value);
  }

  bool getKeepScreenOn() {
    return _prefs?.getBool(_keyKeepScreenOn) ?? true;
  }

  Future<void> startBackgroundDownload(
    List<Song> songs,
    SubsonicService subsonicService, {
    int? parallelCount,
  }) async {
    if (_isBackgroundDownloadActive) {
      debugPrint('Background download already in progress');
      return;
    }

    _isBackgroundDownloadActive = true;
    final alreadyDownloadedCount = getDownloadedCount();
    final concurrentDownloads = parallelCount ?? getParallelDownloadsCount();
    final keepScreenOn = getKeepScreenOn();

    // Enable wake lock to prevent the screen from turning off during download
    if (keepScreenOn && !kIsWeb) {
      try {
        await WakelockPlus.enable();
        debugPrint('Wake lock enabled for library download');
      } catch (e) {
        debugPrint('Failed to enable wake lock: $e');
      }
    }

    downloadState.value = DownloadState(
      isDownloading: true,
      currentProgress: 0,
      totalCount: songs.length,
      downloadedCount: alreadyDownloadedCount,
    );

    if (_offlineDir == null) await initialize();

    try {
      final pendingSongs = songs.where((s) => !isSongDownloaded(s.id)).toList();
      int completedCount = songs.length - pendingSongs.length;

      // Process songs in batches using parallel downloads
      for (int i = 0; i < pendingSongs.length; i += concurrentDownloads) {
        if (!_isBackgroundDownloadActive) {
          break;
        }

        // Get the next batch of songs
        final batch = pendingSongs.skip(i).take(concurrentDownloads).toList();

        // Download all songs in the batch concurrently
        final downloadFutures = batch.map((song) async {
          if (!_isBackgroundDownloadActive) return false;

          final success = await downloadSong(song, subsonicService);
          completedCount++;

          final newDownloadedCount = getDownloadedCount();
          downloadState.value = downloadState.value.copyWith(
            currentProgress: completedCount,
            downloadedCount: newDownloadedCount,
          );

          if (!success) {
            debugPrint('Failed to download song: ${song.title}');
          }
          return success;
        });

        // Wait for all downloads in the batch to complete
        await Future.wait(downloadFutures);
      }
    } catch (e) {
      debugPrint('Error during background download: $e');
    } finally {
      _isBackgroundDownloadActive = false;
      downloadState.value = downloadState.value.copyWith(isDownloading: false);

      // Always disable wake lock when download finishes or fails
      if (!kIsWeb) {
        try {
          await WakelockPlus.disable();
          debugPrint('Wake lock disabled after download');
        } catch (e) {
          debugPrint('Failed to disable wake lock: $e');
        }
      }
    }
  }

  void cancelBackgroundDownload() {
    _isBackgroundDownloadActive = false;
    downloadState.value = downloadState.value.copyWith(isDownloading: false);
  }

  bool get isBackgroundDownloadActive => _isBackgroundDownloadActive;

  Future<void> downloadPlaylist(
    Playlist playlist,
    SubsonicService subsonicService, {
    Function(int current, int total)? onProgress,
    Function()? onComplete,
  }) async {
    final songs = playlist.songs ?? [];
    await downloadSongs(
      songs,
      subsonicService,
      onProgress: onProgress,
      onComplete: onComplete,
    );
  }

  Future<bool> deleteSong(String songId) async {
    if (_offlineDir == null) return false;

    try {
      final file = File(_getSongPath(songId));
      if (await file.exists()) {
        await file.delete();
      }
      final lyricsFile = File(_getLyricsPath(songId));
      if (await lyricsFile.exists()) {
        await lyricsFile.delete();
      }
      final coverArtFile = File(_getCoverArtPath(songId));
      if (await coverArtFile.exists()) {
        await coverArtFile.delete();
      }

      final downloadedIds = getDownloadedSongIds();
      downloadedIds.remove(songId);
      await _prefs?.setStringList(_keyDownloadedSongs, downloadedIds);

      return true;
    } catch (e) {
      debugPrint('Error deleting song: $e');
      return false;
    }
  }

  Future<void> deleteAllDownloads() async {
    if (_offlineDir == null) return;

    try {
      final dir = Directory(_offlineDir!);
      if (await dir.exists()) {
        await for (final entity in dir.list()) {
          if (entity is File) {
            await entity.delete();
          }
        }
      }

      await _prefs?.setStringList(_keyDownloadedSongs, []);
    } catch (e) {
      debugPrint('Error deleting all downloads: $e');
    }
  }

  String? getLocalPath(String songId) {
    if (isSongDownloaded(songId)) {
      return _getSongPath(songId);
    }
    return null;
  }

  Future<void> queueScrobble(String songId, {bool submission = true}) async {
    if (_prefs == null) await initialize();
    final scrobbles = _getPendingScrobbles();
    scrobbles.add({
      'id': songId,
      'submission': submission ? 'true' : 'false',
      'time': DateTime.now().millisecondsSinceEpoch.toString(),
    });
    await _prefs!.setString(_keyPendingScrobbles, json.encode(scrobbles));
    debugPrint(
      'Scrobble queued for $songId (submission=$submission). Total pending: ${scrobbles.length}',
    );
  }

  List<Map<String, String>> _getPendingScrobbles() {
    final raw = _prefs?.getString(_keyPendingScrobbles);
    if (raw == null) return [];
    try {
      final list = json.decode(raw) as List;
      return list.map((e) => Map<String, String>.from(e as Map)).toList();
    } catch (_) {
      return [];
    }
  }

  int getPendingScrobbleCount() => _getPendingScrobbles().length;

  Future<void> flushPendingScrobbles(SubsonicService subsonicService) async {
    if (_prefs == null) await initialize();
    final pending = _getPendingScrobbles();
    if (pending.isEmpty) return;

    debugPrint('Flushing ${pending.length} pending scrobble(s)...');
    final remaining = <Map<String, String>>[];
    for (final scrobble in pending) {
      try {
        await subsonicService.scrobble(
          scrobble['id']!,
          submission: scrobble['submission'] == 'true',
        );
      } catch (e) {
        debugPrint('Scrobble flush failed for ${scrobble['id']}: $e');
        remaining.add(scrobble);
      }
    }

    if (remaining.isEmpty) {
      await _prefs!.remove(_keyPendingScrobbles);
      debugPrint('All pending scrobbles flushed successfully.');
    } else {
      await _prefs!.setString(_keyPendingScrobbles, json.encode(remaining));
      debugPrint('${remaining.length} scrobble(s) still pending after flush.');
    }
  }

  String getPlayableUrl(Song song, SubsonicService subsonicService) {
    
    if (song.isLocal == true && song.path != null) {
      return 'file://${song.path}';
    }

    final localPath = getLocalPath(song.id);
    if (localPath != null) {
      return 'file://$localPath';
    }
    return subsonicService.getStreamUrl(song.id);
  }
}
