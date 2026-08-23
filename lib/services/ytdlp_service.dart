import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart' as yt;

List<Map<String, dynamic>> _decodeJsonList(String jsonStr) {
  final list = jsonDecode(jsonStr) as List<dynamic>;
  return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
}

Map<String, List<Map<String, dynamic>>> _decodeDualSearch(String jsonStr) {
  final data = jsonDecode(jsonStr) as Map<String, dynamic>;
  final musicRaw = (data['music'] as List<dynamic>? ?? [])
      .map((e) => Map<String, dynamic>.from(e as Map))
      .toList();
  final ytRaw = (data['youtube'] as List<dynamic>? ?? [])
      .map((e) => Map<String, dynamic>.from(e as Map))
      .toList();
  return {
    'music': musicRaw,
    'youtube': ytRaw,
  };
}

Map<String, dynamic> _decodeJsonMap(String jsonStr) {
  return jsonDecode(jsonStr) as Map<String, dynamic>;
}

/// Audio stream information returned by yt-dlp.
class YtStreamInfo {
  final String url;
  final Map<String, String> headers;
  final String ext;

  YtStreamInfo({
    required this.url,
    required this.headers,
    this.ext = 'mp4',
  });
}

/// Service that interacts with yt-dlp to extract high-quality audio streams and metadata.
///
/// Platforms:
/// - **Android**: Runs CPython 3.11 with `yt-dlp` embedded directly in the app via Chaquopy / MethodChannel.
/// - **Desktop (macOS / Windows / Linux)**: Spawns the host Python interpreter or `yt-dlp` CLI subprocess.
// Modern music player design
class YtDlpService {
  static final YtDlpService _instance = YtDlpService._internal();
  factory YtDlpService() => _instance;
  YtDlpService._internal();

  static const MethodChannel _androidChannel = MethodChannel('com.devid.musly/ytdlp');

  yt.YoutubeExplode? _fallbackYt;

  // Stream Info cache: videoId -> YtStreamInfo
  final Map<String, YtStreamInfo> _streamInfoCache = {};
  final Map<String, DateTime> _streamCacheTime = {};
  static const Duration _cacheTtl = Duration(hours: 5);

  // Cached paths for detected binaries on desktop
  String? _detectedYtDlpPath;
  String? _detectedPythonPath;
  bool _detectionDone = false;

  yt.YoutubeExplode get _fallbackClient {
    _fallbackYt ??= yt.YoutubeExplode();
    return _fallbackYt!;
  }

  void dispose() {
    _fallbackYt?.close();
    _fallbackYt = null;
    _streamInfoCache.clear();
    _streamCacheTime.clear();
  }

  void invalidateCache(String videoId) {
    _streamInfoCache.remove(videoId);
    _streamCacheTime.remove(videoId);
  }

  // ── Binary Detection (Desktop) ──────────────────────────────────────────────

