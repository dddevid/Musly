import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'storage_service.dart';

/// Service that searches LRCLIB (https://lrclib.net) for synced and plain lyrics.
///
/// Features:
/// - Robust multi-candidate artist and title extraction (handles "Artist - Track", uploader noise, etc.)
/// - Multi-tier search: exact `/get` -> fuzzy `/search` across title & artist variations
/// - In-memory lyrics caching
/// - Outputs Subsonic and Musly compatible structured and plain lyrics formats
class LrcLibService {
  static final LrcLibService _instance = LrcLibService._internal();
  factory LrcLibService() => _instance;
  LrcLibService._internal();

  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: 'https://lrclib.net/api',
      connectTimeout: const Duration(seconds: 6),
      receiveTimeout: const Duration(seconds: 6),
      headers: {
        'User-Agent': 'Musly/1.0 (https://github.com/musly)',
      },
    ),
  );

  // In-memory cache for lyrics: "artist|title" -> response map
  final Map<String, Map<String, dynamic>> _cache = {};

  static final List<RegExp> _noiseRegexes = [
    RegExp(r'\((?:official|music|video|audio|lyrics?|lyric video|visualizer|hd|4k|remastered|live|explicit|clip|video oficial|clip officiel).*?\)', caseSensitive: false),
    RegExp(r'\[(?:official|music|video|audio|lyrics?|lyric video|visualizer|hd|4k|remastered|live|explicit|clip|video oficial|clip officiel).*?\]', caseSensitive: false),
    RegExp(r'\((?:feat\.|ft\.|featuring).*?\)', caseSensitive: false),
    RegExp(r'\[(?:feat\.|ft\.|featuring).*?\]', caseSensitive: false),
    RegExp(r'(?:feat\.|ft\.|featuring).*$', caseSensitive: false),
    RegExp(r'\(prod\..*?\)', caseSensitive: false),
    RegExp(r'\[prod\..*?\]', caseSensitive: false),
  ];

  static final RegExp _multiSpaceRegex = RegExp(r'\s+');
  static final RegExp _topicRegex = RegExp(r'\s*-\s*Topic$', caseSensitive: false);
  static final RegExp _vevoRegex = RegExp(r'\s*VEVO$', caseSensitive: false);
  static final RegExp _officialRegex = RegExp(r'\s*Official$', caseSensitive: false);
  static final RegExp _featRegex = RegExp(r'(?:feat\.|ft\.|featuring).*$', caseSensitive: false);

  /// Normalizes and cleans YouTube track titles by stripping common fluff.
  static String cleanTitle(String rawTitle) {
    var title = rawTitle;

    // If formatted as "Artist - Track", extract the track portion
    if (title.contains(' - ')) {
      final parts = title.split(' - ');
      if (parts.length >= 2) {
        title = parts.sublist(1).join(' - ');
      }
    }

    for (final reg in _noiseRegexes) {
      title = title.replaceAll(reg, ' ');
    }

    title = title
        .replaceAll('"', '')
        .replaceAll("'", '')
        .replaceAll(_multiSpaceRegex, ' ')
        .trim();

    return title.isNotEmpty ? title : rawTitle;
  }

  /// Cleans artist names (e.g. removes " - Topic" from YouTube Music channel names).
  static String cleanArtist(String rawArtist) {
    var artist = rawArtist;
    artist = artist.replaceAll(_topicRegex, '');
    artist = artist.replaceAll(_vevoRegex, '');
    artist = artist.replaceAll(_officialRegex, '');
    artist = artist.replaceAll(_featRegex, '');
    return artist.trim().isNotEmpty ? artist.trim() : rawArtist;
  }

  /// Searches LRCLIB for a track matching [title] and optional [artist].
  ///
  /// Returns a map compatible with Subsonic `getLyrics` and `getLyricsBySongId`:
  ///   `{ 'value': '<raw lrc or plain text>', 'structuredLyrics': [ ... ] }`
  Future<Map<String, dynamic>?> searchLyrics({
    String? artist,
    required String title,
    int? durationSeconds,
  }) async {
    final isEnabled = await StorageService().getLrcLibFallback();
    if (!isEnabled) return null;

    if (title.trim().isEmpty) return null;

    final cleanedTitle = cleanTitle(title);
    final cleanedArtist = (artist != null && artist.isNotEmpty) ? cleanArtist(artist) : null;
    final cacheKey = '${cleanedArtist?.toLowerCase() ?? ''}|${cleanedTitle.toLowerCase()}';

    if (_cache.containsKey(cacheKey)) {
      return _cache[cacheKey];
    }

    // Extract potential artist and title candidates if title was "Artist - Track"
    String? extractedArtist;
    String? extractedTrack;
    if (title.contains(' - ')) {
      final parts = title.split(' - ');
      if (parts.length >= 2) {
        extractedArtist = cleanArtist(parts[0]);
        extractedTrack = cleanTitle(parts.sublist(1).join(' - '));
      }
    }

    // 1. Direct /api/get candidates
    final getPairs = <MapEntry<String, String>>[];
    if (extractedArtist != null && extractedTrack != null && extractedArtist.isNotEmpty && extractedTrack.isNotEmpty) {
      getPairs.add(MapEntry(extractedArtist, extractedTrack));
    }
    if (cleanedArtist != null && cleanedArtist.isNotEmpty && cleanedTitle.isNotEmpty) {
      getPairs.add(MapEntry(cleanedArtist, cleanedTitle));
    }

    for (final pair in getPairs) {
      try {
        final response = await _dio.get(
          '/get',
          queryParameters: {
            'artist_name': pair.key,
            'track_name': pair.value,
          },
        );

        if (response.statusCode == 200 && response.data != null && response.data is Map) {
          final result = _parseLrcLibResponse(response.data as Map<String, dynamic>);
          if (result != null) {
            _cache[cacheKey] = result;
            debugPrint('[LRCLIB] Exact match found for "${pair.key} - ${pair.value}"');
            return result;
          }
        }
      } catch (_) {}
    }

    // 2. Query variations for /api/search
    final searchQueries = <String>[];
    if (extractedArtist != null && extractedTrack != null && extractedArtist.isNotEmpty && extractedTrack.isNotEmpty) {
      searchQueries.add('$extractedArtist $extractedTrack'.trim());
    }
    if (cleanedArtist != null && cleanedArtist.isNotEmpty && cleanedTitle.isNotEmpty) {
      searchQueries.add('$cleanedArtist $cleanedTitle'.trim());
    }
    if (cleanedTitle.isNotEmpty && !searchQueries.contains(cleanedTitle)) {
      searchQueries.add(cleanedTitle);
    }
    // Raw title stripped of parenthesis noise
    final simpleRaw = title.replaceAll(RegExp(r'[\(\[\{].*?[\)\]\}]'), ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
    if (simpleRaw.isNotEmpty && !searchQueries.contains(simpleRaw)) {
      searchQueries.add(simpleRaw);
    }

    for (final query in searchQueries) {
      if (query.isEmpty) continue;
      try {
        final searchResp = await _dio.get(
          '/search',
          queryParameters: {
            'q': query,
          },
        );

        if (searchResp.statusCode == 200 && searchResp.data is List) {
          final list = searchResp.data as List;
          if (list.isNotEmpty) {
            // Find item with synced lyrics first, or plain lyrics
            Map<String, dynamic>? bestMatch;
            for (final item in list) {
              if (item is Map<String, dynamic>) {
                final synced = item['syncedLyrics'] as String?;
                final plain = item['plainLyrics'] as String?;
                if (synced != null && synced.trim().isNotEmpty) {
                  bestMatch = item;
                  break;
                } else if (plain != null && plain.trim().isNotEmpty && bestMatch == null) {
                  bestMatch = item;
                }
              }
            }
            bestMatch ??= list.first as Map<String, dynamic>;

            final result = _parseLrcLibResponse(bestMatch);
            if (result != null) {
              _cache[cacheKey] = result;
              debugPrint('[LRCLIB] Search match found for query "$query"');
              return result;
            }
          }
        }
      } catch (e) {
        debugPrint('[LRCLIB] Search query "$query" error: $e');
      }
    }

    return null;
  }

  Map<String, dynamic>? _parseLrcLibResponse(Map<String, dynamic> data) {
    // Try synced lyrics first
    final synced = data['syncedLyrics'] as String?;
    if (synced != null && synced.isNotEmpty) {
      return _buildStructuredLyrics(synced);
    }

    // Fallback to plain lyrics
    final plain = data['plainLyrics'] as String?;
    if (plain != null && plain.isNotEmpty) {
      return {'value': plain};
    }

    return null;
  }

  /// Converts an LRC string into the Subsonic structured-lyrics format.
  Map<String, dynamic> _buildStructuredLyrics(String lrcText) {
    final lines = <Map<String, dynamic>>[];
    for (final raw in LineSplitter.split(lrcText)) {
      final line = raw.trim();
      if (line.isEmpty) continue;

      // Parse [mm:ss.xx] or [mm:ss.xxx] tags
      final match = RegExp(r'\[(\d+):(\d{2})\.(\d{2,3})\](.*)').firstMatch(line);
      if (match == null) continue;

      final minutes = int.parse(match.group(1)!);
      final seconds = int.parse(match.group(2)!);
      final fracStr = match.group(3)!;
      final text = match.group(4)!.trim();
      if (text.isEmpty) continue;

      // Normalise fractional seconds to milliseconds
      final fracMs = fracStr.length == 2
          ? int.parse(fracStr) * 10
          : int.parse(fracStr);

      final startMs =
          (minutes * 60 + seconds) * 1000 + fracMs.clamp(0, 999);

      lines.add({
        'start': startMs,
        'value': text,
      });
    }

    if (lines.isEmpty) {
      return {'value': lrcText};
    }

    return {
      'value': lrcText,
      'structuredLyrics': [
        {
          'synced': true,
          'line': lines,
        },
      ],
    };
  }
}
