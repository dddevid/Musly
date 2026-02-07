import 'package:flutter_chrome_cast/lib.dart';

extension GoogleCastMediaMetadataExtensions on GoogleCastMediaMetadata {
  String? get extractedTitle {
    final type = metadataType;
    String? title;
    final metadata = this;

    switch (type) {
      case GoogleCastMediaMetadataType.tvShowMediaMetadata:
        metadata as GoogleCastTvShowMediaMetadata;
        title = metadata.seriesTitle;
        break;
      case GoogleCastMediaMetadataType.genericMediaMetadata:
        metadata as GoogleCastGenericMediaMetadata;
        title = metadata.title;
        break;
      case GoogleCastMediaMetadataType.movieMediaMetadata:
        metadata as GoogleCastMovieMediaMetadata;
        title = metadata.title;
        break;
      case GoogleCastMediaMetadataType.musicTrackMediaMetadata:
        metadata as GoogleCastMusicMediaMetadata;
        title = metadata.title;
        break;
      case GoogleCastMediaMetadataType.photoMediaMetadata:
        metadata as GoogleCastPhotoMediaMetadata;
        title = metadata.title;
        break;
      default:
    }
    return title;
  }
}

extension DurationExtension on Duration {
  String get formatted {
    var seconds = inSeconds;
    final days = seconds ~/ Duration.secondsPerDay;
    seconds -= days * Duration.secondsPerDay;
    final hours = seconds ~/ Duration.secondsPerHour;
    seconds -= hours * Duration.secondsPerHour;
    final minutes = seconds ~/ Duration.secondsPerMinute;
    seconds -= minutes * Duration.secondsPerMinute;

    final List<String> tokens = [];
    if (days != 0) {
      tokens.add('${days}d');
    }
    if (tokens.isNotEmpty || hours != 0) {
      tokens.add('$hours');
    }

    tokens.add('$minutes'.padLeft(2, '0'));

    tokens.add('$seconds'.padLeft(2, '0'));

    return tokens.join(':');
  }
}
