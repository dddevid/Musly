import 'package:flutter_chrome_cast/enums/media_resume_state.dart';

///Enum defining the media control channel resume state.
class GoogleCastMediaSeekOption {
  final Duration position;
  final bool relative;
  final GoogleCastMediaResumeState resumeState;
  final bool seekToInfinity;

  GoogleCastMediaSeekOption({
    required this.position,
    this.relative = false,
    this.resumeState = GoogleCastMediaResumeState.GCKMediaResumeStatePlay,
    this.seekToInfinity = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'position': position.inSeconds,
      'relative': relative,
      'resumeState': resumeState.index,
      'seekToInfinity': seekToInfinity,
    };
  }
}
