class Genre {
  final String value;
  final int songCount;
  final int albumCount;

  Genre({
    required this.value,
    required this.songCount,
    required this.albumCount,
  });

  factory Genre.fromJson(Map<String, dynamic> json) {
    return Genre(
      value: json['value']?.toString() ?? '',
      songCount: json['songCount'] as int? ?? 0,
      albumCount: json['albumCount'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {'value': value, 'songCount': songCount, 'albumCount': albumCount};
  }

  @override
  String toString() => value;
}
