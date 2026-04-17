import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/song.dart';
import '../models/playlist.dart';
import 'subsonic_service.dart';

enum DownloadStatus { queued, downloading, done, failed }

class DownloadLogEntry {
  final Song song;
  final DownloadStatus status;
  const DownloadLogEntry(this.song, this.status);
  DownloadLogEntry copyWith({DownloadStatus? status}) =>
      DownloadLogEntry(song, status ?? this.status);
}

class DownloadState {
  final bool isDownloading;
  final int currentProgress;
  final int totalCount;
  final int downloadedCount;
  final Song? currentSong;
  final List<Song> failedSongs;

  DownloadState({
    this.isDownloading = false,
    this.currentProgress = 0,
    this.totalCount = 0,
    this.downloadedCount = 0,
    this.currentSong,
    this.failedSongs = const [],
  });

  DownloadState copyWith({
    bool? isDownloading,
    int? currentProgress,
    int? totalCount,
    int? downloadedCount,
    Song? currentSong,
    bool clearCurrentSong = false,
    List<Song>? failedSongs,
  }) {
    return DownloadState(
      isDownloading: isDownloading ?? this.isDownloading,
      currentProgress: currentProgress ?? this.currentProgress,
      totalCount: totalCount ?? this.totalCount,
      downloadedCount: downloadedCount ?? this.downloadedCount,
      currentSong: clearCurrentSong ? null : (currentSong ?? this.currentSong),
      failedSongs: failedSongs ?? this.failedSongs,
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

  /// Reactive set of song IDs that are confirmed downloaded on disk.
  /// Widgets can listen to this to show/hide the green checkmark badge.
  final ValueNotifier<Set<String>> downloadedSongIds = ValueNotifier({});

  /// Per-batch download log, cleared at the start of each batch.
  /// Used by the Active Downloads detail screen.
  final ValueNotifier<List<DownloadLogEntry>> downloadLog = ValueNotifier([]);

  bool _isBackgroundDownloadActive = false;

  static const String _keyDownloadedSongs = 'offline_downloaded_songs';
  static const String _keyPendingScrobbles = 'pending_scrobbles';
  static const String _keyExpectedSizes = 'offline_expected_sizes';
  static const String _keyQueuedPlaylists = 'offline_queued_playlists';
  static const String _keyQueuedPlaylistData = 'offline_queued_playlist_data';

  Map<String, int> _expectedSizes = {};

  /// Playlist IDs that have been queued for download but aren't fully done.
  /// Drives the outline-check badge in playlist list views.
  final ValueNotifier<Set<String>> queuedPlaylistIds = ValueNotifier({});

  /// playlistId → serialised song list, so we can resume without LibraryProvider.
  Map<String, List<Map<String, dynamic>>> _queuedPlaylistData = {};

  /// Sequential download queue: each entry is (playlistId, songs).
  final List<({String playlistId, List<Song> songs, SubsonicService service})>
      _downloadQueue = [];
  bool _queueProcessorRunning = false;

  Future<void> initialize() async {
    _prefs ??= await SharedPreferences.getInstance();
    final dir = await getApplicationDocumentsDirectory();
    _offlineDir = '${dir.path}/offline_music';

    final offlineDirectory = Directory(_offlineDir!);
    if (!await offlineDirectory.exists()) {
      await offlineDirectory.create(recursive: true);
    }

    // Load expected sizes map
    final sizesJson = _prefs?.getString(_keyExpectedSizes);
    if (sizesJson != null) {
      try {
        final raw = json.decode(sizesJson) as Map<String, dynamic>;
        _expectedSizes = raw.map((k, v) => MapEntry(k, v as int));
      } catch (_) {}
    }

    // Seed from SharedPrefs first
    final prefsIds = getDownloadedSongIds().toSet();

    // Reconcile with disk: any valid .mp3 on disk that isn't in the index
    // gets added (handles interrupted downloads where file landed but prefs
    // weren't updated before the app was killed)
    final diskIds = <String>{};
    final offDir = Directory(_offlineDir!);
    if (await offDir.exists()) {
      await for (final entity in offDir.list()) {
        if (entity is File && entity.path.endsWith('.mp3')) {
          final songId = entity.path.split('/').last.replaceAll('.mp3', '');
          if (_isFileValid(songId, entity)) diskIds.add(songId);
        }
      }
    }

    final merged = {...prefsIds, ...diskIds};
    if (merged.length != prefsIds.length) {
      await _prefs?.setStringList(_keyDownloadedSongs, merged.toList());
    }
    downloadedSongIds.value = merged;

    // Load queued playlist tracking
    final queuedIds = _prefs?.getStringList(_keyQueuedPlaylists) ?? [];
    final queuedDataJson = _prefs?.getString(_keyQueuedPlaylistData);
    if (queuedDataJson != null) {
      try {
        final raw = json.decode(queuedDataJson) as Map<String, dynamic>;
        _queuedPlaylistData = raw.map(
          (k, v) => MapEntry(k, (v as List).cast<Map<String, dynamic>>()),
        );
      } catch (_) {}
    }
    queuedPlaylistIds.value = queuedIds.toSet();

    // Unmark any playlists that are now fully on disk
    _checkAndUnmarkCompleted(merged);
  }

  /// Removes playlists from the queued set if all their songs are now present.
  void _checkAndUnmarkCompleted(Set<String> presentIds) {
    final nowDone = <String>{};
    for (final playlistId in queuedPlaylistIds.value) {
      final data = _queuedPlaylistData[playlistId];
      if (data == null || data.isEmpty) continue;
      final songIds = data.map((s) => s['id']?.toString() ?? '').where((id) => id.isNotEmpty);
      if (songIds.every(presentIds.contains)) nowDone.add(playlistId);
    }
    if (nowDone.isEmpty) return;
    for (final id in nowDone) { _queuedPlaylistData.remove(id); }
    queuedPlaylistIds.value = queuedPlaylistIds.value.difference(nowDone);
    _prefs?.setStringList(_keyQueuedPlaylists, queuedPlaylistIds.value.toList());
    _prefs?.setString(_keyQueuedPlaylistData, json.encode(_queuedPlaylistData));
  }

  /// Queue a playlist for download. If the processor isn't running, start it.
  /// Multiple calls stack up and are processed sequentially.
  Future<void> queuePlaylistDownload(
    String playlistId,
    List<Song> songs,
    SubsonicService subsonicService,
  ) async {
    if (_offlineDir == null) await initialize();

    // Persist queued state so outline badge appears immediately
    _queuedPlaylistData[playlistId] = songs.map((s) => s.toJson()).toList();
    queuedPlaylistIds.value = {...queuedPlaylistIds.value, playlistId};
    await _prefs?.setStringList(_keyQueuedPlaylists, queuedPlaylistIds.value.toList());
    await _prefs?.setString(_keyQueuedPlaylistData, json.encode(_queuedPlaylistData));

    // Filter to only songs that still need downloading
    final missing = songs.where((s) => !isSongDownloaded(s.id)).toList();
    if (missing.isEmpty) {
      _checkAndUnmarkCompleted(downloadedSongIds.value);
      return;
    }

    _downloadQueue.add((playlistId: playlistId, songs: missing, service: subsonicService));
    _startQueueProcessor();
  }

  void _startQueueProcessor() {
    if (_queueProcessorRunning) return;
    _queueProcessorRunning = true;
    _processQueue();
  }

  Future<void> _processQueue() async {
    while (_downloadQueue.isNotEmpty) {
      final entry = _downloadQueue.removeAt(0);
      await startBackgroundDownload(entry.songs, entry.service);
      _checkAndUnmarkCompleted(downloadedSongIds.value);
    }
    _queueProcessorRunning = false;
  }

  /// Called at startup to re-queue any playlists that were interrupted.
  Future<void> resumeIncompleteDownloads(SubsonicService subsonicService) async {
    if (_queuedPlaylistData.isEmpty) return;
    for (final entry in _queuedPlaylistData.entries) {
      final missing = entry.value
          .map((s) => Song.fromJson(s))
          .where((s) => !isSongDownloaded(s.id))
          .toList();
      if (missing.isEmpty) continue;
      _downloadQueue.add((playlistId: entry.key, songs: missing, service: subsonicService));
    }
    if (_downloadQueue.isNotEmpty) _startQueueProcessor();
  }

  /// Returns true if the file on disk is complete.
  /// Uses the stored expected size when available, falls back to 64 KB floor.
  bool _isFileValid(String songId, File file) {
    try {
      final len = file.lengthSync();
      final expected = _expectedSizes[songId];
      if (expected != null && expected > 0) {
        return len >= expected;
      }
      return len >= 65536;
    } catch (_) {
      return false;
    }
  }

  Future<void> _persistExpectedSize(String songId, int bytes) async {
    _expectedSizes[songId] = bytes;
    await _prefs?.setString(_keyExpectedSizes, json.encode(_expectedSizes));
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
    if (!file.existsSync()) return false;
    return _isFileValid(songId, file);
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

  /// Returns (downloaded, total) for a list of songs — used by the
  /// Playlist Status settings panel.
  (int, int) getPlaylistDownloadStatus(List<Song> songs) {
    final ids = downloadedSongIds.value;
    final downloaded = songs.where((s) => ids.contains(s.id)).length;
    return (downloaded, songs.length);
  }

  Future<bool> downloadSong(
    Song song,
    SubsonicService subsonicService, {
    Function(double progress)? onProgress,
  }) async {
    if (_offlineDir == null) await initialize();

    // Persist expected size before downloading so reconciliation can use it
    // even if the app is killed mid-download.
    if (song.size != null && song.size! > 0) {
      await _persistExpectedSize(song.id, song.size!);
    }

    final filePath = _getSongPath(song.id);
    try {
      // Use /download (original file, no transcoding) so size matches song.size
      final url = subsonicService.getDownloadUrl(song.id);

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

      // Validate against stored expected size (or 64 KB floor if unknown)
      if (!isSongDownloaded(song.id)) {
        throw Exception('Downloaded file for ${song.id} failed size check');
      }
      final downloadedIds = getDownloadedSongIds();
      if (!downloadedIds.contains(song.id)) {
        downloadedIds.add(song.id);
        await _prefs?.setStringList(_keyDownloadedSongs, downloadedIds);
      }
      // Notify reactive listeners (SongTile badges, playlist checkmarks)
      downloadedSongIds.value = {...downloadedSongIds.value, song.id};

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
      // Remove partial file so isSongDownloaded() doesn't treat it as complete
      try {
        final partial = File(filePath);
        if (partial.existsSync()) await partial.delete();
      } catch (_) {}
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

  Future<void> startBackgroundDownload(
    List<Song> songs,
    SubsonicService subsonicService,
  ) async {
    if (_isBackgroundDownloadActive) {
      debugPrint('Background download already in progress');
      return;
    }

    _isBackgroundDownloadActive = true;
    final alreadyDownloadedCount = getDownloadedCount();

    // Reset the per-batch log and seed it with queued entries
    downloadLog.value = songs
        .map((s) => DownloadLogEntry(s, DownloadStatus.queued))
        .toList();

    downloadState.value = DownloadState(
      isDownloading: true,
      currentProgress: 0,
      totalCount: songs.length,
      downloadedCount: alreadyDownloadedCount,
      failedSongs: [],
    );

    if (_offlineDir == null) await initialize();

    try {
      for (int i = 0; i < songs.length; i++) {
        if (!_isBackgroundDownloadActive) {
          break;
        }

        final song = songs[i];

        if (isSongDownloaded(song.id)) {
          _updateLogEntry(i, DownloadStatus.done);
          downloadState.value = downloadState.value.copyWith(
            currentProgress: i + 1,
          );
          continue;
        }

        // Mark as actively downloading
        _updateLogEntry(i, DownloadStatus.downloading);
        downloadState.value = downloadState.value.copyWith(
          currentSong: song,
        );

        final success = await downloadSong(song, subsonicService);

        _updateLogEntry(i, success ? DownloadStatus.done : DownloadStatus.failed);

        final newDownloadedCount = getDownloadedCount();
        final newFailed = success
            ? downloadState.value.failedSongs
            : [...downloadState.value.failedSongs, song];

        downloadState.value = downloadState.value.copyWith(
          currentProgress: i + 1,
          downloadedCount: newDownloadedCount,
          failedSongs: newFailed,
        );

        if (!success) {
          debugPrint('Failed to download song: ${song.title}');
        }
      }
    } catch (e) {
      debugPrint('Error during background download: $e');
    }

    // One automatic retry pass for any failed songs
    final toRetry = List<Song>.from(downloadState.value.failedSongs);
    if (toRetry.isNotEmpty && _isBackgroundDownloadActive) {
      debugPrint('Retrying ${toRetry.length} failed song(s)...');
      final retryFailed = <Song>[];
      for (final song in toRetry) {
        if (!_isBackgroundDownloadActive) break;
        final success = await downloadSong(song, subsonicService);
        if (!success) retryFailed.add(song);
      }
      downloadState.value = downloadState.value.copyWith(
        failedSongs: retryFailed,
      );
    }

    _isBackgroundDownloadActive = false;
    downloadState.value = downloadState.value.copyWith(
      isDownloading: false,
      clearCurrentSong: true,
    );
  }

  void _updateLogEntry(int index, DownloadStatus status) {
    final log = List<DownloadLogEntry>.from(downloadLog.value);
    if (index < log.length) {
      log[index] = log[index].copyWith(status: status);
      downloadLog.value = log;
    }
  }

  void cancelBackgroundDownload() {
    _isBackgroundDownloadActive = false;
    downloadState.value = downloadState.value.copyWith(
      isDownloading: false,
      clearCurrentSong: true,
    );
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
      downloadedSongIds.value = {...downloadedSongIds.value}..remove(songId);
      _expectedSizes.remove(songId);
      await _prefs?.setString(_keyExpectedSizes, json.encode(_expectedSizes));

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
      await _prefs?.remove(_keyExpectedSizes);
      await _prefs?.remove(_keyQueuedPlaylists);
      await _prefs?.remove(_keyQueuedPlaylistData);
      _expectedSizes = {};
      _queuedPlaylistData = {};
      _downloadQueue.clear();
      queuedPlaylistIds.value = {};
      downloadedSongIds.value = {};
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
