class ArtistInfo {
  final String? biography;
  final String? musicBrainzId;
  final String? lastFmUrl;
  final String? smallImageUrl;
  final String? mediumImageUrl;
  final String? largeImageUrl;

  ArtistInfo({
    this.biography,
    this.musicBrainzId,
    this.lastFmUrl,
    this.smallImageUrl,
    this.mediumImageUrl,
    this.largeImageUrl,
  });

  factory ArtistInfo.fromJson(Map<String, dynamic> json) {
    return ArtistInfo(
      biography: json['biography']?.toString(),
      musicBrainzId: json['musicBrainzId']?.toString(),
      lastFmUrl: json['lastFmUrl']?.toString(),
      smallImageUrl: json['smallImageUrl']?.toString(),
      mediumImageUrl: json['mediumImageUrl']?.toString(),
      largeImageUrl: json['largeImageUrl']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'biography': biography,
      'musicBrainzId': musicBrainzId,
      'lastFmUrl': lastFmUrl,
      'smallImageUrl': smallImageUrl,
      'mediumImageUrl': mediumImageUrl,
      'largeImageUrl': largeImageUrl,
    };
  }
}
