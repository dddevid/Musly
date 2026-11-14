import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DiscoveryRelease {
  final String id;
  final String title;
  final String artist;
  final String? releaseDate;
  final String? primaryType;
  final String? coverUrl;
  final Map<String, dynamic> raw;

  DiscoveryRelease({
    required this.id,
    required this.title,
    required this.artist,
    this.releaseDate,
    this.primaryType,
    this.coverUrl,
    this.raw = const {},
  });

  factory DiscoveryRelease.fromMusicBrainz(Map<String, dynamic> json) {
    final id = json['id']?.toString() ?? '';
    final title = json['title']?.toString() ?? 'Unknown';

    var artistName = 'Unknown Artist';
    if (json['artist-credit'] is List &&
        (json['artist-credit'] as List).isNotEmpty) {
      final firstCredit = (json['artist-credit'] as List)[0];
      if (firstCredit is Map) {
        artistName = firstCredit['name']?.toString() ??
            firstCredit['artist']?['name']?.toString() ??
            artistName;
      }
    }

    final releaseDate = json['first-release-date']?.toString();
    final primaryType = json['primary-type']?.toString();
    final cover = id.isNotEmpty
        ? 'https://coverartarchive.org/release-group/$id/front-250.jpg'
        : null;

    return DiscoveryRelease(
      id: id,
      title: title,
      artist: artistName,
      releaseDate: releaseDate,
      primaryType: primaryType,
      coverUrl: cover,
      raw: json,
    );
  }
}

class DiscoveryArtist {
  final String id;
  final String name;
  final String? disambiguation;
  final String? country;
  final List<String> tags;

  DiscoveryArtist({
    required this.id,
    required this.name,
    this.disambiguation,
    this.country,
    this.tags = const [],
  });

  factory DiscoveryArtist.fromMusicBrainz(Map<String, dynamic> json) {
    final id = json['id']?.toString() ?? '';
    final name = json['name']?.toString() ?? 'Unknown Artist';
    final disambiguation = json['disambiguation']?.toString();
    final country = json['country']?.toString();

    final tags = <String>[];
    if (json['tags'] is List) {
      for (final t in json['tags'] as List) {
        if (t is Map && t['name'] != null) {
          tags.add(t['name'].toString());
        }
      }
    }

    return DiscoveryArtist(
      id: id,
      name: name,
      disambiguation: disambiguation,
      country: country,
      tags: tags,
    );
  }
}

class DiscoveryService {
  static const String _keyDiscoveryEnabled = 'discovery_recommendations_enabled';

  static final DiscoveryService _instance = DiscoveryService._internal();
  factory DiscoveryService() => _instance;
  DiscoveryService._internal();

