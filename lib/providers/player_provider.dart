import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' show Random;

import 'package:audio_session/audio_session.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/models.dart';
import '../services/subsonic_service.dart';
import '../services/offline_service.dart';
import '../services/windows_system_service.dart';
import '../services/recommendation_service.dart';
import '../services/replay_gain_service.dart';
import '../services/auto_dj_service.dart';
import '../services/ytdlp_service.dart';
import '../services/lrclib_service.dart';
import '../services/discord_rpc_service.dart';
import '../services/storage_service.dart';
import '../services/cast_service.dart';
import 'package:flutter_chrome_cast/flutter_chrome_cast.dart';
import '../services/upnp_service.dart';
import '../services/jukebox_service.dart';
import '../services/audio_handler.dart';
import '../services/fade_settings_service.dart';
import '../services/crossfade_service.dart';

import '../services/transcoding_service.dart';
// import '../services/musly_connect_service.dart';
import '../providers/library_provider.dart';

enum RepeatMode { off, all, one }

class PlayerProvider extends ChangeNotifier with WidgetsBindingObserver {
  final SubsonicService _subsonicService;
  late final StorageService _storageService;
  final MuslyAudioHandler _audioHandler;
  // Convenience getter — use this everywhere just_audio is accessed directly.
  AudioPlayer get _audioPlayer => _audioHandler.player;
  final OfflineService _offlineService = OfflineService();
  final WindowsSystemService _windowsService = WindowsSystemService();
  final ReplayGainService _replayGainService = ReplayGainService();
  final AutoDjService _autoDjService = AutoDjService();
  final CrossfadeService _crossfadeService = CrossfadeService();
  late final DiscordRpcService _discordRpcService;
  final CastService _castService;
  late final UpnpService _upnpService;

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
  double _lastNonZeroVolume = 1.0;

  /// True only while audio is actually being rendered on a remote device.
  /// Distinct from isConnected: if the user plays a radio station while a
  /// UPnP renderer is connected, the audio is still local, so this stays false.
  bool _isRenderingRemotely = false;

  String? _resolvedArtworkUrl;

  RadioStation? _currentRadioStation;
  bool _isPlayingRadio = false;

  bool _hasPlayedOnce = false;

  // fix #207: track per-song playback time to enforce the Last.FM scrobble
  // minimum threshold (50% of duration or 4 minutes, whichever comes first).
  DateTime? _songPlaybackStartTime;
  Duration _songAccumulatedPlayTime = Duration.zero;
  String? _scrobbleTrackedSongId; // which song we're currently tracking

  /// Returns true if the current song has been played long enough to
  /// qualify for a Last.FM-compliant scrobble (>=50% or >=240s).
  bool _canScrobble(Song song) {
    if (_scrobbleTrackedSongId != song.id) return false;
    final played = _songAccumulatedPlayTime +
        ((_songPlaybackStartTime != null && _isPlaying)
            ? DateTime.now().difference(_songPlaybackStartTime!)
            : Duration.zero);
    final duration = _duration > Duration.zero ? _duration
        : (song.duration != null ? Duration(seconds: song.duration!) : Duration.zero);
    if (duration <= Duration.zero) return played.inSeconds >= 30;
    return played.inSeconds >= 240 ||
        played.inMilliseconds >= duration.inMilliseconds ~/ 2;
  }

  /// Called when a new song starts playing; resets scrobble tracking.
  void _resetScrobbleTracking(Song song) {
    _songPlaybackStartTime = DateTime.now();
    _songAccumulatedPlayTime = Duration.zero;
    _scrobbleTrackedSongId = song.id;
  }

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
  Timer? _jukeboxPollTimer;

  // Fade in/out
  final FadeSettingsService _fadeSettingsService = FadeSettingsService();
  Timer? _fadeTimer;
  bool _isFading = false;

  final JukeboxService _jukeboxService;
  final TranscodingService _transcodingService;

  double _playbackSpeed = 1.0;
  double _pitch = 1.0;
  bool _pitchCorrection = true;

  // 50-Song Milestone Celebration Callback
  VoidCallback? onMilestone50Triggered;

  PlayerProvider(
    this._subsonicService,
    StorageService storageService,
    this._castService,
    this._upnpService,
    this._audioHandler,
    this._jukeboxService,
    this._transcodingService,
  ) {
    _storageService = storageService;
    _discordRpcService = DiscordRpcService(storageService);
    _castService.addListener(_onCastStateChanged);
    _upnpService.addListener(_onUpnpStateChanged);
    _upnpService.onRendererLost = _onUpnpRendererLost;
    _jukeboxService.addListener(_onJukeboxEnabledChanged);
    // MuslyConnectService().addListener(_onMuslyConnectStateChanged);
    _initializePlayer();
    _onJukeboxEnabledChanged();
    try {
      _initializeAndroidAuto();
    } catch (_) {}
    try {
      _initializeSystemServices();
    } catch (_) {}
    _initializeAutoDj();
    _wireAudioHandlerCallbacks();

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

    // Register app lifecycle observer to save state on iOS when app goes to background
    WidgetsBinding.instance.addObserver(this);
  }

