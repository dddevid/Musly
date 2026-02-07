import 'dart:convert';

///Represents current status of break.
class GoogleCastBrakeStatus {
  ///ID of the current break clip.
  final String? breakClipId;

  ///ID of the current break.

  final String? breakId;

//Time in seconds elapsed after the current break clip starts.
//This member is only updated sporadically,
//so its value is often out of date. Use the
//getEstimatedBreakClipTime method to get an estimate of
//the real playback position based on the last
//information reported by the receiver.

  final Duration? currentBreakClipTime;

  ///Time in seconds elapsed after
  ///the current break starts. This member
  /// is only updated sporadically,
  /// so its value is often out of date.
  ///  Use the getEstimatedBreakTime
  /// method to get an estimate of
  /// the real playback position
  /// based on the last information
  ///  reported by the receiver.

  final Duration? currentBreakTime;

  /// The time in seconds when this break
  ///  clip becomes skippable. 5
  /// means that the end user can
  ///  skip this break clip after
  ///  5 seconds. If this field is
  ///  not defined, it means that
  ///  the current break clip is
  ///  not skippable.

  final Duration? whenSkippable;
  GoogleCastBrakeStatus({
    this.breakClipId,
    this.breakId,
    this.currentBreakClipTime,
    this.currentBreakTime,
    this.whenSkippable,
  });

  Map<String, dynamic> toMap() {
    return {
      'breakClipId': breakClipId,
      'breakId': breakId,
      'currentBreakClipTime': currentBreakClipTime?.inSeconds,
      'currentBreakTime': currentBreakTime?.inSeconds,
      'whenSkippable': whenSkippable?.inSeconds,
    };
  }

  factory GoogleCastBrakeStatus.fromMap(Map<String, dynamic> map) {
    return GoogleCastBrakeStatus(
      breakClipId: map['breakClipId'],
      breakId: map['breakId'],
      currentBreakClipTime: map['currentBreakClipTime'] != null
          ? Duration(seconds: map['currentBreakClipTime'].toInt())
          : null,
      currentBreakTime: map['currentBreakTime'] != null
          ? Duration(seconds: map['currentBreakTime'].toInt())
          : null,
      whenSkippable: map['whenSkippable'] != null
          ? Duration(seconds: map['whenSkippable'].toInt())
          : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory GoogleCastBrakeStatus.fromJson(String source) =>
      GoogleCastBrakeStatus.fromMap(json.decode(source));
}
