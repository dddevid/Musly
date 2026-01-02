import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:smtc_windows/smtc_windows.dart';
import 'package:windows_taskbar/windows_taskbar.dart';
import '../models/song.dart';

class WindowsSystemService {
  static final WindowsSystemService _instance = WindowsSystemService._internal();
  factory WindowsSystemService() => _instance;
  WindowsSystemService._internal();

  SMTCWindows? _smtc;
  bool _isInitialized = false;

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
        
        // smtc_windows 1.1.0 initialization
        _isInitialized = true;
        debugPrint('WindowsSystemService initialized (SMTC & Taskbar)');
        debugPrint('WindowsSystemService initialized (SMTC & Taskbar)');
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
        // SMTC Updates (Verified to compile)
        _smtc?.setPlaybackStatus(isPlaying ? PlaybackStatus.playing : PlaybackStatus.paused);

        if (song != null) {
          _smtc?.updateMetadata(MusicMetadata(
            title: song.title,
            artist: song.artist ?? 'Unknown Artist',
            album: song.album ?? 'Unknown Album',
            thumbnail: artworkUrl,
          ));
        }

        _smtc?.setPosition(position);

        // Taskbar Updates
        if (duration.inMilliseconds > 0) {
          WindowsTaskbar.setProgress(
            position.inMilliseconds,
            duration.inMilliseconds,
          );
          WindowsTaskbar.setProgressMode(
            isPlaying ? TaskbarProgressMode.normal : TaskbarProgressMode.paused,
          );
        } else {
          WindowsTaskbar.setProgressMode(TaskbarProgressMode.noProgress);
        }

      } catch (e) {
        debugPrint('Error updating Windows playback state: $e');
      }
    }
  }

  Future<void> dispose() async {
    if (!kIsWeb && Platform.isWindows) {
      WindowsTaskbar.setProgressMode(TaskbarProgressMode.noProgress);
      _isInitialized = false;
    }
  }
}