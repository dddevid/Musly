class MusicFolder {
  final String id;
  final String name;

  MusicFolder({required this.id, required this.name});

  factory MusicFolder.fromJson(Map<String, dynamic> json) {
    return MusicFolder(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? 'Unknown Folder',
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name};
  }
}
