import 'dart:convert';

import 'package:flutter_chrome_cast/lib.dart';
import 'package:flutter_chrome_cast/models/android/android_media_information.dart';
import 'package:flutter_chrome_cast/models/android/extensions/cast_media_player_state.dart';
import 'package:flutter_chrome_cast/models/android/extensions/idle_reason.dart';
import 'package:flutter_chrome_cast/models/android/extensions/repeat_mode.dart';

class GoogleCastAndroidMediaStatus extends GoggleCastMediaStatus {
  GoogleCastAndroidMediaStatus({
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
  });
  factory GoogleCastAndroidMediaStatus.fromMap(Map<String, dynamic> map) {
    return GoogleCastAndroidMediaStatus(
      mediaSessionID: map['mediaSessionId']?.toInt() ?? 0,
      playerState: CastMediaPlayerStateAndroid.fromMap(map['playerState']),
      idleReason: map['idleReason'] != null
          ? GoogleCastIdleReasonAndroid.fromMap(map['idleReason'])
          : null,
      playbackRate: map['playbackRate'] ?? 1,
      mediaInformation: map['media'] != null
          ? GoogleCastMediaInformationAndroid.fromMap(
              Map<String, dynamic>.from(map['media']))
          : null,

      volume: map['volume']?['level'] ?? 0,
      isMuted: map['volume']?['muted'] ?? true,
      repeatMode: GoogleCastRepeatModeAndroid.fromMap(map['repeatMode']),
      currentItemId: map['currentItemId']?.toInt(),
      activeTrackIds:
          List<int>.from(jsonDecode(map['activeTrackIds'] ?? '[]') ?? []),

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
