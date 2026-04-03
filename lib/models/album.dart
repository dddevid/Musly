import 'artist_ref.dart';

class Album {
  final String id;
  final String name;
  final String? artist;
  final String? artistId;
  final String? coverArt;
  final int? songCount;
  final int? duration;
  final int? year;
  final String? genre;
  final DateTime? created;
  final bool isLocal;
  final List<ArtistRef>? artistParticipants;

  Album({
    required this.id,
    required this.name,
    this.artist,
    this.artistId,
    this.coverArt,
    this.songCount,
    this.duration,
    this.year,
    this.genre,
    this.created,
    this.isLocal = false,
    this.artistParticipants,
  });

  factory Album.fromJson(Map<String, dynamic> json) {
    return Album(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? json['album'] ?? 'Unknown Album',
      artist: json['artist']?.toString(),
      artistId: json['artistId']?.toString(),
      coverArt: json['coverArt']?.toString(),
      songCount: json['songCount'] as int?,
      duration: json['duration'] as int?,
      year: json['year'] as int?,
      genre: json['genre']?.toString(),
      created: json['created'] != null
          ? DateTime.tryParse(json['created'].toString())
          : null,
      artistParticipants: ArtistRef.parseList(json['artists']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'artist': artist,
      'artistId': artistId,
      'coverArt': coverArt,
      'songCount': songCount,
      'duration': duration,
      'year': year,
      'genre': genre,
      'created': created?.toIso8601String(),
      if (artistParticipants != null)
        'artists': artistParticipants!.map((a) => a.toJson()).toList(),
    };
  }

  String get formattedDuration {
    if (duration == null) return '';
    final minutes = duration! ~/ 60;
    final seconds = duration! % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}
