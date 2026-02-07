import 'package:flutter_chrome_cast/lib.dart';

class IosMediaTrack extends GoogleCastMediaTrack {
  IosMediaTrack({
    required super.trackContentType,
    required super.trackId,
    required super.type,
    super.customData,
    super.language,
    super.name,
    super.subtype,
    super.trackContentId,
  });

  factory IosMediaTrack.fromMap(Map json) {
    return IosMediaTrack(
      trackContentType: json['content_type'],
      trackId: json['id'],
      type: TrackType.values[json['type']],
      language: RFC5646_LANGUAGE.fromMap(json['language_code']),
      name: json['name'],
      subtype: json['subtype'] != null
          ? TextTrackType.values[json['subtype']]
          : null,
      trackContentId: json['content_id'],
      customData: json['custom_data'],
    );
  }
}
