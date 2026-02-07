import 'package:flutter_chrome_cast/enums/repeat_mode.dart';

class GoogleCastQueueLoadOptions {
  final int startIndex;
  final Duration playPosition;
  final GoogleCastMediaRepeatMode repeatMode;
  final Map<String, dynamic>? customData;

  GoogleCastQueueLoadOptions({
    this.startIndex = 0,
    this.playPosition = Duration.zero,
    this.repeatMode = GoogleCastMediaRepeatMode.OFF,
    this.customData,
  });

  Map<String, dynamic> toMap() {
    return {
      'startIndex': startIndex,
      'playPosition': playPosition.inSeconds,
      'repeatMode': repeatMode.index,
      'customData': customData,
    };
  }
}