  Future<void> _detectBinaries() async {
    if (_detectionDone || Platform.isAndroid || Platform.isIOS) return;
    _detectionDone = true;

    final ytDlpCandidates = <String>[
      'yt-dlp',
      if (Platform.isMacOS) ...[
        '/opt/homebrew/bin/yt-dlp',
        '/usr/local/bin/yt-dlp',
        '/Library/Frameworks/Python.framework/Versions/3.14/bin/yt-dlp',
        '/Library/Frameworks/Python.framework/Versions/3.13/bin/yt-dlp',
        '/Library/Frameworks/Python.framework/Versions/3.12/bin/yt-dlp',
        '/Library/Frameworks/Python.framework/Versions/3.11/bin/yt-dlp',
      ],
      if (Platform.isLinux) ...[
        '/usr/bin/yt-dlp',
        '/usr/local/bin/yt-dlp',
        '~/.local/bin/yt-dlp',
      ],
      if (Platform.isWindows) ...[
        'yt-dlp.exe',
      ],
    ];

    for (final bin in ytDlpCandidates) {
      try {
        final result = await Process.run(bin, ['--version']).timeout(
          const Duration(seconds: 3),
        );
        if (result.exitCode == 0) {
          _detectedYtDlpPath = bin;
          debugPrint('[yt-dlp] Found yt-dlp binary at: $bin (v${result.stdout.toString().trim()})');
          break;
        }
      } catch (_) {}
    }

    final pythonCandidates = <String>[
      'python3',
      'python',
      if (Platform.isMacOS) ...[
        '/opt/homebrew/bin/python3',
        '/usr/local/bin/python3',
        '/usr/bin/python3',
        '/Library/Frameworks/Python.framework/Versions/3.14/bin/python3',
        '/Library/Frameworks/Python.framework/Versions/3.13/bin/python3',
        '/Library/Frameworks/Python.framework/Versions/3.12/bin/python3',
        '/Library/Frameworks/Python.framework/Versions/3.11/bin/python3',
      ],
      if (Platform.isLinux) ...[
        '/usr/bin/python3',
        '/usr/local/bin/python3',
      ],
      if (Platform.isWindows) ...[
        'python.exe',
        'python3.exe',
      ],
    ];

    for (final py in pythonCandidates) {
      try {
        final result = await Process.run(py, ['--version']).timeout(
          const Duration(seconds: 3),
        );
        if (result.exitCode == 0) {
          _detectedPythonPath = py;
          debugPrint('[yt-dlp] Found Python interpreter at: $py (${result.stdout.toString().trim()})');
          break;
        }
      } catch (_) {}
    }
  }

  // ── Process Execution Helper (Desktop) ──────────────────────────────────────

  Future<ProcessResult?> _runYtDlp(List<String> args, {Duration timeout = const Duration(seconds: 20)}) async {
    await _detectBinaries();

    if (_detectedYtDlpPath != null) {
      try {
        final result = await Process.run(_detectedYtDlpPath!, args).timeout(timeout);
        if (result.exitCode == 0) return result;
      } catch (_) {}
    }

    if (_detectedPythonPath != null) {
      try {
        final result = await Process.run(_detectedPythonPath!, ['-m', 'yt_dlp', ...args]).timeout(timeout);
        if (result.exitCode == 0) return result;
      } catch (_) {}
    }

    return null;
  }

  // ── Stream URL Extraction ───────────────────────────────────────────────────

  /// Resolves the stream info (URL and matching HTTP headers) for [videoId].
  Future<YtStreamInfo> resolveStreamInfo(String videoId, {bool forceRefresh = false}) async {
    if (Platform.isIOS) {
      throw UnsupportedError('YT Stream is disabled on iOS');
    }
    final cleanId = videoId.replaceFirst('ytmusic://', '');

    if (!forceRefresh) {
      final cached = _streamInfoCache[cleanId];
      if (cached != null) {
        final age = DateTime.now().difference(_streamCacheTime[cleanId] ?? DateTime.now());
        if (age < _cacheTtl) {
          return cached;
        }
      }
    }

    if (Platform.isAndroid) {
      // Parallel race: native Dart AOT and Android Python Chaquopy simultaneously.
      // The fastest resolver returns immediately to achieve sub-second playback start.
      final completer = Completer<YtStreamInfo>();
      int errors = 0;
      const total = 2;

      void onDone(YtStreamInfo info) {
        if (!completer.isCompleted) {
          _streamInfoCache[cleanId] = info;
          _streamCacheTime[cleanId] = DateTime.now();
          completer.complete(info);
        }
      }

      void onError(Object e) {
        errors++;
        if (errors >= total && !completer.isCompleted) {
          completer.completeError(e);
        }
      }

      _resolveViaDartExplode(cleanId).then(onDone).catchError(onError);
      _resolveViaAndroidPython(cleanId).then(onDone).catchError(onError);

      return completer.future;
    }

    // Desktop
    try {
      final info = await _resolveViaDartExplode(cleanId);
      _streamInfoCache[cleanId] = info;
      _streamCacheTime[cleanId] = DateTime.now();
      return info;
    } catch (_) {
      final info = await _resolveViaDesktopYtDlp(cleanId);
      _streamInfoCache[cleanId] = info;
      _streamCacheTime[cleanId] = DateTime.now();
      return info;
    }
  }