  /// Handle app lifecycle changes - save queue state when going to background (important for iOS)
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      debugPrint(
          '[Player] App lifecycle state: $state - saving queue state immediately');
      _saveQueueStateImmediate();
    }
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
      await _saveQueueStateImmediate();
    });
  }

  Future<void> _saveQueueStateImmediate() async {
    try {
      _prefs ??= await SharedPreferences.getInstance();
      if (_prefs == null) return;
      final queueJson = _queue.map((s) => s.toJson()).toList();
      await _prefs!.setString(_keyQueue, jsonEncode(queueJson));
      await _prefs!.setInt(_keyQueueIndex, _currentIndex);
      await _prefs!.setString(_keyQueueSongId, _currentSong?.id ?? '');
      await _prefs!.setInt(_keyQueuePosition, _position.inMilliseconds);
      debugPrint(
          'Queue state saved: index $_currentIndex, position $_position');
    } catch (e) {
      debugPrint('Error saving queue state: $e');
    }
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
      final songDurationSecs = restoredSongs[targetIndex].duration;
      if (songDurationSecs != null && songDurationSecs > 0) {
        _duration = Duration(seconds: songDurationSecs);
      }
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

  // ── Jukebox mode ─────────────────────────────────────────────────────────

  void _onJukeboxEnabledChanged() {
    if (_jukeboxService.enabled) {
      _startJukeboxPolling();
    } else {
      _stopJukeboxPolling();
    }
  }

  void _startJukeboxPolling() {
    _stopJukeboxPolling();
    _jukeboxPollTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _pollJukebox();
    });
    _pollJukebox();
  }

  void _stopJukeboxPolling() {
    _jukeboxPollTimer?.cancel();
    _jukeboxPollTimer = null;
  }

  Future<void> _pollJukebox() async {
    if (!_jukeboxService.enabled) return;
    try {
      await _jukeboxService.refresh(_subsonicService);
      _syncFromJukeboxStatus();
    } catch (e) {
      debugPrint('Jukebox poll error: $e');
    }
  }

  void _syncFromJukeboxStatus() {
    if (!_jukeboxService.enabled) return;
    final status = _jukeboxService.status;
    final song = status.currentSong;

    bool changed = false;
    if (song != null && song.id != _currentSong?.id) {
      _currentSong = song;
      _resolvedArtworkUrl = null;
      changed = true;
    }
    if (_isPlaying != status.playing) {
      _isPlaying = status.playing;
      changed = true;
    }
    if (_position != status.position) {
      _position = status.position;
      changed = true;
    }
    if (status.playlist.isNotEmpty && !identical(_queue, status.playlist)) {
      _queue = List.from(status.playlist);
      changed = true;
    }
    final clampedIndex = status.currentIndex.clamp(
      0,
      (_queue.length - 1).clamp(0, double.maxFinite.toInt()),
    );
    if (_currentIndex != clampedIndex) {
      _currentIndex = clampedIndex;
      changed = true;
    }
    if (changed) {
      notifyListeners();
      _updateAllServices();
      _updateAndroidAuto();
    }
  }

  void setLibraryProvider(LibraryProvider libraryProvider) {
    _libraryProvider = libraryProvider;
  }

  void setRecommendationService(RecommendationService recommendationService) {
    _recommendationService = recommendationService;
    _autoDjService.setServices(_subsonicService, recommendationService);
  }

  AutoDjService get autoDjService => _autoDjService;


  Future<void> _initializeAutoDj() async {
    await _autoDjService.initialize();
    _autoDjService.setServices(_subsonicService, _recommendationService);
  }



  Future<void> _initializeSystemServices() async {
    await _windowsService.initialize();
    _windowsService.onPlay = play;
    _windowsService.onPause = pause;
    _windowsService.onStop = stop;
    _windowsService.onSkipNext = skipNext;
    _windowsService.onSkipPrevious = skipPrevious;
    _windowsService.onSeekTo = seek;
  }

  void _initializeAndroidAuto() {
    // Song-level browse data, search and playback for Android Auto are
    // served through the audio_service handler (see MuslyAudioHandler).
    _audioHandler.onGetAlbumSongs = _getAlbumSongsForAndroidAuto;
    _audioHandler.onGetArtistAlbums = _getArtistAlbumsForAndroidAuto;
    _audioHandler.onGetPlaylistSongs = _getPlaylistSongsForAndroidAuto;
    _audioHandler.onSearch = _searchForAndroidAuto;
    _audioHandler.onPlayFromMediaId = _playFromMediaId;
    _audioHandler.onPlayFromSearch = _playFromSearchForAndroidAuto;
    _audioHandler.onSetRemoteVolume = _onRemoteVolumeChange;
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

    // For Web Stream, also do a fast local-DB search on already-cached songs
    // before hitting the network, to make Auto browsing feel snappier.
    if (_subsonicService.isYoutube && _libraryProvider != null) {
      final lowerQuery = query.toLowerCase();
      final localHits = _libraryProvider!.cachedAllSongs
          .where(
            (s) =>
                s.title.toLowerCase().contains(lowerQuery) ||
                (s.artist?.toLowerCase().contains(lowerQuery) ?? false),
          )
          .take(20)
          .toList();
      if (localHits.isNotEmpty) {
        return localHits
            .map(
              (song) => {
                'id': song.id,
                'title': song.title,
                'artist': song.artist ?? '',
                'album': song.album ?? '',
                // Modern music player design
                'artworkUrl': song.coverArt ?? '',
                'duration': (song.duration ?? 0).toString(),
              },
            )
            .toList();
      }
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
              'artworkUrl': _subsonicService.isYoutube
                  ? (song.coverArt ?? '')
                  : _subsonicService.getCoverArtUrl(song.coverArt, size: 300),
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
          return;
        }
        // In Web Stream mode play from cached songs when no query is given.
        if (_subsonicService.isYoutube &&
            _libraryProvider != null &&
            _libraryProvider!.cachedAllSongs.isNotEmpty) {
          final songs = _libraryProvider!.cachedAllSongs;
          await playSong(songs.first, playlist: songs, startIndex: 0);
          return;
        }
        if (_libraryProvider != null &&
            _libraryProvider!.randomSongs.isNotEmpty) {
          final songs = _libraryProvider!.randomSongs;
          await playSong(songs.first, playlist: songs, startIndex: 0);
        }
        return;
      }

      // For Web Stream, use the internal search which returns full Song objects
      // (with title, artist, coverArt) so Auto shows proper metadata.
      if (_subsonicService.isYoutube) {
        final ytResults = await _searchForAndroidAuto(query);
        if (ytResults.isNotEmpty) {
          final first = ytResults.first;
          final song = Song(
            id: first['id'] ?? '',
            title: first['title'] ?? query,
            artist: first['artist'],
            album: first['album'],
            coverArt: first['artworkUrl'],
            duration: int.tryParse(first['duration'] ?? '') ?? 0,
          );
          final allSongs = ytResults.map((r) => Song(
            id: r['id'] ?? '',
            title: r['title'] ?? '',
            artist: r['artist'],
            coverArt: r['artworkUrl'],
            duration: int.tryParse(r['duration'] ?? '') ?? 0,
          )).where((s) => s.id.isNotEmpty).toList();
          await playSong(song, playlist: allSongs, startIndex: 0);
        } else {
          debugPrint('Android Auto: no YT search results for "$query"');
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

    // 1. Check the current queue first (works for all server types).
    final queueIndex = _queue.indexWhere((song) => song.id == mediaId);
    if (queueIndex != -1) {
      await skipToIndex(queueIndex);
      return;
    }

    // 2. Check the in-memory library (randomSongs for Subsonic/Jellyfin;
    //    cachedAllSongs for Web Stream which keeps track in its local DB).
    if (_libraryProvider != null) {
      final allSongs = _subsonicService.isYoutube
          ? _libraryProvider!.cachedAllSongs
          : _libraryProvider!.randomSongs;
      final songIndex = allSongs.indexWhere((song) => song.id == mediaId);
      if (songIndex != -1) {
        await playSong(
          allSongs[songIndex],
          playlist: allSongs,
          startIndex: songIndex,
        );
        return;
      }
    }

    // Modern music player design
    //    Push a placeholder MediaItem immediately so Auto doesn't show a blank
    //    screen, then resolve the real metadata in background and update.
    if (_subsonicService.isYoutube) {
      // Push a "loading" MediaItem so Auto shows a title immediately.
      _audioHandler.updateNowPlaying(
        id: mediaId,
        title: 'Loading…',
        artist: 'YouTube',
      );

      // Start playback with placeholder song immediately.
      final tempSong = Song(
        id: mediaId,
        title: 'Loading…',
        artist: 'YouTube',
        duration: 0,
      );

      try {
        await playSong(tempSong);
      } catch (e) {
        debugPrint('Android Auto: Web Stream playFromMediaId error: $e');
        return;
      }

      // After playback has started, fetch real metadata in background.
      _resolveAndUpdateYoutubeMetadata(mediaId);
      return;
    }

    // 4. Fallback: search by ID for Subsonic / Jellyfin.
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

  /// Fetches real title/artist/thumbnail for a YT video after playback starts
  /// and updates the currentSong + Android Auto / lock-screen MediaItem.
  void _resolveAndUpdateYoutubeMetadata(String videoId) {
    final ytDlp = YtDlpService();
    ytDlp.getVideoInfo(videoId).then((info) {
      if (info == null) return;
      // Only update if this video is still the active song.
      if (_currentSong?.id != videoId) return;

      final title = info['title'] as String? ?? videoId;
      final artist = info['artist'] as String? ??
          info['uploader'] as String? ??
          info['channel'] as String? ??
          'YouTube';
      final thumbUrl = info['thumbnailUrl'] as String? ??
          info['thumbnail'] as String? ??
          info['coverArt'] as String?;

      final updatedSong = Song(
        id: videoId,
        title: title,
        artist: artist,
        coverArt: thumbUrl,
        duration: _currentSong?.duration ?? 0,
      );
      _currentSong = updatedSong;
      _resolvedArtworkUrl = thumbUrl;
      notifyListeners();
      _updateAndroidAuto();
      debugPrint('Android Auto: YT metadata resolved — "$title" by $artist');
    }).catchError((e) {
      debugPrint('Android Auto: YT metadata resolution failed (harmless): $e');
    });
  }

  String? _resolveInitialArtworkUrl(Song? song) {
    if (song == null) return null;
    if (song.isLocal) {
      return Uri.file(song.coverArt ?? song.path ?? '').toString();
    }
    if (_resolvedArtworkUrl != null && _currentSong?.id == song.id) {
      return _resolvedArtworkUrl;
    }
    if (song.coverArt != null && song.coverArt!.isNotEmpty) {
      if (song.coverArt!.startsWith('/') || (song.coverArt!.length > 2 && song.coverArt![1] == ':')) {
        return Uri.file(song.coverArt!).toString();
      }
      return _subsonicService.getCoverArtUrl(song.coverArt, size: 800);
    }
    return _subsonicService.getCoverArtUrl(song.id, size: 800);
  }

  String? _resolveArtworkUrl() {
    if (_currentSong == null) return null;
    if (_currentSong!.isLocal) {
      return Uri.file(_currentSong!.coverArt ?? _currentSong!.path ?? '').toString();
    }
    if (_resolvedArtworkUrl != null && _resolvedArtworkUrl!.isNotEmpty) {
      return _resolvedArtworkUrl;
    }
    return _resolveInitialArtworkUrl(_currentSong);
  }

  Future<void> _refreshArtworkUrl() async {
    final song = _currentSong;
    if (song == null) {
      _resolvedArtworkUrl = null;
      return;
    }
    if (song.isLocal) {
      _resolvedArtworkUrl = Uri.file(song.coverArt ?? song.path ?? '').toString();
      if (_currentSong?.id == song.id) {
        _updateAndroidAuto();
        _updateAllServices();
      }
      return;
    }

    await _offlineService.initialize();

    final localPath = _offlineService.getLocalCoverArtPath(song.id);
    if (localPath != null && File(localPath).existsSync()) {
      _resolvedArtworkUrl = Uri.file(localPath).toString();
      if (_currentSong?.id == song.id) {
        _updateAndroidAuto();
        _updateAllServices();
      }
      return;
    }

    final coverArtId = song.coverArt ?? song.id;

    // Search for cached artwork from highest to lowest quality
    for (final sz in [1200, 800, 600, 400, 300, 200]) {
      for (final key in [
        '${coverArtId}_natural_$sz',
        '${coverArtId}_$sz',
        '${song.coverArt}_$sz',
        '${song.coverArt}_natural_$sz',
        coverArtId,
      ]) {
        try {
          final fileInfo = await DefaultCacheManager().getFileFromCache(key);
          if (fileInfo != null && fileInfo.file.existsSync()) {
            if (_currentSong?.id == song.id) {
              _resolvedArtworkUrl = Uri.file(fileInfo.file.path).toString();
              _updateAndroidAuto();
              _updateAllServices();
            }
            return;
          }
        } catch (_) {}
      }
    }

    // Request high quality for Android MediaSession / iOS Now Playing (800px)
    final serverUrl = _subsonicService.getCoverArtUrl(coverArtId, size: 800);

    if (!_offlineService.isOfflineMode && serverUrl.isNotEmpty) {
      _resolvedArtworkUrl = serverUrl;
      if (_currentSong?.id == song.id) {
        _updateAndroidAuto();
        _updateAllServices();
      }

      // Pre-download cover art to disk in background so Android MediaSession can display natively from file://
      try {
        final cacheKey = coverArtId.startsWith('http')
            ? 'yt_thumb_${coverArtId.split('=').first.hashCode}_800'
            : '${coverArtId}_800';
        final fileInfo = await DefaultCacheManager().downloadFile(serverUrl, key: cacheKey);
        if (_currentSong?.id == song.id && fileInfo.file.existsSync()) {
          _resolvedArtworkUrl = Uri.file(fileInfo.file.path).toString();
          _updateAndroidAuto();
          _updateAllServices();
        }
      } catch (_) {}
    }
  }

  void _updateAndroidAuto() {
    if (_currentSong == null) return;

    final artworkUrl = _resolveArtworkUrl();

    final effectiveDuration = _duration.inMilliseconds > 0
        ? _duration
        : Duration(seconds: _currentSong!.duration ?? 0);

    // Update the audio_service handler so lock screen / Control Center /
    // Android Auto Now Playing info stays accurate regardless of the UI
    // lifecycle.
    _audioHandler.updateNowPlaying(
      id: _currentSong!.id,
      title: _currentSong!.title,
      artist: _currentSong!.artist,
      album: _currentSong!.album,
      artworkUrl: artworkUrl,
      duration: effectiveDuration,
    );

    // While rendering on a remote target the local just_audio player is
    // paused, so push the real playback state to the media session manually.
    if (_isRenderingRemotely || _jukeboxService.enabled) {
      _audioHandler.updateRemotePlaybackState(
        playing: _isPlaying,
        position: _position,
      );
    }

    _updateDiscordRpc();
    _updateAllServices();
  }

  void _updateAllServices() {
    if (_currentSong == null) return;

    final artworkUrl = _resolveArtworkUrl();

    final effectiveDuration = _duration.inMilliseconds > 0
        ? _duration
        : Duration(seconds: _currentSong!.duration ?? 0);

    _windowsService.updatePlaybackState(
      song: _currentSong!,
      artworkUrl: artworkUrl,
      duration: effectiveDuration,
      position: _position,
      isPlaying: _isPlaying,
    );
    _updateDiscordRpc();

    /*
    MuslyConnectService().broadcastLocalState(
      currentSong: _currentSong,
      isPlaying: _isPlaying,
      positionSeconds: _position.inSeconds,
      durationSeconds: effectiveDuration.inSeconds,
      volume: _volume,
      shuffleEnabled: _shuffleEnabled,
      repeatModeIndex: _repeatMode.index,
      currentIndex: _currentIndex,
    );
    */
  }

  List<Song> get queue => _queue;
  int get currentIndex => _currentIndex;
  bool get isPlaying => _isPlaying;
  bool get isLoading => _isLoading;

  /// True when audio is playing on a remote renderer (UPnP, Cast).
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

  // Preloading state: tracks the last preloaded song ID to avoid redundant work
  String? _lastPreloadedSongId;

  /// Checks if the currently playing song is nearing its end, and if so,
  /// triggers background preloading for the next song in the queue.
  void _checkAndPreloadNextSong(Duration position) {
    if (_queue.isEmpty || _currentSong == null || _isRenderingRemotely) return;
    final totalSeconds = _duration.inSeconds > 0
        ? _duration.inSeconds
        : (_currentSong?.duration ?? 0);
    if (totalSeconds <= 5) return;

    final secondsRemaining = totalSeconds - position.inSeconds;
    final progressRatio = position.inSeconds / totalSeconds;

    // Start preloading when <= 25 seconds remain, or when 75% of the song has played
    final shouldPreload = (secondsRemaining <= 25 && secondsRemaining > 0) ||
        (progressRatio >= 0.75 && position.inSeconds >= 5);

    if (!shouldPreload) return;

    final nextSong = _getNextSongToPreload();
    if (nextSong == null ||
        nextSong.id == _lastPreloadedSongId ||
        nextSong.id == _currentSong?.id) {
      return;
    }

    _lastPreloadedSongId = nextSong.id;
    _preloadSong(nextSong);
  }

  Song? _getNextSongToPreload() {
    if (_queue.isEmpty || _currentIndex < 0) return null;
    if (_repeatMode == RepeatMode.one) return _currentSong;
    if (_shuffleEnabled && _queue.length > 1) {
      for (int i = 0; i < _queue.length; i++) {
        if (i != _currentIndex) return _queue[i];
      }
    }
    if (_currentIndex < _queue.length - 1) {
      return _queue[_currentIndex + 1];
    }
    if (_repeatMode == RepeatMode.all && _queue.isNotEmpty) {
      return _queue[0];
    }
    return null;
  }

  Future<void> _preloadSong(Song nextSong) async {
    debugPrint(
      '[Player Preload] ⚡ Pre-buffering next song: "${nextSong.title}" (${nextSong.id})',
    );

    // Modern music player design
    if (nextSong.isLocal != true) {
      final cleanId = nextSong.id.replaceFirst('ytmusic://', '');
      if (_subsonicService.isYoutube ||
          nextSong.id.startsWith('ytmusic://') ||
          nextSong.id.length == 11) {
        unawaited(
          YtDlpService().resolveStreamInfo(cleanId).catchError((e) {
            debugPrint('[Player Preload] YtDlp pre-resolve error (harmless): $e');
            return YtStreamInfo(url: '', headers: {});
          }),
        );
      } else {
        unawaited(
          _subsonicService.resolveStreamUrlAsync(nextSong).catchError((e) {
            debugPrint('[Player Preload] Subsonic pre-resolve error (harmless): $e');
            return '';
          }),
        );
      }
    }

    // 2. Preload synced lyrics in cache
    if (nextSong.title.isNotEmpty) {
      LrcLibService()
          .searchLyrics(
            artist: nextSong.artist,
            title: nextSong.title,
            durationSeconds: nextSong.duration,
          )
          .catchError((_) => null);
    }

    // 3. Preload cover artwork into Flutter image cache (800px)
    if (nextSong.coverArt != null && nextSong.coverArt!.isNotEmpty) {
      final coverUrl =
          _subsonicService.getCoverArtUrl(nextSong.coverArt, size: 800);
      if (coverUrl.isNotEmpty) {
        try {
          final provider = CachedNetworkImageProvider(coverUrl);
          provider.resolve(ImageConfiguration.empty).addListener(
            ImageStreamListener(
              (info, sync) {},
              onError: (dynamic error, StackTrace? stackTrace) {
                // Silently swallow decode errors
              },
            ),
          );
          DefaultCacheManager().downloadFile(coverUrl, key: '${nextSong.coverArt}_800').catchError((_) => null as dynamic);
        } catch (_) {}
      }
    }

    // Modern music player design
    if (_subsonicService.isYoutube &&
        _currentIndex >= _queue.length - 2 &&
        _currentSong != null) {
      _fetchAndQueueRadioTracks(_currentSong!).catchError((_) {});
    }
    if (_autoDjService.shouldAddSongs(_currentIndex + 1, _queue.length)) {
      _addAutoDjSongs().catchError((_) {});
    }
  }

  double get progress {
    if (_duration.inMilliseconds == 0) {
      if (_currentSong?.duration != null && _currentSong!.duration! > 0) {
        return (_position.inSeconds / _currentSong!.duration!).clamp(0.0, 1.0);
      }
      return 0.0;
    }
    final val = _position.inMilliseconds / _duration.inMilliseconds;
    if (val.isNaN || val.isInfinite) return 0.0;
    return val.clamp(0.0, 1.0);
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

    // Resume any playlists that were queued for download but interrupted
    _offlineService.initialize().then((_) {
      _offlineService.resumeIncompleteDownloads(_subsonicService);
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
                  _checkAndPreloadNextSong(pos);
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

    Duration? lastSystemUpdate;
    _positionSub = _audioPlayer.positionStream.listen(
      (position) {
        // In remote-playback mode the local player sits idle at position zero;
        // ignore its ticks so they don't overwrite the UPnP/Cast position.
        if (_isRenderingRemotely) return;

        _position = position;
        _positionController.add(position);
        _checkAndPreloadNextSong(position);
        _checkCrossfade(position);

        if (lastSystemUpdate == null ||
            (position.inMilliseconds - lastSystemUpdate!.inMilliseconds).abs() > 1000) {
          lastSystemUpdate = position;
          _updateAllServices();
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

  /// Configures the Android AudioAttributes used by the underlying
  /// AudioTrack/ExoPlayer (music content type/usage). This does NOT drive
  /// audio focus — `AndroidSystemService`/`AndroidSystemPlugin.kt` is the sole
  /// owner of focus acquisition/release on Android (see [_ensureAudioFocus],
  /// [onAudioFocusGain] wiring below, and `audio_handler.dart`, which disables
  /// just_audio's own automatic session-activation/interruption handling on
  /// Android to avoid two systems fighting over the same responsibility).
  bool _wasPlayingBeforeInterruption = false;
  bool _isManuallyPaused = false;

  Future<void> _fadeOutAndPause() async {
    try {
      if (!_isPlaying) return;
      final currentVol = _audioPlayer.volume > 0 ? _audioPlayer.volume : _volume;
      // Quick gentle fade out
      await _audioPlayer.setVolume((currentVol * 0.4).clamp(0.0, 1.0));
      await Future.delayed(const Duration(milliseconds: 100));
      await _audioPlayer.setVolume(0.0);
      await _audioPlayer.pause();
      _isPlaying = false;
      notifyListeners();
      _updateAndroidAuto();
      // Restore normal effective volume so the track is unmuted for playback
      await _applyReplayGain(_currentSong);
    } catch (_) {
      await _audioPlayer.pause();
      _isPlaying = false;
      notifyListeners();
      await _applyReplayGain(_currentSong);
    }
  }

  Future<void> _fadeInAndResume() async {
    if (_currentSong == null) return;
    try {
      if (!kIsWeb) {
        final session = await AudioSession.instance;
        await session.setActive(true);
      }
      await _applyReplayGain(_currentSong);
      await _audioPlayer.play();
      _isPlaying = true;
      notifyListeners();
      _updateAndroidAuto();
    } catch (e) {
      debugPrint('[Player] Resume error: $e');
      try {
        await _applyReplayGain(_currentSong);
        await _audioPlayer.play();
        _isPlaying = true;
        notifyListeners();
      } catch (_) {}
    }
  }

  Future<void> _configureAudioSession() async {
    if (kIsWeb) return;
    try {
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration.music());
      debugPrint('[Player] AudioSession configured for music playback');

      session.interruptionEventStream.listen((event) async {
        debugPrint('[Player AudioSession] Interruption: begin=${event.begin}, type=${event.type}');
        if (event.begin) {
          if (_isPlaying) {
            _wasPlayingBeforeInterruption = true;
            await _fadeOutAndPause();
          }
        } else {
          if (_wasPlayingBeforeInterruption && !_isManuallyPaused) {
            _wasPlayingBeforeInterruption = false;
            await _fadeInAndResume();
          }
        }
      });

      session.becomingNoisyEventStream.listen((_) async {
        if (_isPlaying) {
          _wasPlayingBeforeInterruption = false;
          _isManuallyPaused = true;
          await _fadeOutAndPause();
        }
      });
    } catch (e) {
      debugPrint('[Player] AudioSession configuration failed: $e');
    }
  }

  final bool _audioFocusDenied = false;
  bool get audioFocusDenied => _audioFocusDenied;

  VoidCallback? onAudioFocusDenied;

  Future<void> _ensureAudioFocus(Future<void> Function() onGranted) async {
    if (!kIsWeb) {
      try {
        final session = await AudioSession.instance;
        await session.setActive(true);
      } catch (e) {
        debugPrint('[Player] setActive error: $e');
      }
    }
    await onGranted();
  }

  Future<void> _onSongComplete() async {
    if (_currentSong != null && _currentSong!.isLocal != true) {
      // fix #207: only scrobble if the song was played long enough
      if (_canScrobble(_currentSong!)) {
        _subsonicService.scrobble(_currentSong!.id, submission: true).catchError((
          e,
        ) {
          _offlineService.queueScrobble(_currentSong!.id, submission: true);
        });
      }
    }

    if (_currentSong != null && _recommendationService != null) {
      _recommendationService!.trackSongPlay(
        _currentSong!,
        durationPlayed: _duration.inSeconds,
        completed: true,
      );
    }

    // ── Check 50 Songs Milestone ──────────────────────────────────────────
    _check50SongsMilestone().catchError((e) => debugPrint('[Player] Milestone check error: $e'));

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
      if (_subsonicService.isYoutube && _currentIndex >= _queue.length - 2 && _currentSong != null) {
        _fetchAndQueueRadioTracks(_currentSong!).catchError((_) {});
      }
      await skipNext();
    } else if (_subsonicService.isYoutube && _currentSong != null) {
      final moreSimilar = await _subsonicService.getSimilarSongs(_currentSong!.id, count: 20);
      final existingIds = _queue.map((s) => s.id).toSet();
      final toAdd = moreSimilar.where((s) => !existingIds.contains(s.id)).toList();
      if (toAdd.isNotEmpty) {
        _queue.addAll(toAdd);
        notifyListeners();
        _saveQueueState();
        await skipNext();
      } else {
        await _handleEndOfQueue();
      }
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

  Future<void> _check50SongsMilestone() async {
    final count = await _storageService.incrementListenedSongsCount();
    final alreadyShown = await _storageService.is50SongsMilestoneShown();

    if (count >= 50 && !alreadyShown) {
      final isForeground = WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
      if (isForeground) {
        await _storageService.set50SongsMilestoneShown(true);
        await _storageService.set50SongsMilestonePending(false);
        await pause();
        onMilestone50Triggered?.call();
      } else {
        // App is in background or screen is off: flag as pending for next foreground play
        await _storageService.set50SongsMilestonePending(true);
      }
    }
  }

  /// Checks if a 50-song milestone was reached while backgrounded and triggers now that app is foregrounded.
  Future<void> checkPending50Milestone() async {
    final isPending = await _storageService.is50SongsMilestonePending();
    final isShown = await _storageService.is50SongsMilestoneShown();
    final isForeground = WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;

    if (isPending && !isShown && isForeground) {
      await _storageService.set50SongsMilestoneShown(true);
      await _storageService.set50SongsMilestonePending(false);
      await pause();
      onMilestone50Triggered?.call();
    }
  }

  /// Plays a single song immediately and automatically populates the queue with similar / radio songs in the background.
  Future<void> playSongWithRadio(Song song) async {
    await playSong(song);

    _fetchAndQueueRadioTracks(song).catchError((e) {
      debugPrint('[Player] _fetchAndQueueRadioTracks error: $e');
    });
  }

  Future<void> _fetchAndQueueRadioTracks(Song song) async {
    if (_currentSong?.id != song.id) return;
    try {
      final similar = await _subsonicService.getSimilarSongs(song.id, count: 25);
      if (similar.isNotEmpty && _currentSong?.id == song.id) {
        final existingIds = _queue.map((s) => s.id).toSet();
        final toAdd = similar.where((s) => !existingIds.contains(s.id)).toList();
        if (toAdd.isNotEmpty) {
          _queue.addAll(toAdd);
          if (_concatenatingSource != null && !_isRenderingRemotely) {
            for (final s in toAdd) {
              try {
                final source = await _buildAudioSourceForSong(s);
                _concatenatingSource!.add(source);
              } catch (e) {
                debugPrint('Error adding radio song to concatenating source: $e');
              }
            }
          }
          notifyListeners();
          _saveQueueState();
          debugPrint('[Player] Radio queue populated with ${toAdd.length} similar songs for "${song.title}"');
        }
      }
    } catch (e) {
      debugPrint('[Player] _fetchAndQueueRadioTracks failed: $e');
    }
  }

  Future<void> playSong(
    Song song, {
    List<Song>? playlist,
    int? startIndex,
    Duration? initialPosition,
  }) async {
    if (_currentSong?.id == song.id && !_isPlayingRadio) {
      if (initialPosition != null && initialPosition > Duration.zero) {
        await seek(initialPosition);
      }
      if (!_isPlaying) {
        await play();
      }
      return;
    }

    _isPlayingRadio = false;
    _currentRadioStation = null;

    // Jukebox mode: send to server instead of playing locally.
    if (_jukeboxService.enabled) {
      final targetPlaylist = (playlist ?? [song]).toList();
      final targetIndex = startIndex ??
          targetPlaylist
              .indexWhere((s) => s.id == song.id)
              .clamp(0, targetPlaylist.length - 1);
      await _jukeboxService.setQueue(
        _subsonicService,
        targetPlaylist,
        startIndex: targetIndex,
      );
      _isPlaying = true;
      _isLoading = false;
      notifyListeners();
      _updateAllServices();
      _updateAndroidAuto();
      return;
    }

    debugPrint(
        '[Player] ▶ playSong: "${song.title}" by ${song.artist ?? 'unknown'} (id=${song.id} local=${song.isLocal})');
    _isLoading = true;
    notifyListeners();

    try {
      if (playlist != null) {
        bool isSameQueue = _queue.length == playlist.length;
        if (isSameQueue) {
          for (int i = 0; i < _queue.length; i++) {
            if (_queue[i].id != playlist[i].id) {
              isSameQueue = false;
              break;
            }
          }
        }

        if (isSameQueue && _concatenatingSource != null && !_isRenderingRemotely) {
          final targetIndex =
              startIndex ?? playlist.indexWhere((s) => s.id == song.id);
          if (targetIndex != -1 && targetIndex != _currentIndex) {
            await _audioPlayer.seek(Duration.zero, index: targetIndex);
            return;
          } else if (targetIndex == _currentIndex && !_isPlaying) {
            await play();
            return;
          }
        }

        _queue = List.from(playlist);
        _currentIndex =
            startIndex ?? playlist.indexWhere((s) => s.id == song.id);
        if (_currentIndex == -1) _currentIndex = 0;
        _shuffleHistory.clear();
      } else if (_queue.isEmpty || !_queue.any((s) => s.id == song.id)) {
        _queue = [song];
        _currentIndex = 0;
        _shuffleHistory.clear();
      } else {
        _currentIndex = startIndex ?? _queue.indexWhere((s) => s.id == song.id);
      }
      _currentSong = song;
      _lastPreloadedSongId = null;
      _resolvedArtworkUrl = _resolveInitialArtworkUrl(song);
      _position = Duration.zero;
      // fix #207: reset playback-time tracking so scrobble threshold is
      // measured from the start of this song's playback, not carried over.
      _resetScrobbleTracking(song);
      notifyListeners();
      _saveQueueState();

      // Immediately push to Android Auto / MediaSession so lockscreen/notification updates on frame 0
      _updateAndroidAuto();

      _refreshArtworkUrl().catchError((_) {});

      // Pre-warm the next song in the queue in background
      Timer(const Duration(milliseconds: 1200), () {
        final next = _getNextSongToPreload();
        if (next != null && next.id != song.id) {
          _preloadSong(next).catchError((_) {});
        }
      });

      if (_castService.isConnected) {
        _castWasPlaying = false;
        if (_audioPlayer.playing) await _audioPlayer.stop();

        final playUrl = song.isLocal == true && song.path != null
            ? Uri.file(song.path!).toString()
            : await _subsonicService.resolveStreamUrlAsync(song);
        final coverUrl = song.isLocal == true && song.coverArt != null
            ? song.coverArt!
            : _subsonicService.getCoverArtUrl(song.coverArt ?? song.id, size: 800);
        final mimeType =
            song.contentType ?? UpnpService.mimeTypeFromSuffix(song.suffix);

        final success = await _castService.loadMedia(
          url: playUrl,
          title: song.title,
          artist: song.artist ?? 'Unknown Artist',
          imageUrl: coverUrl,
          albumName: song.album,
          trackNumber: song.track,
          duration:
              song.duration != null ? Duration(seconds: song.duration!) : null,
          playPosition: initialPosition ?? Duration.zero,
          contentType: mimeType,
          autoPlay: true,
        );

        if (song.isLocal != true) {
          if (_offlineService.isOfflineMode) {
            _offlineService.queueScrobble(song.id, submission: false);
          } else {
            _subsonicService.scrobble(song.id, submission: false).catchError((e) {
              _offlineService.queueScrobble(song.id, submission: false);
            });
          }
        }

        _isRenderingRemotely = true;
        _isPlaying = success;
        _isLoading = false;
        if (initialPosition != null && initialPosition > Duration.zero) {
          _position = initialPosition;
          _positionController.add(initialPosition);
        }
        notifyListeners();
        _updateAllServices();
        _updateAndroidAuto();
        return;
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
                ? _subsonicService.getCoverArtUrl(song.coverArt, size: 800)
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

        // Modern music player design
        // Modern music player design
        final youtubeSource = song.isLocal != true
            ? await _subsonicService.getYoutubeAudioSource(song)
            : null;

        if (youtubeSource != null) {
          // Modern music player design
          _concatenatingSource = null;
          await _audioPlayer.setAudioSource(youtubeSource);
          _applyReplayGain(song).catchError((_) {});
          await _ensureAudioFocus(() => _audioPlayer.play());
        } else if (_subsonicService.isYoutube) {
          // Modern music player design
          _concatenatingSource = null;
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
          _applyReplayGain(song).catchError((_) {});
          await _ensureAudioFocus(() => _audioPlayer.play());
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
              await _buildAndSetConcatenatingSource(
                  initialIndex: _currentIndex);
              _hasPlayedOnce = true;
            } else {
              rethrow;
            }
          }
          _applyReplayGain(song).catchError((_) {});
          await _ensureAudioFocus(() => _audioPlayer.play());
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
              // Apply transcoding settings if enabled
              final maxBitRate = _transcodingService.enabled
                  ? _transcodingService.currentBitRate
                  : null;
              final format = _transcodingService.enabled
                  ? _transcodingService.format
                  : null;
              playUrl = _subsonicService.getStreamUrl(song.id,
                  maxBitRate: maxBitRate, format: format);
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
          await _ensureAudioFocus(() => _audioPlayer.play());
        }

        if (initialPosition != null && initialPosition > Duration.zero) {
          await _audioPlayer.seek(initialPosition);
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

      await _ensureAudioFocus(() => _audioPlayer.play());

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

      notifyListeners();
    }
  }



  void _updateSystemServicesForRadio(RadioStation station) {
    _windowsService.updatePlaybackState(
      song: null,
      isPlaying: true,
      position: Duration.zero,
      duration: Duration.zero,
      artworkUrl: null,
    );
  }

  Future<void> play() async {
    _isManuallyPaused = false;
    _wasPlayingBeforeInterruption = false;
    /*
    if (MuslyConnectService().isControllingRemoteDevice) {
      _isPlaying = true;
      notifyListeners();
      MuslyConnectService().sendCommand(ConnectCommandType.play);
      return;
    }
    */
    if (_jukeboxService.enabled) {
      _isPlaying = true;
      notifyListeners();
      _updateAndroidAuto();
      await _jukeboxService.play(_subsonicService);
      return;
    }
    if (_castService.isConnected) {
      _isPlaying = true;
      notifyListeners();
      _updateAndroidAuto();
      if (_currentSong != null && _castService.mediaState.title == null) {
        await playSong(_currentSong!, initialPosition: _position);
      } else {
        await _castService.play();
      }
      return;
    } else if (_upnpService.isConnected) {
      _isPlaying = true;
      notifyListeners();
      _updateAndroidAuto();
      await _upnpService.play();
    } else {
      _isPlaying = true;
      notifyListeners();
      _updateAndroidAuto();

      // After app restart or if player went idle/empty, prepare it first.
      if (_currentSong != null &&
          (_audioPlayer.audioSource == null ||
              _audioPlayer.processingState == ProcessingState.idle ||
              _audioPlayer.processingState == ProcessingState.completed)) {
        await _prepareCurrentSong();
      }
      await _ensureAudioFocus(() async {
        try {
          await _audioPlayer.play();
          await _fadeIn();
        } catch (e) {
          debugPrint('Error playing audio: $e, attempting recovery...');
          if (_currentSong != null) {
            await _prepareCurrentSong();
            await _audioPlayer.play();
            await _fadeIn();
          }
        }
      });
      _isPlaying = _audioPlayer.playing;
      notifyListeners();
      _updateAndroidAuto();
    }
  }

  Future<void> pause() async {
    _isManuallyPaused = true;
    _wasPlayingBeforeInterruption = false;
    /*
    if (MuslyConnectService().isControllingRemoteDevice) {
      _isPlaying = false;
      notifyListeners();
      MuslyConnectService().sendCommand(ConnectCommandType.pause);
      return;
    }
    */
    if (_jukeboxService.enabled) {
      _isPlaying = false;
      notifyListeners();
      _updateAndroidAuto();
      await _jukeboxService.pause(_subsonicService);
      return;
    }
    if (_castService.isConnected) {
      _isPlaying = false;
      notifyListeners();
      _updateAndroidAuto();
      await _castService.pause();
      return;
    } else if (_upnpService.isConnected) {
      _isPlaying = false;
      notifyListeners();
      _updateAndroidAuto();
      await _upnpService.pause();
    } else {
      _isPlaying = false;
      notifyListeners();
      _updateAndroidAuto();

      try {
        await _fadeOut(onComplete: () async {
          await _audioPlayer.pause();
        });
      } catch (e) {
        await _audioPlayer.pause();
      }

      _isPlaying = false;
      notifyListeners();
      _updateAndroidAuto();
      // Intentionally do NOT abandon audio focus here: pause() is also
      // invoked in reaction to a transient OS focus loss (e.g. an incoming
      // call, via onAudioFocusLossTransient). Abandoning would unregister
      // our AudioFocusRequest and its listener, so the OS's AUDIOFOCUS_GAIN
      // callback telling us the call ended — delivered to that SAME
      // request — would never arrive. Keeping focus while paused matches
      // standard Android media-app behavior; stop() below is the actual
      // "done with playback" signal that releases focus for other apps.
    }
  }

  /// Forcibly pauses the local audio player engine (e.g. during playback transfer).
  Future<void> pauseLocal() async {
    try {
      await _audioPlayer.pause();
    } catch (_) {}
    _isPlaying = false;
    notifyListeners();
  }

  /*
  Timer? _muslyConnectPositionTimer;

  void _onMuslyConnectStateChanged() {
    final connect = MuslyConnectService();
    if (connect.isControllingRemoteDevice) {
      final dev = connect.activeRemoteDevice;
      if (dev != null) {
        if (dev.currentSong != null && dev.currentSong?.id != _currentSong?.id) {
          _currentSong = dev.currentSong;
          _currentIndex = dev.currentIndex >= 0 ? dev.currentIndex : _currentIndex;
          _resolvedArtworkUrl = _resolveArtworkUrl();
          _updateAndroidAuto();
        }
        _isPlaying = dev.isPlaying;
        _position = Duration(seconds: dev.positionSeconds);
        _duration = Duration(seconds: dev.durationSeconds);
        _volume = dev.volume;
        _shuffleEnabled = dev.shuffleEnabled;
        _repeatMode = RepeatMode.values[dev.repeatModeIndex.clamp(0, RepeatMode.values.length - 1)];
        if (!_positionController.isClosed) {
          _positionController.add(_position);
        }
        _syncMuslyConnectPositionTimer(dev.isPlaying);

        // Keep Android media session / notification / lockscreen live and accurate
        _audioHandler.updateNowPlaying(
          id: _currentSong?.id ?? '',
          title: _currentSong?.title ?? dev.currentSongTitle ?? '',
          artist: _currentSong?.artist ?? dev.currentSongArtist,
          album: _currentSong?.album,
          artworkUrl: _resolvedArtworkUrl,
          duration: _duration,
        );
        _audioHandler.updateRemotePlaybackState(
          playing: _isPlaying,
          position: _position,
        );

        notifyListeners();
      }
    } else {
      _muslyConnectPositionTimer?.cancel();
      _muslyConnectPositionTimer = null;
    }
  }

  void _syncMuslyConnectPositionTimer(bool isPlaying) {
    _muslyConnectPositionTimer?.cancel();
    if (isPlaying && MuslyConnectService().isControllingRemoteDevice) {
      _muslyConnectPositionTimer = Timer.periodic(const Duration(milliseconds: 250), (_) {
        if (!MuslyConnectService().isControllingRemoteDevice || !_isPlaying) {
          _muslyConnectPositionTimer?.cancel();
          return;
        }
        final newPos = _position + const Duration(milliseconds: 250);
        if (_duration > Duration.zero && newPos > _duration) {
          _position = _duration;
        } else {
          _position = newPos;
        }
        if (!_positionController.isClosed) {
          _positionController.add(_position);
        }
        _audioHandler.updateRemotePlaybackState(
          playing: _isPlaying,
          position: _position,
        );
      });
    }
  }
  */

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

  // ── Fade In/Out ────────────────────────────────────────────────────────────

  void _stopFade() {
    _fadeTimer?.cancel();
    _fadeTimer = null;
    _isFading = false;
  }

  Future<void> _fadeIn() async {
    _stopFade();

    if (!_fadeSettingsService.getFadeEnabled()) {
      await _audioPlayer.setVolume(_volume);
      return;
    }

    final fadeDurationMs = _fadeSettingsService.getFadeDurationMs();
    final steps = 20;
    final stepDurationMs = fadeDurationMs ~/ steps;
    final volumeStep = _volume / steps;

    _isFading = true;
    await _audioPlayer.setVolume(0.0);

    var currentStep = 0;
    _fadeTimer =
        Timer.periodic(Duration(milliseconds: stepDurationMs), (timer) async {
      if (!_isFading || currentStep >= steps) {
        timer.cancel();
        _isFading = false;
        return;
      }
      currentStep++;
      final newVolume = volumeStep * currentStep;
      await _audioPlayer.setVolume(newVolume.clamp(0.0, _volume));
    });
  }

  Future<void> _fadeOut({Future<void> Function()? onComplete}) async {
    _stopFade();

    if (!_fadeSettingsService.getFadeEnabled()) {
      if (onComplete != null) await onComplete();
      return;
    }

    final fadeDurationMs = _fadeSettingsService.getFadeDurationMs();
    final steps = 10;
    final stepDurationMs = fadeDurationMs ~/ steps;
    final currentVolume = _audioPlayer.volume;
    final volumeStep = currentVolume / steps;

    _isFading = true;
    final completer = Completer<void>();

    var currentStep = 0;
    _fadeTimer =
        Timer.periodic(Duration(milliseconds: stepDurationMs), (timer) async {
      if (!_isFading || currentStep >= steps) {
        timer.cancel();
        _isFading = false;
        if (onComplete != null) await onComplete();
        if (!completer.isCompleted) completer.complete();
        return;
      }
      currentStep++;
      final newVolume = currentVolume - (volumeStep * currentStep);
      await _audioPlayer.setVolume(newVolume.clamp(0.0, 1.0));
    });

    await completer.future.timeout(
      Duration(milliseconds: fadeDurationMs + 200),
      onTimeout: () {
        _stopFade();
        if (onComplete != null) onComplete();
      },
    );
  }



  Future<void> togglePlayPause() async {
    /*
    if (MuslyConnectService().isControllingRemoteDevice) {
      MuslyConnectService().sendCommand(ConnectCommandType.togglePlayPause);
      return;
    }
    */
    if (_isPlaying) {
      await pause();
    } else {
      await play();
    }
  }

  Future<void> seek(Duration position) async {
    _position = position;
    notifyListeners();
    /*
    if (MuslyConnectService().isControllingRemoteDevice) {
      MuslyConnectService().sendCommand(ConnectCommandType.seek, {'seconds': position.inSeconds});
      return;
    }
    */
    if (_jukeboxService.enabled) {
      // Jukebox doesn't support seek by position; ignore.
      return;
    }
    if (_castService.isConnected) {
      _position = position;
      _positionController.add(position);
      notifyListeners();
      await _castService.seek(position);
      return;
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
    /*
    if (MuslyConnectService().isControllingRemoteDevice) {
      MuslyConnectService().sendCommand(ConnectCommandType.next);
      return;
    }
    */
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

    if (_jukeboxService.enabled) {
      await _jukeboxService.skipNext(_subsonicService);
      return;
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
      if (_subsonicService.isYoutube && _currentIndex >= _queue.length - 2 && _currentSong != null) {
        _fetchAndQueueRadioTracks(_currentSong!).catchError((_) {});
      }
      await skipToIndex(_currentIndex + 1);
    } else if (_subsonicService.isYoutube && _currentSong != null) {
      final moreSimilar = await _subsonicService.getSimilarSongs(_currentSong!.id, count: 20);
      final existingIds = _queue.map((s) => s.id).toSet();
      final toAdd = moreSimilar.where((s) => !existingIds.contains(s.id)).toList();
      if (toAdd.isNotEmpty) {
        _queue.addAll(toAdd);
        notifyListeners();
        _saveQueueState();
        await skipToIndex(_currentIndex + 1);
      }
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
              debugPrint(
                  'Error adding AutoDJ song to concatenating source: $e');
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
    /*
    if (MuslyConnectService().isControllingRemoteDevice) {
      MuslyConnectService().sendCommand(ConnectCommandType.previous);
      return;
    }
    */
    if (_jukeboxService.enabled) {
      await _jukeboxService.skipPrevious(_subsonicService);
      return;
    }
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
      if (_concatenatingSource != null && !_isRenderingRemotely) {
        await _audioPlayer.seek(Duration.zero, index: index);
      } else {
        await playSong(_queue[index], playlist: _queue, startIndex: index);
      }
    }
  }

  void toggleShuffle({bool? forceValue}) {
    /*
    if (MuslyConnectService().isControllingRemoteDevice) {
      _shuffleEnabled = forceValue ?? !_shuffleEnabled;
      MuslyConnectService().sendCommand(
        ConnectCommandType.toggleShuffle,
        {'shuffle': _shuffleEnabled},
      );
      notifyListeners();
      return;
    }
    */

    _shuffleEnabled = forceValue ?? !_shuffleEnabled;
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
    _updateAllServices();
  }

  void setRepeatModeIndex(int? idx) {
    if (idx != null && idx >= 0 && idx < RepeatMode.values.length) {
      setRepeatMode(RepeatMode.values[idx]);
    }
  }

  void setRepeatMode(RepeatMode mode) {
    _repeatMode = mode;
    switch (_repeatMode) {
      case RepeatMode.off:
        _audioPlayer.setLoopMode(LoopMode.off);
        break;
      case RepeatMode.all:
        _audioPlayer.setLoopMode(LoopMode.all);
        break;
      case RepeatMode.one:
        _audioPlayer.setLoopMode(LoopMode.one);
        break;
    }
    _storageService.saveRepeatMode(_repeatMode.index);
    /*
    if (MuslyConnectService().isControllingRemoteDevice) {
      MuslyConnectService().sendCommand(
        ConnectCommandType.setRepeatMode,
        {'repeatMode': _repeatMode.index},
      );
    }
    */
    notifyListeners();
    _updateAllServices();
  }

  void toggleRepeat() {
    final nextMode = switch (_repeatMode) {
      RepeatMode.off => RepeatMode.all,
      RepeatMode.all => RepeatMode.one,
      RepeatMode.one => RepeatMode.off,
    };
    /*
    if (MuslyConnectService().isControllingRemoteDevice) {
      _repeatMode = nextMode;
      MuslyConnectService().sendCommand(
        ConnectCommandType.setRepeatMode,
        {'repeatMode': nextMode.index},
      );
      notifyListeners();
      return;
    }
    */
    setRepeatMode(nextMode);
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
      if (_concatenatingSource != null &&
          index < _concatenatingSource!.length) {
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
    _clearPersistedQueue();
    _audioPlayer.stop();
    _isPlaying = false;
    _position = Duration.zero;
    notifyListeners();
    _updateAndroidAuto();
  }

  Future<void> resetForServerSwitch() async {
    _stopFade();
    _sleepTimer?.cancel();
    _sleepTimer = null;
    _jukeboxPollTimer?.cancel();
    _jukeboxPollTimer = null;

    if (_castService.isConnected) {
      try {
        await _castService.stop();
      } catch (_) {}
    }
    if (_upnpService.isConnected) {
      try {
        await _upnpService.stop();
      } catch (_) {}
    }

    try {
      await _audioPlayer.stop();
    } catch (_) {}

    _queue.clear();
    _currentIndex = -1;
    _currentSong = null;
    _concatenatingSource = null;
    _resolvedArtworkUrl = null;
    _currentRadioStation = null;
    _isPlayingRadio = false;
    _isPlaying = false;
    _position = Duration.zero;
    _duration = Duration.zero;

    try {
      _discordRpcService.clearPresence();
    } catch (_) {}

    _clearPersistedQueue();
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

  double get lastNonZeroVolume => _lastNonZeroVolume;

  Future<void> setVolume(double volume) async {
    final clamped = volume.clamp(0.0, 1.0);
    if (clamped > 0.0) {
      _lastNonZeroVolume = clamped;
    }
    _volume = clamped;
    await _storageService.saveVolume(_volume);
    /*
    if (MuslyConnectService().isControllingRemoteDevice) {
      MuslyConnectService().sendCommand(ConnectCommandType.setVolume, {'volume': _volume});
    }
    */
    if (_castService.isConnected) {
      await _castService.setVolume(_volume);
    } else if (_upnpService.isConnected) {
      await _upnpService.setVolume((_volume * 100).round());
    } else {
      await _applyReplayGain(_currentSong);
    }
    notifyListeners();
  }

  Future<void> toggleMute() async {
    if (_volume > 0.0) {
      _lastNonZeroVolume = _volume;
      await setVolume(0.0);
    } else {
      await setVolume(_lastNonZeroVolume > 0.0 ? _lastNonZeroVolume : 1.0);
    }
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
        _audioHandler.updateRemoteVolume(actual);
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
    if (_subsonicService.isYoutube) {
      final ytSource = await _subsonicService.getYoutubeAudioSource(song);
      if (ytSource != null) return ytSource;
    }
    // Apply transcoding settings if enabled
    final maxBitRate =
        _transcodingService.enabled ? _transcodingService.currentBitRate : null;
    final format =
        _transcodingService.enabled ? _transcodingService.format : null;
    final url = _subsonicService.getStreamUrl(song.id,
        maxBitRate: maxBitRate, format: format);
    if (_transcodingService.enabled) {
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
    } else {
      return AudioSource.uri(
        Uri.parse(url),
        tag: song.id,
      );
    }
  }

  Future<void> _buildAndSetConcatenatingSource(
      {required int initialIndex}) async {
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
    // When jukebox mode is active, the server handles playback.
    if (_jukeboxService.enabled) return;
    try {
      if (_subsonicService.isYoutube && _currentSong!.isLocal != true) {
        final ytSource =
            await _subsonicService.getYoutubeAudioSource(_currentSong!);
        if (ytSource != null) {
          await _audioPlayer.setAudioSource(ytSource);
          if (_position.inMilliseconds > 0) {
            await _audioPlayer.seek(_position);
          }
          return;
        }
      }
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
            playUrl =
                await _subsonicService.resolveStreamUrlAsync(_currentSong!);
          }
        }
        if (_currentSong!.isLocal == true ||
            _offlineService.getLocalPath(_currentSong!.id) != null) {
          await _audioPlayer.setUrl(playUrl);
        } else {
          if (_transcodingService.enabled) {
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
          } else {
            await _audioPlayer.setAudioSource(
              AudioSource.uri(
                Uri.parse(playUrl),
                tag: _currentSong!.id,
              ),
            );
          }
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
        // fix #207: only scrobble if the Last.FM threshold was met
        if (_canScrobble(_currentSong!)) {
          _subsonicService
              .scrobble(_currentSong!.id, submission: true)
              .catchError(
            (e) {
              _offlineService.queueScrobble(_currentSong!.id, submission: true);
            },
          );
        } else {
          debugPrint(
              '[Player] Skipped scrobble for "${_currentSong!.title}" '
              '(not played long enough)');
        }
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
    _lastPreloadedSongId = null;
    _position = Duration.zero;
    _resolvedArtworkUrl = null;
    // fix #207: reset tracking so the new song's scrobble threshold starts fresh
    _resetScrobbleTracking(_currentSong!);
    notifyListeners();
    _saveQueueState();

    // fix #210: send "Now Playing" notification for the new track so the
    // server's "Now Playing" status updates correctly (gapless auto-advance).
    if (_currentSong!.isLocal != true) {
      if (_offlineService.isOfflineMode) {
        _offlineService.queueScrobble(_currentSong!.id, submission: false);
      } else {
        _subsonicService
            .scrobble(_currentSong!.id, submission: false)
            .catchError((e) {
          _offlineService.queueScrobble(_currentSong!.id, submission: false);
        });
      }
    }

    await _refreshArtworkUrl();
    if (_currentSong != null) {
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
  CrossfadeService get crossfadeService => _crossfadeService;

  bool _isCrossfadingOut = false;

  void _checkCrossfade(Duration position) {
    if (!_crossfadeService.isEnabled || _duration == Duration.zero || _isRenderingRemotely) return;
    final crossfadeSec = _crossfadeService.getCrossfadeSeconds();
    if (crossfadeSec <= 0) return;
    final threshold = _duration - Duration(seconds: crossfadeSec);
    if (position >= threshold && !_isCrossfadingOut && _isPlaying && hasNext) {
      _startCrossfadeAttenuation(crossfadeSec);
    }
  }

  void _startCrossfadeAttenuation(int crossfadeSec) {
    _isCrossfadingOut = true;
    final steps = (crossfadeSec * 4).clamp(4, 40);
    final stepDurationMs = (crossfadeSec * 1000) ~/ steps;
    final currentVol = _audioPlayer.volume;
    final volStep = currentVol / steps;
    var step = 0;

    Timer.periodic(Duration(milliseconds: stepDurationMs), (timer) {
      if (!_isCrossfadingOut || !_isPlaying || step >= steps) {
        timer.cancel();
        return;
      }
      step++;
      final newVol = (currentVol - (volStep * step)).clamp(0.0, 1.0);
      _audioPlayer.setVolume(newVol).catchError((_) {});
    });
  }

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
    WidgetsBinding.instance.removeObserver(this);
    _sleepTimer?.cancel();
    _sleepTimerFadeTimer?.cancel();
    _sleepTimerFadePeriodicTimer?.cancel();
    // Save queue state immediately before cancelling the debounce timer
    _saveQueueStateImmediate();
    _persistDebounceTimer?.cancel();
    _jukeboxPollTimer?.cancel();
    _jukeboxService.removeListener(_onJukeboxEnabledChanged);
    // _muslyConnectPositionTimer?.cancel();
    // MuslyConnectService().removeListener(_onMuslyConnectStateChanged);
    _windowsPositionTimer?.cancel();
    _castService.removeListener(_onCastStateChanged);
    _upnpService.removeListener(_onUpnpStateChanged);
    if (_upnpService.onRendererLost == _onUpnpRendererLost) {
      _upnpService.onRendererLost = null;
    }
    // Stop playback before disposing audio handler to prevent NPE on Android
    _audioPlayer.stop().catchError((_) {});

    // Dispose audio handler with error handling
    _audioHandler.customAction('dispose').catchError((e) {
      debugPrint('Error disposing audio handler: $e');
    });

    try {
      _windowsService.dispose();
    } catch (_) {}

    try {
      _discordRpcService.shutdown();
    } catch (_) {}
    _playerStateSub?.cancel();
    _positionSub?.cancel();
    _durationSub?.cancel();
    _currentIndexSub?.cancel();
    _positionController.close();
    // Remove app lifecycle observer
    WidgetsBinding.instance.removeObserver(this);
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

  String? _lastDiscordSongId;
  bool? _lastDiscordIsPlaying;
  String? _lastDiscordStateText;
  int _lastDiscordSeekPosMs = -1;

  void _updateDiscordRpc({bool force = false}) {
    try {
      if (_currentSong == null) {
        if (_lastDiscordSongId != null) {
          _discordRpcService.clearPresence();
          _lastDiscordSongId = null;
          _lastDiscordIsPlaying = null;
          _lastDiscordStateText = null;
          _lastDiscordSeekPosMs = -1;
        }
        return;
      }

      final stateText = _discordStateText();
      final posMs = _position.inMilliseconds;
      final bool seekJumped = (_lastDiscordSeekPosMs - posMs).abs() > 3000;

      if (!force &&
          _lastDiscordSongId == _currentSong!.id &&
          _lastDiscordIsPlaying == _isPlaying &&
          _lastDiscordStateText == stateText &&
          !seekJumped) {
        return;
      }

      _lastDiscordSongId = _currentSong!.id;
      _lastDiscordIsPlaying = _isPlaying;
      _lastDiscordStateText = stateText;
      _lastDiscordSeekPosMs = posMs;

      if (!_isPlaying) {
        _discordRpcService.updatePresence(
          state: stateText,
          details: _currentSong!.title,
          largeImageKey: 'musly_logo',
          largeImageText: _currentSong!.album ?? 'Musly',
          smallImageKey: 'musly_logo',
          smallImageText: 'Paused',
          startTime: null,
          endTime: null,
        );
      } else {
        final int now = DateTime.now().millisecondsSinceEpoch;
        final int startTimestamp = now - posMs;
        final int? endTimestamp = _duration.inMilliseconds > 0
            ? startTimestamp + _duration.inMilliseconds
            : null;

        _discordRpcService.updatePresence(
          state: stateText,
          details: _currentSong!.title,
          largeImageKey: 'musly_logo',
          largeImageText: _currentSong!.album ?? 'Musly',
          smallImageKey: 'musly_logo',
          smallImageText: 'Playing',
          startTime: startTimestamp,
          endTime: endTimestamp,
        );
      }
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

  bool _castWasConnected = false;
  bool _castWasPlaying = false;

  void _onCastStateChanged() {
    final connected = _castService.isConnected;

    if (connected && !_castWasConnected) {
      _castWasConnected = true;
      _castWasPlaying = false;
      _isRenderingRemotely = true;
      if (_audioPlayer.playing) _audioPlayer.pause();
      final vol = _castService.mediaState.volume;
      if (vol >= 0) {
        _volume = vol.clamp(0.0, 1.0);
      }
      _audioHandler.setRemotePlayback(
        isRemote: true,
        volume: (_volume * 100).round().clamp(0, 100),
      );
      if (_currentSong != null) {
        final song = _currentSong!;
        final currentPos = _position;
        _currentSong = null;
        playSong(song, initialPosition: currentPos);
      }
      return;
    }

    if (!connected && _castWasConnected) {
      _castWasConnected = false;
      _castWasPlaying = false;
      _isRenderingRemotely = false;
      _isPlaying = false;
      _audioHandler.setRemotePlayback(isRemote: false);
      notifyListeners();
      _updateAndroidAuto();
      return;
    }

    if (!connected) return;

    final pos = _castService.mediaState.position;
    final dur = _castService.mediaState.duration;
    final playing = _castService.mediaState.isPlaying;
    final isIdleFinished = _castService.mediaState.playerState ==
            CastMediaPlayerState.idle &&
        _castService.mediaState.idleReason == GoogleCastMediaIdleReason.finished;

    if (_castWasPlaying && isIdleFinished) {
      debugPrint(
        'Cast: Track ended naturally (pos=${pos.inSeconds}s, dur=${dur.inSeconds}s) — advancing',
      );
      _castWasPlaying = false;
      _onSongComplete()
          .catchError((e) => debugPrint('[Player] _onSongComplete error: $e'));
      return;
    }

    _castWasPlaying = playing;

    bool changed = false;

    if ((_position - pos).abs() > const Duration(milliseconds: 500)) {
      _position = pos;
      changed = true;
    }
    if (dur != Duration.zero && dur != _duration) {
      _duration = dur;
      changed = true;
    }
    if (playing != _isPlaying) {
      _isPlaying = playing;
      changed = true;
    }

    final vol = _castService.mediaState.volume;
    if ((_volume - vol).abs() > 0.005) {
      _volume = vol.clamp(0.0, 1.0);
      changed = true;
      _audioHandler.updateRemoteVolume((_volume * 100).round().clamp(0, 100));
    }

    if (changed) {
      _positionController.add(_position);
      notifyListeners();
      _updateAndroidAuto();
    }
  }

  bool _upnpWasConnected = false;
  bool _upnpWasPlaying = false;
  // True when an A2DP audio-output device (car, speaker) is connected.
  // Control-only devices (Garmin watch, etc.) don't set this flag.
  final bool _isA2dpAudioActive = false;

  void _onUpnpStateChanged() {
    final connected = _upnpService.isConnected;

    if (connected && !_upnpWasConnected) {
      _upnpWasConnected = true;
      _upnpWasPlaying = false;
      if (_audioPlayer.playing) _audioPlayer.pause();
      final vol = _upnpService.volume;

      if (vol >= 0) _volume = vol / 100.0;
      _audioHandler.setRemotePlayback(
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
      _audioHandler.setRemotePlayback(isRemote: false);
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
    if (dur != Duration.zero && dur != _duration) {
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
        _audioHandler.updateRemoteVolume(vol);
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
