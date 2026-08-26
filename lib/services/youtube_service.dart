import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';
import 'library_database_service.dart';
import 'subsonic_service.dart';
import 'ytdlp_service.dart';

class _YoutubeStreamAudioSource extends StreamAudioSource {
  final String _videoId;
  final YtDlpService _ytdlp;
  static HttpClient? _sharedClient;

  static HttpClient get _client {
    _sharedClient ??= HttpClient()
      ..idleTimeout = const Duration(minutes: 5)
      ..connectionTimeout = const Duration(seconds: 15)
      ..autoUncompress = false;
    return _sharedClient!;
  }

  _YoutubeStreamAudioSource(this._videoId, this._ytdlp) : super(tag: _videoId);

  String _sanitizeId(String id) {
    return id.replaceAll(RegExp(r'[^a-zA-Z0-9_\-]'), '_');
  }

  Future<File?> _getCachedFile(String cleanId) async {
    try {
      final safeId = _sanitizeId(cleanId);
      final tempDir = await getTemporaryDirectory();
      final cacheDir = Directory('${tempDir.path}/musly_yt_cache');
      if (!cacheDir.existsSync()) {
        await cacheDir.create(recursive: true);
      }
      final file = File('${cacheDir.path}/yt_$safeId.audio');
      if (await file.exists() && (await file.length()) > 10000) {
        return file;
      }
    } catch (_) {}
    return null;
  }

  Future<File> _getPartFile(String cleanId) async {
    final safeId = _sanitizeId(cleanId);
    final tempDir = await getTemporaryDirectory();
    final cacheDir = Directory('${tempDir.path}/musly_yt_cache');
    if (!cacheDir.existsSync()) {
      await cacheDir.create(recursive: true);
    }
    return File('${cacheDir.path}/yt_$safeId.part');
  }

  @override
  Future<StreamAudioResponse> request([int? start, int? end]) async {
    final cleanId = _videoId.replaceFirst('ytmusic://', '');

    final cachedFile = await _getCachedFile(cleanId);
    if (cachedFile != null) {
      final fileLength = await cachedFile.length();
      final s = start ?? 0;
      final e = (end != null && end < fileLength) ? end + 1 : fileLength;
      final contentLength = e - s;

      final isWebm = cachedFile.path.endsWith('.webm') ||
          cachedFile.path.endsWith('.opus');
      final type = isWebm ? 'audio/webm' : 'audio/mp4';

      debugPrint(
          '[Web Stream] Serving "$cleanId" from local disk cache ($s-$e of $fileLength bytes)');
      return StreamAudioResponse(
        sourceLength: fileLength,
        contentLength: contentLength > 0 ? contentLength : null,
        offset: s,
        stream: cachedFile.openRead(s, e),
        contentType: type,
      );
    }

    int retries = 0;
    while (true) {
      try {
        final streamInfo =
            await _ytdlp.resolveStreamInfo(cleanId, forceRefresh: retries > 0);
        final s = start ?? 0;

        final req = await _client.getUrl(Uri.parse(streamInfo.url));

        streamInfo.headers.forEach((key, value) {
          final lower = key.toLowerCase();
          if (lower != 'host' && lower != 'content-length') {
            req.headers.set(key, value);
          }
        });

        if (end != null) {
          req.headers.set('Range', 'bytes=$s-$end');
        } else if (s > 0) {
          req.headers.set('Range', 'bytes=$s-');
        }

        final resp = await req.close();

        if (resp.statusCode == 403 || resp.statusCode == 429) {
          debugPrint(
              '[Web Stream] Stream rejected (${resp.statusCode}) for $cleanId, refreshing...');
          _ytdlp.invalidateCache(cleanId);
          if (retries < 2) {
            retries++;
            await Future.delayed(Duration(milliseconds: 300 * retries));
            continue;
          }
        }

        if (resp.statusCode >= 400) {
          if (retries < 2) {
            retries++;
            await Future.delayed(Duration(milliseconds: 300 * retries));
            continue;
          }
          throw Exception('GoogleVideo stream error: HTTP ${resp.statusCode}');
        }

        final total = resp.contentLength >= 0 ? resp.contentLength + s : null;
        final isWebm = (streamInfo.ext == 'webm' || streamInfo.ext == 'opus');
        final type = isWebm ? 'audio/webm' : 'audio/mp4';

        if (s == 0 && end == null) {
          final partFile = await _getPartFile(cleanId);
          final controller = StreamController<List<int>>();
          IOSink? sink;
          try {
            sink = partFile.openWrite();
          } catch (_) {}

          resp.listen(
            (chunk) {
              controller.add(chunk);
              try {
                sink?.add(chunk);
              } catch (_) {}
            },
            onError: (err, st) {
              controller.addError(err, st);
              sink?.close().catchError((_) {});
            },
            onDone: () async {
              await controller.close();
              try {
                await sink?.flush();
                await sink?.close();
                if (await partFile.exists() &&
                    (await partFile.length()) > 50000) {
                  final safeId = _sanitizeId(cleanId);
                  final tempDir = await getTemporaryDirectory();
                  final target =
                      File('${tempDir.path}/musly_yt_cache/yt_$safeId.audio');
                  await partFile.rename(target.path);
                  debugPrint(
                      '[Web Stream] Cached complete audio for "$cleanId" to disk');
                }
              } catch (_) {}
            },
            cancelOnError: false,
          );

          return StreamAudioResponse(
            sourceLength: total,
            contentLength: resp.contentLength >= 0 ? resp.contentLength : null,
            offset: 0,
            stream: controller.stream,
            contentType: type,
          );
        }

        return StreamAudioResponse(
          sourceLength: total,
          contentLength: resp.contentLength >= 0 ? resp.contentLength : null,
          offset: s,
          stream: resp,
          contentType: type,
        );
      } catch (e) {
        if (retries < 2) {
          retries++;
          debugPrint(
              '[Web Stream] Retrying request for $cleanId (attempt $retries): $e');
          await Future.delayed(Duration(milliseconds: 400 * retries));
          continue;
        }
        debugPrint(
            '[Web Stream] StreamAudioSource request failed for $cleanId: $e');
        rethrow;
      }
    }
  }
}

