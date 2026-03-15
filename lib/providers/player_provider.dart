import 'package:flutter/foundation.dart';
import 'dart:async';
import 'dart:io';

import 'package:audio_session/audio_session.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:just_audio/just_audio.dart';
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
  LibraryProvider? _libraryProvider;
  RecommendationService? _recommendationService;

  List<Song> _queue = [];
  int _currentIndex = -1;
  bool _isPlaying = false;
  bool _isLoading = false;
  bool _shuffleEnabled = false;
  RepeatMode _repeatMode = RepeatMode.off;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  Song? _currentSong;
  double _volume = 1.0;

  String? _resolvedArtworkUrl;

  RadioStation? _currentRadioStation;
  bool _isPlayingRadio = false;

  bool _hasPlayedOnce = false;

  bool _reactivatingSession = false;

  Timer? _sleepTimer;
  DateTime? _sleepTimerEnd;

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
    _initializePlayer();
    _initializeAndroidAuto();
    _initializeSystemServices();
    _initializeAutoDj();
    _wireAudioHandlerCallbacks();
    
    if (!kIsWeb &&
        (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      _discordRpcService.initialize();
      loadDiscordRpcStateStyle();
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
    await _androidSystemService.initialize();
    _androidSystemService.onPlay = play;
    _androidSystemService.onPause = pause;
    _androidSystemService.onStop = stop;
    _androidSystemService.onSkipNext = skipNext;
    _androidSystemService.onSkipPrevious = skipPrevious;
    _androidSystemService.onSeekTo = seek;
    _androidSystemService.onSeekForward = (interval) => seek(_position + interval);
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

    _androidSystemService.onAudioFocusLoss = () {
      pause();
    };
    _androidSystemService.onAudioFocusLossTransient = () {
      pause();
    };
    _androidSystemService.onAudioFocusLossTransientCanDuck = () {
      _audioPlayer.setVolume(0.3);
    };
    _androidSystemService.onAudioFocusGain = () {
      _audioPlayer.setVolume(_volume);
    };
    _androidSystemService.onBecomingNoisy = () {
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
      _updateAllServices();
    };
    _bluetoothService.onDeviceDisconnected = (device) {
      debugPrint('Bluetooth device disconnected: ${device.name}');
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
                'artworkUrl': _offlineService.getLocalCoverArtPath(song.id) != null
                    ? Uri.file(_offlineService.getLocalCoverArtPath(song.id)!).toString()
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
                  'artworkUrl': _offlineService.getLocalCoverArtPath(song.id) != null
                      ? Uri.file(_offlineService.getLocalCoverArtPath(song.id)!).toString()
                      : _subsonicService.getCoverArtUrl(song.coverArt, size: 300),
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
              'artworkUrl': _offlineService.getLocalCoverArtPath(song.id) != null
                  ? Uri.file(_offlineService.getLocalCoverArtPath(song.id)!).toString()
                  : _subsonicService.getCoverArtUrl(song.coverArt, size: 300),
              'duration': (song.duration ?? 0).toString(),
            },
          )
          .toList();
    }
    try {
      final results = await _subsonicService.search(
        query,
        songCount: 20,
        albumCount: 0,
        artistCount: 0,
      );
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
    } catch (e) {
      debugPrint('Android Auto search error: $e');
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
    
    for (final sz in [400, 300, 200, 150, 100]) {
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
    final serverUrl = _subsonicService.getCoverArtUrl(coverArtId, size: 600);

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
  bool get shuffleEnabled => _shuffleEnabled;
  RepeatMode get repeatMode => _repeatMode;
  Duration get position => _position;
  Duration get duration => _duration;
  Song? get currentSong => _currentSong;
  bool get hasNext => _currentIndex < _queue.length - 1;
  bool get hasPrevious => _currentIndex > 0;
  double get volume => _volume;

  RadioStation? get currentRadioStation => _currentRadioStation;
  bool get isPlayingRadio => _isPlayingRadio;

  Stream<Duration> get positionStream => _audioPlayer.positionStream;

  double get progress {
    if (_duration.inMilliseconds == 0) return 0;
    return _position.inMilliseconds / _duration.inMilliseconds;
  }

  bool get hasSleepTimer => _sleepTimer != null;

  Duration? get sleepTimerRemaining {
    if (_sleepTimerEnd == null) return null;
    final remaining = _sleepTimerEnd!.difference(DateTime.now());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  void setSleepTimer(Duration duration) {
    _sleepTimer?.cancel();
    _sleepTimer = null;
    _sleepTimerEnd = null;

    if (duration > Duration.zero) {
      _sleepTimerEnd = DateTime.now().add(duration);
      _sleepTimer = Timer(duration, () {
        pause();
        _sleepTimer = null;
        _sleepTimerEnd = null;
        notifyListeners();
      });
    }
    notifyListeners();
  }

  void _initializePlayer() {
    
    _storageService.getVolume().then((savedVolume) {
      _volume = savedVolume;
      _audioPlayer.setVolume(_volume);
      notifyListeners();
    });

    _audioPlayer.playerStateStream.listen(
      (state) {
        final wasPlaying = _isPlaying;
        _isPlaying = state.playing;

        if (wasPlaying != _isPlaying && !_reactivatingSession) {
          debugPrint('[Player] ${_isPlaying ? '▶ Playing' : '⏸ Paused'} — "${_currentSong?.title ?? 'unknown'}" (${state.processingState.name})');
        }

        if (state.processingState == ProcessingState.completed) {
          debugPrint('[Player] ✓ Song completed: "${_currentSong?.title ?? 'unknown'}"');
          _onSongComplete();
        }

        if (state.processingState == ProcessingState.buffering && !wasPlaying) {
          debugPrint('[Player] ⟳ Buffering: "${_currentSong?.title ?? 'unknown'}"');
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
    _audioPlayer.positionStream.listen(
      (position) {
        
        final positionJumpedBack =
            _position.inMilliseconds > 0 &&
            position.inMilliseconds < _position.inMilliseconds - 1000;

        _position = position;

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
        }
      },
      onError: (error) {
        debugPrint('Position stream error (can be ignored): $error');
      },
    );

    _audioPlayer.durationStream.listen(
      (duration) {
        _duration = duration ?? Duration.zero;
        notifyListeners();
        _updateAndroidAuto(); 
      },
      onError: (error) {
        debugPrint('Duration stream error (can be ignored): $error');
      },
    );
  }

  void _onSongComplete() {
    
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

    switch (_repeatMode) {
      case RepeatMode.one:
        seek(Duration.zero);
        play();
        break;
      case RepeatMode.all:
        if (_currentIndex >= _queue.length - 1) {
          skipToIndex(0);
        } else {
          skipNext();
        }
        break;
      case RepeatMode.off:
        if (_currentIndex < _queue.length - 1) {
          skipNext();
        } else {
          
          _handleEndOfQueue();
        }
        break;
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

    debugPrint('[Player] ▶ playSong: "${song.title}" by ${song.artist ?? 'unknown'} (id=${song.id} local=${song.isLocal})');
    _isLoading = true;
    notifyListeners();

    try {
      if (playlist != null) {
        _queue = List.from(playlist);
        _currentIndex =
            startIndex ?? playlist.indexWhere((s) => s.id == song.id);
        if (_currentIndex == -1) _currentIndex = 0;
      } else if (_queue.isEmpty || !_queue.any((s) => s.id == song.id)) {
        _queue = [song];
        _currentIndex = 0;
      } else {
        _currentIndex = _queue.indexWhere((s) => s.id == song.id);
      }

      _currentSong = song;
      _resolvedArtworkUrl = null; 
      _position = Duration.zero;
      notifyListeners();

      await _refreshArtworkUrl();

      if (_castService.isConnected) {
        if (_audioPlayer.playing) await _audioPlayer.stop();

        final playUrl = song.isLocal == true
            ? Uri.file(song.path!).toString()
            : _subsonicService.getStreamUrl(song.id);
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
          duration: song.duration != null
              ? Duration(seconds: song.duration!)
              : null,
          autoPlay: true,
        );
        _isPlaying = true;
      } else if (_upnpService.isConnected) {
        
        debugPrint(
          'UPnP: playSong() taking UPnP branch, isConnected=${_upnpService.isConnected}',
        );
        if (_audioPlayer.playing) await _audioPlayer.stop();

        final playUrl = song.isLocal == true && song.path != null
            ? Uri.file(song.path!).toString()
            : _subsonicService.getStreamUrl(song.id);

        try {
          final success = await _upnpService.loadAndPlay(
            url: playUrl,
            title: song.title,
            artist: song.artist ?? 'Unknown Artist',
            album: song.album,
            albumArtUrl: song.coverArt != null
                ? _subsonicService.getCoverArtUrl(song.coverArt, size: 0)
                : null,
            durationSecs: song.duration,
          );
          if (!success) {
            _upnpService.disconnect();
            debugPrint('UPnP playback failed (retries exhausted), disconnected');
            return;
          }
        } catch (e) {
          
          _upnpService.disconnect();
          debugPrint('UPnP playback failed, disconnected: $e');
          rethrow;
        }
        _isPlaying = true;
      } else {
        
        final String playUrl;
        if (song.isLocal == true && song.path != null) {
          playUrl = Uri.file(song.path!).toString();
        } else {
          playUrl = _offlineService.getPlayableUrl(song, _subsonicService);
        }

        try {
          await _audioPlayer.setUrl(playUrl);
        } catch (e) {
          if (!_hasPlayedOnce) {
            debugPrint(
              'First playback failed (Android 16 Media3 issue), retrying: $e',
            );
            await Future.delayed(const Duration(milliseconds: 100));
            await _audioPlayer.setUrl(playUrl);
            _hasPlayedOnce = true;
          } else {
            rethrow;
          }
        }

        await _applyReplayGain(song);
        await _audioPlayer.play();
      }

      if (song.isLocal != true) {
        if (_offlineService.isOfflineMode) {
          
          _offlineService.queueScrobble(song.id, submission: false);
        } else {
          _subsonicService.scrobble(song.id, submission: false).catchError((e) {
            _offlineService.queueScrobble(song.id, submission: false);
          });

          _offlineService.flushPendingScrobbles(_subsonicService).catchError((e) {
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

    if (_currentIndex < _queue.length - 1) {
      await skipToIndex(_currentIndex + 1);
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
        notifyListeners();
        debugPrint('Auto DJ added ${songsToAdd.length} songs to queue');
      }
    } catch (e) {
      debugPrint('Auto DJ error: $e');
    }
  }

  Future<void> skipPrevious() async {
    if (_position.inSeconds > 3) {
      await seek(Duration.zero);
    } else if (_currentIndex > 0) {
      await skipToIndex(_currentIndex - 1);
    } else {
      await seek(Duration.zero);
    }
  }

  Future<void> skipToIndex(int index) async {
    if (index >= 0 && index < _queue.length) {
      await playSong(_queue[index], playlist: _queue, startIndex: index);
    }
  }

  void toggleShuffle() {
    _shuffleEnabled = !_shuffleEnabled;
    if (_shuffleEnabled && _queue.length > 1 && _currentSong != null) {
      final currentSong = _currentSong!;
      _queue.shuffle();
      _queue.remove(currentSong);
      _queue.insert(0, currentSong);
      _currentIndex = 0;
    }
    notifyListeners();
  }

  void toggleRepeat() {
    switch (_repeatMode) {
      case RepeatMode.off:
        _repeatMode = RepeatMode.all;
        break;
      case RepeatMode.all:
        _repeatMode = RepeatMode.one;
        break;
      case RepeatMode.one:
        _repeatMode = RepeatMode.off;
        break;
    }
    notifyListeners();
  }

  void addToQueue(Song song) {
    _queue.add(song);
    notifyListeners();
  }

  void addToQueueNext(Song song) {
    if (_currentIndex + 1 < _queue.length) {
      _queue.insert(_currentIndex + 1, song);
    } else {
      _queue.add(song);
    }
    notifyListeners();
  }

  void addAllToQueue(Iterable<Song> songs) {
    _queue.addAll(songs);
    notifyListeners();
  }

  void removeFromQueue(int index) {
    if (index >= 0 && index < _queue.length) {
      _queue.removeAt(index);
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
      notifyListeners();
    }
  }

  void clearQueue() {
    _queue.clear();
    _currentIndex = -1;
    _currentSong = null;
    _discordRpcService.clearPresence();
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

    if (oldIndex == _currentIndex) {
      _currentIndex = newIndex;
    } else if (oldIndex < _currentIndex && newIndex >= _currentIndex) {
      _currentIndex -= 1;
    } else if (oldIndex > _currentIndex && newIndex <= _currentIndex) {
      _currentIndex += 1;
    }

    notifyListeners();
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

  void _onRemoteVolumeChange(int volume) {
    if (_castService.isConnected) {
      _castService.setVolume(volume / 100.0);
    } else if (_upnpService.isConnected) {
      _upnpService.setVolume(volume);
    }
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
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    _sleepTimer?.cancel();
    _castService.removeListener(_onCastStateChanged);
    _upnpService.removeListener(_onUpnpStateChanged);
    _audioHandler.customAction('dispose');
    _androidAutoService.dispose();
    _androidSystemService.dispose();
    _windowsService.dispose();
    _bluetoothService.dispose();
    _samsungService.dispose();
    
    _discordRpcService.shutdown();
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

  }

  Future<void> setDiscordRpcEnabled(bool enabled) async {
    await _discordRpcService.setEnabled(enabled);
    if (enabled) {
      _updateDiscordRpc();
    }
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
      
      _androidSystemService.setRemotePlayback(isRemote: false);
      _isPlaying = false;
      notifyListeners();
      _updateAndroidAuto();
    }
  }

  bool _upnpWasConnected = false;
  bool _upnpWasPlaying = false;

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
      _isPlaying = false;
      _position = Duration.zero;
      _duration = Duration.zero;
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

    if (_upnpWasPlaying &&
        rendererState == 'STOPPED' &&
        dur > Duration.zero &&
        pos.inSeconds >= dur.inSeconds - 1) {
      debugPrint('UPnP: Track ended (pos=${pos.inSeconds}s, dur=${dur.inSeconds}s) — advancing');
      _upnpWasPlaying = false;
      _onSongComplete();
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
    if (vol >= 0) {
      final normalized = vol / 100.0;
      if ((_volume - normalized).abs() > 0.005) {
        _volume = normalized;
        changed = true;
      }
      _androidSystemService.updateRemoteVolume(vol);
    }

    if (changed) {
      notifyListeners();
      _updateAndroidAuto();
    }
  }
}
