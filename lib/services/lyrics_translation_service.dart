import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../models/lyric_line.dart';

class LyricsTranslationService {
  static final LyricsTranslationService _instance =
      LyricsTranslationService._internal();
  factory LyricsTranslationService() => _instance;
  LyricsTranslationService._internal();

  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 8),
      receiveTimeout: const Duration(seconds: 8),
      headers: {
        'User-Agent':
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
      },
    ),
  );

  final Map<String, String> _cache = {};

  String _cacheKey(String text, String targetLang) => '$targetLang::$text';

  Future<String?> translateText(String text, {String targetLanguage = 'en'}) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return null;

    final key = _cacheKey(trimmed, targetLanguage);
    if (_cache.containsKey(key)) return _cache[key];

    try {
      final url =
          'https://translate.googleapis.com/translate_a/single?client=gtx&sl=auto&tl=$targetLanguage&dt=t&q=${Uri.encodeComponent(trimmed)}';
      final response = await _dio.get<dynamic>(url);
      if (response.data is List && (response.data as List).isNotEmpty) {
        final segments = response.data[0] as List;
        final buffer = StringBuffer();
        for (final seg in segments) {
          if (seg is List && seg.isNotEmpty && seg[0] != null) {
            buffer.write(seg[0].toString());
          }
        }
        final result = buffer.toString().trim();
        if (result.isNotEmpty) {
          _cache[key] = result;
          return result;
        }
      }
    } catch (e) {
      debugPrint('[LyricsTranslation] translateText error: $e');
    }
    return null;
  }

  Future<List<LyricLine>> translateLyrics(
    List<LyricLine> lines, {
    String targetLanguage = 'en',
  }) async {
    if (lines.isEmpty) return lines;

    // Filter non-empty lines that need translation
    final needTranslateIndices = <int>[];
    for (int i = 0; i < lines.length; i++) {
      final text = lines[i].text.trim();
      if (text.isEmpty) continue;
      final key = _cacheKey(text, targetLanguage);
      if (_cache.containsKey(key)) {
        lines[i].translation = _cache[key];
      } else {
        needTranslateIndices.add(i);
      }
    }

    if (needTranslateIndices.isEmpty) return lines;

    // Translate in batches of up to 15 lines joined by newlines to minimize latency
    const batchSize = 15;
    for (int i = 0; i < needTranslateIndices.length; i += batchSize) {
      final end = (i + batchSize < needTranslateIndices.length)
          ? i + batchSize
          : needTranslateIndices.length;
      final slice = needTranslateIndices.sublist(i, end);

      final combined = slice.map((idx) => lines[idx].text.trim()).join('\n');
      try {
        final url =
            'https://translate.googleapis.com/translate_a/single?client=gtx&sl=auto&tl=$targetLanguage&dt=t&q=${Uri.encodeComponent(combined)}';
        final response = await _dio.get<dynamic>(url);
        if (response.data is List && (response.data as List).isNotEmpty) {
          final segments = response.data[0] as List;
          final buffer = StringBuffer();
          for (final seg in segments) {
            if (seg is List && seg.isNotEmpty && seg[0] != null) {
              buffer.write(seg[0].toString());
            }
          }
          final fullTranslated = buffer.toString();
          final splitLines = fullTranslated.split('\n');

          if (splitLines.length == slice.length) {
            for (int k = 0; k < slice.length; k++) {
              final idx = slice[k];
              final translated = splitLines[k].trim();
              lines[idx].translation = translated;
              _cache[_cacheKey(lines[idx].text.trim(), targetLanguage)] =
                  translated;
            }
            continue;
          }
        }
      } catch (e) {
        debugPrint('[LyricsTranslation] Batch translation error: $e');
      }

      // Fallback for this slice: individual lines
      await Future.wait(
        slice.map((idx) async {
          final original = lines[idx].text.trim();
          final translated =
              await translateText(original, targetLanguage: targetLanguage);
          if (translated != null) {
            lines[idx].translation = translated;
          }
        }),
      );
    }

    return lines;
  }
}
