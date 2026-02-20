import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/song.dart';
import 'subsonic_service.dart';

class JukeboxStatus {
  final bool playing;
  final int currentIndex;
  final double gain;
  final Duration position;
  final List<Song> playlist;

  JukeboxStatus({
    required this.playing,
    required this.currentIndex,
    required this.gain,
    required this.position,
    required this.playlist,
  });

  static JukeboxStatus empty() => JukeboxStatus(
    playing: false,
    currentIndex: 0,
    gain: 1.0,
    position: Duration.zero,
    playlist: [],
  );

  Song? get currentSong => playlist.isNotEmpty && currentIndex < playlist.length
      ? playlist[currentIndex]
      : null;
}

/// Manages Navidrome/Subsonic jukebox mode.
///
/// Jukebox mode routes audio playback to the server instead of the local device.
/// The client acts as a remote control.
class JukeboxService extends ChangeNotifier {
  static final JukeboxService _instance = JukeboxService._internal();
  factory JukeboxService() => _instance;
  JukeboxService._internal();

  static const _enabledKey = 'jukebox_mode_enabled';

  bool _enabled = false;
  JukeboxStatus _status = JukeboxStatus.empty();
  bool _isLoading = false;
  String? _error;
  bool _serverUnsupported = false;

  bool get enabled => _enabled;
  JukeboxStatus get status => _status;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get serverUnsupported => _serverUnsupported;

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _enabled = prefs.getBool(_enabledKey) ?? false;
    notifyListeners();
  }

  Future<void> setEnabled(bool value) async {
    _enabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, value);
    notifyListeners();
  }

  Future<void> refresh(SubsonicService subsonic) async {
    if (!_enabled) return;
    _isLoading = true;
    notifyListeners();
    try {
      final data = await subsonic.jukeboxGet();
      _status = _parseStatus(data);
      _error = null;
      _serverUnsupported = false;
    } catch (e) {
      debugPrint('Jukebox refresh error: $e');
      final msg = e.toString();
      if (msg.contains('501')) {
        _serverUnsupported = true;
        _error = null; // use the localised string in the UI
      } else {
        _error = msg.replaceFirst('Exception: ', '');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> play(SubsonicService subsonic) async {
    await _command(() => subsonic.jukeboxStart(), subsonic);
  }

  Future<void> pause(SubsonicService subsonic) async {
    await _command(() => subsonic.jukeboxStop(), subsonic);
  }

  Future<void> skip(SubsonicService subsonic, int index) async {
    await _command(() => subsonic.jukeboxSkip(index), subsonic);
  }

  Future<void> skipNext(SubsonicService subsonic) async {
    final next = (_status.currentIndex + 1).clamp(
      0,
      (_status.playlist.length - 1).clamp(0, double.maxFinite.toInt()),
    );
    await skip(subsonic, next);
  }

  Future<void> skipPrevious(SubsonicService subsonic) async {
    final prev = (_status.currentIndex - 1).clamp(0, double.maxFinite.toInt());
    await skip(subsonic, prev);
  }

  Future<void> setQueue(
    SubsonicService subsonic,
    List<Song> songs, {
    int startIndex = 0,
  }) async {
    if (songs.isEmpty) return;
    _isLoading = true;
    notifyListeners();
    try {
      final ids = songs.map((s) => s.id).toList();
      await subsonic.jukeboxSet(ids);
      await subsonic.jukeboxSkip(startIndex);
      await subsonic.jukeboxStart();
    } catch (e) {
      debugPrint('Jukebox setQueue error: $e');
    } finally {
      await refresh(subsonic);
    }
  }

  Future<void> addToQueue(SubsonicService subsonic, List<Song> songs) async {
    if (songs.isEmpty) return;
    final ids = songs.map((s) => s.id).toList();
    await _command(() => subsonic.jukeboxAdd(ids), subsonic);
  }

  Future<void> clearQueue(SubsonicService subsonic) async {
    await _command(() => subsonic.jukeboxClear(), subsonic);
  }

  Future<void> shuffleQueue(SubsonicService subsonic) async {
    await _command(() => subsonic.jukeboxShuffle(), subsonic);
  }

  Future<void> removeFromQueue(SubsonicService subsonic, int index) async {
    await _command(() => subsonic.jukeboxRemove(index), subsonic);
  }

  Future<void> setGain(SubsonicService subsonic, double gain) async {
    await _command(
      () => subsonic.jukeboxSetGain(gain.clamp(0.0, 1.0)),
      subsonic,
    );
  }

  Future<void> _command(
    Future<Map<String, dynamic>> Function() fn,
    SubsonicService subsonic,
  ) async {
    _isLoading = true;
    notifyListeners();
    try {
      final data = await fn();
      _status = _parseStatus(data);
      _error = null;
      _serverUnsupported = false;
    } catch (e) {
      debugPrint('Jukebox command error: $e');
      final msg = e.toString();
      if (msg.contains('501')) {
        _serverUnsupported = true;
        _error = null;
      } else {
        _error = msg.replaceFirst('Exception: ', '');
      }
      await refresh(subsonic);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  JukeboxStatus _parseStatus(Map<String, dynamic> data) {
    final playing = data['playing'] == true;
    final currentIndex = (data['currentIndex'] as int?) ?? 0;
    final gainRaw = data['gain'];
    final gain = gainRaw is num ? gainRaw.toDouble() : 1.0;
    final positionSecs = (data['position'] as int?) ?? 0;
    final position = Duration(seconds: positionSecs);

    final entriesRaw = data['entry'];
    final List<Song> playlist = [];
    if (entriesRaw is List) {
      for (final e in entriesRaw) {
        if (e is Map<String, dynamic>) {
          playlist.add(Song.fromJson(e));
        }
      }
    }

    return JukeboxStatus(
      playing: playing,
      currentIndex: currentIndex,
      gain: gain,
      position: position,
      playlist: playlist,
    );
  }
}
