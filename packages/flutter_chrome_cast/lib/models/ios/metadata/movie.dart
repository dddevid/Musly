import 'package:flutter_chrome_cast/common/image.dart';
import 'package:flutter_chrome_cast/entities/media_metadata/movie_media_metadata.dart';

class GoogleCastMovieMediaMetadataIOS extends GoogleCastMovieMediaMetadata {
  GoogleCastMovieMediaMetadataIOS({
    super.images,
    super.releaseDate,
    super.studio,
    super.subtitle,
    super.title,
  });

  factory GoogleCastMovieMediaMetadataIOS.fromMap(Map<String, dynamic> map) {
    return GoogleCastMovieMediaMetadataIOS(
      title: map['title'],
      subtitle: map['subtitle'],
      studio: map['studio'],
      images: map['images'] != null
          ? List<GoogleCastImage>.from(map['images']?.map(
              (x) => GoogleCastImage.fromMap(Map<String, dynamic>.from(x))))
          : null,
      releaseDate: map['releaseDate'] != null
          ? DateTime.fromMicrosecondsSinceEpoch(map['releaseDate'] ?? 0)
          : null,
    );
  }
}
