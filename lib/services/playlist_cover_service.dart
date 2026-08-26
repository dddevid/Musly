import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:path_provider/path_provider.dart';
import 'package:crypto/crypto.dart';
import '../models/song.dart';
import 'subsonic_service.dart';
import 'offline_service.dart';

bool _isLocalFile(String? s) {
  if (s == null || s.isEmpty) return false;
  if (s.startsWith('/')) return true;
  if (s.length > 2 && s[1] == ':') return true;
  return false;
}

class PlaylistCoverService {
  static final PlaylistCoverService _instance =
      PlaylistCoverService._internal();
  factory PlaylistCoverService() => _instance;
  PlaylistCoverService._internal();

  final Map<String, String> _coverPaths = {};
  final Set<String> _inProgress = {};
  Directory? _coverDir;
  bool _initialized = false;

  final ValueNotifier<int> coverUpdates = ValueNotifier<int>(0);

  Future<void> init() async {
    if (_initialized) return;
    try {
      final appDir = await getApplicationSupportDirectory();
      _coverDir = Directory('${appDir.path}/musly_playlist_covers');
      if (!await _coverDir!.exists()) {
        await _coverDir!.create(recursive: true);
      } else {
        final entities = _coverDir!.listSync();
        for (final entity in entities) {
          if (entity is File && entity.path.endsWith('.png')) {
            final filename = entity.uri.pathSegments.last;

            if (filename.startsWith('playlist_mosaic_')) {
              final withoutPrefix =
                  filename.substring('playlist_mosaic_'.length);
              final lastUnderscore = withoutPrefix.lastIndexOf('_');
              if (lastUnderscore != -1) {
                final playlistId = withoutPrefix.substring(0, lastUnderscore);
                _coverPaths[playlistId] = entity.path;
              }
            }
          }
        }
      }
      _initialized = true;
    } catch (e) {
      debugPrint('[PlaylistCoverService] init error: $e');
    }
  }

  String? getCoverPath(String playlistId) {
    final path = _coverPaths[playlistId];
    if (path != null && File(path).existsSync()) {
      return path;
    }

    if (_coverDir != null && _coverDir!.existsSync()) {
      try {
        final matches = _coverDir!
            .listSync()
            .whereType<File>()
            .where((f) =>
                f.path.contains('playlist_mosaic_${playlistId}_') &&
                f.path.endsWith('.png'))
            .toList();
        if (matches.isNotEmpty) {
          _coverPaths[playlistId] = matches.first.path;
          return matches.first.path;
        }
      } catch (_) {}
    }
    return null;
  }

  String? computeSignature(List<Song> songs) {
    final distinctCovers = <String>[];
    final seen = <String>{};
    for (final s in songs) {
      final c = s.coverArt ?? (s.id.isNotEmpty ? s.id : null);
      if (c != null && c.isNotEmpty && !seen.contains(c)) {
        seen.add(c);
        distinctCovers.add(c);
        if (distinctCovers.length == 4) break;
      }
    }
    if (distinctCovers.length < 2) return null;
    return md5.convert(utf8.encode(distinctCovers.join('::'))).toString();
  }

  Future<String?> checkAndGenerateCover({
    required String playlistId,
    required List<Song> songs,
    required SubsonicService subsonicService,
  }) async {
    if (playlistId.isEmpty || songs.isEmpty) return null;
    await init();

    final distinctCovers = <String>[];
    final seen = <String>{};
    for (final s in songs) {
      final c = s.coverArt ?? (s.id.isNotEmpty ? s.id : null);
      if (c != null && c.isNotEmpty && !seen.contains(c)) {
        seen.add(c);
        distinctCovers.add(c);
        if (distinctCovers.length == 4) break;
      }
    }

    if (distinctCovers.length < 2) {
      return null;
    }

    final signature =
        md5.convert(utf8.encode(distinctCovers.join('::'))).toString();
    final expectedFilename = 'playlist_mosaic_${playlistId}_$signature.png';
    final expectedFile = File('${_coverDir!.path}/$expectedFilename');

    if (await expectedFile.exists() && (await expectedFile.length()) > 500) {
      _coverPaths[playlistId] = expectedFile.path;
      return expectedFile.path;
    }

    if (_inProgress.contains(playlistId)) {
      return null;
    }

    _inProgress.add(playlistId);
    try {
      final resultPath = await _generateMosaic(
        playlistId: playlistId,
        covers: distinctCovers,
        signature: signature,
        subsonicService: subsonicService,
      );
      if (resultPath != null) {
        _coverPaths[playlistId] = resultPath;
        coverUpdates.value++;
      }
      return resultPath;
    } catch (e) {
      debugPrint(
          '[PlaylistCoverService] Error generating mosaic for playlist $playlistId: $e');
      return null;
    } finally {
      _inProgress.remove(playlistId);
    }
  }

