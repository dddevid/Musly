import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';

/// Service that searches LRCLIB (https://lrclib.net) for lyrics when the
/// Subsonic / Navidrome server does not provide them.
class LrcLibService {
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: 'https://lrclib.net/api',
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );

  /// Searches LRCLIB for a track matching [artist] and [title].
  ///
  /// Returns a map compatible with the Subsonic `getLyrics` response:
  ///   { 'value': '<plain lyrics>' }
  /// or with `getLyricsBySongId` / structured lyrics:
  ///   { 'structuredLyrics': [ { 'synced': true, 'line': [...] } ] }
  ///
  /// Returns `null` when no match is found.
  Future<Map<String, dynamic>?> searchLyrics({
    required String artist,
    required String title,
    int? durationSeconds,
  }) async {
    try {
      final response = await _dio.get(
        '/get',
        queryParameters: {
          'artist_name': artist,
          'track_name': title,
          if (durationSeconds != null) 'duration': durationSeconds,
        },
      );

      if (response.statusCode != 200 || response.data == null) return null;

      final data = response.data as Map<String, dynamic>;

      // Try synced lyrics first (most useful)
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
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        debugPrint('[LRCLIB] No lyrics found for "$title" by "$artist"');
      } else {
        debugPrint('[LRCLIB] Error: $e');
      }
      return null;
    } catch (e) {
      debugPrint('[LRCLIB] Unexpected error: $e');
      return null;
    }
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
      // No valid LRC lines — return as plain text instead
      return {'value': lrcText};
    }

    return {
      'structuredLyrics': [
        {
          'synced': true,
          'line': lines,
        },
      ],
    };
  }
}
