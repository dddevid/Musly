import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:live_activities/live_activities.dart';

import 'lyrics_manager.dart';
import 'windows_system_service.dart';

/// Service for managing synchronized lyrics on the lock screen
/// Handles iOS Live Activities and Android Media Notification updates
class LockScreenLyricsService {
  static const _platform = MethodChannel('com.devid.musly/lyrics');
  static const _eventChannel = EventChannel('com.devid.musly/lyrics_updates');

  final LiveActivities _liveActivities = LiveActivities();
  String? _activityId;

  LyricsManager? _currentLyrics;
  StreamSubscription<Duration>? _positionSubscription;
  String? _lastSentLine;
  Timer? _updateTimer;
  StreamSubscription? _eventSubscription;
  final WindowsSystemService _windowsService = WindowsSystemService();

  // Throttling configuration
  static const _updateInterval = Duration(milliseconds: 500);

  /// Whether Live Activities (iOS 16.1+) or Android RemoteViews are supported
  bool get supportsLiveActivities => !kIsWeb && (Platform.isIOS || Platform.isAndroid);

  /// Whether Windows notification lyrics are supported
  bool get supportsWindowsNotification => !kIsWeb && Platform.isWindows;

  /// Initialize the service
  Future<void> initialize() async {
    if (kIsWeb) {
      debugPrint('[Lyrics] Web platform - lyrics disabled');
      return;
    }

    debugPrint('[Lyrics] Initializing lock screen lyrics service...');
    debugPrint('[Lyrics] Platform: ${Platform.operatingSystem}');
    debugPrint('[Lyrics] Live Activities supported: $supportsLiveActivities');
    debugPrint('[Lyrics] Windows notification supported: $supportsWindowsNotification');

    // Initialize live_activities for iOS and Android
    if (supportsLiveActivities) {
      try {
        await _liveActivities.init(appGroupId: 'group.com.dddevid.musly');
        debugPrint('[Lyrics] LiveActivities initialized');
      } catch (e) {
        debugPrint('[Lyrics] Failed to initialize LiveActivities: $e');
      }
    }

    _eventSubscription = _eventChannel.receiveBroadcastStream().listen(
      (dynamic event) {
        debugPrint('[Lyrics] Native event: $event');
      },
      onError: (dynamic error) {
        debugPrint('[Lyrics] Native error: $error');
      },
    );
  }

  /// Load lyrics for the current song
  Future<void> loadLyrics(String? lrcContent) async {
    if (lrcContent == null || lrcContent.isEmpty) {
      _currentLyrics = null;
      await _clearLyrics();
      return;
    }

    _currentLyrics = LyricsManager.parse(lrcContent);
    _lastSentLine = null;

    // Create Live Activity when lyrics are available (iOS/Android)
    if (supportsLiveActivities && _currentLyrics!.hasLyrics) {
      try {
        final songId = 'lyrics_${DateTime.now().millisecondsSinceEpoch}';
        _activityId = await _liveActivities.createActivity(
          songId,
          {
            'currentLine': '',
            'songTitle': '',
            'artist': '',
          },
        );
        debugPrint('[Lyrics] Live Activity created: $_activityId');
      } catch (e) {
        debugPrint('[Lyrics] Failed to create Live Activity: $e');
      }
    }
  }

  /// Clear current lyrics
  Future<void> _clearLyrics() async {
    _currentLyrics = null;
    _lastSentLine = null;
    _updateTimer?.cancel();
    _updateTimer = null;

    // End Live Activity (iOS/Android)
    if (supportsLiveActivities && _activityId != null) {
      try {
        await _liveActivities.endActivity(_activityId!);
        _activityId = null;
        debugPrint('[Lyrics] Live Activity ended');
      } catch (e) {
        debugPrint('[Lyrics] Failed to end Live Activity: $e');
      }
    }

    // Clear Windows notification
    if (supportsWindowsNotification) {
      await _windowsService.clearLyrics();
    }
  }

