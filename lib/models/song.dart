class Song {
  final String id;
  final String title;
  final String? album;
  final String? albumId;
  final String? artist;
  final String? artistId;
  final int? track;
  final int? year;
  final String? genre;
  final String? coverArt;
  final int? duration;
  final int? bitRate;
  final String? suffix;
  final String? contentType;
  final int? size;
  final String? path;
  final bool? starred;
  final int? userRating; // 1-5 stars, null if not rated
  final bool isLocal;
  final double? replayGainTrackGain;
  final double? replayGainAlbumGain;
  final double? replayGainTrackPeak;
  final double? replayGainAlbumPeak;

  Song({
    required this.id,
    required this.title,
    this.album,
    this.albumId,
    this.artist,
    this.artistId,
    this.track,
    this.year,
    this.genre,
    this.coverArt,
    this.duration,
    this.bitRate,
    this.suffix,
    this.contentType,
    this.size,
    this.path,
    this.starred,
    this.userRating,
    this.isLocal = false,
    this.replayGainTrackGain,
    this.replayGainAlbumGain,
    this.replayGainTrackPeak,
    this.replayGainAlbumPeak,
  });

  factory Song.fromJson(Map<String, dynamic> json) {
    // Parse ReplayGain data - Subsonic API provides it in a nested 'replayGain' object
    final replayGain = json['replayGain'] as Map<String, dynamic>?;

    return Song(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? 'Unknown Title',
      album: json['album']?.toString(),
      albumId: json['albumId']?.toString(),
      artist: json['artist']?.toString(),
      artistId: json['artistId']?.toString(),
      track: json['track'] as int?,
      year: json['year'] as int?,
      genre: json['genre']?.toString(),
      coverArt: json['coverArt']?.toString(),
      duration: json['duration'] as int?,
      bitRate: json['bitRate'] as int?,
      suffix: json['suffix']?.toString(),
      contentType: json['contentType']?.toString(),
      size: json['size'] as int?,
      path: json['path']?.toString(),
      starred: json['starred'] != null ? true : false,
      userRating: json['userRating'] as int?,
      isLocal: json['isLocal'] as bool? ?? false,
      replayGainTrackGain: (replayGain?['trackGain'] as num?)?.toDouble(),
      replayGainAlbumGain: (replayGain?['albumGain'] as num?)?.toDouble(),
      replayGainTrackPeak: (replayGain?['trackPeak'] as num?)?.toDouble(),
      replayGainAlbumPeak: (replayGain?['albumPeak'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'album': album,
      'albumId': albumId,
      'artist': artist,
      'artistId': artistId,
      'track': track,
      'year': year,
      'genre': genre,
      'coverArt': coverArt,
      'duration': duration,
      'bitRate': bitRate,
      'suffix': suffix,
      'contentType': contentType,
      'size': size,
      'path': path,
      'isLocal': isLocal,
      'replayGain': {
        if (replayGainTrackGain != null) 'trackGain': replayGainTrackGain,
        if (replayGainAlbumGain != null) 'albumGain': replayGainAlbumGain,
        if (replayGainTrackPeak != null) 'trackPeak': replayGainTrackPeak,
        if (replayGainAlbumPeak != null) 'albumPeak': replayGainAlbumPeak,
      },
    };
  }

  String get formattedDuration {
    if (duration == null) return '0:00';
    final minutes = duration! ~/ 60;
    final seconds = duration! % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  Song copyWith({
    String? id,
    String? title,
    String? album,
    String? albumId,
    String? artist,
    String? artistId,
    int? track,
    int? year,
    String? genre,
    String? coverArt,
    int? duration,
    int? bitRate,
    String? suffix,
    String? contentType,
    int? size,
    String? path,
    bool? starred,
    int? userRating,
    bool? isLocal,
    double? replayGainTrackGain,
    double? replayGainAlbumGain,
    double? replayGainTrackPeak,
    double? replayGainAlbumPeak,
  }) {
    return Song(
      id: id ?? this.id,
      title: title ?? this.title,
      album: album ?? this.album,
      albumId: albumId ?? this.albumId,
      artist: artist ?? this.artist,
      artistId: artistId ?? this.artistId,
      track: track ?? this.track,
      year: year ?? this.year,
      genre: genre ?? this.genre,
      coverArt: coverArt ?? this.coverArt,
      duration: duration ?? this.duration,
      bitRate: bitRate ?? this.bitRate,
      suffix: suffix ?? this.suffix,
      contentType: contentType ?? this.contentType,
      size: size ?? this.size,
      path: path ?? this.path,
      starred: starred ?? this.starred,
      userRating: userRating ?? this.userRating,
      isLocal: isLocal ?? this.isLocal,
      replayGainTrackGain: replayGainTrackGain ?? this.replayGainTrackGain,
      replayGainAlbumGain: replayGainAlbumGain ?? this.replayGainAlbumGain,
      replayGainTrackPeak: replayGainTrackPeak ?? this.replayGainTrackPeak,
      replayGainAlbumPeak: replayGainAlbumPeak ?? this.replayGainAlbumPeak,
    );
  }
}
