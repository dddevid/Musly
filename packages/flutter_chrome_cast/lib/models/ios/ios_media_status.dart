import 'package:flutter_chrome_cast/lib.dart';

class GoogleCastIOSMediaStatus extends GoggleCastMediaStatus {
  GoogleCastIOSMediaStatus({
    required super.mediaSessionID,
    required super.playerState,
    required super.playbackRate,
    required super.volume,
    required super.isMuted,
    required super.repeatMode,
    super.activeTrackIds,
    super.adBreakStatus,
    super.currentItemId,
    super.idleReason,
    super.liveSeekableRange,
    super.mediaInformation,
    // super.queueData,
  });

  factory GoogleCastIOSMediaStatus.fromMap(Map<String, dynamic> map) {
    return GoogleCastIOSMediaStatus(
      mediaSessionID: map['mediaSessionID']?.toInt() ?? 0,
      playerState: CastMediaPlayerState.values[map['playerState']],
      idleReason: map['idleReason'] != null
          ? GoogleCastMediaIdleReason.values[map['idleReason']]
          : null,
      playbackRate: map['playbackRate'] ?? 0,
      mediaInformation: map['mediaInformation'] != null
          ? GoogleCastMediaInformationIOS.fromMap(
              Map<String, dynamic>.from(map['mediaInformation']))
          : null,

      volume: map['volume'] ?? 0,
      isMuted: map['isMuted'] ?? true,
      repeatMode: GoogleCastMediaRepeatMode.values[(map['repeatMode'])],
      currentItemId: map['currentItemId']?.toInt(),

      activeTrackIds: List<int>.from(map['activeTrackIds'] ?? []),
      // adBreakStatus: map['adBreakStatus'] != null
      //     ? GoogleCastBrakeStatus.fromMap(map['adBreakStatus'])
      //     : null,
      // liveSeekableRange: map['liveSeekableRange'] != null
      //     ? GoogleCastMediaLiveSeekableRange.fromMap(map['liveSeekableRange'])
      //     : null,
      // queueData: map['queueData'] != null
      //     ? GoogleCastMediaQueueData.fromMap(map['queueData'])
      //     : null,
    );
  }
}
