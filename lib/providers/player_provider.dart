import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import '../models/models.dart';
import '../services/subsonic_service.dart';
import '../services/offline_service.dart';
import '../services/android_auto_service.dart';
import '../services/android_system_service.dart';
import '../services/bluetooth_avrcp_service.dart';
import '../services/samsung_integration_service.dart';
import '../providers/library_provider.dart';

enum RepeatMode { off, all, one }

class PlayerProvider extends ChangeNotifier {
  final SubsonicService _subsonicService;
  final AudioPlayer _audioPlayer = AudioPlayer();
  final OfflineService _offlineService = OfflineService();
  final AndroidAutoService _androidAutoService = AndroidAutoService();
  final AndroidSystemService _androidSystemService = AndroidSystemService();
  final BluetoothAvrcpService _bluetoothService = BluetoothAvrcpService();
  final SamsungIntegrationService _samsungService = SamsungIntegrationService();

  LibraryProvider? _libraryProvider;

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

  PlayerProvider(this._subsonicService) {
    _initializePlayer();
    _initializeAndroidAuto();
    _initializeSystemServices();
  }

  void setLibraryProvider(LibraryProvider libraryProvider) {
    _libraryProvider = libraryProvider;
  }

  void _initializeSystemServices() {
    _androidSystemService.initialize();
    _androidSystemService.onPlay = play;
    _androidSystemService.onPause = pause;
    _androidSystemService.onStop = stop;
    _androidSystemService.onSkipNext = skipNext;
    _androidSystemService.onSkipPrevious = skipPrevious;
    _androidSystemService.onSeekTo = seek;
    _androidSystemService.onHeadsetHook = togglePlayPause;
    _androidSystemService.onHeadsetDoubleClick = skipNext;

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

    _bluetoothService.initialize();
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

  Stream<Duration> get positionStream => _audioPlayer.positionStream;

  double get progress {
    if (_duration.inMilliseconds == 0) return 0;
    return _position.inMilliseconds / _duration.inMilliseconds;
  }

  void _initializePlayer() {
    _audioPlayer.playerStateStream.listen((state) {
      final wasPlaying = _isPlaying;
      _isPlaying = state.playing;

      if (state.processingState == ProcessingState.completed) {
        _onSongComplete();
      }

      if (wasPlaying != _isPlaying) {
        notifyListeners();
        _updateAndroidAuto();
      }
    });

    Duration? lastNotified;
    _audioPlayer.positionStream.listen((position) {
      _position = position;
      if (lastNotified == null ||
          position.inMilliseconds - lastNotified!.inMilliseconds > 250) {
        lastNotified = position;
        notifyListeners();
      }
    });

    _audioPlayer.durationStream.listen((duration) {
      _duration = duration ?? Duration.zero;
      notifyListeners();
    });
  }

  void _onSongComplete() {
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
        }
        break;
    }
  }

  Future<void> playSong(
    Song song, {
    List<Song>? playlist,
    int? startIndex,
  }) async {
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
      await _audioPlayer.play();

      _subsonicService.scrobble(song.id, submission: false);
      _updateAndroidAuto();
    } catch (e) {
      debugPrint('Error playing song: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
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
  }

  Future<void> togglePlayPause() async {
    if (_isPlaying) {
      await pause();
    } else {
      await play();
    }
  }

  Future<void> seek(Duration position) async {
    await _audioPlayer.seek(position);
  }

  Future<void> seekToProgress(double progress) async {
    final position = Duration(
      milliseconds: (progress * _duration.inMilliseconds).round(),
    );
    await seek(position);
  }

  Future<void> skipNext() async {
    if (_currentIndex < _queue.length - 1) {
      await skipToIndex(_currentIndex + 1);
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
    notifyListeners();
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
    await _audioPlayer.setVolume(_volume);
    notifyListeners();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _androidAutoService.dispose();
    _androidSystemService.dispose();
    _bluetoothService.dispose();
    _samsungService.dispose();
    super.dispose();
  }
}