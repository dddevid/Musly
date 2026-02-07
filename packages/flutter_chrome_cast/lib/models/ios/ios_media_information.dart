import 'package:flutter_chrome_cast/lib.dart';
import 'package:flutter_chrome_cast/models/ios/ios_media_track.dart';
import 'package:flutter_chrome_cast/models/ios/metadata/generic.dart';
import 'package:flutter_chrome_cast/models/ios/metadata/metadata.dart';
import 'package:flutter_chrome_cast/models/ios/metadata/movie.dart';
import 'package:flutter_chrome_cast/models/ios/metadata/music.dart';
import 'package:flutter_chrome_cast/models/ios/metadata/tv_show.dart';

class GoogleCastMediaInformationIOS extends GoogleCastMediaInformation {
  GoogleCastMediaInformationIOS({
    required super.contentId,
    required super.streamType,
    required super.contentType,
    super.atvEntity,
    super.breakClips,
    super.breaks,
    super.contentUrl,
    super.customData,
    super.duration,
    super.entity,
    super.hlsSegmentFormat,
    super.hlsVideoSegmentFormat,
    super.metadata,
    super.startAbsoluteTime,
    super.textTrackStyle,
    super.tracks,
    super.userActionStates,
    super.vmapAdsRequest,
  });

  factory GoogleCastMediaInformationIOS.fromMap(Map<String, dynamic> map) {
    return GoogleCastMediaInformationIOS(
      atvEntity: map['atvEntity'],
      breakClips: map['breakClips'] != null
          ? List<CastBreakClips>.from(
              map['breakClips']?.map((x) => CastBreakClips.fromMap(x)))
          : null,
      contentId: map['contentID'] ?? '',
      streamType: CastMediaStreamType.values[map['streamType']],
      contentType: map['contentType'] ?? '',
      metadata: map['metadata'] != null
          ? _getCastMediaMetadata(Map.from(map['metadata']))
          : null,
      duration: map['duration'] != null
          ? Duration(seconds: map['duration']?.round() ?? 0)
          : null,
      customData: Map<String, dynamic>.from(map['customData'] ?? {}),
      breaks: map['breaks'] != null
          ? List<CastBreak>.from(
              map['breaks']?.map((x) => CastBreak.fromMap(x)))
          : null,
      contentUrl: Uri.tryParse(map['contentURL'] ?? ''),
      entity: map['entity'],
      hlsSegmentFormat: map['hlsSegmentFormat'] != null
          ? CastHlsSegmentFormat.fromMap(map['hlsSegmentFormat'])
          : null,
      hlsVideoSegmentFormat: map['hlsVideoSegmentFormat'] != null
          ? HlsVideoSegmentFormat.fromMap(map['hlsVideoSegmentFormat'])
          : null,
      startAbsoluteTime: map['startAbsoluteTime'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['startAbsoluteTime'])
          : null,
      textTrackStyle: map['textTrackStyle'] != null
          ? TextTrackStyle.fromMap(map['textTrackStyle'])
          : null,
      tracks: map['tracks'] != null
          ? List<GoogleCastMediaTrack>.from(
              map['tracks']?.map(
                (x) => IosMediaTrack.fromMap(x),
              ),
            )
          : null,
      userActionStates: map['userActionStates'] != null
          ? List<UserActionState>.from(
              map['userActionStates']?.map((x) => UserActionState.fromMap(x)))
          : null,
      vmapAdsRequest: map['vmapAdsRequest'] != null
          ? VastAdsRequest.fromMap(map['vmapAdsRequest'])
          : null,
    );
  }
}

GoogleCastMediaMetadata? _getCastMediaMetadata(Map<String, dynamic> map) {
  final type = GoogleCastMediaMetadataType.values[map['type']];
  if (type == GoogleCastMediaMetadataType.genericMediaMetadata) {
    return GoogleCastGenericMediaMetadataIOS.fromMap(map);
  } else if (type == GoogleCastMediaMetadataType.movieMediaMetadata) {
    return GoogleCastMovieMediaMetadataIOS.fromMap(map);
  } else if (type == GoogleCastMediaMetadataType.tvShowMediaMetadata) {
    return GoogleCastTvShowMediaMetadataIOS.fromMap(map);
  } else if (type == GoogleCastMediaMetadataType.musicTrackMediaMetadata) {
    return GoogleCastMusicMediaMetadataIOS.fromMap(map);
  } else if (type == GoogleCastMediaMetadataType.photoMediaMetadata) {
    return GooglCastPhotoMediaMetadataIOS.fromMap(map);
  } else {
    return null;
  }
}
