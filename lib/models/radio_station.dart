/// Represents an internet radio station from the Subsonic/Navidrome server.
class RadioStation {
  final String id;
  final String name;
  final String streamUrl;
  final String? homePageUrl;

  RadioStation({
    required this.id,
    required this.name,
    required this.streamUrl,
    this.homePageUrl,
  });

  factory RadioStation.fromJson(Map<String, dynamic> json) {
    return RadioStation(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? 'Unknown Station',
      streamUrl: json['streamUrl'] ?? '',
      homePageUrl: json['homePageUrl']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'streamUrl': streamUrl,
      'homePageUrl': homePageUrl,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RadioStation &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
