import 'package:flutter_chrome_cast/lib.dart';

class GoogleCastQueueItemIOS extends GoogleCastQueueItem {
  GoogleCastQueueItemIOS({
    required super.mediaInformation,
    super.activeTrackIds,
    super.autoPlay,
    super.customData,
    super.itemId,
    super.playbackDuration,
    super.preLoadTime,
    super.startTime,
  });

  factory GoogleCastQueueItemIOS.fromMap(Map<String, dynamic> map) {
    return GoogleCastQueueItemIOS(
      mediaInformation: GoogleCastMediaInformationIOS.fromMap(
          Map<String, dynamic>.from(map['mediaInformation'])),
      activeTrackIds: List.from(map['activeTracksIds'] ?? []),
      autoPlay: map['autoPlay'] ?? false,
      customData: map['customData'],
      itemId: map['itemId'],
      playbackDuration: map['playbackDuration'] == null
          ? null
          : Duration(seconds: map['playbackDuration']),
      preLoadTime: Duration(seconds: map['preLoadTime'] ?? 0),
      startTime: Duration(seconds: map['startTime'] ?? 0),
    );
  }
}
