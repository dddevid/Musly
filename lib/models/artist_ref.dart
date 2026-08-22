/// A lightweight artist reference parsed from Navidrome's `participants` or `artists` field.
/// Standard Subsonic servers do not provide this field, so it is always optional.
class ArtistRef {
  final String id;
  final String name;
  /// Explicit cover art ID from the API response. When absent, falls back to
  /// [id] for servers (like Navidrome) that serve artist images via
  /// `getCoverArt?id={artistId}`.
  final String? coverArt;

  const ArtistRef({required this.id, required this.name, this.coverArt});

  /// Cover art ID for `getCoverArt`: explicit [coverArt] if set, otherwise [id].
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

  /// Splits combined artist strings like "Drake / 21 Savage" or "Queen; David Bowie"
  static List<String> splitArtistNames(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return [];
    final parts = trimmed
        .split(_artistSplitRegex)
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    return parts.isEmpty ? [trimmed] : parts;
  }

  static List<ArtistRef>? parseList(dynamic data) {
    if (data == null || data is! List) return null;
    final list = <ArtistRef>[];
    for (final e in data) {
      if (e is Map<String, dynamic>) {
        final ref = ArtistRef.fromJson(e);
        final splits = splitArtistNames(ref.name);
        if (splits.length > 1) {
          for (final s in splits) {
            list.add(ArtistRef(
              id: '',
              name: s,
              coverArt: ref.coverArt,
            ));
          }
        } else if (ref.id.isNotEmpty || ref.name.isNotEmpty) {
          list.add(ref);
        }
      }
    }
    return list.isEmpty ? null : list;
  }

  static List<ArtistRef> fromListOrFallback(
    List<ArtistRef>? participants, {
    String? fallbackName,
    String? fallbackId,
  }) {
    if (participants != null && participants.isNotEmpty) {
      final expanded = <ArtistRef>[];
      for (final p in participants) {
        final splits = splitArtistNames(p.name);
        if (splits.length > 1) {
          for (final s in splits) {
            expanded.add(ArtistRef(id: '', name: s, coverArt: p.coverArt));
          }
        } else {
          expanded.add(p);
        }
      }
      if (expanded.isNotEmpty) return expanded;
    }

    if (fallbackName != null && fallbackName.trim().isNotEmpty) {
      final splits = splitArtistNames(fallbackName);
      if (splits.length > 1) {
        return splits.map((s) => ArtistRef(id: '', name: s)).toList();
      }
      return [ArtistRef(id: fallbackId ?? '', name: fallbackName.trim())];
    }

    if (fallbackId != null && fallbackId.isNotEmpty) {
      return [ArtistRef(id: fallbackId, name: '')];
    }

    return [];
  }
}