  /// Start synchronizing lyrics to position updates
  /// Call this when a song starts playing
  void startSync(Stream<Duration> positionStream) {
    debugPrint('[Lyrics] Starting lyrics sync...');
    _positionSubscription?.cancel();
    _updateTimer?.cancel();

    if (_currentLyrics == null || !_currentLyrics!.hasLyrics) {
      debugPrint('[Lyrics] No lyrics to sync');
      return;
    }
    
    debugPrint('[Lyrics] Lyrics loaded: ${_currentLyrics!.lineCount} lines');

    // Use a timer-based approach for more control over update frequency
    DateTime? lastUpdate;
    String? lastLine;

    _positionSubscription = positionStream.listen(
      (position) {
        final now = DateTime.now();
        
        // Throttle updates
        if (lastUpdate != null && 
            now.difference(lastUpdate!) < _updateInterval) {
          return;
        }

        final currentLine = _currentLyrics!.getCurrentLine(position);
        
        // Only send if line changed
        if (currentLine != lastLine && currentLine != null) {
          lastUpdate = now;
          lastLine = currentLine;
          debugPrint('[Lyrics] Line changed: "$currentLine"');
          _updateLockScreenLyrics(currentLine);
        }
      },
      onError: (error) {
        debugPrint('Position stream error in lyrics sync: $error');
      },
    );
  }

  /// Stop synchronization
  void stopSync() {
    _positionSubscription?.cancel();
    _positionSubscription = null;
    _updateTimer?.cancel();
    _updateTimer = null;
  }

  /// Update the lock screen with current lyrics
  Future<void> _updateLockScreenLyrics(String line) async {
    if (line == _lastSentLine) return;
    _lastSentLine = line;

    // Update Live Activity (iOS/Android)
    if (supportsLiveActivities && _activityId != null) {
      try {
        await _liveActivities.updateActivity(_activityId!, {
          'currentLine': line,
        });
        debugPrint('[Lyrics] Live Activity updated: "$line"');
      } catch (e) {
        debugPrint('[Lyrics] Failed to update Live Activity: $e');
      }
      return;
    }

    // Update Windows notification lyrics
    if (supportsWindowsNotification) {
      await _windowsService.updateLyrics(line);
    }
  }

  /// Update song info for Live Activity (iOS) and Windows
  Future<void> updateSongInfo({
    required String title,
    required String artist,
    String? artworkUrl,
  }) async {
    if (kIsWeb) return;

    debugPrint('[Lyrics] Updating song info: $title - $artist');

    // Update Live Activity with song info (iOS/Android)
    if (supportsLiveActivities && _activityId != null) {
      try {
        await _liveActivities.updateActivity(_activityId!, {
          'songTitle': title,
          'artist': artist,
          'artworkUrl': artworkUrl ?? '',
        });
      } catch (e) {
        debugPrint('[Lyrics] Failed to update song info in Live Activity: $e');
      }
      return;
    }

    // Update Windows service with current song info
    if (supportsWindowsNotification) {
      // We don't have Song object here, so just pass basic info
      // The song info will be updated when loadLyrics is called
    }
  }

  /// Clear all lyrics displays
  Future<void> clearAllLyrics() async {
    if (kIsWeb) return;

    // Clear Windows notification lyrics
    if (supportsWindowsNotification) {
      await _windowsService.clearLyrics();
    }

    // Clear native lyrics (Android/iOS)
    try {
      await _platform.invokeMethod('clearLyrics');
    } catch (e) {
      debugPrint('[Lyrics] Failed to clear native lyrics: $e');
    }

    _lastSentLine = null;
  }

  /// Update lyrics for Android media notification
  /// This should be called from your audio handler when updating media item
  Future<String?> getNotificationSubtitle(Duration position) async {
    if (_currentLyrics == null || !_currentLyrics!.hasLyrics) {
      return null;
    }

    return _currentLyrics!.getCurrentLine(position);
  }

  /// Get current lyrics line for display
  String? getCurrentLine(Duration position) {
    return _currentLyrics?.getCurrentLine(position);
  }

  /// Get lyrics context (previous, current, next) for rich UI display
  LyricsContext? getLyricsContext(Duration position) {
    return _currentLyrics?.getContext(position);
  }

  /// Public stream for in-app UI display
  /// More frequent updates than lock screen (100ms vs 500ms)
  Stream<String?> getLyricsStream(Stream<Duration> positionStream) {
    if (_currentLyrics == null || !_currentLyrics!.hasLyrics) {
      return const Stream.empty();
    }
    
    return positionStream
      .asyncMap((position) async => _currentLyrics!.getCurrentLine(position))
      .distinct();
  }

  /// Dispose the service
  void dispose() {
    _eventSubscription?.cancel();
    _eventSubscription = null;
    stopSync();
    _clearLyrics();
  }
}
