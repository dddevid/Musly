import 'package:flutter_chrome_cast/lib.dart';

class GoogleCastTvShowMediaMetadataIOS extends GoogleCastTvShowMediaMetadata {
  GoogleCastTvShowMediaMetadataIOS({
    super.episode,
    super.images,
    super.originalAirDate,
    super.season,
    super.seriesTitle,
  });

  factory GoogleCastTvShowMediaMetadataIOS.fromMap(Map<String, dynamic> map) {
    return GoogleCastTvShowMediaMetadataIOS(
      seriesTitle: map['seriesTitle'],
      season: map['seasonNumber']?.toInt(),
      episode: map['episodeNumber']?.toInt(),
      images: map['images'] != null
          ? List<GoogleCastImage>.from(map['images']?.map(
              (x) => GoogleCastImage.fromMap(Map<String, dynamic>.from(x))))
          : null,
      originalAirDate: map['releaseDate'] != null
          ? DateTimeString.tryParse(map['releaseDate'])
          : null,
    );
  }
}
