import 'package:flutter/foundation.dart';
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
import '../providers/library_provider.dart';

enum RepeatMode { off, all, one }

class PlayerProvider extends ChangeNotifier {
  final SubsonicService _subsonicService;
  final AudioPlayer _audioPlayer = AudioPlayer();
  final OfflineService _offlineService = OfflineService();
  final AndroidAutoService _androidAutoService = AndroidAutoService();
  final AndroidSystemService _androidSystemService = AndroidSystemService();
  final WindowsSystemService _windowsService = WindowsSystemService();
  final BluetoothAvrcpService _bluetoothService = BluetoothAvrcpService();
  final SamsungIntegrationService _samsungService = SamsungIntegrationService();
  final ReplayGainService _replayGainService = ReplayGainService();
  final AutoDjService _autoDjService = AutoDjService();

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

  // Radio station support
  RadioStation? _currentRadioStation;
  bool _isPlayingRadio = false;

  PlayerProvider(this._subsonicService) {
    _initializePlayer();
    _initializeAndroidAuto();
    _initializeSystemServices();
    _initializeAutoDj();
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
    // Register absolute volume control when available (AVRCP 1.6 capable devices).
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

    _androidAutoService.onGetAlbumSongs = _getAlbumSongsForAndroidAuto;
    _androidAutoService.onGetArtistAlbums = _getArtistAlbumsForAndroidAuto;
    _androidAutoService.onGetPlaylistSongs = _getPlaylistSongsForAndroidAuto;
  }

