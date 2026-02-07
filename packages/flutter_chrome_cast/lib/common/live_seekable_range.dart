import 'dart:convert';

///Provides the live seekable range with start and end time in seconds.
class GoogleCastMediaLiveSeekableRange {
  ///End of the seekable range in seconds.
  /// This member is only updated sporadically,
  /// so its value is often out of date. Use
  ///  the getEstimatedLiveSeekableRange method
  ///  to get an estimate of the real position
  /// based on the last information reported
  /// by the receiver.
  final Duration? end;

  ///A boolean value indicates whether
  ///a live stream is ended. If it
  ///is done, the end of live seekable
  /// range should stop updating.
  final bool? isLiveDone;

  ///A boolean value indicates whether
  /// the live seekable range is a moving window.
  ///  If false, it will be either a expanding
  ///  range or a fixed range meaning live has ended.
  final bool? isMovingWindow;

  ///Start of the seekable range in seconds.
  ///This member is only updated sporadically,
  /// so its value is often out of date. Use
  /// the getEstimatedLiveSeekableRange method
  /// to get an estimate of the real position
  ///  based on the last information reported
  ///  by the receiver.
  final Duration? start;
  GoogleCastMediaLiveSeekableRange({
    this.end,
    this.isLiveDone,
    this.isMovingWindow,
    this.start,
  });

  Map<String, dynamic> toMap() {
    return {
      'end': end?.inSeconds,
      'isLiveDone': isLiveDone,
      'isMovingWindow': isMovingWindow,
      'start': start?.inSeconds,
    };
  }

  factory GoogleCastMediaLiveSeekableRange.fromMap(Map<String, dynamic> map) {
    return GoogleCastMediaLiveSeekableRange(
      end: map['end'] != null ? Duration(seconds: map['end'].toInt()) : null,
      isLiveDone: map['isLiveDone'],
      isMovingWindow: map['isMovingWindow'],
      start:
          map['start'] != null ? Duration(seconds: map['start'].toInt()) : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory GoogleCastMediaLiveSeekableRange.fromJson(String source) =>
      GoogleCastMediaLiveSeekableRange.fromMap(json.decode(source));
}
