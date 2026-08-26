class ArtistRef {
  final String id;
  final String name;
  final String? coverArt;

  const ArtistRef({
    required this.id,
    required this.name,
    this.coverArt,
  });

  String? get effectiveCoverArt {
    if (coverArt != null && coverArt!.isNotEmpty) return coverArt;
    return id.isNotEmpty ? id : null;
  }

  factory ArtistRef.fromJson(Map<String, dynamic> json) {
    return ArtistRef(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      coverArt: json['coverArt']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        if (coverArt != null) 'coverArt': coverArt,
      };

  static final RegExp _artistSplitRegex = RegExp(
    r'\s*(?:,|/|;|&|\\|\||\bfeat\.?|\bft\.?|\bfeaturing\b|\band\b|\bx\b|\bwith\b)\s*',
    caseSensitive: false,
  );

  static List<String> splitArtistNames(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return [];

    final parts = trimmed
        .split(_artistSplitRegex)
        .map((segment) => segment.trim())
        .where((segment) => segment.isNotEmpty)
        .toList();

    return parts.isEmpty ? [trimmed] : parts;
  }

  static List<ArtistRef>? parseList(dynamic data) {
    if (data == null || data is! List) return null;

    final parsedRefs = <ArtistRef>[];
    for (final item in data) {
      if (item is Map<String, dynamic>) {
        final ref = ArtistRef.fromJson(item);
        final splitNames = splitArtistNames(ref.name);

        if (splitNames.length > 1) {
          for (final splitName in splitNames) {
            parsedRefs.add(ArtistRef(
              id: '',
              name: splitName,
              coverArt: ref.coverArt,
            ));
          }
        } else if (ref.id.isNotEmpty || ref.name.isNotEmpty) {
          parsedRefs.add(ref);
        }
      }
    }

    return parsedRefs.isEmpty ? null : parsedRefs;
  }

  static List<ArtistRef> fromListOrFallback(
    List<ArtistRef>? participants, {
    String? fallbackName,
    String? fallbackId,
  }) {
    if (participants != null && participants.isNotEmpty) {
      final expandedList = <ArtistRef>[];
      for (final participant in participants) {
        final splitNames = splitArtistNames(participant.name);
        if (splitNames.length > 1) {
          for (final splitName in splitNames) {
            expandedList.add(
              ArtistRef(
                  id: '', name: splitName, coverArt: participant.coverArt),
            );
          }
        } else {
          expandedList.add(participant);
        }
      }
      if (expandedList.isNotEmpty) return expandedList;
    }

    if (fallbackName != null && fallbackName.trim().isNotEmpty) {
      final splitNames = splitArtistNames(fallbackName);
      if (splitNames.length > 1) {
        return splitNames
            .map((splitName) => ArtistRef(id: '', name: splitName))
            .toList();
      }
      return [ArtistRef(id: fallbackId ?? '', name: fallbackName.trim())];
    }

    if (fallbackId != null && fallbackId.isNotEmpty) {
      return [ArtistRef(id: fallbackId, name: '')];
    }

    return [];
  }
}