class YoutubeService {
  final YtDlpService _ytdlp = YtDlpService();
  final LibraryDatabaseService _db = LibraryDatabaseService();

  void dispose() {
    _ytdlp.dispose();
  }

  Future<PingResult> pingWithError() async {
    try {
      final req = await HttpClient().getUrl(
        Uri.parse('https://music.youtube.com/'),
      );
      req.headers.set('User-Agent', 'Mozilla/5.0');
      final res = await req.close();
      await res.drain<void>();
      return PingResult(
        success: res.statusCode < 400,
        serverType: 'Web Stream (yt-dlp)',
        serverVersion: '1.0',
      );
    } catch (e) {
      return PingResult(
          success: false, error: 'Cannot reach stream service: $e');
    }
  }

  String getCoverArtUrl(String? id, {int size = 800}) {
    if (id == null || id.isEmpty) return '';
    final effectiveSize = size > 0 ? size : 800;

    if (id.startsWith('http://') || id.startsWith('https://')) {
      if (id.contains('googleusercontent.com') || id.contains('ggpht.com')) {
        final base = id.split('=')[0];
        return '$base=w$effectiveSize-h$effectiveSize-l90-rj';
      }

      if (id.contains('i.ytimg.com') || id.contains('img.youtube.com')) {
        final match = RegExp(r'/vi/([a-zA-Z0-9_-]{11})').firstMatch(id);
        if (match != null) {
          final vid = match.group(1);
          return 'https://i.ytimg.com/vi/$vid/hqdefault.jpg';
        }
      }
      return id;
    }

    if (RegExp(r'^[a-zA-Z0-9_-]{11}$').hasMatch(id)) {
      return 'https://i.ytimg.com/vi/$id/hqdefault.jpg';
    }
    return '';
  }

  String getStreamUrl(String videoId) => 'ytmusic://$videoId';

  Future<String> resolveStreamUrl(String videoId) async {
    final cleanId = videoId.replaceFirst('ytmusic://', '');
    return await _ytdlp.resolveStreamUrl(cleanId);
  }

  Future<StreamAudioSource> buildAudioSource(String videoId) async {
    return _YoutubeStreamAudioSource(videoId, _ytdlp);
  }

  Song _mapDictToSong(Map<String, dynamic> d) {
    final id = d['id'] as String;
    final thumb = d['thumbnailUrl'] as String?;
    final coverArt = (thumb != null && thumb.isNotEmpty)
        ? getCoverArtUrl(thumb, size: 800)
        : (d['coverArt'] != null && d['coverArt'].toString().startsWith('http')
            ? getCoverArtUrl(d['coverArt'].toString(), size: 800)
            : getCoverArtUrl(id, size: 800));

    return Song(
      id: id,
      title: d['title'] as String? ?? 'Unknown Title',
      artist: d['artist'] as String? ?? 'Unknown Artist',
      album: d['album'] as String?,
      duration: d['duration'] as int?,
      coverArt: coverArt,
    );
  }

