import 'dart:convert';
import 'package:flutter/foundation.dart';

import 'song.dart';

enum ConnectMode {
  subsonic,
  jellyfin,
  webStream,
  local,
  unknown,
}

class ConnectDevice {
  final String id;
  final String name;
  final String platform;
  final String ip;
  final int port;
  final ConnectMode mode;
  final String serverHash;
  final Song? currentSong;
  final String? currentSongTitle;
  final String? currentSongArtist;
  final String? coverArt;
  final bool isPlaying;
  final double volume;
  final int positionSeconds;
  final int durationSeconds;
  final bool shuffleEnabled;
  final int repeatModeIndex;
  final int currentIndex;
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
    this.currentSong,
    this.currentSongTitle,
    this.currentSongArtist,
    this.coverArt,
    this.isPlaying = false,
    this.volume = 1.0,
    this.positionSeconds = 0,
    this.durationSeconds = 0,
    this.shuffleEnabled = false,
    this.repeatModeIndex = 0,
    this.currentIndex = -1,
    this.isPartyHost = false,
    this.partyRoomName,
    this.partyGuestCount = 0,
    DateTime? lastSeen,
  }) : lastSeen = lastSeen ?? DateTime.now();

  bool isCompatibleWith({
    required ConnectMode myMode,
    required String myServerHash,
  }) {
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
        'currentSong': currentSong?.toJson(),
        'currentSongTitle': currentSongTitle ?? currentSong?.title,
        'currentSongArtist': currentSongArtist ?? currentSong?.artist,
        'coverArt': coverArt ?? currentSong?.coverArt,
        'isPlaying': isPlaying,
        'volume': volume,
        'positionSeconds': positionSeconds,
        'durationSeconds': durationSeconds,
        'shuffleEnabled': shuffleEnabled,
        'repeatModeIndex': repeatModeIndex,
        'currentIndex': currentIndex,
        'isPartyHost': isPartyHost,
        'partyRoomName': partyRoomName,
        'partyGuestCount': partyGuestCount,
      };

  factory ConnectDevice.fromJson(
    Map<String, dynamic> json, {
    String? overrideIp,
  }) {
    ConnectMode parsedMode;
    try {
      parsedMode = ConnectMode.values.firstWhere(
        (m) => m.name == json['mode'],
        orElse: () => ConnectMode.unknown,
      );
    } catch (_) {
      parsedMode = ConnectMode.unknown;
    }

    final songMap = json['currentSong'] as Map<String, dynamic>?;
    final parsedSong = songMap != null ? Song.fromJson(songMap) : null;

    return ConnectDevice(
      id: json['id'] as String? ?? 'unknown',
      name: json['name'] as String? ?? 'Musly Device',
      platform: json['platform'] as String? ?? 'mobile',
      ip: overrideIp ?? json['ip'] as String? ?? '127.0.0.1',
      port: json['port'] as int? ?? 43883,
      mode: parsedMode,
      serverHash: json['serverHash'] as String? ?? '',
      currentSong: parsedSong,
      currentSongTitle:
          (json['currentSongTitle'] as String?) ?? parsedSong?.title,
      currentSongArtist:
          (json['currentSongArtist'] as String?) ?? parsedSong?.artist,
      coverArt: (json['coverArt'] as String?) ?? parsedSong?.coverArt,
      isPlaying: json['isPlaying'] as bool? ?? false,
      volume: (json['volume'] as num?)?.toDouble() ?? 1.0,
      positionSeconds: json['positionSeconds'] as int? ?? 0,
      durationSeconds: json['durationSeconds'] as int? ?? 0,
      shuffleEnabled: json['shuffleEnabled'] as bool? ?? false,
      repeatModeIndex: json['repeatModeIndex'] as int? ?? 0,
      currentIndex: json['currentIndex'] as int? ?? -1,
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
    Song? currentSong,
    String? currentSongTitle,
    String? currentSongArtist,
    String? coverArt,
    bool? isPlaying,
    double? volume,
    int? positionSeconds,
    int? durationSeconds,
    bool? shuffleEnabled,
    int? repeatModeIndex,
    int? currentIndex,
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
      currentSong: currentSong ?? this.currentSong,
      currentSongTitle: currentSongTitle ?? this.currentSongTitle,
      currentSongArtist: currentSongArtist ?? this.currentSongArtist,
      coverArt: coverArt ?? this.coverArt,
      isPlaying: isPlaying ?? this.isPlaying,
      volume: volume ?? this.volume,
      positionSeconds: positionSeconds ?? this.positionSeconds,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      shuffleEnabled: shuffleEnabled ?? this.shuffleEnabled,
      repeatModeIndex: repeatModeIndex ?? this.repeatModeIndex,
      currentIndex: currentIndex ?? this.currentIndex,
      isPartyHost: isPartyHost ?? this.isPartyHost,
      partyRoomName: partyRoomName ?? this.partyRoomName,
      partyGuestCount: partyGuestCount ?? this.partyGuestCount,
      lastSeen: lastSeen ?? this.lastSeen,
    );
  }
}

enum ConnectCommandType {
  play,
  pause,
  togglePlayPause,
  next,
  previous,
  seek,
  setVolume,
  toggleShuffle,
  setRepeatMode,
  transferQueue,
  requestState,
  stateUpdate,
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
      timestamp:
          json['timestamp'] as int? ?? DateTime.now().millisecondsSinceEpoch,
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
