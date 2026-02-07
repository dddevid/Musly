import 'package:flutter_chrome_cast/lib.dart';
import 'package:flutter_chrome_cast/models/android/extensions/date_time.dart';

class GoogleCastGenericMediaMetadataAndroid
    extends GoogleCastGenericMediaMetadata {
  GoogleCastGenericMediaMetadataAndroid({
    required super.title,
    required super.subtitle,
    required super.images,
    super.releaseDate,
  });
  factory GoogleCastGenericMediaMetadataAndroid.fromMap(
      Map<String, dynamic> map) {
    return GoogleCastGenericMediaMetadataAndroid(
      title: map['title'],
      subtitle: map['subtitle'],
      images: map['images'] != null
          ? List<GoogleCastImage>.from(
              map['images']?.map((x) => GoogleCastImage.fromMap(x)))
          : null,
      releaseDate: map['releaseDate'] != null
          ? DateTimeString.tryParse(map['releaseDate'] ?? '')
          : null,
    );
  }
}
