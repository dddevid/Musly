import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../models/song.dart';

class BluetoothDeviceInfo {
  final String address;
  final String name;
  final bool isConnected;
  final bool supportsAvrcp;
  final int avrcpVersion;
  final bool supportsAlbumArt;
  final bool supportsBrowsing;

  BluetoothDeviceInfo({
    required this.address,
    required this.name,
    required this.isConnected,
    required this.supportsAvrcp,
    required this.avrcpVersion,
    required this.supportsAlbumArt,
    required this.supportsBrowsing,
  });

  factory BluetoothDeviceInfo.fromMap(Map<String, dynamic> map) {
    return BluetoothDeviceInfo(
      address: map['address'] as String? ?? '',
      name: map['name'] as String? ?? 'Unknown Device',
      isConnected: map['isConnected'] as bool? ?? false,
      supportsAvrcp: map['supportsAvrcp'] as bool? ?? false,
      avrcpVersion: map['avrcpVersion'] as int? ?? 0,
      supportsAlbumArt: map['supportsAlbumArt'] as bool? ?? false,
      supportsBrowsing: map['supportsBrowsing'] as bool? ?? false,
    );
  }

  String get avrcpVersionString {
    switch (avrcpVersion) {
      case 10:
        return '1.0';
      case 13:
        return '1.3';
      case 14:
        return '1.4';
      case 15:
        return '1.5';
      case 16:
        return '1.6';
      default:
        return 'Unknown';
    }
  }

  @override
  String toString() {
    return 'BluetoothDeviceInfo(name: $name, address: $address, connected: $isConnected, '
        'avrcp: $supportsAvrcp v$avrcpVersionString, albumArt: $supportsAlbumArt)';
  }
}

class BluetoothAvrcpService {
  static final BluetoothAvrcpService _instance =
      BluetoothAvrcpService._internal();
  factory BluetoothAvrcpService() => _instance;
  BluetoothAvrcpService._internal();

  static const MethodChannel _methodChannel = MethodChannel(
    'com.devid.musly/bluetooth_avrcp',
  );
  static const EventChannel _eventChannel = EventChannel(
    'com.devid.musly/bluetooth_avrcp_events',
  );

  StreamSubscription? _eventSubscription;
  bool _isInitialized = false;

  final List<BluetoothDeviceInfo> _connectedDevices = [];

  Function(BluetoothDeviceInfo device)? onDeviceConnected;
  Function(BluetoothDeviceInfo device)? onDeviceDisconnected;
  VoidCallback? onPlay;
  VoidCallback? onPause;
  VoidCallback? onStop;
  VoidCallback? onSkipNext;
  VoidCallback? onSkipPrevious;
  Function(Duration position)? onSeekTo;
  Function(double volume)? onVolumeChange;

  List<BluetoothDeviceInfo> get connectedDevices =>
      List.unmodifiable(_connectedDevices);
  bool get hasConnectedDevices => _connectedDevices.isNotEmpty;
  bool get hasAvrcpDevice => _connectedDevices.any((d) => d.supportsAvrcp);
  bool get hasAlbumArtSupport =>
      _connectedDevices.any((d) => d.supportsAlbumArt);

  Future<void> initialize() async {
    if (defaultTargetPlatform != TargetPlatform.android) return;
    if (_isInitialized) return;

    try {
      _eventSubscription = _eventChannel.receiveBroadcastStream().listen(
        _handleEvent,
        onError: _handleError,
      );

      await _methodChannel.invokeMethod('initialize');

      await refreshConnectedDevices();

      _isInitialized = true;
      debugPrint('BluetoothAvrcpService initialized');
    } catch (e) {
      debugPrint('Error initializing BluetoothAvrcpService: $e');
    }
  }

  void _handleEvent(dynamic event) {
    if (event is! Map) return;

    final eventType = event['event'] as String?;
    debugPrint('Bluetooth AVRCP event received: $eventType');

    switch (eventType) {
      case 'deviceConnected':
        final deviceMap = event['device'] as Map?;
        if (deviceMap != null) {
          final device = BluetoothDeviceInfo.fromMap(
            Map<String, dynamic>.from(deviceMap),
          );
          _connectedDevices.removeWhere((d) => d.address == device.address);
          _connectedDevices.add(device);
          onDeviceConnected?.call(device);
        }
        break;
      case 'deviceDisconnected':
        final deviceMap = event['device'] as Map?;
        if (deviceMap != null) {
          final device = BluetoothDeviceInfo.fromMap(
            Map<String, dynamic>.from(deviceMap),
          );
          _connectedDevices.removeWhere((d) => d.address == device.address);
          onDeviceDisconnected?.call(device);
        }
        break;
      case 'play':
        onPlay?.call();
        break;
      case 'pause':
        onPause?.call();
        break;
      case 'stop':
        onStop?.call();
        break;
      case 'skipNext':
        onSkipNext?.call();
        break;
      case 'skipPrevious':
        onSkipPrevious?.call();
        break;
      case 'seekTo':
        final position = event['position'] as int?;
        if (position != null) {
          onSeekTo?.call(Duration(milliseconds: position));
        }
        break;
      case 'volumeChange':
        final volume = event['volume'] as double?;
        if (volume != null) {
          onVolumeChange?.call(volume);
        }
        break;
    }
  }