  Future<List<Artist>> getArtists() async {
    try {
      final starredSongs = await _db.getStarredSongs();
      final playlists = await _db.getAllPlaylists();
      final artistNames = <String>{};
      final artists = <Artist>[];

      void addArtist(String? name, String? coverArt, String? artistId) {
        if (name == null || name.trim().isEmpty) return;
        final cleanName = name.trim();
        if (!artistNames.contains(cleanName)) {
          artistNames.add(cleanName);
          artists.add(Artist(
            id: artistId ?? cleanName,
            name: cleanName,
            coverArt: coverArt,
          ));
        }
      }

      for (final s in starredSongs) {
        addArtist(s.artist, s.coverArt, s.artistId);
      }

      for (final p in playlists) {
        if (p.songs != null) {
          for (final s in p.songs!) {
            addArtist(s.artist, s.coverArt, s.artistId);
          }
        }
      }

      return artists;
    } catch (e) {
      debugPrint('[YouTube] getArtists error: $e');
      return [];
    }
  }

  Future<List<Album>> getAlbumList({
    String type = 'recent',
    int size = 20,
    int offset = 0,
  }) async {
    try {
      final albums = await _db.getStarredAlbums();
      return albums.skip(offset).take(size).toList();
    } catch (e) {
      debugPrint('[YouTube] getAlbumList error: $e');
      return [];
    }
  }

  Future<Album> getAlbum(String playlistOrAlbumId) async {
    try {
      final songs = await getAlbumSongs(playlistOrAlbumId);
      return Album(
        id: playlistOrAlbumId,
        name: songs.isNotEmpty ? (songs.first.album ?? 'Album') : 'Album',
        artist: songs.isNotEmpty ? songs.first.artist : 'Artist',
        coverArt: playlistOrAlbumId,
        songCount: songs.length,
      );
    } catch (e) {
      debugPrint('[YouTube] getAlbum error: $e');
      return Album(id: playlistOrAlbumId, name: 'Album');
    }
  }

  Future<List<Song>> getAlbumSongs(String albumId) async {
    try {
      final starred = await _db.getStarredSongs();
      final matching = starred
          .where((s) => s.albumId == albumId || s.album == albumId)
          .toList();
      if (matching.isNotEmpty) return matching;

      final videos = await _ytdlp.getPlaylistVideos(albumId);
      return videos.map(_mapDictToSong).toList();
    } catch (e) {
      debugPrint('[YouTube] getAlbumSongs error: $e');
      return [];
    }
  }

  Future<List<Album>> getArtistAlbums(String channelOrArtistId) async {
    try {
      final starred = await _db.getStarredSongs();
      final artistSongs = starred
          .where((s) =>
              s.artistId == channelOrArtistId || s.artist == channelOrArtistId)
          .toList();
      final albumMap = <String, Album>{};
      for (final s in artistSongs) {
        if (s.album != null &&
            s.album!.isNotEmpty &&
            !albumMap.containsKey(s.album)) {
          albumMap[s.album!] = Album(
            id: s.albumId ?? s.album!,
            name: s.album!,
            artist: s.artist,
            coverArt: s.coverArt,
          );
        }
      }
      return albumMap.values.toList();
    } catch (e) {
      debugPrint('[YouTube] getArtistAlbums error: $e');
      return [];
    }
  }

  Future<List<Playlist>> getPlaylists() async {
    try {
      final playlists = await _db.getAllPlaylists();
      final result = <Playlist>[];
      for (final p in playlists) {
        if (p.songs != null && p.songs!.isNotEmpty) {
          final resolvedSongs = <Song>[];
          final missingIds = <String>[];
          for (final s in p.songs!) {
            if (s.title != 'Unknown' && s.title.isNotEmpty) {
              resolvedSongs.add(s);
            } else {
              missingIds.add(s.id);
            }
          }
          if (missingIds.isNotEmpty) {
            final fromDb = await _db.getSongs(missingIds);
            final map = {for (final s in fromDb) s.id: s};
            for (final s in p.songs!) {
              if (s.title == 'Unknown' || s.title.isEmpty) {
                resolvedSongs.add(map[s.id] ?? s);
              }
            }
          }
          result.add(p.copyWith(
            songs: resolvedSongs,
            songCount: resolvedSongs.length,
            coverArt:
                resolvedSongs.isNotEmpty && resolvedSongs.first.coverArt != null
                    ? resolvedSongs.first.coverArt
                    : p.coverArt,
          ));
        } else {
          result.add(p);
        }
      }
      return result;
    } catch (e) {
      debugPrint('[YouTube] getPlaylists error: $e');
      return [];
    }
  }

