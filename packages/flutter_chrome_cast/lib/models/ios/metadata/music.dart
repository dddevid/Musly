import 'package:flutter_chrome_cast/common/image.dart';
import 'package:flutter_chrome_cast/entities/media_metadata/music_track_media_metadata.dart';

class GoogleCastMusicMediaMetadataIOS extends GoogleCastMusicMediaMetadata {
  GoogleCastMusicMediaMetadataIOS({
    super.albumArtist,
    super.albumName,
    super.artist,
    super.composer,
    super.discNumber,
    super.images,
    super.releaseDate,
    super.title,
    super.trackNumber,
  });

  factory GoogleCastMusicMediaMetadataIOS.fromMap(Map<String, dynamic> map) {
    return GoogleCastMusicMediaMetadataIOS(
      albumName: map['albumTitle'],
      title: map['title'],
      albumArtist: map['albumArtist'],
      artist: map['artist'],
      composer: map['composer'],
      trackNumber: map['trackNumber']?.toInt(),
      discNumber: map['discNumber']?.toInt(),
      images: map['images'] != null
          ? List<GoogleCastImage>.from(map['images']?.map(
              (x) => GoogleCastImage.fromMap(Map<String, dynamic>.from(x))))
          : null,
      releaseDate: map['releaseDate'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['releaseDate'] ?? 0)
          : null,
    );
  }
}