  void _handleError(dynamic error) {
    debugPrint('Bluetooth AVRCP event error: $error');
  }

  Future<void> refreshConnectedDevices() async {
    if (defaultTargetPlatform != TargetPlatform.android) return;

    try {
      final result = await _methodChannel.invokeMethod<List>(
        'getConnectedDevices',
      );
      _connectedDevices.clear();
      if (result != null) {
        for (final deviceMap in result) {
          if (deviceMap is Map) {
            _connectedDevices.add(
              BluetoothDeviceInfo.fromMap(Map<String, dynamic>.from(deviceMap)),
            );
          }
        }
      }
      debugPrint('Connected Bluetooth devices: $_connectedDevices');
    } catch (e) {
      debugPrint('Error getting connected Bluetooth devices: $e');
    }
  }

  Future<void> updatePlaybackState({
    required String? songId,
    required String title,
    required String artist,
    required String album,
    String? artworkUrl,
    required Duration duration,
    required Duration position,
    required bool isPlaying,
    int? trackNumber,
    int? totalTracks,
    String? genre,
    int? year,
  }) async {
    if (defaultTargetPlatform != TargetPlatform.android) return;

    try {
      await _methodChannel.invokeMethod('updatePlaybackState', {
        'songId': songId,
        'title': title,
        'artist': artist,
        'album': album,
        'artworkUrl': artworkUrl,
        'duration': duration.inMilliseconds,
        'position': position.inMilliseconds,
        'playing': isPlaying,
        'trackNumber': trackNumber,
        'totalTracks': totalTracks,
        'genre': genre,
        'year': year,
      });
    } catch (e) {
      debugPrint('Error updating Bluetooth AVRCP playback state: $e');
    }
  }

  Future<void> updateFromSong({
    required Song song,
    required String? artworkUrl,
    required Duration duration,
    required Duration position,
    required bool isPlaying,
    int? currentIndex,
    int? queueLength,
  }) async {
    await updatePlaybackState(
      songId: song.id,
      title: song.title,
      artist: song.artist ?? 'Unknown Artist',
      album: song.album ?? 'Unknown Album',
      artworkUrl: artworkUrl,
      duration: duration,
      position: position,
      isPlaying: isPlaying,
      trackNumber: currentIndex != null ? currentIndex + 1 : song.track,
      totalTracks: queueLength,
      genre: song.genre,
      year: song.year,
    );
  }

  Future<void> updateAlbumArt({
    required String? artworkUrl,
    Uint8List? imageBytes,
  }) async {
    if (defaultTargetPlatform != TargetPlatform.android) return;
    if (!hasAlbumArtSupport) return;

    try {
      await _methodChannel.invokeMethod('updateAlbumArt', {
        'artworkUrl': artworkUrl,
        'imageBytes': imageBytes,
      });
    } catch (e) {
      debugPrint('Error updating Bluetooth album art: $e');
    }
  }

  Future<void> updatePosition(Duration position) async {
    if (defaultTargetPlatform != TargetPlatform.android) return;

    try {
      await _methodChannel.invokeMethod('updatePosition', {
        'position': position.inMilliseconds,
      });
    } catch (e) {
      debugPrint('Error updating Bluetooth position: $e');
    }
  }

  Future<bool> registerAbsoluteVolumeControl() async {
    if (defaultTargetPlatform != TargetPlatform.android) return false;

    try {
      final result = await _methodChannel.invokeMethod<bool>(
        'registerAbsoluteVolumeControl',
      );
      return result ?? false;
    } catch (e) {
      debugPrint('Error registering absolute volume control: $e');
      return false;
    }
  }

  Future<void> setBluetoothVolume(double volume) async {
    if (defaultTargetPlatform != TargetPlatform.android) return;

    try {
      await _methodChannel.invokeMethod('setVolume', {
        'volume': volume.clamp(0.0, 1.0),
      });
    } catch (e) {
      debugPrint('Error setting Bluetooth volume: $e');
    }
  }

  Future<bool> isA2dpConnected() async {
    if (defaultTargetPlatform != TargetPlatform.android) return false;

    try {
      final result = await _methodChannel.invokeMethod<bool>('isA2dpConnected');
      return result ?? false;
    } catch (e) {
      debugPrint('Error checking A2DP connection: $e');
      return false;
    }
  }

  Future<void> dispose() async {
    if (defaultTargetPlatform != TargetPlatform.android) return;

    _eventSubscription?.cancel();
    _connectedDevices.clear();
    _isInitialized = false;
    try {
      await _methodChannel.invokeMethod('dispose');
    } catch (e) {
      debugPrint('Error disposing BluetoothAvrcpService: $e');
    }
  }
}