  Future<Playlist> getPlaylist(String id) async {
    try {
      final local = await _db.getPlaylist(id);
      if (local != null) {
        if (local.songs != null && local.songs!.isNotEmpty) {
          final resolvedSongs = <Song>[];
          for (final s in local.songs!) {
            if (s.title != 'Unknown' && s.title.isNotEmpty) {
              resolvedSongs.add(s);
            } else {
              final inDb = await _db.getSong(s.id);
              if (inDb != null && inDb.title != 'Unknown') {
                resolvedSongs.add(inDb);
              } else {
                try {
                  final info = await _ytdlp.getVideoInfo(s.id);
                  if (info != null) {
                    final newSong = _mapDictToSong(info);
                    await _db.insertOrUpdateSong(newSong);
                    resolvedSongs.add(newSong);
                  } else {
                    resolvedSongs.add(s);
                  }
                } catch (_) {
                  resolvedSongs.add(s);
                }
              }
            }
          }
          final updated = local.copyWith(
            songs: resolvedSongs,
            songCount: resolvedSongs.length,
            coverArt:
                resolvedSongs.isNotEmpty && resolvedSongs.first.coverArt != null
                    ? resolvedSongs.first.coverArt
                    : local.coverArt,
          );

          await _db.insertOrUpdatePlaylist(updated);
          return updated;
        }
        return local;
      }

      final items = await _ytdlp.getPlaylistVideos(id);
      final songs = items.map(_mapDictToSong).toList();
      return Playlist(
        id: id,
        name: 'Web Stream Playlist',
        songCount: songs.length,
        songs: songs,
      );
    } catch (e) {
      debugPrint('[YouTube] getPlaylist error: $e');
      return Playlist(id: id, name: 'Playlist');
    }
  }

  Future<void> createPlaylist({
    required String name,
    String? comment,
    List<String>? songIds,
  }) async {
    try {
      final newId = const Uuid().v4();
      List<Song> songs = [];
      if (songIds != null && songIds.isNotEmpty) {
        final existingSongs = await _db.getSongs(songIds);
        final foundMap = {for (final s in existingSongs) s.id: s};
        for (final sid in songIds) {
          if (foundMap.containsKey(sid)) {
            songs.add(foundMap[sid]!);
          } else {
            try {
              final info = await _ytdlp.getVideoInfo(sid);
              if (info != null) {
                final newSong = _mapDictToSong(info);
                await _db.insertOrUpdateSong(newSong);
                songs.add(newSong);
              } else {
                songs.add(Song(id: sid, title: 'Track'));
              }
            } catch (_) {
              songs.add(Song(id: sid, title: 'Track'));
            }
          }
        }
      }

      final playlist = Playlist(
        id: newId,
        name: name,
        comment: comment,
        owner: 'Local',
        songCount: songs.length,
        created: DateTime.now(),
        changed: DateTime.now(),
        coverArt: songs.isNotEmpty ? songs.first.coverArt : null,
        songs: songs,
      );

      await _db.insertOrUpdatePlaylist(playlist);
      debugPrint(
          '[YouTube] Created local playlist: $name (id: $newId, songs: ${songs.length})');
    } catch (e) {
      debugPrint('[YouTube] createPlaylist error: $e');
      rethrow;
    }
  }

