import 'package:flutter_chrome_cast/lib.dart';
import 'package:flutter_chrome_cast/models/android/extensions/date_time.dart';

class GoogleCastTvShowMediaMetadataAndroid
    extends GoogleCastTvShowMediaMetadata {
  GoogleCastTvShowMediaMetadataAndroid({
    super.episode,
    super.images,
    super.originalAirDate,
    super.season,
    super.seriesTitle,
  });

  factory GoogleCastTvShowMediaMetadataAndroid.fromMap(
      Map<String, dynamic> map) {
    return GoogleCastTvShowMediaMetadataAndroid(
      seriesTitle: map['seriesTitle'],
      season: map['season']?.toInt(),
      episode: map['episode']?.toInt(),
      images: map['images'] != null
          ? List<GoogleCastImage>.from(
              map['images']?.map((x) => GoogleCastImage.fromMap(x)))
          : null,
      originalAirDate: map['originalAirDate'] != null
          ? DateTimeString.tryParse(map['originalAirDate'])
          : null,
    );
  }
}