  Future<YtStreamInfo> _resolveViaAndroidPython(String cleanId) async {
    final jsonStr = await _androidChannel.invokeMethod<String>('getStreamUrl', {'videoId': cleanId});
    if (jsonStr != null && jsonStr.isNotEmpty) {
      final data = jsonDecode(jsonStr) as Map<String, dynamic>;
      final url = data['url'] as String? ?? '';
      if (url.isNotEmpty) {
        final rawHeaders = data['headers'] as Map<String, dynamic>? ?? {};
        final headers = rawHeaders.map((k, v) => MapEntry(k.toString(), v.toString()));
        final ext = data['ext'] as String? ?? 'mp4';
        return YtStreamInfo(url: url, headers: headers, ext: ext);
      }
    }
    throw Exception('Empty stream info from Android Python');
  }

  Future<YtStreamInfo> _resolveViaDartExplode(String cleanId) async {
    final clients = [
      [yt.YoutubeApiClient.androidMusic],
      [yt.YoutubeApiClient.mweb],
      [yt.YoutubeApiClient.ios],
      null,
    ];

    Object? lastError;
    for (final clientList in clients) {
      try {
        final manifest = await _fallbackClient.videos.streamsClient.getManifest(
          cleanId,
          ytClients: clientList,
        );
        final audioOnly = manifest.audioOnly;
        if (audioOnly.isNotEmpty) {
          final best = audioOnly.withHighestBitrate();
          final url = best.url.toString();
          return YtStreamInfo(
            url: url,
            headers: {
              'User-Agent':
                  'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
            },
            ext: best.container.name,
          );
        }
      } catch (e) {
        lastError = e;
      }
    }
    throw lastError ?? Exception('No audio streams available via Dart for $cleanId');
  }

  Future<YtStreamInfo> _resolveViaDesktopYtDlp(String cleanId) async {
    final targetUrl = cleanId.startsWith('http') ? cleanId : 'https://www.youtube.com/watch?v=$cleanId';
    final result = await _runYtDlp([
      '-j',
      '-f', 'ba/b[acodec!=none]/bestaudio/best',
      '--extractor-args', 'youtube:player_client=mweb,android_music,android,ios',
      '--no-warnings',
      '--',
      targetUrl,
    ], timeout: const Duration(seconds: 15));

    if (result != null && result.exitCode == 0) {
      final json = jsonDecode(result.stdout.toString().trim()) as Map<String, dynamic>;
      final url = json['url'] as String?;
      if (url != null && url.isNotEmpty) {
        final rawHeaders = json['http_headers'] as Map<String, dynamic>? ?? {};
        final headers = rawHeaders.map((k, v) => MapEntry(k.toString(), v.toString()));
        final ext = json['ext'] as String? ?? 'mp4';
        return YtStreamInfo(url: url, headers: headers, ext: ext);
      }
    }
    throw Exception('Desktop yt-dlp resolution failed for $cleanId');
  }

  /// Extracts the direct audio stream URL for a given [videoId].
  Future<String> resolveStreamUrl(String videoId, {bool forceRefresh = false}) async {
    final info = await resolveStreamInfo(videoId, forceRefresh: forceRefresh);
    return info.url;
  }

  // ── Search & Discovery ──────────────────────────────────────────────────────

  // Modern music player design
  Future<Map<String, List<Map<String, dynamic>>>> searchDual(String query, {int limit = 25}) async {
    if (Platform.isIOS) {
      return {'music': [], 'youtube': []};
    }
    // 1. Android: Execute embedded Python interpreter with yt-dlp (Chaquopy)
    if (Platform.isAndroid) {
      try {
        final jsonStr = await _androidChannel.invokeMethod<String>('searchDual', {
          'query': query,
          'limit': limit,
        });
        if (jsonStr != null && jsonStr.isNotEmpty) {
          final dualResult = await compute(_decodeDualSearch, jsonStr);
          debugPrint('[yt-dlp/Android Python] Dual search "$query": ${dualResult['music']?.length ?? 0} music, ${dualResult['youtube']?.length ?? 0} youtube');
          return dualResult;
        }
      } catch (e) {
        debugPrint('[yt-dlp/Android Python] searchDual error: $e');
      }
    }

    // 2. Desktop: Parallel searches
    try {
      final results = await Future.wait([
        search('$query audio', limit: limit),
        search(query, limit: limit),
      ]);
      return {
        'music': results[0],
        'youtube': results[1],
      };
    } catch (_) {
      final single = await search(query, limit: limit);
      return {
        'music': single,
        'youtube': single,
      };
    }
  }