  Future<void> updatePlaylist({
    required String playlistId,
    String? name,
    String? comment,
    List<String>? songIdsToAdd,
    List<int>? songIndexesToRemove,
  }) async {
    try {
      final existing = await _db.getPlaylist(playlistId);
      if (existing == null) {
        throw Exception('Playlist $playlistId not found in local library');
      }

      final currentSongs = List<Song>.from(existing.songs ?? []);

      if (songIndexesToRemove != null && songIndexesToRemove.isNotEmpty) {
        final sortedIndices = List<int>.from(songIndexesToRemove)
          ..sort((a, b) => b.compareTo(a));
        for (final idx in sortedIndices) {
          if (idx >= 0 && idx < currentSongs.length) {
            currentSongs.removeAt(idx);
          }
        }
      }

      if (songIdsToAdd != null && songIdsToAdd.isNotEmpty) {
        for (final sid in songIdsToAdd) {
          final s = await _db.getSong(sid);
          if (s != null && s.title != 'Unknown') {
            currentSongs.add(s);
          } else {
            final info = await _ytdlp.getVideoInfo(sid);
            final newSong = info != null
                ? _mapDictToSong(info)
                : Song(id: sid, title: 'Stream Track');
            await _db.insertOrUpdateSong(newSong);
            currentSongs.add(newSong);
          }
        }
      }

      final updated = existing.copyWith(
        name: name ?? existing.name,
        comment: comment ?? existing.comment,
        changed: DateTime.now(),
        songCount: currentSongs.length,
        coverArt: currentSongs.isNotEmpty
            ? currentSongs.first.coverArt
            : existing.coverArt,
        songs: currentSongs,
      );

      await _db.insertOrUpdatePlaylist(updated);
      debugPrint(
          '[YouTube] Updated local playlist $playlistId (now ${currentSongs.length} songs)');
    } catch (e) {
      debugPrint('[YouTube] updatePlaylist error: $e');
      rethrow;
    }
  }

  Future<void> deletePlaylist(String id) async {
    try {
      await _db.deletePlaylist(id);
      debugPrint('[YouTube] Deleted local playlist: $id');
    } catch (e) {
      debugPrint('[YouTube] deletePlaylist error: $e');
      rethrow;
    }
  }

  Future<SearchResult> search(
    String query, {
    int artistCount = 20,
    int albumCount = 20,
    int songCount = 20,
  }) async {
    try {
      final dualResults = await _ytdlp.searchDual(query, limit: songCount);
      final musicSongs =
          (dualResults['music'] ?? []).map(_mapDictToSong).toList();
      final youtubeVideos =
          (dualResults['youtube'] ?? []).map(_mapDictToSong).toList();

      final localSongs = await _db.searchSongs(query, limit: songCount);

      final mergedMusic = <Song>[...musicSongs];
      final seenIds = musicSongs.map((s) => s.id).toSet();
      for (final ls in localSongs) {
        if (!seenIds.contains(ls.id)) {
          mergedMusic.add(ls);
          seenIds.add(ls.id);
        }
      }

      final artists = <Artist>[];
      final albums = <Album>[];
      final seenArtists = <String>{};
      final seenAlbums = <String>{};

      for (final s in [...mergedMusic, ...youtubeVideos]) {
        if (s.artist != null &&
            s.artist!.isNotEmpty &&
            !seenArtists.contains(s.artist)) {
          seenArtists.add(s.artist!);
          artists.add(Artist(
              id: s.artistId ?? s.artist!,
              name: s.artist!,
              coverArt: s.coverArt));
        }
        if (s.album != null &&
            s.album!.isNotEmpty &&
            !seenAlbums.contains(s.album)) {
          seenAlbums.add(s.album!);
          albums.add(Album(
              id: s.albumId ?? s.album!,
              name: s.album!,
              artist: s.artist,
              coverArt: s.coverArt));
        }
      }

      return SearchResult(
        artists: artists.take(artistCount).toList(),
        albums: albums.take(albumCount).toList(),
        songs: mergedMusic.take(songCount).toList(),
        youtubeVideos: youtubeVideos.take(songCount).toList(),
      );
    } catch (e) {
      debugPrint('[YouTube] search error: $e');
      return SearchResult(artists: [], albums: [], songs: []);
    }
  }

  Future<List<Song>> getRandomSongs({int size = 20, String? genre}) async {
    try {
      String query;
      if (genre != null && genre.isNotEmpty) {
        query = '$genre music hits';
      } else {
        final allDbSongs = await _db.getAllSongs();
        if (allDbSongs.isNotEmpty) {
          final artistCounts = <String, int>{};
          for (final s in allDbSongs) {
            if (s.artist != null &&
                s.artist!.isNotEmpty &&
                s.artist != 'Unknown') {
              artistCounts[s.artist!] =
                  (artistCounts[s.artist!] ?? 0) + (s.userRating ?? 1);
            }
          }
          if (artistCounts.isNotEmpty) {
            final sortedArtists = artistCounts.keys.toList()
              ..sort((a, b) =>
                  (artistCounts[b] ?? 0).compareTo(artistCounts[a] ?? 0));

            final topPool = sortedArtists.take(4).toList();
            final pickedArtist = topPool[Random().nextInt(topPool.length)];
            query = '$pickedArtist songs hits';
          } else {
            query = 'top music hits 2026';
          }
        } else {
          query = 'top music hits 2026';
        }
      }

      final rawResults = await _ytdlp.search(query, limit: size);
      final songs = rawResults.map(_mapDictToSong).toList();
      for (final song in songs) {
        await _db.insertOrUpdateSong(song);
      }
      return songs;
    } catch (e) {
      debugPrint('[YouTube] getRandomSongs error: $e');
      return [];
    }
  }

