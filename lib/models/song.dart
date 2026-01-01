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
  });

  factory Song.fromJson(Map<String, dynamic> json) {
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
    };
  }

  String get formattedDuration {
    if (duration == null) return '0:00';
    final minutes = duration! ~/ 60;
    final seconds = duration! % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}