  // Modern music player design
  Future<List<Map<String, dynamic>>> search(String query, {int limit = 25}) async {
    if (Platform.isIOS) {
      return [];
    }
    // 1. Android: Execute embedded Python interpreter with yt-dlp (Chaquopy)
    if (Platform.isAndroid) {
      try {
        final jsonStr = await _androidChannel.invokeMethod<String>('search', {
          'query': query,
          'limit': limit,
        });
        if (jsonStr != null && jsonStr.isNotEmpty) {
          final items = await compute(_decodeJsonList, jsonStr);
          if (items.isNotEmpty) {
            debugPrint('[yt-dlp/Android Python] Search "$query" returned ${items.length} items');
            return items;
          }
        }
      } catch (e) {
        debugPrint('[yt-dlp/Android Python] Search error: $e');
      }
    }

    // 2. Desktop: Execute host Python / yt-dlp subprocess
    final searchParam = 'ytsearch$limit:$query';
    try {
      final result = await _runYtDlp([
        '--dump-json',
        '--flat-playlist',
        '--no-warnings',
        '--',
        searchParam,
      ], timeout: const Duration(seconds: 15));

      if (result != null && result.exitCode == 0) {
        final lines = result.stdout.toString().trim().split('\n');
        final items = <Map<String, dynamic>>[];

        for (final line in lines) {
          final trimmed = line.trim();
          if (trimmed.isEmpty) continue;
          try {
            final json = jsonDecode(trimmed) as Map<String, dynamic>;
            final id = json['id'] as String? ?? json['url'] as String?;
            if (id == null || id.isEmpty) continue;

            final title = json['title'] as String? ?? 'Unknown Title';
            final uploader = json['uploader'] as String? ??
                json['channel'] as String? ??
                json['artist'] as String? ??
                'Unknown Artist';
            final durationSec = (json['duration'] is num)
                ? (json['duration'] as num).toInt()
                : null;
            final thumbnails = json['thumbnails'] as List<dynamic>?;
            String? thumbUrl;
            if (thumbnails != null && thumbnails.isNotEmpty) {
              final last = thumbnails.last;
              if (last is Map && last['url'] != null) {
                thumbUrl = last['url'].toString();
              }
            }

            items.add({
              'id': id,
              'title': title,
              'artist': uploader,
              'album': json['album'] as String?,
              'duration': durationSec,
              'coverArt': id,
              'thumbnailUrl': thumbUrl,
            });
          } catch (_) {}
        }

        if (items.isNotEmpty) {
          debugPrint('[yt-dlp/Desktop Python] Search "$query" returned ${items.length} items');
          return items;
        }
      }
    } catch (e) {
      debugPrint('[yt-dlp/Desktop Python] Search error: $e');
    }

    // Modern music player design
    debugPrint('[yt-dlp] Falling back to youtube_explode_dart search');
    final searchResults = await _fallbackClient.search.search(
      query,
      filter: yt.TypeFilters.video,
    );

    return searchResults.take(limit).map((v) {
      final music = v.musicData.isNotEmpty ? v.musicData.first : null;
      return <String, dynamic>{
        'id': v.id.value,
        'title': music?.song ?? v.title,
        'artist': music?.artist ?? v.author,
        'album': music?.album,
        'duration': v.duration?.inSeconds,
        'coverArt': v.id.value,
        'thumbnailUrl': v.thumbnails.highResUrl,
      };
    }).toList();
  }

  // ── Playlist Retrieval ──────────────────────────────────────────────────────