  Future<void> star({String? id, String? albumId, String? artistId}) async {
    try {
      if (id != null) {
        await _db.setSongStarred(id, true);
        final existing = await _db.getSong(id);
        if (existing == null) {
          final info = await _ytdlp.getVideoInfo(id);
          if (info != null) {
            await _db.insertOrUpdateSong(
                _mapDictToSong(info).copyWith(starred: true));
          }
        }
        debugPrint('[YouTube] Starred song $id locally');
      }
      if (albumId != null) {
        await _db.setAlbumStarred(albumId, true);
      }
    } catch (e) {
      debugPrint('[YouTube] star error: $e');
    }
  }

  Future<void> unstar({String? id, String? albumId, String? artistId}) async {
    try {
      if (id != null) {
        await _db.setSongStarred(id, false);
        debugPrint('[YouTube] Unstarred song $id locally');
      }
      if (albumId != null) {
        await _db.setAlbumStarred(albumId, false);
      }
    } catch (e) {
      debugPrint('[YouTube] unstar error: $e');
    }
  }

  Future<void> scrobble(String id, {bool submission = true}) async {
    debugPrint('[YouTube] Scrobble song $id (submission=$submission)');
  }

  Future<SearchResult> getStarred() async {
    try {
      final songs = await _db.getStarredSongs();
      final albums = await _db.getStarredAlbums();
      return SearchResult(artists: [], albums: albums, songs: songs);
    } catch (e) {
      debugPrint('[YouTube] getStarred error: $e');
      return SearchResult(artists: [], albums: [], songs: []);
    }
  }

  Future<List<Genre>> getGenres() async {
    return [
      Genre(value: 'Pop', songCount: 50, albumCount: 10),
      Genre(value: 'Rock', songCount: 50, albumCount: 10),
      Genre(value: 'Hip-Hop / Rap', songCount: 50, albumCount: 10),
      Genre(value: 'R&B / Soul', songCount: 50, albumCount: 10),
      Genre(value: 'Electronic / Dance', songCount: 50, albumCount: 10),
      Genre(value: 'Indie / Alternative', songCount: 50, albumCount: 10),
      Genre(value: 'Classical', songCount: 50, albumCount: 10),
      Genre(value: 'Jazz', songCount: 50, albumCount: 10),
      Genre(value: 'Italian / Sanremo', songCount: 50, albumCount: 10),
      Genre(value: 'Acoustic / Lo-Fi', songCount: 50, albumCount: 10),
    ];
  }

  Future<List<Song>> getSongsByGenre(
    String genre, {
    int size = 50,
    int offset = 0,
  }) async {
    try {
      final rawResults =
          await _ytdlp.search('$genre music hits', limit: size + offset);
      final songs = rawResults.map(_mapDictToSong).toList();
      return songs.skip(offset).take(size).toList();
    } catch (e) {
      debugPrint('[YouTube] getSongsByGenre error: $e');
      return [];
    }
  }

  Future<List<Album>> getAlbumsByGenre(
    String genre, {
    int size = 50,
    int offset = 0,
  }) async =>
      [];

  Future<List<Song>> getSimilarSongs(String videoId, {int count = 50}) async {
    try {
      final radioRaw = await _ytdlp.getRadioTracks(videoId, limit: count);
      if (radioRaw.isNotEmpty) {
        return radioRaw.map(_mapDictToSong).toList();
      }

      final info = await _ytdlp.getVideoInfo(videoId);
      final query = info != null
          ? '${info['artist'] ?? ''} ${info['title'] ?? ''} audio'
          : 'recommended music';
      final rawResults = await _ytdlp.search(query, limit: count);
      return rawResults.map(_mapDictToSong).toList();
    } catch (e) {
      debugPrint('[YouTube] getSimilarSongs error: $e');
      return [];
    }
  }

  Future<List<Song>> getArtistTopSongs(
    String channelId, {
    int count = 50,
  }) async {
    try {
      final rawResults =
          await _ytdlp.search('$channelId top songs', limit: count);
      return rawResults.map(_mapDictToSong).toList();
    } catch (e) {
      debugPrint('[YouTube] getArtistTopSongs error: $e');
      return [];
    }
  }
}
