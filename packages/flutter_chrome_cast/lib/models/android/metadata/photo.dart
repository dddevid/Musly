import 'package:flutter_chrome_cast/lib.dart';
import 'package:flutter_chrome_cast/models/android/extensions/date_time.dart';

class GooglCastPhotoMediaMetadataAndroid extends GoogleCastPhotoMediaMetadata {
  GooglCastPhotoMediaMetadataAndroid({
    super.artist,
    super.creationDateTime,
    super.height,
    super.latitude,
    super.location,
    super.longitude,
    super.title,
    super.width,
  });

  factory GooglCastPhotoMediaMetadataAndroid.fromMap(Map<String, dynamic> map) {
    return GooglCastPhotoMediaMetadataAndroid(
      title: map['title'],
      artist: map['artist'],
      location: map['location'],
      latitude: map['latitude']?.toDouble(),
      longitude: map['longitude']?.toDouble(),
      width: map['width']?.toInt(),
      height: map['height']?.toInt(),
      creationDateTime: map['creationDateTime'] != null
          ? DateTimeString.tryParse(map['creationDateTime'])
          : null,
    );
  }
}