  // Modern music player design
  Future<List<Map<String, dynamic>>> getPlaylistVideos(String playlistId, {int limit = 100}) async {
    // 1. Android: Execute embedded Python interpreter with yt-dlp (Chaquopy)
    if (Platform.isAndroid) {
      try {
        final jsonStr = await _androidChannel.invokeMethod<String>('getPlaylist', {
          'playlistId': playlistId,
          'limit': limit,
        });
        if (jsonStr != null && jsonStr.isNotEmpty) {
          final items = await compute(_decodeJsonList, jsonStr);
          if (items.isNotEmpty) {
            return items;
          }
        }
      } catch (e) {
        debugPrint('[yt-dlp/Android Python] getPlaylist error: $e');
      }
    }

    // 2. Desktop: Execute host Python / yt-dlp subprocess
    final playlistUrl = playlistId.startsWith('http')
        ? playlistId
        : 'https://www.youtube.com/playlist?list=$playlistId';

    try {
      final result = await _runYtDlp([
        '--dump-json',
        '--flat-playlist',
        '--no-warnings',
        '--',
        playlistUrl,
      ], timeout: const Duration(seconds: 20));

      if (result != null && result.exitCode == 0) {
        final lines = result.stdout.toString().trim().split('\n');
        final items = <Map<String, dynamic>>[];

        for (final line in lines.take(limit)) {
          final trimmed = line.trim();
          if (trimmed.isEmpty) continue;
          try {
            final json = jsonDecode(trimmed) as Map<String, dynamic>;
            final id = json['id'] as String? ?? json['url'] as String?;
            if (id == null || id.isEmpty) continue;

            final title = json['title'] as String? ?? 'Unknown Title';
            final uploader = json['uploader'] as String? ??
                json['channel'] as String? ??
                json['artist'] as String? ??
                'Unknown Artist';
            final durationSec = (json['duration'] is num)
                ? (json['duration'] as num).toInt()
                : null;

            items.add({
              'id': id,
              'title': title,
              'artist': uploader,
              'album': json['album'] as String?,
              'duration': durationSec,
              'coverArt': id,
            });
          } catch (_) {}
        }

        if (items.isNotEmpty) {
          return items;
        }
      }
    } catch (e) {
      debugPrint('[yt-dlp/Desktop Python] getPlaylist error: $e');
    }

    // Modern music player design
    final videos = await _fallbackClient.playlists.getVideos(playlistId).take(limit).toList();
    return videos.map((v) {
      final music = v.musicData.isNotEmpty ? v.musicData.first : null;
      return <String, dynamic>{
        'id': v.id.value,
        'title': music?.song ?? v.title,
        'artist': music?.artist ?? v.author,
        'album': music?.album,
        'duration': v.duration?.inSeconds,
        'coverArt': v.id.value,
        'thumbnailUrl': v.thumbnails.highResUrl,
      };
    }).toList();
  }