  Future<String?> _generateMosaic({
    required String playlistId,
    required List<String> covers,
    required String signature,
    required SubsonicService subsonicService,
  }) async {
    final List<String> fourCovers;
    if (covers.length >= 4) {
      fourCovers = [covers[0], covers[1], covers[2], covers[3]];
    } else if (covers.length == 3) {
      fourCovers = [covers[0], covers[1], covers[2], covers[0]];
    } else {
      fourCovers = [covers[0], covers[1], covers[1], covers[0]];
    }

    final imageFutures =
        fourCovers.map((c) => _loadCoverImage(c, subsonicService)).toList();
    final images = await Future.wait(imageFutures);

    const int targetSize = 512;
    const double halfSize = targetSize / 2.0;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder,
        Rect.fromLTWH(0, 0, targetSize.toDouble(), targetSize.toDouble()));

    final bgPaint = Paint()..color = const Color(0xFF1E1E1E);
    canvas.drawRect(
        Rect.fromLTWH(0, 0, targetSize.toDouble(), targetSize.toDouble()),
        bgPaint);

    final quadrants = [
      const Rect.fromLTWH(0, 0, halfSize, halfSize),
      const Rect.fromLTWH(halfSize, 0, halfSize, halfSize),
      const Rect.fromLTWH(0, halfSize, halfSize, halfSize),
      const Rect.fromLTWH(halfSize, halfSize, halfSize, halfSize),
    ];

    for (int i = 0; i < 4; i++) {
      final img = images[i];
      if (img != null) {
        paintImage(
          canvas: canvas,
          rect: quadrants[i],
          image: img,
          fit: BoxFit.cover,
        );
      } else {
        final pPaint = Paint()..color = const Color(0xFF2C2C2C);
        canvas.drawRect(quadrants[i], pPaint);
      }
    }

    final picture = recorder.endRecording();
    final compositeUiImage = await picture.toImage(targetSize, targetSize);
    final byteData =
        await compositeUiImage.toByteData(format: ui.ImageByteFormat.png);

    if (byteData == null) return null;
    final bytes = byteData.buffer.asUint8List();

    try {
      final oldFiles = _coverDir!.listSync().whereType<File>().where((f) =>
          f.path.contains('playlist_mosaic_${playlistId}_') &&
          f.path.endsWith('.png'));
      for (final oldFile in oldFiles) {
        try {
          oldFile.deleteSync();
        } catch (_) {}
      }
    } catch (_) {}

    final targetFile =
        File('${_coverDir!.path}/playlist_mosaic_${playlistId}_$signature.png');
    await targetFile.writeAsBytes(bytes, flush: true);
    return targetFile.path;
  }

  Future<ui.Image?> _loadCoverImage(
      String coverArt, SubsonicService subsonicService) async {
    try {
      Uint8List? bytes;

      if (_isLocalFile(coverArt)) {
        final file = File(coverArt);
        if (await file.exists()) {
          bytes = await file.readAsBytes();
        }
      }

      if (bytes == null) {
        final offlinePath =
            OfflineService().getLocalCoverArtPathByCoverArtId(coverArt);
        if (offlinePath != null && await File(offlinePath).exists()) {
          bytes = await File(offlinePath).readAsBytes();
        }
      }

      if (bytes == null) {
        final imageUrl = subsonicService.getCoverArtUrl(coverArt, size: 300);
        if (imageUrl.isNotEmpty) {
          final file = await DefaultCacheManager().getSingleFile(imageUrl);
          if (await file.exists()) {
            bytes = await file.readAsBytes();
          }
        }
      }

      if (bytes != null && bytes.isNotEmpty) {
        final codec = await ui.instantiateImageCodec(bytes,
            targetWidth: 256, targetHeight: 256);
        final frame = await codec.getNextFrame();
        return frame.image;
      }
    } catch (e) {
      debugPrint('[PlaylistCoverService] Error loading cover $coverArt: $e');
    }
    return null;
  }
}
