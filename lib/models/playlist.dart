import 'song.dart';

class Playlist {
  final String id;
  final String name;
  final String? comment;
  final String? owner;
  final bool? public;
  final int? songCount;
  final int? duration;
  final DateTime? created;
  final DateTime? changed;
  final String? coverArt;
  final List<Song>? songs;

  Playlist({
    required this.id,
    required this.name,
    this.comment,
    this.owner,
    this.public,
    this.songCount,
    this.duration,
    this.created,
    this.changed,
    this.coverArt,
    this.songs,
  });

  factory Playlist.fromJson(Map<String, dynamic> json) {
    List<Song>? songsList;
    if (json['entry'] != null) {
      songsList = (json['entry'] as List)
          .map((e) => Song.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    return Playlist(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? 'Unknown Playlist',
      comment: json['comment']?.toString(),
      owner: json['owner']?.toString(),
      public: json['public'] as bool?,
      songCount: json['songCount'] as int?,
      duration: json['duration'] as int?,
      created: json['created'] != null
          ? DateTime.tryParse(json['created'].toString())
          : null,
      changed: json['changed'] != null
          ? DateTime.tryParse(json['changed'].toString())
          : null,
      coverArt: json['coverArt']?.toString(),
      songs: songsList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'comment': comment,
      'owner': owner,
      'public': public,
      'songCount': songCount,
      'duration': duration,
      'created': created?.toIso8601String(),
      'changed': changed?.toIso8601String(),
      'coverArt': coverArt,
      'entry': songs?.map((s) => s.toJson()).toList(),
    };
  }

  String get formattedDuration {
    if (duration == null) return '';
    final hours = duration! ~/ 3600;
    final minutes = (duration! % 3600) ~/ 60;
    if (hours > 0) {
      return '$hours h $minutes min';
    }
    return '$minutes min';
  }
}