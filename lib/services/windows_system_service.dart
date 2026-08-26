import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:smtc_windows/smtc_windows.dart';
import 'package:windows_taskbar/windows_taskbar.dart';
import 'package:local_notifier/local_notifier.dart';
import '../models/song.dart';

class WindowsSystemService {
  static final WindowsSystemService _instance =
      WindowsSystemService._internal();
  factory WindowsSystemService() => _instance;
  WindowsSystemService._internal();

  SMTCWindows? _smtc;
  StreamSubscription<PressedButton>? _buttonPressSub;
  bool _isInitialized = false;
  LocalNotification? _lyricsNotification;
  bool _lyricsEnabled = false;
  Song? _currentSong;

  VoidCallback? onPlay;
  VoidCallback? onPause;
  VoidCallback? onStop;
  VoidCallback? onSkipNext;
  VoidCallback? onSkipPrevious;
  Function(Duration position)? onSeekTo;

  Future<void> initialize() async {
    if (!kIsWeb && Platform.isWindows) {
      if (_isInitialized) return;

      try {
        await SMTCWindows.initialize();

        _smtc = SMTCWindows(
          config: const SMTCConfig(
            playEnabled: true,
            pauseEnabled: true,
            stopEnabled: true,
            nextEnabled: true,
            prevEnabled: true,
            fastForwardEnabled: false,
            rewindEnabled: false,
          ),
        );

        _buttonPressSub?.cancel();
        _buttonPressSub = _smtc?.buttonPressStream.listen((event) {
          debugPrint('[Windows SMTC] Button pressed: $event');
          switch (event) {
            case PressedButton.play:
              onPlay?.call();
              break;
            case PressedButton.pause:
              onPause?.call();
              break;
            case PressedButton.next:
              onSkipNext?.call();
              break;
            case PressedButton.previous:
              onSkipPrevious?.call();
              break;
            case PressedButton.stop:
              onStop?.call();
              break;
            default:
              break;
          }
        });

        _isInitialized = true;

        await localNotifier.setup(
          appName: 'Musly',
          shortcutPolicy: ShortcutPolicy.requireNoCreate,
        );

        debugPrint(
            'WindowsSystemService initialized (SMTC, Taskbar & Lyrics Notification)');
      } catch (e) {
        debugPrint('Error initializing WindowsSystemService: $e');
      }
    }
  }

  Future<void> updatePlaybackState({
    required Song? song,
    required bool isPlaying,
    required Duration position,
    required Duration duration,
    String? artworkUrl,
  }) async {
    if (!kIsWeb && Platform.isWindows && _isInitialized) {
      try {
        await _smtc?.setPlaybackStatus(
          isPlaying ? PlaybackStatus.playing : PlaybackStatus.paused,
        );

        if (song != null) {
          await _smtc?.updateMetadata(
            MusicMetadata(
              title: song.title,
              artist: song.artist ?? 'Unknown Artist',
              album: song.album ?? 'Unknown Album',
              thumbnail: artworkUrl,
            ),
          );
        }

        if (duration.inMilliseconds > 0) {
          try {
            await _smtc?.updateTimeline(
              PlaybackTimeline(
                startTimeMs: 0,
                endTimeMs: duration.inMilliseconds,
                positionMs: position.inMilliseconds,
                minSeekTimeMs: 0,
                maxSeekTimeMs: duration.inMilliseconds,
              ),
            );
          } catch (_) {
            await _smtc?.setPosition(position);
          }

          WindowsTaskbar.setProgress(
            position.inMilliseconds,
            duration.inMilliseconds,
          );
          WindowsTaskbar.setProgressMode(
            isPlaying ? TaskbarProgressMode.normal : TaskbarProgressMode.paused,
          );
        } else {
          await _smtc?.setPosition(position);
          WindowsTaskbar.setProgressMode(TaskbarProgressMode.noProgress);
        }
      } catch (e) {
        debugPrint('Error updating Windows playback state: $e');
      }
    }
  }

  Future<void> updateSongInfo(Song? song) async {
    if (!kIsWeb && Platform.isWindows) {
      _currentSong = song;

      await clearLyrics();
    }
  }

  Future<void> updateLyrics(String? lyricsLine) async {
    if (!kIsWeb && Platform.isWindows && _lyricsEnabled) {
      if (lyricsLine == null || lyricsLine.isEmpty) {
        await clearLyrics();
        return;
      }

      try {
        await _lyricsNotification?.close();

        _lyricsNotification = LocalNotification(
          title: _currentSong?.title ?? 'Now Playing',
          body: lyricsLine,
          subtitle: _currentSong?.artist ?? 'Unknown Artist',
          silent: true,
        );

        await _lyricsNotification?.show();
        debugPrint('[Windows] Lyrics notification updated: $lyricsLine');
      } catch (e) {
        debugPrint('[Windows] Failed to update lyrics notification: $e');
      }
    }
  }

  Future<void> clearLyrics() async {
    if (!kIsWeb && Platform.isWindows) {
      try {
        await _lyricsNotification?.close();
        _lyricsNotification = null;
        debugPrint('[Windows] Lyrics notification cleared');
      } catch (e) {
        debugPrint('[Windows] Failed to clear lyrics notification: $e');
      }
    }
  }

  Future<void> setLyricsEnabled(bool enabled) async {
    _lyricsEnabled = enabled;
    if (!enabled) {
      await clearLyrics();
    }
    debugPrint('[Windows] Lyrics notifications enabled: $enabled');
  }

  bool get lyricsEnabled => _lyricsEnabled;

  Future<void> dispose() async {
    if (!kIsWeb && Platform.isWindows) {
      try {
        await clearLyrics();
        await WindowsTaskbar.setProgressMode(TaskbarProgressMode.noProgress);
        await _buttonPressSub?.cancel();
        _buttonPressSub = null;
        await _smtc?.dispose();
        _smtc = null;
      } catch (e) {
        debugPrint('WindowsSystemService dispose failed: $e');
      }
      _isInitialized = false;
    }
  }
}
