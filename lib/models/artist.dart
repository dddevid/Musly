class Artist {
  final String id;
  final String name;
  final String? coverArt;
  final int? albumCount;
  final String? artistImageUrl;
  final bool isLocal;

  Artist({
    required this.id,
    required this.name,
    this.coverArt,
    this.albumCount,
    this.artistImageUrl,
    this.isLocal = false,
  });

  factory Artist.fromJson(Map<String, dynamic> json) {
    return Artist(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? 'Unknown Artist',
      coverArt: json['coverArt']?.toString(),
      albumCount: json['albumCount'] as int?,
      artistImageUrl: json['artistImageUrl']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'coverArt': coverArt,
      'albumCount': albumCount,
      'artistImageUrl': artistImageUrl,
    };
  }
}
