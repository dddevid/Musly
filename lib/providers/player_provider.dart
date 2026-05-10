import 'package:flutter/foundation.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' show Random;

import 'package:audio_session/audio_session.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import '../services/subsonic_service.dart';
import '../services/offline_service.dart';
import '../services/android_auto_service.dart';
import '../services/android_system_service.dart';
import '../services/windows_system_service.dart';
import '../services/bluetooth_avrcp_service.dart';
import '../services/samsung_integration_service.dart';
import '../services/recommendation_service.dart';
import '../services/replay_gain_service.dart';
import '../services/auto_dj_service.dart';
import '../services/discord_rpc_service.dart';
import '../services/storage_service.dart';
import '../services/cast_service.dart';
import '../services/upnp_service.dart';
import '../services/audio_handler.dart';
import '../services/lock_screen_lyrics_service.dart';
import '../providers/library_provider.dart';

enum RepeatMode { off, all, one }

class PlayerProvider extends ChangeNotifier {
  final SubsonicService _subsonicService;
  late final StorageService _storageService;
  final MuslyAudioHandler _audioHandler;
  // Convenience getter — use this everywhere just_audio is accessed directly.
  AudioPlayer get _audioPlayer => _audioHandler.player;
  final OfflineService _offlineService = OfflineService();
  final AndroidAutoService _androidAutoService = AndroidAutoService();
  final AndroidSystemService _androidSystemService = AndroidSystemService();
  final WindowsSystemService _windowsService = WindowsSystemService();
  final BluetoothAvrcpService _bluetoothService = BluetoothAvrcpService();
  final SamsungIntegrationService _samsungService = SamsungIntegrationService();
  final ReplayGainService _replayGainService = ReplayGainService();
  final AutoDjService _autoDjService = AutoDjService();
  late final DiscordRpcService _discordRpcService;
  final CastService _castService;
  late final UpnpService _upnpService;
  final LockScreenLyricsService _lyricsService = LockScreenLyricsService();
  LibraryProvider? _libraryProvider;
  RecommendationService? _recommendationService;

  List<Song> _queue = [];
  int _currentIndex = -1;
  bool _isPlaying = false;
  bool _isLoading = false;
  bool _shuffleEnabled = false;
  bool _gaplessEnabled = true;
  final List<String> _shuffleHistory = [];
  RepeatMode _repeatMode = RepeatMode.off;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  Song? _currentSong;
  double _volume = 1.0;

  /// True only while audio is actually being rendered on a remote device.
  /// Distinct from isConnected: if the user plays a radio station while a
  /// UPnP renderer is connected, the audio is still local, so this stays false.
  bool _isRenderingRemotely = false;

  String? _resolvedArtworkUrl;

  RadioStation? _currentRadioStation;
  bool _isPlayingRadio = false;

  bool _hasPlayedOnce = false;

  SharedPreferences? _prefs;
  Timer? _persistDebounceTimer;
  static const String _keyQueue = 'persistent_queue';
  static const String _keyQueueIndex = 'persistent_queue_index';
  static const String _keyQueueSongId = 'persistent_queue_song_id';
  static const String _keyQueuePosition = 'persistent_queue_position_ms';

  final bool _reactivatingSession = false;

  Timer? _sleepTimer;
  DateTime? _sleepTimerEnd;
  bool _sleepTimerEndCurrentSong = false;
  bool _sleepTimerFadeOut = false;
  int _sleepTimerFadeDurationSeconds = 30;
  Timer? _sleepTimerFadeTimer;
  Timer? _sleepTimerFadePeriodicTimer;

  double _playbackSpeed = 1.0;
  double _pitch = 1.0;
  bool _pitchCorrection = true;