  // Modern music player design
  Future<List<Map<String, dynamic>>> getRadioTracks(String videoId, {int limit = 50}) async {
    final radioUrl = 'https://music.youtube.com/watch?v=$videoId&list=RD$videoId';
    final fallbackRadioUrl = 'https://www.youtube.com/watch?v=$videoId&list=RD$videoId';

    // 1. Android: Chaquopy Python
    if (Platform.isAndroid) {
      try {
        final jsonStr = await _androidChannel.invokeMethod<String>('getPlaylist', {
          'playlistId': 'RDAMVM$videoId',
          'limit': limit,
        });
        if (jsonStr != null && jsonStr.isNotEmpty) {
          final items = await compute(_decodeJsonList, jsonStr);
          if (items.isNotEmpty) return items;
        }
      } catch (e) {
        debugPrint('[yt-dlp/Android Python] getRadioTracks RDAMVM error: $e');
      }

      // Try RD fallback on Android
      try {
        final jsonStr = await _androidChannel.invokeMethod<String>('getPlaylist', {
          'playlistId': fallbackRadioUrl,
          'limit': limit,
        });
        if (jsonStr != null && jsonStr.isNotEmpty) {
          final items = await compute(_decodeJsonList, jsonStr);
          if (items.isNotEmpty) return items;
        }
      } catch (_) {}
    }

    // 2. Desktop: Subprocess execution with yt-dlp
    final urlsToTry = [radioUrl, fallbackRadioUrl];
    for (final url in urlsToTry) {
      try {
        final result = await _runYtDlp([
          '--flat-playlist',
          '--dump-json',
          '--playlist-items',
          '1:$limit',
          '--no-warnings',
          '--',
          url,
        ], timeout: const Duration(seconds: 15));

        if (result != null && result.exitCode == 0) {
          final lines = result.stdout.toString().trim().split('\n');
          final items = <Map<String, dynamic>>[];

          for (final line in lines) {
            final trimmed = line.trim();
            if (trimmed.isEmpty) continue;
            try {
              final json = jsonDecode(trimmed) as Map<String, dynamic>;
              final id = json['id'] as String? ?? json['url'] as String?;
              if (id == null || id.isEmpty) continue;

              final title = json['title'] as String? ?? 'Unknown Title';
              final uploader = json['uploader'] as String? ??
                  json['channel'] as String? ??
                  json['artist'] as String? ??
                  'Unknown Artist';
              final durationSec = (json['duration'] is num)
                  ? (json['duration'] as num).toInt()
                  : null;
              final thumbnails = json['thumbnails'] as List<dynamic>?;
              String? thumbUrl;
              if (thumbnails != null && thumbnails.isNotEmpty) {
                final last = thumbnails.last;
                if (last is Map && last['url'] != null) {
                  thumbUrl = last['url'].toString();
                }
              }

              items.add({
                'id': id,
                'title': title,
                'artist': uploader,
                'album': json['album'] as String?,
                'duration': durationSec,
                'coverArt': id,
                'thumbnailUrl': thumbUrl,
              });
            } catch (_) {}
          }

          if (items.isNotEmpty) {
            return items;
          }
        }
      } catch (e) {
        debugPrint('[yt-dlp/Desktop Python] getRadioTracks error for $url: $e');
      }
    }

    return [];
  }

  // ── Video Metadata ──────────────────────────────────────────────────────────

  /// Fetches metadata for a single video.
  Future<Map<String, dynamic>?> getVideoInfo(String videoId) async {
    final cleanId = videoId.replaceFirst('ytmusic://', '');

    // 1. Android: Execute embedded Python interpreter with yt-dlp (Chaquopy)
    if (Platform.isAndroid) {
      try {
        final jsonStr = await _androidChannel.invokeMethod<String>('getVideoInfo', {
          'videoId': cleanId,
        });
        if (jsonStr != null && jsonStr.isNotEmpty) {
          final map = await compute(_decodeJsonMap, jsonStr);
          return map;
        }
      } catch (e) {
        debugPrint('[yt-dlp/Android Python] getVideoInfo error: $e');
      }
    }

    // 2. Desktop: Execute host Python / yt-dlp subprocess
    final targetUrl = cleanId.startsWith('http') ? cleanId : 'https://www.youtube.com/watch?v=$cleanId';

    try {
      final result = await _runYtDlp([
        '-j',
        '--no-warnings',
        '--',
        targetUrl,
      ], timeout: const Duration(seconds: 10));

      if (result != null && result.exitCode == 0) {
        final json = jsonDecode(result.stdout.toString().trim()) as Map<String, dynamic>;
        final title = json['title'] as String? ?? 'Unknown Title';
        final artist = json['uploader'] as String? ?? json['channel'] as String? ?? 'Unknown Artist';
        final duration = (json['duration'] is num) ? (json['duration'] as num).toInt() : null;

        return {
          'id': cleanId,
          'title': title,
          'artist': artist,
          'album': json['album'] as String?,
          'duration': duration,
          'coverArt': cleanId,
        };
      }
    } catch (_) {}

    // Modern music player design
    try {
      final video = await _fallbackClient.videos.get(cleanId);
      final music = video.musicData.isNotEmpty ? video.musicData.first : null;
      return {
        'id': video.id.value,
        'title': music?.song ?? video.title,
        'artist': music?.artist ?? video.author,
        'album': music?.album,
        'duration': video.duration?.inSeconds,
        'coverArt': video.id.value,
      };
    } catch (e) {
      debugPrint('[yt-dlp] getVideoInfo fallback error: $e');
      return null;
    }
  }
}