  SharedPreferences? _prefs;
  final ValueNotifier<bool> enabledNotifier = ValueNotifier(true);

  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 8),
      receiveTimeout: const Duration(seconds: 12),
      headers: {
        'User-Agent': 'MuslyApp/1.0.0 ( contact@musly.app )',
        'Accept': 'application/json',
      },
    ),
  );

  Future<void> initialize() async {
    _prefs ??= await SharedPreferences.getInstance();
    enabledNotifier.value = isEnabled;
  }

  bool get isEnabled => _prefs?.getBool(_keyDiscoveryEnabled) ?? true;

  Future<void> setEnabled(bool value) async {
    await initialize();
    await _prefs!.setBool(_keyDiscoveryEnabled, value);
    enabledNotifier.value = value;
  }

  Future<List<DiscoveryRelease>> searchMusicBrainzReleases(String query) async {
    final clean = query.trim();
    if (clean.isEmpty) return [];

    try {
      final url =
          'https://musicbrainz.org/ws/2/release-group/?query=${Uri.encodeComponent(clean)}&fmt=json&limit=20';
      final response = await _dio.get<dynamic>(url);

      if (response.data is Map && response.data['release-groups'] is List) {
        final groups = response.data['release-groups'] as List;
        return groups
            .whereType<Map<String, dynamic>>()
            .map(DiscoveryRelease.fromMusicBrainz)
            .toList();
      }
    } catch (e) {
      debugPrint('[DiscoveryService] searchMusicBrainzReleases error: $e');
    }
    return [];
  }

  Future<List<DiscoveryArtist>> searchMusicBrainzArtists(String query) async {
    final clean = query.trim();
    if (clean.isEmpty) return [];

    try {
      final url =
          'https://musicbrainz.org/ws/2/artist/?query=${Uri.encodeComponent(clean)}&fmt=json&limit=10';
      final response = await _dio.get<dynamic>(url);

      if (response.data is Map && response.data['artists'] is List) {
        final artists = response.data['artists'] as List;
        return artists
            .whereType<Map<String, dynamic>>()
            .map(DiscoveryArtist.fromMusicBrainz)
            .toList();
      }
    } catch (e) {
      debugPrint('[DiscoveryService] searchMusicBrainzArtists error: $e');
    }
    return [];
  }

  Future<List<DiscoveryRelease>> getArtistReleases(String artistMbid) async {
    if (artistMbid.isEmpty) return [];

    try {
      final url =
          'https://musicbrainz.org/ws/2/release-group?artist=$artistMbid&type=album|ep&limit=15&fmt=json';
      final response = await _dio.get<dynamic>(url);

      if (response.data is Map && response.data['release-groups'] is List) {
        final groups = response.data['release-groups'] as List;
        return groups
            .whereType<Map<String, dynamic>>()
            .map(DiscoveryRelease.fromMusicBrainz)
            .toList();
      }
    } catch (e) {
      debugPrint('[DiscoveryService] getArtistReleases error: $e');
    }
    return [];
  }

  Future<List<DiscoveryArtist>> getSimilarArtists(
    String artistName, {
    String? artistMbid,
  }) async {
    final name = artistName.trim();
    if (name.isEmpty) return [];

    var mbid = artistMbid;
    if (mbid == null || mbid.isEmpty) {
      final artists = await searchMusicBrainzArtists(name);
      if (artists.isNotEmpty) {
        mbid = artists.first.id;
      }
    }

    if (mbid == null || mbid.isEmpty) return [];

    try {
      final url =
          'https://api.listenbrainz.org/1/explore/similar-artists/?artist_mbids=$mbid&algorithm=session_based_days_730';
      final response = await _dio.get<dynamic>(url);

      if (response.data is Map && response.data['payload'] is List) {
        final payload = response.data['payload'] as List;
        final results = <DiscoveryArtist>[];
        for (final item in payload) {
          if (item is Map) {
            final simMbid = item['artist_mbid']?.toString() ?? '';
            final simName = item['artist_name']?.toString() ?? '';
            if (simName.isNotEmpty && simName.toLowerCase() != name.toLowerCase()) {
              results.add(
                DiscoveryArtist(
                  id: simMbid,
                  name: simName,
                ),
              );
            }
          }
        }
        if (results.isNotEmpty) return results.take(8).toList();
      }
    } catch (e) {
      debugPrint('[DiscoveryService] ListenBrainz similar artists error: $e');
    }

    return [];
  }

  Future<Map<String, dynamic>> getRecommendationsForArtist(
    String artistName, {
    String? artistMbid,
  }) async {
    final similar = await getSimilarArtists(artistName, artistMbid: artistMbid);
    final recommendedReleases = <DiscoveryRelease>[];

    // Fetch up to 2 top releases from top 3 similar artists
    final topSimilar = similar.take(3).toList();
    for (final artist in topSimilar) {
      if (artist.id.isNotEmpty) {
        final releases = await getArtistReleases(artist.id);
        recommendedReleases.addAll(releases.take(2));
      }
    }

    return {
      'similarArtists': similar,
      'recommendedReleases': recommendedReleases,
    };
  }
}