  PlayerProvider(
    this._subsonicService,
    StorageService storageService,
    this._castService,
    this._upnpService,
    this._audioHandler,
  ) {
    _storageService = storageService;
    _discordRpcService = DiscordRpcService(storageService);
    _castService.addListener(_onCastStateChanged);
    _upnpService.addListener(_onUpnpStateChanged);
    _upnpService.onRendererLost = _onUpnpRendererLost;
    _initializePlayer();
    try {
      _initializeAndroidAuto();
    } catch (_) {}
    try {
      _initializeSystemServices();
    } catch (_) {}
    _initializeAutoDj();
    _wireAudioHandlerCallbacks();
    try {
      _initializeLyricsService();
    } catch (_) {}

    if (!kIsWeb &&
        (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      try {
        _discordRpcService.initialize();
      } catch (_) {}
      try {
        loadDiscordRpcStateStyle();
      } catch (_) {}
    }

    _restoreQueueState();
  }

  /// Connect [MuslyAudioHandler] lock-screen commands back to this provider.
  /// On iOS these come via [audio_service] instead of [iOSSystemPlugin].
  void _wireAudioHandlerCallbacks() {
    _audioHandler.onPlay = play;
    _audioHandler.onPause = pause;
    _audioHandler.onStop = stop;
    _audioHandler.onSkipNext = skipNext;
    _audioHandler.onSkipPrevious = skipPrevious;
    _audioHandler.onSeekTo = seek;
    _audioHandler.onTogglePlayPause = togglePlayPause;
  }

  // ── Persistent Queue ───────────────────────────────────────────────────────

  void _saveQueueState() {
    _persistDebounceTimer?.cancel();
    _persistDebounceTimer = Timer(const Duration(milliseconds: 200), () async {
      try {
        _prefs ??= await SharedPreferences.getInstance();
        if (_prefs == null) return;
        final queueJson = _queue.map((s) => s.toJson()).toList();
        await _prefs!.setString(_keyQueue, jsonEncode(queueJson));
        await _prefs!.setInt(_keyQueueIndex, _currentIndex);
        await _prefs!.setString(_keyQueueSongId, _currentSong?.id ?? '');
        await _prefs!.setInt(_keyQueuePosition, _position.inMilliseconds);
      } catch (e) {
        debugPrint('Error saving queue state: $e');
      }
    });
  }

  Future<void> _restoreQueueState() async {
    try {
      _prefs ??= await SharedPreferences.getInstance();
      if (_prefs == null) return;

      final queueRaw = _prefs!.getString(_keyQueue);
      if (queueRaw == null || queueRaw.isEmpty) return;

      final queueJson = jsonDecode(queueRaw) as List<dynamic>;
      if (queueJson.isEmpty) return;

      final restoredSongs = queueJson
          .map((j) => Song.fromJson(j as Map<String, dynamic>))
          .where((s) {
        // Validate local files still exist.
        if (s.isLocal && s.path != null) {
          return File(s.path!).existsSync();
        }
        return true;
      }).toList();

      if (restoredSongs.isEmpty) return;

      final savedIndex = _prefs!.getInt(_keyQueueIndex) ?? 0;
      final savedSongId = _prefs!.getString(_keyQueueSongId);
      final savedPositionMs = _prefs!.getInt(_keyQueuePosition) ?? 0;

      var targetIndex = savedIndex.clamp(0, restoredSongs.length - 1);
      if (savedSongId != null && savedSongId.isNotEmpty) {
        final idIndex = restoredSongs.indexWhere((s) => s.id == savedSongId);
        if (idIndex != -1) targetIndex = idIndex;
      }

      _queue = restoredSongs;
      _currentIndex = targetIndex;
      _currentSong = restoredSongs[targetIndex];
      _position = Duration(milliseconds: savedPositionMs);
      notifyListeners();
      debugPrint(
          'Restored persistent queue: ${restoredSongs.length} songs, index $targetIndex, position $_position');
    } catch (e) {
      debugPrint('Error restoring queue state: $e');
    }
  }

  void _clearPersistedQueue() {
    _persistDebounceTimer?.cancel();
    try {
      SharedPreferences.getInstance().then((p) {
        p.remove(_keyQueue);
        p.remove(_keyQueueIndex);
        p.remove(_keyQueueSongId);
      });
    } catch (_) {}
  }

  void setLibraryProvider(LibraryProvider libraryProvider) {
    _libraryProvider = libraryProvider;
  }

  void setRecommendationService(RecommendationService recommendationService) {
    _recommendationService = recommendationService;
    _autoDjService.setServices(_subsonicService, recommendationService);
  }

  AutoDjService get autoDjService => _autoDjService;
  LockScreenLyricsService get lyricsService => _lyricsService;

  Future<void> _initializeAutoDj() async {
    await _autoDjService.initialize();
    _autoDjService.setServices(_subsonicService, _recommendationService);
  }

  Future<void> _initializeLyricsService() async {
    await _lyricsService.initialize();
  }

  Future<void> _initializeSystemServices() async {
    await _androidSystemService.initialize();
    _androidSystemService.onPlay = play;
    _androidSystemService.onPause = pause;
    _androidSystemService.onStop = stop;
    _androidSystemService.onSkipNext = skipNext;
    _androidSystemService.onSkipPrevious = skipPrevious;
    _androidSystemService.onSeekTo = seek;
    _androidSystemService.onSeekForward =
        (interval) => seek(_position + interval);
    _androidSystemService.onSeekBackward = (interval) {
      final target = _position - interval;
      seek(target.isNegative ? Duration.zero : target);
    };
    _androidSystemService.onHeadsetHook = togglePlayPause;
    _androidSystemService.onHeadsetDoubleClick = skipNext;

    await _windowsService.initialize();
    _windowsService.onPlay = play;
    _windowsService.onPause = pause;
    _windowsService.onStop = stop;
    _windowsService.onSkipNext = skipNext;
    _windowsService.onSkipPrevious = skipPrevious;
    _windowsService.onSeekTo = seek;

    // Audio focus and noisy callbacks must be no-ops in remote-playback mode.
    // The audio is playing on the renderer device, not on this phone, so
    // Android reassigning audio focus at screen-off (or a noisy event) must
    // not pause the renderer.
    _androidSystemService.onAudioFocusLoss = () {
      if (isRemotePlayback) return;
      pause();
    };
    _androidSystemService.onAudioFocusLossTransient = () {
      if (isRemotePlayback) return;
      pause();
    };
    _androidSystemService.onAudioFocusLossTransientCanDuck = () {
      if (isRemotePlayback) return;
      _audioPlayer.setVolume(0.3);
    };
    _androidSystemService.onAudioFocusGain = () {
      if (isRemotePlayback) return;
      _audioPlayer.setVolume(_volume);
    };
    _androidSystemService.onBecomingNoisy = () {
      if (isRemotePlayback) return;
      pause();
    };

    await _bluetoothService.initialize();
    _bluetoothService.onPlay = play;
    _bluetoothService.onPause = pause;
    _bluetoothService.onStop = stop;
    _bluetoothService.onSkipNext = skipNext;
    _bluetoothService.onSkipPrevious = skipPrevious;
    _bluetoothService.onSeekTo = seek;
    _bluetoothService.onDeviceConnected = (device) {
      debugPrint('Bluetooth device connected: ${device.name}');
      // AVRCP support means the device can handle audio controls, which is
      // a reliable proxy for A2DP audio output (watches/controllers don't
      // advertise AVRCP). Re-query isA2dpConnected for ground truth.
      _bluetoothService.isA2dpConnected().then((active) {
        _isA2dpAudioActive = active;
        debugPrint('Bluetooth A2DP audio active: $_isA2dpAudioActive');
      });
      _updateAllServices();
    };
    _bluetoothService.onDeviceDisconnected = (device) {
      debugPrint('Bluetooth device disconnected: ${device.name}');
      _bluetoothService.isA2dpConnected().then((active) {
        _isA2dpAudioActive = active;
        debugPrint('Bluetooth A2DP audio active: $_isA2dpAudioActive');
      });
    };

    _bluetoothService.registerAbsoluteVolumeControl();

    _samsungService.initialize();
    _samsungService.onDexModeEnter = () {
      debugPrint('Entered Samsung DeX mode');
      notifyListeners();
    };
    _samsungService.onDexModeExit = () {
      debugPrint('Exited Samsung DeX mode');
      notifyListeners();
    };
    _samsungService.onEdgePanelAction = (action) {
      switch (action) {
        case 'play':
          play();
          break;
        case 'pause':
          pause();
          break;
        case 'next':
          skipNext();
          break;
        case 'previous':
          skipPrevious();
          break;
      }
    };
  }

  void _initializeAndroidAuto() {
    _androidAutoService.initialize();

    _androidAutoService.onPlay = play;
    _androidAutoService.onPause = pause;
    _androidAutoService.onStop = stop;
    _androidAutoService.onSkipNext = skipNext;
    _androidAutoService.onSkipPrevious = skipPrevious;
    _androidAutoService.onSeekTo = seek;
    _androidAutoService.onPlayFromMediaId = _playFromMediaId;
    _androidAutoService.onSetVolume = _onRemoteVolumeChange;

    _androidAutoService.onGetAlbumSongs = _getAlbumSongsForAndroidAuto;
    _androidAutoService.onGetArtistAlbums = _getArtistAlbumsForAndroidAuto;
    _androidAutoService.onGetPlaylistSongs = _getPlaylistSongsForAndroidAuto;
    _androidAutoService.onSearch = _searchForAndroidAuto;
    _androidAutoService.onPlayFromSearch = _playFromSearchForAndroidAuto;
    _androidAutoService.onRequestLibraryData = _onRequestLibraryData;
  }

  void _onRequestLibraryData() {
    debugPrint(
        'PlayerProvider: Android Auto requested library data, delegating to LibraryProvider');
    // The LibraryProvider handles this in its constructor, but we add this
    // as a fallback to ensure the request is handled
    if (_libraryProvider != null) {
      // Trigger a re-push of library data via the LibraryProvider
      // This is handled by the callback registered in LibraryProvider's constructor
    }
  }

  Future<List<Map<String, String>>> _getAlbumSongsForAndroidAuto(
    String albumId,
  ) async {
    if (_offlineService.isOfflineMode && _libraryProvider != null) {
      await _offlineService.initialize();
      final downloadedIds = _offlineService.getDownloadedSongIds().toSet();
      final offlineSongs = _libraryProvider!.cachedAllSongs
          .where((s) => s.albumId == albumId && downloadedIds.contains(s.id))
          .toList();
      if (offlineSongs.isNotEmpty) {
        return offlineSongs
            .map(
              (song) => {
                'id': song.id,
                'title': song.title,
                'artist': song.artist ?? '',
                'album': song.album ?? '',
                'artworkUrl': _offlineService.getLocalCoverArtPath(song.id) !=
                        null
                    ? Uri.file(_offlineService.getLocalCoverArtPath(song.id)!)
                        .toString()
                    : _subsonicService.getCoverArtUrl(song.coverArt, size: 300),
                'duration': (song.duration ?? 0).toString(),
              },
            )
            .toList();
      }
    }
    try {
      final songs = await _subsonicService.getAlbumSongs(albumId);
      return songs
          .map(
            (song) => {
              'id': song.id,
              'title': song.title,
              'artist': song.artist ?? '',
              'album': song.album ?? '',
              'artworkUrl': _subsonicService.getCoverArtUrl(
                song.coverArt,
                size: 300,
              ),
              'duration': (song.duration ?? 0).toString(),
            },
          )
          .toList();
    } catch (e) {
      debugPrint('Error getting album songs for Android Auto: $e');
      return [];
    }
  }

  Future<List<Map<String, String>>> _getArtistAlbumsForAndroidAuto(
    String artistId,
  ) async {
    if (_offlineService.isOfflineMode && _libraryProvider != null) {
      await _offlineService.initialize();
      final downloadedIds = _offlineService.getDownloadedSongIds().toSet();
      final albumIdsWithDownloads = _libraryProvider!.cachedAllSongs
          .where((s) => s.artistId == artistId && downloadedIds.contains(s.id))
          .map((s) => s.albumId)
          .whereType<String>()
          .toSet();
      final offlineAlbums = _libraryProvider!.cachedAllAlbums
          .where((a) => albumIdsWithDownloads.contains(a.id))
          .toList();
      if (offlineAlbums.isNotEmpty) {
        return offlineAlbums
            .map(
              (album) => {
                'id': album.id,
                'name': album.name,
                'artist': album.artist ?? '',
                'artworkUrl': _subsonicService.getCoverArtUrl(
                  album.coverArt,
                  size: 300,
                ),
              },
            )
            .toList();
      }
    }
    try {
      final albums = await _subsonicService.getArtistAlbums(artistId);
      return albums
          .map(
            (album) => {
              'id': album.id,
              'name': album.name,
              'artist': album.artist ?? '',
              'artworkUrl': _subsonicService.getCoverArtUrl(
                album.coverArt,
                size: 300,
              ),
            },
          )
          .toList();
    } catch (e) {
      debugPrint('Error getting artist albums for Android Auto: $e');
      return [];
    }
  }

  Future<List<Map<String, String>>> _getPlaylistSongsForAndroidAuto(
    String playlistId,
  ) async {
    if (_offlineService.isOfflineMode && _libraryProvider != null) {
      await _offlineService.initialize();
      final downloadedIds = _offlineService.getDownloadedSongIds().toSet();
      final cachedPlaylist = _libraryProvider!.playlists
          .where((p) => p.id == playlistId)
          .firstOrNull;
      if (cachedPlaylist?.songs != null && cachedPlaylist!.songs!.isNotEmpty) {
        final offlineSongs = cachedPlaylist.songs!
            .where((s) => downloadedIds.contains(s.id))
            .toList();
        if (offlineSongs.isNotEmpty) {
          return offlineSongs
              .map(
                (song) => {
                  'id': song.id,
                  'title': song.title,
                  'artist': song.artist ?? '',
                  'album': song.album ?? '',
                  'artworkUrl': _offlineService.getLocalCoverArtPath(song.id) !=
                          null
                      ? Uri.file(_offlineService.getLocalCoverArtPath(song.id)!)
                          .toString()
                      : _subsonicService.getCoverArtUrl(song.coverArt,
                          size: 300),
                  'duration': (song.duration ?? 0).toString(),
                },
              )
              .toList();
        }
      }
    }
    try {
      final playlist = await _subsonicService.getPlaylist(playlistId);
      final songs = playlist.songs ?? [];
      return songs
          .map(
            (song) => {
              'id': song.id,
              'title': song.title,
              'artist': song.artist ?? '',
              'album': song.album ?? '',
              'artworkUrl': _subsonicService.getCoverArtUrl(
                song.coverArt,
                size: 300,
              ),
              'duration': (song.duration ?? 0).toString(),
            },
          )
          .toList();
    } catch (e) {
      debugPrint('Error getting playlist songs for Android Auto: $e');
      return [];
    }
  }

  Future<List<Map<String, String>>> _searchForAndroidAuto(
    String query,
  ) async {
    debugPrint(
        'PlayerProvider: _searchForAndroidAuto called with query="$query"');
    debugPrint(
        'PlayerProvider: isOfflineMode=${_offlineService.isOfflineMode}, libraryProvider=$_libraryProvider');

    if (_offlineService.isOfflineMode && _libraryProvider != null) {
      await _offlineService.initialize();
      final downloadedIds = _offlineService.getDownloadedSongIds().toSet();
      final lowerQuery = query.toLowerCase();
      final offlineResults = _libraryProvider!.cachedAllSongs
          .where(
            (s) =>
                downloadedIds.contains(s.id) &&
                (s.title.toLowerCase().contains(lowerQuery) ||
                    (s.artist?.toLowerCase().contains(lowerQuery) ?? false) ||
                    (s.album?.toLowerCase().contains(lowerQuery) ?? false)),
          )
          .take(20)
          .toList();
      return offlineResults
          .map(
            (song) => {
              'id': song.id,
              'title': song.title,
              'artist': song.artist ?? '',
              'album': song.album ?? '',
              'artworkUrl': _offlineService.getLocalCoverArtPath(song.id) !=
                      null
                  ? Uri.file(_offlineService.getLocalCoverArtPath(song.id)!)
                      .toString()
                  : _subsonicService.getCoverArtUrl(song.coverArt, size: 300),
              'duration': (song.duration ?? 0).toString(),
            },
          )
          .toList();
    }
    try {
      debugPrint(
          'PlayerProvider: Calling subsonicService.search with query="$query"');
      final results = await _subsonicService.search(
        query,
        songCount: 20,
        albumCount: 0,
        artistCount: 0,
      );
      debugPrint(
          'PlayerProvider: Search returned ${results.songs.length} songs');
      return results.songs
          .map(
            (song) => {
              'id': song.id,
              'title': song.title,
              'artist': song.artist ?? '',
              'album': song.album ?? '',
              'artworkUrl': _subsonicService.getCoverArtUrl(
                song.coverArt,
                size: 300,
              ),
              'duration': (song.duration ?? 0).toString(),
            },
          )
          .toList();
    } catch (e, stackTrace) {
      debugPrint('PlayerProvider: Android Auto search error: $e');
      debugPrint('PlayerProvider: Stack trace: $stackTrace');
      return [];
    }
  }

  Future<void> _playFromSearchForAndroidAuto(String query) async {
    debugPrint('Android Auto: playFromSearch called with query: "$query"');
    try {
      if (query.trim().isEmpty) {
        if (_currentSong != null) {
          await play();
        } else if (_libraryProvider != null &&
            _libraryProvider!.randomSongs.isNotEmpty) {
          final songs = _libraryProvider!.randomSongs;
          await playSong(songs.first, playlist: songs, startIndex: 0);
        }
        return;
      }

      final results = await _subsonicService.search(
        query,
        songCount: 20,
        albumCount: 0,
        artistCount: 0,
      );
      if (results.songs.isNotEmpty) {
        await playSong(
          results.songs.first,
          playlist: results.songs,
          startIndex: 0,
        );
      } else {
        debugPrint('Android Auto: no search results for "$query"');
      }
    } catch (e) {
      debugPrint('Android Auto: playFromSearch error: $e');
    }
  }

  Future<void> _playFromMediaId(String mediaId) async {
    debugPrint('Android Auto: playFromMediaId called with: $mediaId');

    final queueIndex = _queue.indexWhere((song) => song.id == mediaId);
    if (queueIndex != -1) {
      await skipToIndex(queueIndex);
      return;
    }

    if (_libraryProvider != null) {
      final randomSongs = _libraryProvider!.randomSongs;
      final songIndex = randomSongs.indexWhere((song) => song.id == mediaId);
      if (songIndex != -1) {
        await playSong(
          randomSongs[songIndex],
          playlist: randomSongs,
          startIndex: songIndex,
        );
        return;
      }
    }

    try {
      final searchResults = await _subsonicService.search(
        mediaId,
        songCount: 5,
      );
      if (searchResults.songs.isNotEmpty) {
        final song = searchResults.songs.firstWhere(
          (s) => s.id == mediaId,
          orElse: () => searchResults.songs.first,
        );
        await playSong(song);
        return;
      }

      debugPrint('Android Auto: Could not find song with id: $mediaId');
    } catch (e) {
      debugPrint('Android Auto: Error fetching song: $e');
    }
  }

  String? _resolveArtworkUrl() {
    if (_currentSong == null) return null;
    if (_currentSong!.coverArt == null) return null;
    if (_currentSong!.isLocal) {
      return Uri.file(_currentSong!.coverArt!).toString();
    }

    return _resolvedArtworkUrl;
  }

  Future<void> _refreshArtworkUrl() async {
    final song = _currentSong;
    if (song == null || song.coverArt == null) {
      _resolvedArtworkUrl = null;
      return;
    }
    if (song.isLocal) {
      _resolvedArtworkUrl = Uri.file(song.coverArt!).toString();
      return;
    }

    await _offlineService.initialize();

    final localPath = _offlineService.getLocalCoverArtPath(song.id);
    if (localPath != null) {
      _resolvedArtworkUrl = Uri.file(localPath).toString();
      if (_currentSong?.id == song.id) _updateAllServices();
      return;
    }

    final coverArtId = song.coverArt!;

    // Search for cached artwork from highest to lowest quality for iOS Now Playing
    for (final sz in [1200, 800, 600, 400, 300, 200]) {
      for (final key in ['${coverArtId}_natural_$sz', '${coverArtId}_$sz']) {
        try {
          final fileInfo = await DefaultCacheManager().getFileFromCache(key);
          if (fileInfo != null && fileInfo.file.existsSync()) {
            if (_currentSong?.id == song.id) {
              _resolvedArtworkUrl = Uri.file(fileInfo.file.path).toString();
              _updateAllServices();
            }
            return;
          }
        } catch (_) {}
      }
    }
    // Request high quality for iOS Now Playing bar / Control Center (1200px)
    final serverUrl = _subsonicService.getCoverArtUrl(coverArtId, size: 1200);

    if (!_offlineService.isOfflineMode) {
      _resolvedArtworkUrl = serverUrl;
      if (_currentSong?.id == song.id) _updateAllServices();
    }
  }

  void _updateAndroidAuto() {
    if (_currentSong == null) return;

    final artworkUrl = _resolveArtworkUrl();

    final effectiveDuration = _duration.inMilliseconds > 0
        ? _duration
        : Duration(seconds: _currentSong!.duration ?? 0);

    _androidAutoService.updatePlaybackState(
      songId: _currentSong!.id,
      title: _currentSong!.title,
      artist: _currentSong!.artist ?? '',
      album: _currentSong!.album ?? '',
      artworkUrl: artworkUrl,
      duration: effectiveDuration,
      position: _position,
      isPlaying: _isPlaying,
    );

    // Update the audio_service handler so lock screen / Control Center / iOS
    // Now Playing info stays accurate regardless of the UI lifecycle.
    _audioHandler.updateNowPlaying(
      id: _currentSong!.id,
      title: _currentSong!.title,
      artist: _currentSong!.artist,
      album: _currentSong!.album,
      artworkUrl: artworkUrl,
      duration: effectiveDuration,
    );

    _updateDiscordRpc();
    _updateAllServices();
  }

  void _updateAllServices() {
    if (_currentSong == null) return;

    final artworkUrl = _resolveArtworkUrl();

    final effectiveDuration = _duration.inMilliseconds > 0
        ? _duration
        : Duration(seconds: _currentSong!.duration ?? 0);

    _androidSystemService.updateFromSong(
      song: _currentSong!,
      artworkUrl: artworkUrl,
      duration: effectiveDuration,
      position: _position,
      isPlaying: _isPlaying,
      currentIndex: _currentIndex,
      queueLength: _queue.length,
    );

    _windowsService.updatePlaybackState(
      song: _currentSong!,
      artworkUrl: artworkUrl,
      duration: effectiveDuration,
      position: _position,
      isPlaying: _isPlaying,
    );

    _bluetoothService.updateFromSong(
      song: _currentSong!,
      artworkUrl: artworkUrl,
      duration: effectiveDuration,
      position: _position,
      isPlaying: _isPlaying,
      currentIndex: _currentIndex,
      queueLength: _queue.length,
    );

    if (_samsungService.isSamsungDevice) {
      _samsungService.updateFromSong(
        song: _currentSong!,
        artworkUrl: artworkUrl,
        duration: effectiveDuration,
        position: _position,
        isPlaying: _isPlaying,
      );
    }
  }

  bool get isSamsungDevice => _samsungService.isSamsungDevice;
  bool get isDexMode => _samsungService.isDexMode;
  bool get hasBluetoothDevice => _bluetoothService.hasConnectedDevices;
  List<BluetoothDeviceInfo> get connectedBluetoothDevices =>
      _bluetoothService.connectedDevices;

  List<Song> get queue => _queue;
  int get currentIndex => _currentIndex;
  bool get isPlaying => _isPlaying;
  bool get isLoading => _isLoading;

  /// True when audio is playing on a remote renderer (UPnP or Cast) rather
  /// than locally.  Used to suppress audio-focus and noisy-event handling that
  /// would incorrectly pause the remote device, and to route UI volume changes
  /// to the renderer instead of the Android system volume.
  bool get isRemotePlayback => _isRenderingRemotely;
  bool get shuffleEnabled => _shuffleEnabled;
  bool get gaplessEnabled => _gaplessEnabled;
  RepeatMode get repeatMode => _repeatMode;
  Duration get position => _position;
  Duration get duration => _duration;
  Song? get currentSong => _currentSong;
  bool get hasNext =>
      _queue.isNotEmpty &&
      (_currentIndex < _queue.length - 1 ||
          _repeatMode == RepeatMode.all ||
          (_shuffleEnabled && _queue.length > 1));
  bool get hasPrevious =>
      _queue.isNotEmpty &&
      (_currentIndex > 0 ||
          _repeatMode == RepeatMode.all ||
          (_shuffleEnabled && _shuffleHistory.isNotEmpty));
  double get volume => _volume;

  RadioStation? get currentRadioStation => _currentRadioStation;
  bool get isPlayingRadio => _isPlayingRadio;

  // Unified position stream: fed by the local audio player in normal mode, or
  // by UPnP/Cast polling in remote-playback mode.  The UI subscribes to this
  // instead of directly to _audioPlayer.positionStream so that the progress
  // bar animates correctly regardless of which playback path is active.
  final _positionController = StreamController<Duration>.broadcast();
  Stream<Duration> get positionStream => _positionController.stream;

  // Subscriptions stored so they can be cancelled before dispose closes the
  // StreamController, preventing a late just_audio tick from calling add() on
  // a closed controller.
  StreamSubscription<PlayerState>? _playerStateSub;
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<Duration?>? _durationSub;
  StreamSubscription<int?>? _currentIndexSub;

  ConcatenatingAudioSource? _concatenatingSource;

  // Fallback timer for Windows where positionStream may not emit reliably
  Timer? _windowsPositionTimer;
  Duration? _lastPolledPosition;

  double get progress {
    if (_duration.inMilliseconds == 0) return 0;
    return _position.inMilliseconds / _duration.inMilliseconds;
  }

  double get playbackSpeed => _playbackSpeed;

  double get pitch => _pitch;

  bool get pitchCorrection => _pitchCorrection;

  Future<void> setPlaybackSpeed(double speed) async {
    _playbackSpeed = speed.clamp(0.25, 4.0);

    final targetPitch = _pitchCorrection ? 1.0 : _playbackSpeed;
    _pitch = targetPitch.clamp(0.5, 2.0);

    final success = await _audioHandler.setPlaybackParameters(
      _playbackSpeed,
      _pitch,
    );
    if (!success) {
      // Fallback to just_audio native setSpeed when pitch plugin is unavailable.
      await _audioPlayer.setSpeed(_playbackSpeed);
    }

    notifyListeners();
  }

  Future<void> setPitch(double pitch) async {
    _pitch = pitch.clamp(0.5, 2.0);

    final success = await _audioHandler.setPlaybackParameters(
      _playbackSpeed,
      _pitch,
    );
    if (!success) {
      await _audioPlayer.setSpeed(_playbackSpeed);
    }

    notifyListeners();
  }

  Future<void> togglePitchCorrection() async {
    _pitchCorrection = !_pitchCorrection;
    final targetPitch = _pitchCorrection ? 1.0 : _playbackSpeed;
    _pitch = targetPitch.clamp(0.5, 2.0);

    final success = await _audioHandler.setPlaybackParameters(
      _playbackSpeed,
      _pitch,
    );
    if (!success) {
      await _audioPlayer.setSpeed(_playbackSpeed);
    }

    notifyListeners();
  }

  bool get hasSleepTimer => _sleepTimer != null;
  bool get sleepTimerEndCurrentSong => _sleepTimerEndCurrentSong;
  bool get sleepTimerFadeOut => _sleepTimerFadeOut;
  int get sleepTimerFadeDurationSeconds => _sleepTimerFadeDurationSeconds;

  Duration? get sleepTimerRemaining {
    if (_sleepTimerEnd == null) return null;
    final remaining = _sleepTimerEnd!.difference(DateTime.now());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  void setSleepTimer(
    Duration duration, {
    bool endCurrentSong = false,
    bool fadeOut = false,
    int fadeDurationSeconds = 30,
  }) {
    _sleepTimer?.cancel();
    _sleepTimerFadeTimer?.cancel();
    _sleepTimerFadePeriodicTimer?.cancel();
    _sleepTimerFadePeriodicTimer = null;
    _sleepTimer = null;
    _sleepTimerEnd = null;
    _sleepTimerEndCurrentSong = endCurrentSong;
    _sleepTimerFadeOut = fadeOut;
    _sleepTimerFadeDurationSeconds = fadeDurationSeconds;

    if (duration > Duration.zero) {
      _sleepTimerEnd = DateTime.now().add(duration);

      if (fadeOut) {
        final fadeStart = duration - Duration(seconds: fadeDurationSeconds);
        if (fadeStart > Duration.zero) {
          _sleepTimerFadeTimer =
              Timer(fadeStart, () => _startFadeOut(fadeDurationSeconds));
        } else {
          _startFadeOut(fadeDurationSeconds);
        }
      }

      _sleepTimer = Timer(duration, () {
        if (endCurrentSong) {
          _sleepTimerEndCurrentSong = true;
          _sleepTimer = null;
          _sleepTimerEnd = null;
          notifyListeners();
        } else {
          _doSleepTimerStop();
        }
      });
    }
    notifyListeners();
  }

  void _startFadeOut([int fadeDurationSeconds = 30]) {
    _sleepTimerFadePeriodicTimer?.cancel();
    final steps = fadeDurationSeconds.clamp(5, 300);
    const stepDuration = Duration(seconds: 1);
    final originalVolume = _volume;
    int step = 0;
    _sleepTimerFadePeriodicTimer = Timer.periodic(stepDuration, (t) {
      step++;
      final newVolume = originalVolume * (1.0 - step / steps);
      _audioPlayer.setVolume(newVolume.clamp(0.0, 1.0));
      if (step >= steps) {
        t.cancel();
        _sleepTimerFadePeriodicTimer = null;
      }
    });
  }

  void _doSleepTimerStop() {
    _sleepTimerFadePeriodicTimer?.cancel();
    _sleepTimerFadePeriodicTimer = null;
    _audioPlayer.setVolume(_volume);
    pause();
    _sleepTimer = null;
    _sleepTimerEnd = null;
    _sleepTimerFadeOut = false;
    _sleepTimerFadeDurationSeconds = 30;
    _sleepTimerEndCurrentSong = false;
    notifyListeners();
  }

  void _initializePlayer() {
    _configureAudioSession();

    _storageService.getVolume().then((savedVolume) {
      _volume = savedVolume;
      _audioPlayer.setVolume(_volume);
      notifyListeners();
    });

    _storageService.getShuffleMode().then((saved) {
      _shuffleEnabled = saved;
      notifyListeners();
    });

    _storageService.getRepeatMode().then((saved) {
      _repeatMode =
          RepeatMode.values[saved.clamp(0, RepeatMode.values.length - 1)];
      notifyListeners();
    });

    _storageService.getGaplessPlayback().then((saved) {
      _gaplessEnabled = saved;
      notifyListeners();
    });

    _playerStateSub = _audioPlayer.playerStateStream.listen(
      (state) {
        // In remote-playback mode the local player is stopped/paused; ignore
        // its state so it doesn't overwrite the UPnP/Cast-managed values.
        if (_isRenderingRemotely) return;

        final wasPlaying = _isPlaying;
        _isPlaying = state.playing;

        if (wasPlaying != _isPlaying && !_reactivatingSession) {
          debugPrint(
              '[Player] ${_isPlaying ? '▶ Playing' : '⏸ Paused'} — "${_currentSong?.title ?? 'unknown'}" (${state.processingState.name})');

          // Start/stop Windows position polling timer
          if (_isPlaying && Platform.isWindows && !_isRenderingRemotely) {
            _windowsPositionTimer?.cancel();
            _lastPolledPosition = null;
            _windowsPositionTimer = Timer.periodic(
              const Duration(milliseconds: 500),
              (_) {
                final pos = _audioPlayer.position;
                if (_lastPolledPosition == null ||
                    pos.inMilliseconds != _lastPolledPosition!.inMilliseconds) {
                  _lastPolledPosition = pos;
                  _position = pos;
                  _positionController.add(pos);
                  notifyListeners();
                  _updateAllServices();
                }
              },
            );
          } else {
            _windowsPositionTimer?.cancel();
            _windowsPositionTimer = null;
            _lastPolledPosition = null;
          }
        }

        if (state.processingState == ProcessingState.completed) {
          debugPrint(
              '[Player] ✓ Song completed: "${_currentSong?.title ?? 'unknown'}"');
          _onSongComplete().catchError(
              (e) => debugPrint('[Player] _onSongComplete error: $e'));
        }

        if (state.processingState == ProcessingState.buffering && !wasPlaying) {
          debugPrint(
              '[Player] ⟳ Buffering: "${_currentSong?.title ?? 'unknown'}"');
        }

        if (wasPlaying != _isPlaying && !_reactivatingSession) {
          notifyListeners();
          _updateAndroidAuto();
        }
      },
      onError: (error) {
        debugPrint('[Player] State stream error (usually harmless): $error');
      },
    );

    Duration? lastNotified;
    Duration? lastSystemUpdate;
    _positionSub = _audioPlayer.positionStream.listen(
      (position) {
        // In remote-playback mode the local player sits idle at position zero;
        // ignore its ticks so they don't overwrite the UPnP/Cast position.
        if (_isRenderingRemotely) return;

        final positionJumpedBack = _position.inMilliseconds > 0 &&
            position.inMilliseconds < _position.inMilliseconds - 1000;

        _position = position;
        _positionController.add(position);

        if (positionJumpedBack ||
            lastNotified == null ||
            position.inMilliseconds - lastNotified!.inMilliseconds > 250) {
          lastNotified = position;
          notifyListeners();
        }

        if (lastSystemUpdate == null ||
            (position.inMilliseconds - lastSystemUpdate!.inMilliseconds).abs() >
                1000) {
          lastSystemUpdate = position;
          _updateAllServices();
          _saveQueueState();
        }
      },
      onError: (error) {
        debugPrint('Position stream error (can be ignored): $error');
      },
    );

    _durationSub = _audioPlayer.durationStream.listen(
      (duration) {
        // In remote-playback mode the local player has no loaded track; ignore
        // its duration so it doesn't zero out the UPnP/Cast duration.
        if (_isRenderingRemotely) return;

        _duration = duration ?? Duration.zero;
        notifyListeners();
        _updateAndroidAuto();
      },
      onError: (error) {
        debugPrint('Duration stream error (can be ignored): $error');
      },
    );

    _currentIndexSub = _audioPlayer.currentIndexStream.listen(
      (index) {
        if (index != null &&
            index != _currentIndex &&
            !_isRenderingRemotely &&
            _concatenatingSource != null) {
          _onCurrentIndexChanged(index).catchError((e) {
            debugPrint('[Player] _onCurrentIndexChanged error: $e');
          });
        }
      },
      onError: (error) {
        debugPrint('Current index stream error (can be ignored): $error');
      },
    );
  }

  Future<void> _configureAudioSession() async {
    if (kIsWeb || !Platform.isAndroid) return;
    try {
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration.music());
      debugPrint('[Player] AudioSession configured for music playback');

      // Listen for audio interruptions (another app takes audio focus)
      session.interruptionEventStream.listen((event) {
        if (event.begin) {
          switch (event.type) {
            case AudioInterruptionType.duck:
              _audioPlayer.setVolume(0.3);
              break;
            case AudioInterruptionType.pause:
            case AudioInterruptionType.unknown:
              if (isRemotePlayback) return;
              pause();
              break;
          }
        } else {
          switch (event.type) {
            case AudioInterruptionType.duck:
              _audioPlayer.setVolume(_volume);
              break;
            case AudioInterruptionType.pause:
            case AudioInterruptionType.unknown:
              // Optionally resume after interruption ends
              break;
          }
        }
      });

      // Listen for headphone disconnection
      session.becomingNoisyEventStream.listen((_) {
        if (isRemotePlayback) return;
        pause();
      });
    } catch (e) {
      debugPrint('[Player] AudioSession configuration failed: $e');
    }
  }

  Future<void> _ensureAudioFocus() async {
    if (kIsWeb || !Platform.isAndroid) return;
    try {
      final granted = await _androidSystemService.requestAudioFocus();
      debugPrint('[Player] Audio focus requested, granted=$granted');
    } catch (e) {
      debugPrint('[Player] Audio focus request failed: $e');
    }
  }

  Future<void> _onSongComplete() async {
    if (_currentSong != null && _currentSong!.isLocal != true) {
      _subsonicService.scrobble(_currentSong!.id, submission: true).catchError((
        e,
      ) {
        _offlineService.queueScrobble(_currentSong!.id, submission: true);
      });
    }

    if (_currentSong != null && _recommendationService != null) {
      _recommendationService!.trackSongPlay(
        _currentSong!,
        durationPlayed: _duration.inSeconds,
        completed: true,
      );
    }

    if (_sleepTimerEndCurrentSong) {
      _doSleepTimerStop();
      return;
    }

    if (_concatenatingSource != null) {
      // With ConcatenatingAudioSource this only fires at the very end
      // of the queue when LoopMode is off.
      await _handleEndOfQueue();
      return;
    }

    // Fallback for single-song mode
    if (_repeatMode == RepeatMode.one ||
        (_repeatMode == RepeatMode.all && _queue.length == 1)) {
      await seek(Duration.zero);
      await play();
    } else if (_currentIndex < _queue.length - 1 ||
        _repeatMode == RepeatMode.all ||
        _shuffleEnabled) {
      await skipNext();
    } else {
      await _handleEndOfQueue();
    }
  }

  Future<void> _handleEndOfQueue() async {
    if (_autoDjService.isEnabled) {
      await _addAutoDjSongs();

      if (_currentIndex < _queue.length - 1) {
        await skipToIndex(_currentIndex + 1);
      }
    }
  }

  Future<void> playSong(
    Song song, {
    List<Song>? playlist,
    int? startIndex,
  }) async {
    if (_currentSong?.id == song.id && !_isPlayingRadio) {
      await togglePlayPause();
      return;
    }

    _isPlayingRadio = false;
    _currentRadioStation = null;

    debugPrint(
        '[Player] ▶ playSong: "${song.title}" by ${song.artist ?? 'unknown'} (id=${song.id} local=${song.isLocal})');
    _isLoading = true;
    notifyListeners();

    try {
      if (playlist != null) {
        final isNewQueue = !identical(playlist, _queue);
        _queue = List.from(playlist);
        _currentIndex =
            startIndex ?? playlist.indexWhere((s) => s.id == song.id);
        if (_currentIndex == -1) _currentIndex = 0;
        if (isNewQueue) _shuffleHistory.clear();
      } else if (_queue.isEmpty || !_queue.any((s) => s.id == song.id)) {
        _queue = [song];
        _currentIndex = 0;
        _shuffleHistory.clear();
      } else {
        _currentIndex = _queue.indexWhere((s) => s.id == song.id);
      }

      _currentSong = song;
      _resolvedArtworkUrl = null;
      _position = Duration.zero;
      notifyListeners();
      _saveQueueState();

      await _refreshArtworkUrl();

      // Load lyrics for lock screen sync
      await _loadAndSyncLyrics(song);

      // Update song info for iOS Live Activity
      await _lyricsService.updateSongInfo(
        title: song.title,
        artist: song.artist ?? 'Unknown Artist',
        artworkUrl: _resolvedArtworkUrl ?? song.coverArt,
      );

      if (_castService.isConnected) {
        if (_audioPlayer.playing) await _audioPlayer.stop();

        final playUrl = song.isLocal == true
            ? Uri.file(song.path!).toString()
            : await _subsonicService.resolveStreamUrlAsync(song);
        final coverUrl = song.isLocal == true && song.coverArt != null
            ? song.coverArt!
            : _subsonicService.getCoverArtUrl(song.coverArt ?? song.id);

        await _castService.loadMedia(
          url: playUrl,
          title: song.title,
          artist: song.artist ?? 'Unknown Artist',
          imageUrl: coverUrl,
          albumName: song.album,
          trackNumber: song.track,
          duration:
              song.duration != null ? Duration(seconds: song.duration!) : null,
          autoPlay: true,
        );
        _isRenderingRemotely = true;
        _isPlaying = true;
      } else if (_upnpService.isConnected) {
        // Reset before sending Stop so a poll that fires mid-load can't
        // mistake the STOPPED state for a natural track end and advance twice.
        _upnpWasPlaying = false;
        debugPrint(
          'UPnP: playSong() taking UPnP branch, isConnected=${_upnpService.isConnected}',
        );
        if (_audioPlayer.playing) await _audioPlayer.stop();

        final playUrl = song.isLocal == true && song.path != null
            ? Uri.file(song.path!).toString()
            : await _subsonicService.resolveStreamUrlAsync(song);

        try {
          // Resolve the MIME type so strict UPnP renderers (e.g. moode /
          // upmpdcli with "check metadata" on) can validate protocolInfo.
          final mimeType =
              song.contentType ?? UpnpService.mimeTypeFromSuffix(song.suffix);
          final success = await _upnpService.loadAndPlay(
            url: playUrl,
            title: song.title,
            artist: song.artist ?? 'Unknown Artist',
            album: song.album,
            albumArtUrl: song.coverArt != null
                ? _subsonicService.getCoverArtUrl(song.coverArt, size: 0)
                : null,
            durationSecs: song.duration,
            contentType: mimeType,
          );
          if (!success) {
            _upnpService.disconnect();
            debugPrint(
                'UPnP playback failed (retries exhausted), disconnected');
            return;
          }
        } catch (e) {
          _upnpService.disconnect();
          debugPrint('UPnP playback failed, disconnected: $e');
          rethrow;
        }
        _isRenderingRemotely = true;
        _isPlaying = true;
      } else {
        _isRenderingRemotely = false;

        // For YouTube, pre-fetch the manifest then hand a StreamAudioSource
        // to just_audio so ExoPlayer never touches the YouTube URL directly.
        final youtubeSource = song.isLocal != true
            ? await _subsonicService.getYoutubeAudioSource(song)
            : null;

        if (youtubeSource != null) {
          // YouTube: single StreamAudioSource, no gapless
          await _audioPlayer.setAudioSource(youtubeSource);
          await _applyReplayGain(song);
          await _ensureAudioFocus();
          await _audioPlayer.play();
        } else if (_subsonicService.isYoutube) {
          // All songs are YouTube — can't build ConcatenatingAudioSource easily
          final String playUrl;
          if (song.isLocal == true && song.path != null) {
            playUrl = Uri.file(song.path!).toString();
          } else {
            final offlinePath = _offlineService.getLocalPath(song.id);
            if (offlinePath != null) {
              playUrl = 'file://$offlinePath';
            } else {
              playUrl = await _subsonicService.resolveStreamUrlAsync(song);
            }
          }
          await _audioPlayer.setUrl(playUrl);
          await _applyReplayGain(song);
          await _ensureAudioFocus();
          await _audioPlayer.play();
        } else if (_gaplessEnabled) {
          // Build ConcatenatingAudioSource for gapless playback
          try {
            await _buildAndSetConcatenatingSource(initialIndex: _currentIndex);
          } catch (e) {
            // Android 16 / Media3 first-play workaround
            if (!_hasPlayedOnce) {
              debugPrint(
                'First playback failed (Android 16 Media3 issue), retrying: $e',
              );
              await Future.delayed(const Duration(milliseconds: 100));
              await _buildAndSetConcatenatingSource(initialIndex: _currentIndex);
              _hasPlayedOnce = true;
            } else {
              rethrow;
            }
          }
          await _applyReplayGain(song);
          await _ensureAudioFocus();
          await _audioPlayer.play();
        } else {
          // Gapless disabled — single-song mode
          final String playUrl;
          if (song.isLocal == true && song.path != null) {
            playUrl = Uri.file(song.path!).toString();
          } else {
            final offlinePath = _offlineService.getLocalPath(song.id);
            if (offlinePath != null) {
              playUrl = 'file://$offlinePath';
            } else {
              playUrl = await _subsonicService.resolveStreamUrlAsync(song);
            }
          }
          // Cache remote streams locally so seeking works even when the
          // server transcodes and doesn't support HTTP range requests (#170).
          if (song.isLocal == true ||
              _offlineService.getLocalPath(song.id) != null) {
            await _audioPlayer.setUrl(playUrl);
          } else {
            final cacheDir = await getTemporaryDirectory();
            final cacheFile = File(
              '${cacheDir.path}/musly_stream_${song.id.hashCode}.tmp',
            );
            // ignore: experimental_member_use
            await _audioPlayer.setAudioSource(
              // ignore: experimental_member_use
              LockCachingAudioSource(
                Uri.parse(playUrl),
                cacheFile: cacheFile,
                tag: song.id,
              ),
            );
          }
          await _applyReplayGain(song);
          await _ensureAudioFocus();
          await _audioPlayer.play();
        }
      }

      if (song.isLocal != true) {
        if (_offlineService.isOfflineMode) {
          _offlineService.queueScrobble(song.id, submission: false);
        } else {
          _subsonicService.scrobble(song.id, submission: false).catchError((e) {
            _offlineService.queueScrobble(song.id, submission: false);
          });

          _offlineService
              .flushPendingScrobbles(_subsonicService)
              .catchError((e) {
            debugPrint('Scrobble flush failed: $e');
          });
        }
      }

      if (_recommendationService != null) {
        _recommendationService!.trackSongPlay(
          song,
          durationPlayed: 0,
          completed: false,
        );
      }

      _updateAndroidAuto();
    } catch (e) {
      debugPrint('[Player] ✗ Error playing song "${song.title}": $e');
      _isPlaying = false;
      _position = Duration.zero;
      _updateAndroidAuto();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> playRadioStation(RadioStation station) async {
    if (_isPlayingRadio && _currentRadioStation?.id == station.id) {
      await togglePlayPause();
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      _currentSong = null;
      _queue = [];
      _currentIndex = -1;
      _isPlayingRadio = true;
      _isRenderingRemotely = false; // radio always plays locally
      _currentRadioStation = station;
      _position = Duration.zero;
      _duration = Duration.zero;

      try {
        await _audioPlayer.setUrl(station.streamUrl);
      } catch (e) {
        if (!_hasPlayedOnce) {
          debugPrint(
            'First radio playback failed (Android 16 Media3 issue), retrying: $e',
          );
          await Future.delayed(const Duration(milliseconds: 100));
          await _audioPlayer.setUrl(station.streamUrl);
          _hasPlayedOnce = true;
        } else {
          rethrow;
        }
      }

      await _audioPlayer.setVolume(_volume);

      await _ensureAudioFocus();
      await _audioPlayer.play();

      _updateSystemServicesForRadio(station);
    } catch (e) {
      debugPrint('Error playing radio station: $e');
      _isPlaying = false;
      _isPlayingRadio = false;
      _currentRadioStation = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void stopRadio() {
    if (_isPlayingRadio) {
      _audioPlayer.stop();
      _isPlayingRadio = false;
      _currentRadioStation = null;
      _isPlaying = false;
      // Clear lyrics when stopping radio
      _lyricsService.stopSync();
      _lyricsService.loadLyrics(null);
      notifyListeners();
    }
  }

  /// Load and sync lyrics for the given song
  Future<void> _loadAndSyncLyrics(Song song) async {
    try {
      // Stop any previous sync
      _lyricsService.stopSync();

      // Fetch lyrics from Subsonic API
      final lyricsResponse = await _subsonicService.getLyricsBySongId(song.id);

      if (lyricsResponse != null) {
        // Extract lyrics content from response
        // Subsonic returns lyrics in various formats
        String? lyricsContent;

        if (lyricsResponse.containsKey('lyrics')) {
          // Standard Subsonic format
          lyricsContent = lyricsResponse['lyrics'] as String?;
        } else if (lyricsResponse.containsKey('structuredLyrics')) {
          // Jellyfin format - convert to LRC
          final structured =
              lyricsResponse['structuredLyrics'] as List<dynamic>?;
          if (structured != null && structured.isNotEmpty) {
            lyricsContent = _convertStructuredToLrc(structured);
          }
        }

        if (lyricsContent != null && lyricsContent.isNotEmpty) {
          // Load lyrics into the service
          await _lyricsService.loadLyrics(lyricsContent);

          // Start syncing with position stream
          _lyricsService.startSync(_audioPlayer.positionStream);

          debugPrint('[Lyrics] Loaded and started sync for "${song.title}"');
        } else {
          // No lyrics available - clear any existing
          await _lyricsService.loadLyrics(null);
          debugPrint('[Lyrics] No lyrics available for "${song.title}"');
        }
      } else {
        // No lyrics available - clear any existing
        await _lyricsService.loadLyrics(null);
        debugPrint('[Lyrics] No lyrics available for "${song.title}"');
      }
    } catch (e) {
      debugPrint('[Lyrics] Failed to load lyrics for "${song.title}": $e');
      // Don't block playback if lyrics fail
      await _lyricsService.loadLyrics(null);
    }
  }

  /// Convert Jellyfin structured lyrics to LRC format
  String _convertStructuredToLrc(List<dynamic> structured) {
    final buffer = StringBuffer();
    for (final line in structured) {
      if (line is Map<String, dynamic>) {
        final text = line['text'] as String? ?? '';
        final startTicks = line['startTicks'] as int? ?? 0;
        final startMs = startTicks ~/ 10000; // Convert to milliseconds
        final minutes = startMs ~/ 60000;
        final seconds = (startMs % 60000) ~/ 1000;
        final centiseconds = (startMs % 1000) ~/ 10;
        buffer.writeln(
            '[$minutes:${seconds.toString().padLeft(2, '0')}.${centiseconds.toString().padLeft(2, '0')}]$text');
      }
    }
    return buffer.toString();
  }

  void _updateSystemServicesForRadio(RadioStation station) {
    _windowsService.updatePlaybackState(
      song: null,
      isPlaying: true,
      position: Duration.zero,
      duration: Duration.zero,
      artworkUrl: null,
    );

    _androidSystemService.updatePlaybackState(
      songId: station.id,
      title: station.name,
      artist: 'Internet Radio',
      album: station.homePageUrl ?? '',
      artworkUrl: null,
      duration: Duration.zero,
      position: Duration.zero,
      isPlaying: true,
    );
  }

  Future<void> play() async {
    if (_castService.isConnected) {
      await _castService.play();
      _isPlaying = true;
      notifyListeners();
      _updateAndroidAuto();
    } else if (_upnpService.isConnected) {
      await _upnpService.play();
      _isPlaying = true;
      notifyListeners();
      _updateAndroidAuto();
    } else {
      // After app restart the audio source may not be loaded yet.
      // If we have a current song but the player has no source, prepare it first.
      if (_currentSong != null && _audioPlayer.duration == Duration.zero) {
        await _prepareCurrentSong();
      }
      await _ensureAudioFocus();
      await _audioPlayer.play();
    }
  }

  Future<void> pause() async {
    if (_castService.isConnected) {
      await _castService.pause();
      _isPlaying = false;
      notifyListeners();
      _updateAndroidAuto();
    } else if (_upnpService.isConnected) {
      await _upnpService.pause();
      _isPlaying = false;
      notifyListeners();
      _updateAndroidAuto();
    } else {
      await _audioPlayer.pause();
    }
  }

  Future<void> stop() async {
    if (_castService.isConnected) {
      await _castService.stop();
    } else if (_upnpService.isConnected) {
      _upnpWasPlaying = false; // prevent poll from misreading the STOPPED state
      await _upnpService.stop();
    } else {
      await _audioPlayer.stop();
    }

    _isPlaying = false;
    _position = Duration.zero;
    notifyListeners();
    _updateAndroidAuto();
  }

  Future<void> togglePlayPause() async {
    if (_isPlaying) {
      await pause();
    } else {
      await play();
    }
  }

  Future<void> seek(Duration position) async {
    _position = position;
    notifyListeners();
    if (_castService.isConnected) {
      await _castService.seek(position);
    } else if (_upnpService.isConnected) {
      await _upnpService.seek(position);
    } else {
      await _audioPlayer.seek(position);
    }
  }

  Future<void> seekToProgress(double progress) async {
    final position = Duration(
      milliseconds: (progress * _duration.inMilliseconds).round(),
    );
    await seek(position);
  }

  Future<void> skipNext() async {
    if (_currentSong != null && _recommendationService != null) {
      final played = _position.inSeconds;
      final total = _duration.inSeconds;
      if (total > 0 && played < total * 0.8) {
        _recommendationService!.trackSkip(_currentSong!);
      } else if (played > 0) {
        _recommendationService!.trackSongPlay(
          _currentSong!,
          durationPlayed: played,
          completed: played >= total * 0.8,
        );
      }
    }

    if (_autoDjService.shouldAddSongs(_currentIndex, _queue.length)) {
      await _addAutoDjSongs();
    }

    if (_concatenatingSource != null) {
      if (_shuffleEnabled && _queue.length > 1) {
        _shuffleHistory.add(_currentSong!.id);
        if (_shuffleHistory.length > 50) _shuffleHistory.removeAt(0);
        int next;
        do {
          next = Random().nextInt(_queue.length);
        } while (next == _currentIndex);
        await _audioPlayer.seek(Duration.zero, index: next);
      } else if (_currentIndex < _queue.length - 1) {
        await _audioPlayer.seek(Duration.zero, index: _currentIndex + 1);
      } else if (_repeatMode == RepeatMode.all) {
        await _audioPlayer.seek(Duration.zero, index: 0);
      }
      return;
    }

    if (_shuffleEnabled && _queue.length > 1) {
      _shuffleHistory.add(_currentSong!.id);
      if (_shuffleHistory.length > 50) _shuffleHistory.removeAt(0);
      int next;
      do {
        next = Random().nextInt(_queue.length);
      } while (next == _currentIndex);
      await skipToIndex(next);
    } else if (_currentIndex < _queue.length - 1) {
      await skipToIndex(_currentIndex + 1);
    } else if (_repeatMode == RepeatMode.all) {
      if (_queue.length == 1) {
        await seek(Duration.zero);
        await play();
      } else {
        await skipToIndex(0);
      }
    }
  }

  Future<void> _addAutoDjSongs() async {
    if (!_autoDjService.isEnabled) return;

    try {
      final songsToAdd = await _autoDjService.getSongsToQueue(
        currentSong: _currentSong,
        currentQueue: _queue,
        availableSongs: _libraryProvider?.cachedAllSongs,
      );

      if (songsToAdd.isNotEmpty) {
        _queue.addAll(songsToAdd);
        if (_concatenatingSource != null) {
          for (final song in songsToAdd) {
            try {
              final source = await _buildAudioSourceForSong(song);
              _concatenatingSource!.add(source);
            } catch (e) {
              debugPrint('Error adding AutoDJ song to concatenating source: $e');
            }
          }
        }
        notifyListeners();
        _saveQueueState();
        debugPrint('Auto DJ added ${songsToAdd.length} songs to queue');
      }
    } catch (e) {
      debugPrint('Auto DJ error: $e');
    }
  }

  Future<void> skipPrevious() async {
    if (_position.inSeconds > 3) {
      await seek(Duration.zero);
      return;
    }

    if (_concatenatingSource != null) {
      if (_shuffleEnabled && _shuffleHistory.isNotEmpty) {
        final prevId = _shuffleHistory.removeLast();
        final prev = _queue.indexWhere((s) => s.id == prevId);
        if (prev != -1) {
          await _audioPlayer.seek(Duration.zero, index: prev);
          return;
        }
      }
      if (_currentIndex > 0) {
        await _audioPlayer.seek(Duration.zero, index: _currentIndex - 1);
      } else if (_repeatMode == RepeatMode.all && _queue.isNotEmpty) {
        await _audioPlayer.seek(Duration.zero, index: _queue.length - 1);
      } else {
        await seek(Duration.zero);
      }
      return;
    }

    if (_shuffleEnabled && _shuffleHistory.isNotEmpty) {
      final prevId = _shuffleHistory.removeLast();
      final prev = _queue.indexWhere((s) => s.id == prevId);
      if (prev != -1) await skipToIndex(prev);
    } else if (_currentIndex > 0) {
      await skipToIndex(_currentIndex - 1);
    } else if (_repeatMode == RepeatMode.all && _queue.isNotEmpty) {
      if (_queue.length == 1) {
        await seek(Duration.zero);
        await play();
      } else {
        await skipToIndex(_queue.length - 1);
      }
    } else {
      await seek(Duration.zero);
    }
  }

  Future<void> skipToIndex(int index) async {
    if (index >= 0 && index < _queue.length) {
      if (_concatenatingSource != null) {
        await _audioPlayer.seek(Duration.zero, index: index);
      } else {
        await playSong(_queue[index], playlist: _queue, startIndex: index);
      }
    }
  }

  void toggleShuffle() {
    _shuffleEnabled = !_shuffleEnabled;
    _shuffleHistory.clear();
    if (_shuffleEnabled && _queue.length > 1 && _currentSong != null) {
      final currentSong = _currentSong!;
      _queue.shuffle();
      _queue.remove(currentSong);
      _queue.insert(0, currentSong);
      _currentIndex = 0;
      if (_concatenatingSource != null) {
        _buildAndSetConcatenatingSource(initialIndex: 0).catchError((e) {
          debugPrint('Error rebuilding concatenating source after shuffle: $e');
        });
      }
      _saveQueueState();
    }
    _storageService.saveShuffleMode(_shuffleEnabled);
    notifyListeners();
  }

  void toggleRepeat() {
    switch (_repeatMode) {
      case RepeatMode.off:
        _repeatMode = RepeatMode.all;
        _audioPlayer.setLoopMode(LoopMode.all);
        break;
      case RepeatMode.all:
        _repeatMode = RepeatMode.one;
        _audioPlayer.setLoopMode(LoopMode.one);
        break;
      case RepeatMode.one:
        _repeatMode = RepeatMode.off;
        _audioPlayer.setLoopMode(LoopMode.off);
        break;
    }
    _storageService.saveRepeatMode(_repeatMode.index);
    notifyListeners();
  }

  void toggleGaplessPlayback() {
    _gaplessEnabled = !_gaplessEnabled;
    _storageService.saveGaplessPlayback(_gaplessEnabled);
    notifyListeners();
  }

  void addToQueue(Song song) {
    _queue.add(song);
    notifyListeners();
  }

  Future<void> addToQueueNext(Song song) async {
    final insertIndex = _currentIndex + 1;
    if (insertIndex < _queue.length) {
      _queue.insert(insertIndex, song);
    } else {
      _queue.add(song);
    }
    if (_concatenatingSource != null) {
      try {
        final audioSource = await _buildAudioSourceForSong(song);
        if (insertIndex < _concatenatingSource!.length) {
          _concatenatingSource!.insert(insertIndex, audioSource);
        } else {
          _concatenatingSource!.add(audioSource);
        }
      } catch (e) {
        debugPrint('Error adding to concatenating source: $e');
      }
    }
    notifyListeners();
  }

  Future<void> addAllToQueue(Iterable<Song> songs) async {
    final newSongs = songs.toList();
    _queue.addAll(newSongs);
    if (_concatenatingSource != null) {
      for (final song in newSongs) {
        try {
          final source = await _buildAudioSourceForSong(song);
          _concatenatingSource!.add(source);
        } catch (e) {
          debugPrint('Error adding to concatenating source: $e');
        }
      }
    }
    notifyListeners();
  }

  void removeFromQueue(int index) {
    if (index >= 0 && index < _queue.length) {
      _queue.removeAt(index);
      if (_concatenatingSource != null && index < _concatenatingSource!.length) {
        try {
          _concatenatingSource!.removeAt(index);
        } catch (e) {
          debugPrint('Error removing from concatenating source: $e');
        }
      }
      if (index < _currentIndex) {
        _currentIndex--;
      } else if (index == _currentIndex && _queue.isNotEmpty) {
        if (_currentIndex >= _queue.length) {
          _currentIndex = _queue.length - 1;
        }
        if (_queue.isNotEmpty) {
          playSong(
            _queue[_currentIndex],
            playlist: _queue,
            startIndex: _currentIndex,
          );
        }
      }
      _saveQueueState();
      notifyListeners();
    }
  }

  void clearQueue() {
    _queue.clear();
    _currentIndex = -1;
    _currentSong = null;
    _concatenatingSource = null;
    try {
      _discordRpcService.clearPresence();
    } catch (_) {}
    // Clear lyrics when clearing queue
    try {
      _lyricsService.stopSync();
    } catch (_) {}
    _clearPersistedQueue();
    try {
      _lyricsService.loadLyrics(null);
    } catch (_) {}
    _audioPlayer.stop();
    _isPlaying = false;
    _position = Duration.zero;
    notifyListeners();
    _updateAndroidAuto();
  }

  void reorderQueue(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }

    final song = _queue.removeAt(oldIndex);
    _queue.insert(newIndex, song);

    if (_concatenatingSource != null) {
      try {
        _concatenatingSource!.move(oldIndex, newIndex);
      } catch (e) {
        debugPrint('Error moving in concatenating source: $e');
      }
    }

    if (oldIndex == _currentIndex) {
      _currentIndex = newIndex;
    } else if (oldIndex < _currentIndex && newIndex >= _currentIndex) {
      _currentIndex -= 1;
    } else if (oldIndex > _currentIndex && newIndex <= _currentIndex) {
      _currentIndex += 1;
    }

    notifyListeners();
    _saveQueueState();
  }

  Future<void> setVolume(double volume) async {
    _volume = volume.clamp(0.0, 1.0);
    await _storageService.saveVolume(_volume);
    if (_castService.isConnected) {
      await _castService.setVolume(_volume);
    } else if (_upnpService.isConnected) {
      await _upnpService.setVolume((_volume * 100).round());
    } else {
      await _applyReplayGain(_currentSong);
    }
    notifyListeners();
  }

  bool _upnpVolumeWriteInProgress = false;

  void _onRemoteVolumeChange(int volume) {
    if (_castService.isConnected) {
      _castService.setVolume(volume / 100.0);
    } else if (_upnpService.isConnected) {
      if (_upnpVolumeWriteInProgress) return;
      _applyUpnpVolume(volume);
    }
  }

  Future<void> _applyUpnpVolume(int volume) async {
    _upnpVolumeWriteInProgress = true;
    _volume = (volume / 100.0).clamp(0.0, 1.0);
    notifyListeners();
    try {
      await _upnpService.setVolume(volume);
      final actual = await _upnpService.getVolume();
      if (actual >= 0) {
        _volume = actual / 100.0;
        _androidSystemService.updateRemoteVolume(actual);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('UPnP setVolume error: $e');
    } finally {
      _upnpVolumeWriteInProgress = false;
    }
  }

  // ── Gapless playback helpers ───────────────────────────────────────────

  Future<AudioSource> _buildAudioSourceForSong(Song song) async {
    if (song.isLocal == true && song.path != null) {
      return AudioSource.uri(Uri.file(song.path!));
    }
    final offlinePath = _offlineService.getLocalPath(song.id);
    if (offlinePath != null) {
      return AudioSource.uri(Uri.file(offlinePath));
    }
    final url = _subsonicService.getStreamUrl(song.id);
    // Cache remote streams locally so seeking works even when the server
    // transcodes and doesn't support HTTP range requests (issue #170).
    final cacheDir = await getTemporaryDirectory();
    final cacheFile = File(
      '${cacheDir.path}/musly_stream_${song.id.hashCode}.tmp',
    );
    // ignore: experimental_member_use
    return LockCachingAudioSource(
      Uri.parse(url),
      cacheFile: cacheFile,
      tag: song.id,
    );
  }

  Future<void> _buildAndSetConcatenatingSource({required int initialIndex}) async {
    final children = await Future.wait(_queue.map(_buildAudioSourceForSong));
    _concatenatingSource = ConcatenatingAudioSource(children: children);
    await _audioPlayer.setAudioSource(
      _concatenatingSource!,
      initialIndex: initialIndex,
      preload: true,
    );
  }

  Future<void> _prepareCurrentSong() async {
    if (_currentSong == null) return;
    try {
      if (_gaplessEnabled && _queue.isNotEmpty) {
        await _buildAndSetConcatenatingSource(initialIndex: _currentIndex);
      } else {
        final String playUrl;
        if (_currentSong!.isLocal == true && _currentSong!.path != null) {
          playUrl = Uri.file(_currentSong!.path!).toString();
        } else {
          final offlinePath = _offlineService.getLocalPath(_currentSong!.id);
          if (offlinePath != null) {
            playUrl = 'file://$offlinePath';
          } else {
            playUrl = await _subsonicService.resolveStreamUrlAsync(_currentSong!);
          }
        }
        if (_currentSong!.isLocal == true ||
            _offlineService.getLocalPath(_currentSong!.id) != null) {
          await _audioPlayer.setUrl(playUrl);
        } else {
          final cacheDir = await getTemporaryDirectory();
          final cacheFile = File(
            '${cacheDir.path}/musly_stream_${_currentSong!.id.hashCode}.tmp',
          );
          // ignore: experimental_member_use
          await _audioPlayer.setAudioSource(
            // ignore: experimental_member_use
            LockCachingAudioSource(
              Uri.parse(playUrl),
              cacheFile: cacheFile,
              tag: _currentSong!.id,
            ),
          );
        }
      }
      // Seek to the restored position after the source is loaded
      if (_position.inMilliseconds > 0) {
        await _audioPlayer.seek(_position);
      }
    } catch (e) {
      debugPrint('Error preparing current song after restore: $e');
    }
  }

  Future<void> _onCurrentIndexChanged(int newIndex) async {
    if (newIndex < 0 || newIndex >= _queue.length) return;
    if (newIndex == _currentIndex) return;

    debugPrint(
        '[Player] ⏭ Track changed by index: $newIndex "${_queue[newIndex].title}"');

    // Sleep timer: end after current song
    if (_sleepTimerEndCurrentSong) {
      _doSleepTimerStop();
      return;
    }

    // Track completion of the previous song
    if (_currentSong != null) {
      if (_currentSong!.isLocal != true) {
        _subsonicService.scrobble(_currentSong!.id, submission: true).catchError(
          (e) {
            _offlineService.queueScrobble(_currentSong!.id, submission: true);
          },
        );
      }
      if (_recommendationService != null) {
        _recommendationService!.trackSongPlay(
          _currentSong!,
          durationPlayed: _duration.inSeconds,
          completed: true,
        );
      }
    }

    // AutoDJ: add songs near end of queue
    if (_autoDjService.shouldAddSongs(newIndex, _queue.length)) {
      await _addAutoDjSongs();
    }

    _currentIndex = newIndex;
    _currentSong = _queue[_currentIndex];
    _position = Duration.zero;
    _resolvedArtworkUrl = null;
    notifyListeners();
    _saveQueueState();

    await _refreshArtworkUrl();
    if (_currentSong != null) {
      await _loadAndSyncLyrics(_currentSong!);
      await _lyricsService.updateSongInfo(
        title: _currentSong!.title,
        artist: _currentSong!.artist ?? 'Unknown Artist',
        artworkUrl: _resolvedArtworkUrl ?? _currentSong!.coverArt,
      );
      await _applyReplayGain(_currentSong);
    }

    _updateAllServices();
    _updateAndroidAuto();
  }

  Future<void> _applyReplayGain(Song? song) async {
    await _replayGainService.initialize();

    final replayGainMultiplier = _replayGainService.calculateVolumeMultiplier(
      trackGain: song?.replayGainTrackGain,
      albumGain: song?.replayGainAlbumGain,
      trackPeak: song?.replayGainTrackPeak,
      albumPeak: song?.replayGainAlbumPeak,
    );

    final effectiveVolume = _volume * replayGainMultiplier;
    await _audioPlayer.setVolume(effectiveVolume);
  }

  Future<void> refreshReplayGain() async {
    await _applyReplayGain(_currentSong);
    notifyListeners();
  }

  ReplayGainService get replayGainService => _replayGainService;

  Future<void> toggleFavorite() async {
    if (_currentSong == null) return;

    final isStarred = _currentSong!.starred == true;

    final newSong = _currentSong!.copyWith(starred: !isStarred);
    _currentSong = newSong;
    notifyListeners();

    try {
      if (isStarred) {
        await _subsonicService.unstar(id: newSong.id);
      } else {
        await _subsonicService.star(id: newSong.id);
      }
      _libraryProvider?.loadStarred();
    } catch (e) {
      debugPrint('Error toggling favorite: $e');
      _currentSong = _currentSong!.copyWith(starred: isStarred);
      notifyListeners();
    }
  }

  Future<void> toggleFavoriteForSong(Song song) async {
    final isStarred = song.starred == true;
    try {
      if (isStarred) {
        await _subsonicService.unstar(id: song.id);
      } else {
        await _subsonicService.star(id: song.id);
      }
      _libraryProvider?.loadStarred();

      if (_currentSong?.id == song.id) {
        _currentSong = _currentSong!.copyWith(starred: !isStarred);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error toggling favorite for song: $e');
    }
  }

  Future<void> setRating(String songId, int rating) async {
    if (_currentSong?.id != songId) return;

    final previousRating = _currentSong?.userRating;
    _currentSong = _currentSong?.copyWith(userRating: rating);
    notifyListeners();

    try {
      await _subsonicService.setRating(songId, rating);
    } catch (e) {
      _currentSong = _currentSong?.copyWith(userRating: previousRating);
      notifyListeners();
      rethrow;
    }
  }

  Future<void> reactivateAudioSession() async {
    await _androidSystemService.requestAudioFocus();

    if (_currentSong != null) {
      _updateAllServices();
    }

    if (Platform.isIOS) {
      try {
        final session = await AudioSession.instance;
        await session.setActive(true);

        // Wait a bit for the audio session to stabilize
        await Future.delayed(const Duration(milliseconds: 100));

        // If there's a current song and audio is not playing, resume it
        // This handles the case where iOS pauses audio when dismissing the player
        if (_currentSong != null && !_audioPlayer.playing) {
          debugPrint(
              '[Player] iOS: Resuming playback after audio session reactivation (song: ${_currentSong!.title})');
          await _audioPlayer.play();
          _isPlaying = true;
          notifyListeners();
          _updateAllServices();
        }
      } catch (e) {
        debugPrint('[Player] iOS: Error reactivating audio session: $e');
      }
    }
  }

  @override
  void dispose() {
    _sleepTimer?.cancel();
    _sleepTimerFadeTimer?.cancel();
    _sleepTimerFadePeriodicTimer?.cancel();
    _windowsPositionTimer?.cancel();
    _castService.removeListener(_onCastStateChanged);
    _upnpService.removeListener(_onUpnpStateChanged);
    if (_upnpService.onRendererLost == _onUpnpRendererLost) {
      _upnpService.onRendererLost = null;
    }
    _audioHandler.customAction('dispose');
    try {
      _androidAutoService.dispose();
    } catch (_) {}
    try {
      _androidSystemService.dispose();
    } catch (_) {}
    try {
      _windowsService.dispose();
    } catch (_) {}
    try {
      _bluetoothService.dispose();
    } catch (_) {}
    try {
      _samsungService.dispose();
    } catch (_) {}

    // Dispose lyrics service
    try {
      _lyricsService.dispose();
    } catch (_) {}

    try {
      _discordRpcService.shutdown();
    } catch (_) {}
    _playerStateSub?.cancel();
    _positionSub?.cancel();
    _durationSub?.cancel();
    _currentIndexSub?.cancel();
    _positionController.close();
    super.dispose();
  }

  String _discordStateText() {
    switch (_discordRpcStateStyle) {
      case 'song_title':
        return _currentSong?.title ?? 'Unknown Song';
      case 'app_name':
        return 'Musly';
      case 'artist':
      default:
        return _currentSong?.artist ?? 'Unknown Artist';
    }
  }

  void _updateDiscordRpc() {
    try {
      if (_currentSong == null) {
        _discordRpcService.clearPresence();
        return;
      }

      final int now = DateTime.now().millisecondsSinceEpoch;
      final int startTimestamp = now - _position.inMilliseconds;
      final int? endTimestamp = _isPlaying && _duration.inMilliseconds > 0
          ? startTimestamp + _duration.inMilliseconds
          : null;

      final stateText = _discordStateText();

      _discordRpcService.updatePresence(
        state: stateText,
        details: _currentSong!.title,
        largeImageKey: 'musly_logo',
        largeImageText: _currentSong!.album,
        smallImageKey: 'musly_logo',
        smallImageText: _isPlaying ? 'Playing' : 'Paused',
        startTime: startTimestamp,
        endTime: endTimestamp,
      );
    } catch (_) {}
  }

  Future<void> setDiscordRpcEnabled(bool enabled) async {
    try {
      await _discordRpcService.setEnabled(enabled);
      if (enabled) {
        _updateDiscordRpc();
      }
    } catch (_) {}
  }

  bool get discordRpcEnabled => _discordRpcService.enabled;

  String _discordRpcStateStyle = 'artist';

  Future<void> loadDiscordRpcStateStyle() async {
    _discordRpcStateStyle = await _storageService.getDiscordRpcStateStyle();
  }

  Future<void> setDiscordRpcStateStyle(String style) async {
    _discordRpcStateStyle = style;
    await _storageService.saveDiscordRpcStateStyle(style);
    _updateDiscordRpc();
    notifyListeners();
  }

  String get discordRpcStateStyle => _discordRpcStateStyle;

  void _onCastStateChanged() {
    notifyListeners();
    if (_castService.isConnected) {
      _audioPlayer.pause();
      _androidSystemService.setRemotePlayback(isRemote: true, volume: 50);
      if (_currentSong != null) {
        final song = _currentSong!;
        _currentSong = null;
        playSong(song);
      }
    } else {
      _isRenderingRemotely = false;
      _androidSystemService.setRemotePlayback(isRemote: false);
      _isPlaying = false;
      notifyListeners();
      _updateAndroidAuto();
    }
  }

  bool _upnpWasConnected = false;
  bool _upnpWasPlaying = false;
  // True when an A2DP audio-output device (car, speaker) is connected.
  // Control-only devices (Garmin watch, etc.) don't set this flag.
  bool _isA2dpAudioActive = false;

  void _onUpnpStateChanged() {
    final connected = _upnpService.isConnected;

    if (connected && !_upnpWasConnected) {
      _upnpWasConnected = true;
      _upnpWasPlaying = false;
      if (_audioPlayer.playing) _audioPlayer.pause();
      final vol = _upnpService.volume;

      if (vol >= 0) _volume = vol / 100.0;
      _androidSystemService.setRemotePlayback(
        isRemote: true,
        volume: vol >= 0 ? vol : 50,
      );
      if (_currentSong != null) {
        final song = _currentSong!;
        _currentSong = null;
        playSong(song);
      }
      return;
    }

    if (!connected && _upnpWasConnected) {
      _upnpWasConnected = false;
      _upnpWasPlaying = false;
      _isRenderingRemotely = false;
      _isPlaying = false;
      // Preserve _position and _duration so the UI shows where we were.
      _androidSystemService.setRemotePlayback(isRemote: false);
      notifyListeners();
      _updateAndroidAuto();
      return;
    }

    if (!connected) return;

    final pos = _upnpService.rendererPosition;
    final dur = _upnpService.rendererDuration;
    final playing = _upnpService.isRendererPlaying;
    final rendererState = _upnpService.rendererState;

    if (_upnpWasPlaying && rendererState == 'STOPPED') {
      // _upnpWasPlaying is reset to false in playSong() and stop() before
      // any Stop command is sent, so this only fires for a *natural* track
      // end.  We don't check duration > 0 here because many renderers
      // (including moode/upmpdcli) return 0:00:00 from GetPositionInfo once
      // the transport is stopped, which would cause the check to silently fail.
      debugPrint(
          'UPnP: Track ended (pos=${pos.inSeconds}s, dur=${dur.inSeconds}s) — advancing');
      _upnpWasPlaying = false;
      _onSongComplete()
          .catchError((e) => debugPrint('[Player] _onSongComplete error: $e'));
      return;
    }

    _upnpWasPlaying = playing;

    bool changed = false;

    if ((_position - pos).abs() > const Duration(milliseconds: 500)) {
      _position = pos;
      changed = true;
    }
    if (dur != _duration) {
      _duration = dur;
      changed = true;
    }
    if (playing != _isPlaying) {
      _isPlaying = playing;
      changed = true;
    }

    final vol = _upnpService.volume;
    if (vol >= 0 && !_upnpVolumeWriteInProgress) {
      final normalized = vol / 100.0;
      if ((_volume - normalized).abs() > 0.005) {
        _volume = normalized;
        changed = true;
        _androidSystemService.updateRemoteVolume(vol);
      }
    }

    if (changed) {
      _positionController.add(_position);
      notifyListeners();
      _updateAndroidAuto();
    }
  }

  /// Called by [UpnpService] after 30 consecutive poll failures (~30 s).
  /// [_onUpnpStateChanged] has already switched us off remote playback and
  /// preserved [_position]. Load the song into the local player at the last
  /// known position, paused, so the user can resume wherever they want.
  /// Android routes audio to a connected A2DP device automatically.
  Future<void> _onUpnpRendererLost() async {
    final lastPosition = _position;
    final lastSong = _currentSong;

    debugPrint(
      'UPnP: renderer lost — A2DP audio active: $_isA2dpAudioActive, '
      'last position: ${lastPosition.inSeconds}s, song: "${lastSong?.title}"',
    );

    if (lastSong == null) return;

    final playUrl = lastSong.isLocal == true && lastSong.path != null
        ? Uri.file(lastSong.path!).toString()
        : _offlineService.getPlayableUrl(lastSong, _subsonicService);

    _isLoading = true;
    notifyListeners();

    try {
      await _audioPlayer.setUrl(playUrl);
      _position = lastPosition;
      await _audioPlayer.seek(lastPosition);
      // Leave paused — let the user consciously resume on their new output.
    } catch (e) {
      debugPrint('UPnP fallback: failed to reload local player: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
      _updateAndroidAuto();
    }
  }
}