  Future<List<Map<String, String>>> _getAlbumSongsForAndroidAuto(
    String albumId,
  ) async {
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

  void _updateAndroidAuto() {
    if (_currentSong == null) return;

    final artworkUrl = _currentSong!.coverArt != null
        ? _subsonicService.getCoverArtUrl(_currentSong!.coverArt!, size: 300)
        : null;

    _androidAutoService.updatePlaybackState(
      songId: _currentSong!.id,
      title: _currentSong!.title,
      artist: _currentSong!.artist ?? '',
      album: _currentSong!.album ?? '',
      artworkUrl: artworkUrl,
      duration: _duration,
      position: _position,
      isPlaying: _isPlaying,
    );

    _updateAllServices();
  }

  void _updateAllServices() {
    if (_currentSong == null) return;

    final artworkUrl = _currentSong!.coverArt != null
        ? _subsonicService.getCoverArtUrl(_currentSong!.coverArt!, size: 300)
        : null;

    _androidSystemService.updateFromSong(
      song: _currentSong!,
      artworkUrl: artworkUrl,
      duration: _duration,
      position: _position,
      isPlaying: _isPlaying,
      currentIndex: _currentIndex,
      queueLength: _queue.length,
    );

    _windowsService.updatePlaybackState(
      song: _currentSong!,
      artworkUrl: artworkUrl,
      duration: _duration,
      position: _position,
      isPlaying: _isPlaying,
    );

    _bluetoothService.updateFromSong(
      song: _currentSong!,
      artworkUrl: artworkUrl,
      duration: _duration,
      position: _position,
      isPlaying: _isPlaying,
      currentIndex: _currentIndex,
      queueLength: _queue.length,
    );

    if (_samsungService.isSamsungDevice) {
      _samsungService.updateFromSong(
        song: _currentSong!,
        artworkUrl: artworkUrl,
        duration: _duration,
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

  // Radio station getters
  RadioStation? get currentRadioStation => _currentRadioStation;
  bool get isPlayingRadio => _isPlayingRadio;

  Stream<Duration> get positionStream => _audioPlayer.positionStream;

  double get progress {
    if (_duration.inMilliseconds == 0) return 0;
    return _position.inMilliseconds / _duration.inMilliseconds;
  }

  void _initializePlayer() {
    // Note: just_audio_windows may print "Error accessing BufferingProgress" messages.
    // This is a known harmless issue in the plugin and doesn't affect playback.
    // See: https://github.com/bdlukaa/just_audio_windows/issues

    _audioPlayer.playerStateStream.listen(
      (state) {
        final wasPlaying = _isPlaying;
        _isPlaying = state.playing;

        if (state.processingState == ProcessingState.completed) {
          _onSongComplete();
        }

        if (wasPlaying != _isPlaying) {
          notifyListeners();
          _updateAndroidAuto();
        }
      },
      onError: (error) {
        // Silently handle stream errors (e.g., buffering progress access issues on Windows)
        debugPrint('Player state stream error (can be ignored): $error');
      },
    );

    Duration? lastNotified;
    Duration? lastSystemUpdate;
    _audioPlayer.positionStream.listen(
      (position) {
        _position = position;
        if (lastNotified == null ||
            position.inMilliseconds - lastNotified!.inMilliseconds > 250) {
          lastNotified = position;
          notifyListeners();
        }

        // Update system services progress (SMTC, Taskbar) every 1s
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
      },
      onError: (error) {
        debugPrint('Duration stream error (can be ignored): $error');
      },
    );
  }

  void _onSongComplete() {
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
          // End of queue - try Auto DJ
          _handleEndOfQueue();
        }
        break;
    }
  }

  Future<void> _handleEndOfQueue() async {
    if (_autoDjService.isEnabled) {
      await _addAutoDjSongs();
      // If songs were added, play the next one
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
    // If the song is already the current one, toggle play/pause
    if (_currentSong?.id == song.id && !_isPlayingRadio) {
      await togglePlayPause();
      return;
    }

    // Clear radio state when playing a song
    _isPlayingRadio = false;
    _currentRadioStation = null;

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

      final playUrl = _offlineService.getPlayableUrl(song, _subsonicService);

      await _audioPlayer.setUrl(playUrl);

      // Apply ReplayGain volume adjustment
      await _applyReplayGain(song);

      await _audioPlayer.play();

      _subsonicService.scrobble(song.id, submission: false);

      if (_recommendationService != null) {
        _recommendationService!.trackSongPlay(
          song,
          durationPlayed: 0,
          completed: false,
        );
      }

      _updateAndroidAuto();
    } catch (e) {
      debugPrint('Error playing song: $e');
      // Ensure Android Auto reflects stopped state on error
      _isPlaying = false;
      _position = Duration.zero;
      _updateAndroidAuto();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Play an internet radio station stream.
  Future<void> playRadioStation(RadioStation station) async {
    // If the same station is already playing, toggle play/pause
    if (_isPlayingRadio && _currentRadioStation?.id == station.id) {
      await togglePlayPause();
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      // Clear song queue and set radio state
      _currentSong = null;
      _queue = [];
      _currentIndex = -1;
      _isPlayingRadio = true;
      _currentRadioStation = station;
      _position = Duration.zero;
      _duration = Duration.zero;

      await _audioPlayer.setUrl(station.streamUrl);

      // Apply full volume for radio (no ReplayGain)
      await _audioPlayer.setVolume(_volume);

      await _audioPlayer.play();

      // Update system services with radio info
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

  /// Stop radio playback and clear radio state.
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
    // Update Windows SMTC with radio info
    _windowsService.updatePlaybackState(
      song: null,
      isPlaying: true,
      position: Duration.zero,
      duration: Duration.zero,
      artworkUrl: null,
    );

    // Update Android system service
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
    await _audioPlayer.play();
  }

  Future<void> pause() async {
    await _audioPlayer.pause();
  }

  Future<void> stop() async {
    await _audioPlayer.stop();
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
    await _audioPlayer.seek(position);
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

    // Check if Auto DJ should add more songs
    if (_autoDjService.shouldAddSongs(_currentIndex, _queue.length)) {
      await _addAutoDjSongs();
    }

    if (_currentIndex < _queue.length - 1) {
      await skipToIndex(_currentIndex + 1);
    }
  }

  /// Add songs to the queue using Auto DJ
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
    await _applyReplayGain(_currentSong);
    notifyListeners();
  }

  /// Apply ReplayGain volume adjustment for the current song
  Future<void> _applyReplayGain(Song? song) async {
    await _replayGainService.initialize();

    final replayGainMultiplier = _replayGainService.calculateVolumeMultiplier(
      trackGain: song?.replayGainTrackGain,
      albumGain: song?.replayGainAlbumGain,
      trackPeak: song?.replayGainTrackPeak,
      albumPeak: song?.replayGainAlbumPeak,
    );

    // Apply both user volume and ReplayGain adjustment
    final effectiveVolume = _volume * replayGainMultiplier;
    await _audioPlayer.setVolume(effectiveVolume);
  }

  /// Refresh ReplayGain settings (call when settings change)
  Future<void> refreshReplayGain() async {
    await _applyReplayGain(_currentSong);
    notifyListeners();
  }

  /// Get the ReplayGain service for settings access
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

  @override
  void dispose() {
    _audioPlayer.dispose();
    _androidAutoService.dispose();
    _androidSystemService.dispose();
    _windowsService.dispose();
    _bluetoothService.dispose();
    _samsungService.dispose();
    super.dispose();
  }
}
