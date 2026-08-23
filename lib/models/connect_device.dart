import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'song.dart';

/// Supported operation modes for Musly Connect peer compatibility matching.
enum ConnectMode {
  subsonic,
  jellyfin,
  webStream,
  local,
  unknown,
}

/// Represents a peer Musly device discovered on the local area network.
class ConnectDevice {
  final String id;
  final String name;
  final String platform; // android, ios, windows, macos, linux
  final String ip;
  final int port;
  final ConnectMode mode;
  final String serverHash; // Hash of current server URL (or 'web_stream' / 'local')
  final String? currentSongTitle;
  final String? currentSongArtist;
  final String? coverArt;
  final bool isPlaying;
  final double volume;
  final int positionSeconds;
  final int durationSeconds;
  final bool isPartyHost;
  final String? partyRoomName;
  final int partyGuestCount;
  final DateTime lastSeen;

  ConnectDevice({
    required this.id,
    required this.name,
    required this.platform,
    required this.ip,
    required this.port,
    required this.mode,
    required this.serverHash,
    this.currentSongTitle,
    this.currentSongArtist,
    this.coverArt,
    this.isPlaying = false,
    this.volume = 1.0,
    this.positionSeconds = 0,
    this.durationSeconds = 0,
    this.isPartyHost = false,
    this.partyRoomName,
    this.partyGuestCount = 0,
    DateTime? lastSeen,
  }) : lastSeen = lastSeen ?? DateTime.now();

  bool isCompatibleWith({required ConnectMode myMode, required String myServerHash}) {
    if (mode != myMode) return false;
    return serverHash == myServerHash;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'platform': platform,
        'ip': ip,
        'port': port,
        'mode': mode.name,
        'serverHash': serverHash,
        'currentSongTitle': currentSongTitle,
        'currentSongArtist': currentSongArtist,
        'coverArt': coverArt,
        'isPlaying': isPlaying,
        'volume': volume,
        'positionSeconds': positionSeconds,
        'durationSeconds': durationSeconds,
        'isPartyHost': isPartyHost,
        'partyRoomName': partyRoomName,
        'partyGuestCount': partyGuestCount,
      };

  factory ConnectDevice.fromJson(Map<String, dynamic> json, {String? overrideIp}) {
    ConnectMode parsedMode;
    try {
      parsedMode = ConnectMode.values.firstWhere(
        (m) => m.name == json['mode'],
        orElse: () => ConnectMode.unknown,
      );
    } catch (_) {
      parsedMode = ConnectMode.unknown;
    }

    return ConnectDevice(
      id: json['id'] as String? ?? 'unknown',
      name: json['name'] as String? ?? 'Musly Device',
      platform: json['platform'] as String? ?? 'mobile',
      ip: overrideIp ?? json['ip'] as String? ?? '127.0.0.1',
      port: json['port'] as int? ?? 43883,
      mode: parsedMode,
      serverHash: json['serverHash'] as String? ?? '',
      currentSongTitle: json['currentSongTitle'] as String?,
      currentSongArtist: json['currentSongArtist'] as String?,
      coverArt: json['coverArt'] as String?,
      isPlaying: json['isPlaying'] as bool? ?? false,
      volume: (json['volume'] as num?)?.toDouble() ?? 1.0,
      positionSeconds: json['positionSeconds'] as int? ?? 0,
      durationSeconds: json['durationSeconds'] as int? ?? 0,
      isPartyHost: json['isPartyHost'] as bool? ?? false,
      partyRoomName: json['partyRoomName'] as String?,
      partyGuestCount: json['partyGuestCount'] as int? ?? 0,
      lastSeen: DateTime.now(),
    );
  }

  ConnectDevice copyWith({
    String? name,
    String? platform,
    String? ip,
    int? port,
    ConnectMode? mode,
    String? serverHash,
    String? currentSongTitle,
    String? currentSongArtist,
    String? coverArt,
    bool? isPlaying,
    double? volume,
    int? positionSeconds,
    int? durationSeconds,
    bool? isPartyHost,
    String? partyRoomName,
    int? partyGuestCount,
    DateTime? lastSeen,
  }) {
    return ConnectDevice(
      id: id,
      name: name ?? this.name,
      platform: platform ?? this.platform,
      ip: ip ?? this.ip,
      port: port ?? this.port,
      mode: mode ?? this.mode,
      serverHash: serverHash ?? this.serverHash,
      currentSongTitle: currentSongTitle ?? this.currentSongTitle,
      currentSongArtist: currentSongArtist ?? this.currentSongArtist,
      coverArt: coverArt ?? this.coverArt,
      isPlaying: isPlaying ?? this.isPlaying,
      volume: volume ?? this.volume,
      positionSeconds: positionSeconds ?? this.positionSeconds,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      isPartyHost: isPartyHost ?? this.isPartyHost,
      partyRoomName: partyRoomName ?? this.partyRoomName,
      partyGuestCount: partyGuestCount ?? this.partyGuestCount,
      lastSeen: lastSeen ?? this.lastSeen,
    );
  }
}

/// Commands sent between Musly Connect devices.
enum ConnectCommandType {
  play,
  pause,
  togglePlayPause,
  next,
  previous,
  seek,
  setVolume,
  transferQueue,
  requestState,
  stateUpdate,
  // BeatSync [BETA] Commands
  ntpProbe,
  ntpResponse,
  beatSyncSchedulePlay,
  beatSyncSchedulePause,
  beatSyncHeartbeat,
  joinParty,
  leaveParty,
}

class ConnectMessage {
  final ConnectCommandType type;
  final Map<String, dynamic> payload;
  final String senderId;
  final int timestamp;

  ConnectMessage({
    required this.type,
    required this.payload,
    required this.senderId,
    int? timestamp,
  }) : timestamp = timestamp ?? DateTime.now().millisecondsSinceEpoch;

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'payload': payload,
        'senderId': senderId,
        'timestamp': timestamp,
      };

  factory ConnectMessage.fromJson(Map<String, dynamic> json) {
    final typeStr = json['type'] as String? ?? '';
    final type = ConnectCommandType.values.firstWhere(
      (e) => e.name == typeStr,
      orElse: () => ConnectCommandType.requestState,
    );

    return ConnectMessage(
      type: type,
      payload: (json['payload'] as Map<String, dynamic>?) ?? {},
      senderId: json['senderId'] as String? ?? '',
      timestamp: json['timestamp'] as int? ?? DateTime.now().millisecondsSinceEpoch,
    );
  }

  String serialize() => jsonEncode(toJson());

  static ConnectMessage? deserialize(String raw) {
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return ConnectMessage.fromJson(decoded);
    } catch (e) {
      debugPrint('[ConnectMessage] Deserialization error: $e');
      return null;
    }
  }
}
