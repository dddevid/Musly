import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';
import 'jellyfin_service.dart';
import 'youtube_service.dart';

class PingResult {
  final bool success;
  final String? error;
  final String? serverType;
  final String? serverVersion;

  PingResult({
    required this.success,
    this.error,
    this.serverType,
    this.serverVersion,
  });
}

class SubsonicService {
  Dio _dio;
  ServerConfig? _config;
  JellyfinService? _jellyfin;
  YoutubeService? _youtube;

  static const String _clientName = 'Musly';
  static const String _apiVersion = '1.16.1';

  SubsonicService() : _dio = Dio() {
    _dio.options.connectTimeout = const Duration(seconds: 30);
    _dio.options.receiveTimeout = const Duration(seconds: 30);
    _addLogInterceptor(_dio);
  }

  static String _sanitizeUrl(String url) {
    try {
      final uri = Uri.parse(url);
      final q = Map<String, String>.from(uri.queryParameters);
      for (final key in const ['p', 't', 's']) {
        if (q.containsKey(key)) q[key] = '***';
      }
      return uri.replace(queryParameters: q).toString();
    } catch (_) {
      return url;
    }
  }

  void _addLogInterceptor(Dio dio) {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          options.extra['_logSw'] = Stopwatch()..start();
          final safe = _sanitizeUrl(options.uri.toString());
          debugPrint('[Musly] → ${options.method} $safe');
          handler.next(options);
        },
        onResponse: (response, handler) {
          final sw = response.requestOptions.extra['_logSw'] as Stopwatch?;
          sw?.stop();
          final ms = sw?.elapsedMilliseconds ?? 0;
          final safe = _sanitizeUrl(response.requestOptions.uri.toString());
          debugPrint('[Musly] ← ${response.statusCode} $safe (${ms}ms)');
          handler.next(response);
        },
        onError: (e, handler) {
          final sw = e.requestOptions.extra['_logSw'] as Stopwatch?;
          sw?.stop();
          final ms = sw?.elapsedMilliseconds ?? 0;
          final safe = _sanitizeUrl(e.requestOptions.uri.toString());
          debugPrint('[Musly] ✗ ${e.type.name} $safe (${ms}ms) — ${e.message}');
          if (e.error != null) debugPrint('[Musly]   cause: ${e.error}');
          handler.next(e);
        },
      ),
    );
  }

  Future<void> configure(ServerConfig config) async {
    _config = config;
    if (config.isJellyfin) {
      _jellyfin ??= JellyfinService();
      _jellyfin!.configure(config);
      _youtube?.dispose();
      _youtube = null;
      // } else if (config.serverFamily == 'youtube') {
      //   _youtube ??= YoutubeService();
      //   _jellyfin = null;
    } else {
      _jellyfin = null;
      _youtube?.dispose();
      _youtube = null;
      await _configureCertificateValidation(
        config.allowSelfSignedCertificates,
        customCertPath: config.customCertificatePath,
        clientCertPath: config.clientCertificatePath,
        clientCertPassword: config.clientCertificatePassword,
      );
    }
  }

  bool get isYoutube => _youtube != null;

  bool get isJellyfin => _jellyfin != null;

  /// For YouTube songs, returns a pre-warmed [StreamAudioSource] that proxies
  /// audio through youtube_explode_dart's HTTP client (avoids ExoPlayer's 403).
  /// Returns null for Subsonic / Jellyfin (use [resolveStreamUrlAsync]).
  Future<StreamAudioSource?> getYoutubeAudioSource(Song song) async {
    if (_youtube != null) return _youtube!.buildAudioSource(song.id);
    return null;
  }

  /// Resolves the playable URL for [song]. For YouTube this calls the async
  /// manifest extraction; for other families it returns the pre-built URL.
  Future<String> resolveStreamUrlAsync(Song song) async {
    if (_youtube != null) {
      return _youtube!.resolveStreamUrl(song.id);
    }
    return getStreamUrl(song.id);
  }

  Future<void> _configureCertificateValidation(
    bool allowSelfSigned, {
    String? customCertPath,
    String? clientCertPath,
    String? clientCertPassword,
  }) async {
    _dio = Dio();
    _dio.options.connectTimeout = const Duration(seconds: 30);
    _dio.options.receiveTimeout = const Duration(seconds: 30);
    _addLogInterceptor(_dio);

    final hasCustomServerCert =
        customCertPath != null && customCertPath.isNotEmpty;
    final hasClientCert = clientCertPath != null && clientCertPath.isNotEmpty;

    if (hasCustomServerCert || allowSelfSigned || hasClientCert) {
      // Pre-load certificate files asynchronously to avoid blocking UI
      Uint8List? customServerCertBytes;
      Uint8List? clientCertBytes;

      if (hasCustomServerCert) {
        try {
          final file = File(customCertPath);
          if (await file.exists()) {
            customServerCertBytes = await file.readAsBytes();
          }
        } catch (e) {
          debugPrint('Failed to load custom server certificate: $e');
        }
      }

      if (hasClientCert) {
        try {
          final file = File(clientCertPath);
          if (await file.exists()) {
            clientCertBytes = await file.readAsBytes();
          }
        } catch (e) {
          debugPrint('Failed to load client certificate: $e');
        }
      }

      HttpClient createClient() {
        try {
          final context = SecurityContext(withTrustedRoots: true);

          if (hasCustomServerCert && customServerCertBytes != null) {
            context.setTrustedCertificatesBytes(customServerCertBytes);
          }

          if (hasClientCert && clientCertBytes != null) {
            final password = clientCertPassword;

            context.useCertificateChainBytes(clientCertBytes,
                password: password);

            context.usePrivateKeyBytes(clientCertBytes, password: password);
          }

          final client = HttpClient(context: context);
          client.connectionTimeout = const Duration(seconds: 15);
          client.idleTimeout = const Duration(seconds: 15);
          if (allowSelfSigned) {
            client.badCertificateCallback = (cert, host, port) => true;
          }
          return client;
        } catch (e) {
          debugPrint('Failed to configure TLS: $e');

          final client = HttpClient();
          client.connectionTimeout = const Duration(seconds: 15);
          client.idleTimeout = const Duration(seconds: 15);
          if (allowSelfSigned) {
            client.badCertificateCallback = (cert, host, port) => true;
          }
          return client;
        }
      }

      HttpOverrides.global = _TlsHttpOverrides(createClient);

      (_dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient =
          createClient;
    } else {
      HttpOverrides.global = null;
    }
  }

  ServerConfig? get config => _config;

  bool get isConfigured => _config != null && _config!.isValid;

  Map<String, String> _getAuthParams() {
    if (_config == null) throw Exception('Server not configured');

    final params = <String, String>{
      'u': _config!.username,
      'v': _apiVersion,
      'c': _clientName,
      'f': 'json',
    };

    if (_config!.useLegacyAuth) {
      params['p'] = _config!.password;
    } else {
      final salt = const Uuid().v4().substring(0, 8);
      final token =
          md5.convert(utf8.encode('${_config!.password}$salt')).toString();
      params['t'] = token;
      params['s'] = salt;
    }

    return params;
  }

  Map<String, String>? _stableAuthParams;

  void _ensureStableAuthParams() {
    if (_stableAuthParams != null) return;
    if (_config == null) return;

    final params = <String, String>{
      'u': _config!.username,
      'v': _apiVersion,
      'c': _clientName,
      'f': 'json',
    };

    if (_config!.useLegacyAuth) {
      params['p'] = _config!.password;
    } else {
      const salt = 'musly_stable';
      final token =
          md5.convert(utf8.encode('${_config!.password}$salt')).toString();
      params['t'] = token;
      params['s'] = salt;
    }
    _stableAuthParams = params;
  }

  String _buildUrl(String endpoint, [Map<String, String>? extraParams]) {
    if (_config == null) throw Exception('Server not configured');

    final params = _getAuthParams();
    if (extraParams != null) {
      params.addAll(extraParams);
    }

    if (_config!.selectedMusicFolderIds.isNotEmpty) {
      params['musicFolderId'] = _config!.selectedMusicFolderIds.first;
    }

    final queryString = params.entries
        .map(
          (e) =>
              '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}',
        )
        .join('&');

    return '${_config!.normalizedUrl}/rest/$endpoint?$queryString';
  }

  Future<Map<String, dynamic>> _request(
    String endpoint, [
    Map<String, String>? params,
  ]) async {
    final url = _buildUrl(endpoint, params);

    try {
      final response = await _dio.get(url);
      final data = response.data;

      if (data is String) {
        return json.decode(data);
      }

      final subsonicResponse = data['subsonic-response'];
      if (subsonicResponse == null) {
        throw Exception('Invalid response format');
      }

      if (subsonicResponse['status'] != 'ok') {
        final error = subsonicResponse['error'];
        throw Exception(error?['message'] ?? 'Unknown error');
      }

      return subsonicResponse;
    } on DioException catch (e) {
      switch (e.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          throw Exception('Connection timed out. Check your server URL.');
        case DioExceptionType.connectionError:
          final cause = e.error?.toString() ?? '';
          if (cause.contains('HandshakeException') ||
              cause.contains('CERTIFICATE_VERIFY_FAILED') ||
              cause.contains('SSL')) {
            throw Exception(
                'SSL certificate error. Enable "Allow Self-Signed Certificates" for custom CA servers.');
          }
          throw Exception(
              'Cannot connect to server. Check the URL and your internet connection.');
        case DioExceptionType.badResponse:
          final status = e.response?.statusCode;
          if (status == 401 || status == 403)
            throw Exception('Invalid username or password.');
          if (status == 404)
            throw Exception('Server not found. Check your URL path.');
          if (status != null && status >= 500)
            throw Exception(
                'Server error ($status). The server failed to process the request.');
          throw Exception('Request failed (HTTP $status).');
        default:
          throw Exception('Network error. Check your connection.');
      }
    }
  }

  Future<bool> ping() async {
    try {
      await _request('ping');
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<PingResult> pingWithError() async {
    if (_jellyfin != null) return _jellyfin!.pingWithError();
    if (_youtube != null) return _youtube!.pingWithError();
    try {
      final response = await _request('ping');
      return PingResult(
        success: true,
        serverType: response['type'],
        serverVersion: response['serverVersion'],
      );
    } catch (e) {
      return PingResult(success: false, error: e.toString());
    }
  }

  Future<List<MusicFolder>> getMusicFolders() async {
    try {
      final response = await _request('getMusicFolders');
      final folders = <MusicFolder>[];

      final foldersData = response['musicFolders']?['musicFolder'];
      if (foldersData is List) {
        folders.addAll(
          foldersData.map(
            (f) => MusicFolder.fromJson(f as Map<String, dynamic>),
          ),
        );
      }

      return folders;
    } catch (e) {
      return [];
    }
  }

  String getCoverArtUrl(String? coverArt, {int size = 300}) {
    if (_jellyfin != null)
      return _jellyfin!.getCoverArtUrl(coverArt, size: size);
    if (_youtube != null) return _youtube!.getCoverArtUrl(coverArt, size: size);
    if (coverArt == null || _config == null) {
      return '';
    }
    _ensureStableAuthParams();

    final params = Map<String, String>.from(
      _stableAuthParams ?? _getAuthParams(),
    );
    params['id'] = coverArt;
    if (size > 0) {
      params['size'] = size.toString();
    }

    if (_config!.selectedMusicFolderIds.isNotEmpty) {
      params['musicFolderId'] = _config!.selectedMusicFolderIds.first;
    }

    final queryString = params.entries
        .map(
          (e) =>
              '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}',
        )
        .join('&');

    return '${_config!.normalizedUrl}/rest/getCoverArt?$queryString';
  }

  /// Returns the /download URL for a song — always original file, no transcoding.
  /// Use this for offline downloads so file size matches song.size exactly.
  String getDownloadUrl(String songId) {
    return _buildUrl('download', {'id': songId});
  }

  String getStreamUrl(String songId, {int? maxBitRate, String? format}) {
    if (_jellyfin != null)
      return _jellyfin!
          .getStreamUrl(songId, maxBitRate: maxBitRate, format: format);
    if (_youtube != null) return _youtube!.getStreamUrl(songId);
    final params = <String, String>{'id': songId};
    if (maxBitRate != null) {
      params['maxBitRate'] = maxBitRate.toString();
    }
    if (format != null) {
      params['format'] = format;
    }
    return _buildUrl('stream', params);
  }

  Future<List<Artist>> getArtists() async {
    if (_jellyfin != null) return _jellyfin!.getArtists();
    if (_youtube != null) return _youtube!.getArtists();
    final response = await _request('getArtists');
    final artists = <Artist>[];

    final artistsData = response['artists']?['index'];
    if (artistsData is List) {
      for (final index in artistsData) {
        final indexArtists = index['artist'];
        if (indexArtists is List) {
          artists.addAll(
            indexArtists.map((a) => Artist.fromJson(a as Map<String, dynamic>)),
          );
        }
      }
    }

    return artists;
  }

  Future<List<Song>> getAllSongs() async {
    if (_jellyfin != null) return _jellyfin!.getAllSongs();
    // Subsonic has no direct "get all songs" endpoint.
    return [];
  }

  Future<Artist> getArtist(String id) async {
    final response = await _request('getArtist', {'id': id});
    return Artist.fromJson(response['artist'] as Map<String, dynamic>);
  }

  Future<List<Album>> getAlbumList({
    String type = 'recent',
    int size = 20,
    int offset = 0,
  }) async {
    if (_jellyfin != null)
      return _jellyfin!.getAlbumList(type: type, size: size, offset: offset);
    if (_youtube != null)
      return _youtube!.getAlbumList(type: type, size: size, offset: offset);
    final response = await _request('getAlbumList2', {
      'type': type,
      'size': size.toString(),
      'offset': offset.toString(),
    });

    final albumsData = response['albumList2']?['album'];
    if (albumsData is List) {
      return albumsData
          .map((a) => Album.fromJson(a as Map<String, dynamic>))
          .toList();
    }

    return [];
  }

  Future<Album> getAlbum(String id) async {
    if (_jellyfin != null) return _jellyfin!.getAlbum(id);
    if (_youtube != null) return _youtube!.getAlbum(id);
    final response = await _request('getAlbum', {'id': id});
    return Album.fromJson(response['album'] as Map<String, dynamic>);
  }

  Future<List<Song>> getAlbumSongs(String albumId) async {
    if (_jellyfin != null) return _jellyfin!.getAlbumSongs(albumId);
    if (_youtube != null) return _youtube!.getAlbumSongs(albumId);
    final response = await _request('getAlbum', {'id': albumId});
    final songsData = response['album']?['song'];
    if (songsData is List) {
      return songsData
          .map((s) => Song.fromJson(s as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  Future<List<Album>> getArtistAlbums(String artistId) async {
    if (_jellyfin != null) return _jellyfin!.getArtistAlbums(artistId);
    if (_youtube != null) return _youtube!.getArtistAlbums(artistId);
    final response = await _request('getArtist', {'id': artistId});
    final albumsData = response['artist']?['album'];
    if (albumsData is List) {
      return albumsData
          .map((a) => Album.fromJson(a as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  Future<List<Playlist>> getPlaylists() async {
    if (_jellyfin != null) return _jellyfin!.getPlaylists();
    if (_youtube != null) return _youtube!.getPlaylists();
    final response = await _request('getPlaylists');
    final playlistsData = response['playlists']?['playlist'];
    if (playlistsData is List) {
      return playlistsData
          .map((p) => Playlist.fromJson(p as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  Future<Playlist> getPlaylist(String id) async {
    if (_jellyfin != null) return _jellyfin!.getPlaylist(id);
    if (_youtube != null) return _youtube!.getPlaylist(id);
    final response = await _request('getPlaylist', {'id': id});
    return Playlist.fromJson(response['playlist'] as Map<String, dynamic>);
  }

  Future<void> createPlaylist({
    required String name,
    String? comment,
    List<String>? songIds,
  }) async {
    if (_jellyfin != null) {
      await _jellyfin!
          .createPlaylist(name: name, comment: comment, songIds: songIds);
      return;
    }
    if (_youtube != null) {
      await _youtube!
          .createPlaylist(name: name, comment: comment, songIds: songIds);
      return;
    }
    // songId must be appended directly, using it as a map key would produce
    // songId[i]=x which Navidrome doesn't recognize
    String url = _buildUrl('createPlaylist', {'name': name});
    if (songIds != null && songIds.isNotEmpty) {
      for (final songId in songIds) {
        url += '&songId=${Uri.encodeComponent(songId)}';
      }
    }

    try {
      final response = await _dio.get(url);
      final data = response.data;

      final decoded = data is String ? json.decode(data) : data;
      final subsonicResponse = decoded['subsonic-response'];
      if (subsonicResponse == null) {
        throw Exception('Invalid response format');
      }

      if (subsonicResponse['status'] != 'ok') {
        final error = subsonicResponse['error'];
        throw Exception(error?['message'] ?? 'Unknown error');
      }
    } on DioException catch (e) {
      throw Exception('Network error: ${e.message}');
    }
  }

  Future<void> updatePlaylist({
    required String playlistId,
    String? name,
    String? comment,
    List<String>? songIdsToAdd,
    List<int>? songIndexesToRemove,
  }) async {
    final params = <String, String>{'playlistId': playlistId};
    if (name != null) params['name'] = name;
    if (comment != null) params['comment'] = comment;

    String url = _buildUrl('updatePlaylist', params);

    if (songIdsToAdd != null && songIdsToAdd.isNotEmpty) {
      for (final songId in songIdsToAdd) {
        url += '&songIdToAdd=${Uri.encodeComponent(songId)}';
      }
    }

    if (songIndexesToRemove != null && songIndexesToRemove.isNotEmpty) {
      for (final index in songIndexesToRemove) {
        url += '&songIndexToRemove=${Uri.encodeComponent(index.toString())}';
      }
    }

    debugPrint('updatePlaylist URL: ${_sanitizeUrl(url)}');

    try {
      final response = await _dio.get(url);
      final data = response.data;

      final decoded = data is String ? json.decode(data) : data;
      final subsonicResponse = decoded['subsonic-response'];
      if (subsonicResponse == null) {
        throw Exception('Invalid response format');
      }

      if (subsonicResponse['status'] != 'ok') {
        final error = subsonicResponse['error'];
        throw Exception(error?['message'] ?? 'Unknown error');
      }

      debugPrint('updatePlaylist successful');
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      if (status != null && status >= 500)
        throw Exception(
            'Server error ($status). The server failed to process the request.');
      throw Exception('Network error. Check your connection.');
    }
  }

  Future<void> deletePlaylist(String id) async {
    if (_jellyfin != null) {
      await _jellyfin!.deletePlaylist(id);
      return;
    }
    if (_youtube != null) {
      await _youtube!.deletePlaylist(id);
      return;
    }
    await _request('deletePlaylist', {'id': id});
  }

  Future<SearchResult> search(
    String query, {
    int artistCount = 20,
    int albumCount = 20,
    int songCount = 20,
  }) async {
    if (_jellyfin != null)
      return _jellyfin!.search(query,
          songCount: songCount,
          albumCount: albumCount,
          artistCount: artistCount);
    if (_youtube != null)
      return _youtube!.search(query,
          songCount: songCount,
          albumCount: albumCount,
          artistCount: artistCount);
    final response = await _request('search3', {
      'query': query,
      'artistCount': artistCount.toString(),
      'albumCount': albumCount.toString(),
      'songCount': songCount.toString(),
    });

    final searchResult = response['searchResult3'];
    debugPrint('SubsonicService: search3 response: searchResult=$searchResult');

    // Handle both single item and list responses
    var artistList = searchResult?['artist'];
    var albumList = searchResult?['album'];
    var songList = searchResult?['song'];

    // Normalize to lists
    if (artistList != null && artistList is! List) {
      artistList = [artistList];
    }
    if (albumList != null && albumList is! List) {
      albumList = [albumList];
    }
    if (songList != null && songList is! List) {
      songList = [songList];
    }

    final artists = (artistList as List?)
            ?.map((a) => Artist.fromJson(a as Map<String, dynamic>))
            .toList() ??
        [];

    final albums = (albumList as List?)
            ?.map((a) => Album.fromJson(a as Map<String, dynamic>))
            .toList() ??
        [];

    final songs = (songList as List?)
            ?.map((s) => Song.fromJson(s as Map<String, dynamic>))
            .toList() ??
        [];

    debugPrint(
        'SubsonicService: search3 parsed: ${artists.length} artists, ${albums.length} albums, ${songs.length} songs');
    return SearchResult(artists: artists, albums: albums, songs: songs);
  }

  Future<List<Song>> getRandomSongs({int size = 20, String? genre}) async {
    if (_jellyfin != null)
      return _jellyfin!.getRandomSongs(size: size, genre: genre);
    if (_youtube != null)
      return _youtube!.getRandomSongs(size: size, genre: genre);
    final params = <String, String>{'size': size.toString()};
    if (genre != null) params['genre'] = genre;

    final response = await _request('getRandomSongs', params);
    final songsData = response['randomSongs']?['song'];
    if (songsData is List) {
      return songsData
          .map((s) => Song.fromJson(s as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  Future<void> star({String? id, String? albumId, String? artistId}) async {
    if (_jellyfin != null) {
      await _jellyfin!.star(id: id, albumId: albumId, artistId: artistId);
      return;
    }
    if (_youtube != null) {
      await _youtube!.star(id: id, albumId: albumId, artistId: artistId);
      return;
    }
    final params = <String, String>{};
    if (id != null) params['id'] = id;
    if (albumId != null) params['albumId'] = albumId;
    if (artistId != null) params['artistId'] = artistId;
    await _request('star', params);
  }

  Future<void> unstar({String? id, String? albumId, String? artistId}) async {
    if (_jellyfin != null) {
      await _jellyfin!.unstar(id: id, albumId: albumId, artistId: artistId);
      return;
    }
    if (_youtube != null) {
      await _youtube!.unstar(id: id, albumId: albumId, artistId: artistId);
      return;
    }
    final params = <String, String>{};
    if (id != null) params['id'] = id;
    if (albumId != null) params['albumId'] = albumId;
    if (artistId != null) params['artistId'] = artistId;
    await _request('unstar', params);
  }

  Future<void> setRating(String id, int rating) async {
    if (rating < 0 || rating > 5) {
      throw ArgumentError('Rating must be between 0 and 5');
    }
    await _request('setRating', {'id': id, 'rating': rating.toString()});
  }

  Future<SearchResult> getStarred() async {
    if (_jellyfin != null) return _jellyfin!.getStarred();
    if (_youtube != null) return _youtube!.getStarred();
    final response = await _request('getStarred2');
    final starred = response['starred2'];

    final artists = (starred?['artist'] as List?)
            ?.map((a) => Artist.fromJson(a as Map<String, dynamic>))
            .toList() ??
        [];

    final albums = (starred?['album'] as List?)
            ?.map((a) => Album.fromJson(a as Map<String, dynamic>))
            .toList() ??
        [];

    final songs = (starred?['song'] as List?)
            ?.map((s) => Song.fromJson(s as Map<String, dynamic>))
            .toList() ??
        [];

    return SearchResult(artists: artists, albums: albums, songs: songs);
  }

  Future<void> scrobble(String id, {bool submission = true}) async {
    if (_jellyfin != null) {
      await _jellyfin!.scrobble(id, submission: submission);
      return;
    }
    if (_youtube != null) {
      await _youtube!.scrobble(id, submission: submission);
      return;
    }
    await _request('scrobble', {'id': id, 'submission': submission.toString()});
  }

  Future<Map<String, dynamic>?> getLyrics({
    String? artist,
    String? title,
    String? id,
  }) async {
    if (_jellyfin != null && id != null) {
      final result = await _jellyfin!.getLyrics(id);
      if (result != null && result.containsKey('value')) return result;
      return null;
    }
    try {
      final params = <String, String>{};
      if (artist != null) params['artist'] = artist;
      if (title != null) params['title'] = title;

      final response = await _request('getLyrics', params);
      return response['lyrics'] as Map<String, dynamic>?;
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> getLyricsBySongId(String songId) async {
    if (_jellyfin != null) {
      final result = await _jellyfin!.getLyrics(songId);
      if (result != null && result.containsKey('structuredLyrics'))
        return result;
      return null;
    }
    try {
      final response = await _request('getLyricsBySongId', {'id': songId});
      return response['lyricsList'] as Map<String, dynamic>?;
    } catch (e) {
      return null;
    }
  }

  Future<List<Genre>> getGenres() async {
    if (_jellyfin != null) return _jellyfin!.getGenres();
    if (_youtube != null) return _youtube!.getGenres();
    final response = await _request('getGenres');
    final genresData = response['genres']?['genre'];
    if (genresData is List) {
      return genresData
          .map((g) => Genre.fromJson(g as Map<String, dynamic>))
          .where((g) => g.value.isNotEmpty)
          .toList()
        ..sort((a, b) => a.value.compareTo(b.value));
    }
    return [];
  }

  Future<List<Song>> getSongsByGenre(
    String genre, {
    int count = 50,
    int offset = 0,
  }) async {
    if (_jellyfin != null)
      return _jellyfin!.getSongsByGenre(genre, size: count, offset: offset);
    if (_youtube != null)
      return _youtube!.getSongsByGenre(genre, size: count, offset: offset);
    final response = await _request('getSongsByGenre', {
      'genre': genre,
      'count': count.toString(),
      'offset': offset.toString(),
    });
    final songsData = response['songsByGenre']?['song'];
    if (songsData is List) {
      return songsData
          .map((s) => Song.fromJson(s as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  Future<List<Album>> getAlbumsByGenre(
    String genre, {
    int size = 50,
    int offset = 0,
  }) async {
    if (_jellyfin != null)
      return _jellyfin!.getAlbumsByGenre(genre, size: size, offset: offset);
    if (_youtube != null)
      return _youtube!.getAlbumsByGenre(genre, size: size, offset: offset);
    try {
      final response = await _request('getAlbumList2', {
        'type': 'byGenre',
        'genre': genre,
        'size': size.toString(),
        'offset': offset.toString(),
      });
      final albumsData = response['albumList2']?['album'];
      if (albumsData is List) {
        return albumsData
            .map((a) => Album.fromJson(a as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, dynamic>> jukeboxControl(
    String action, {
    int? index,
    int? offset,
    List<String>? ids,
    double? gain,
  }) async {
    final params = <String, String>{'action': action};
    if (index != null) params['index'] = index.toString();
    if (offset != null) params['offset'] = offset.toString();
    if (gain != null) params['gain'] = gain.toStringAsFixed(2);

    String url = _buildUrl('jukeboxControl', params);
    if (ids != null) {
      for (final id in ids) {
        url += '&id=${Uri.encodeComponent(id)}';
      }
    }

    try {
      final response = await _dio.get(url);
      final data = response.data;
      final sr = data is String
          ? json.decode(data)['subsonic-response']
          : data['subsonic-response'];
      if (sr == null || sr['status'] != 'ok') {
        throw Exception(sr?['error']?['message'] ?? 'Jukebox error');
      }
      return sr['jukeboxStatus'] as Map<String, dynamic>? ??
          sr['jukeboxPlaylist'] as Map<String, dynamic>? ??
          {};
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      if (status != null && status >= 500)
        throw Exception(
            'Server error ($status). The server failed to process the request.');
      throw Exception('Network error. Check your connection.');
    }
  }

  Future<Map<String, dynamic>> jukeboxGet() => jukeboxControl('get');
  Future<Map<String, dynamic>> jukeboxStatus() => jukeboxControl('status');
  Future<Map<String, dynamic>> jukeboxStart() => jukeboxControl('start');
  Future<Map<String, dynamic>> jukeboxStop() => jukeboxControl('stop');
  Future<Map<String, dynamic>> jukeboxSkip(int index, {int offset = 0}) =>
      jukeboxControl('skip', index: index, offset: offset);
  Future<Map<String, dynamic>> jukeboxAdd(List<String> ids) =>
      jukeboxControl('add', ids: ids);
  Future<Map<String, dynamic>> jukeboxClear() => jukeboxControl('clear');
  Future<Map<String, dynamic>> jukeboxSet(List<String> ids) =>
      jukeboxControl('set', ids: ids);
  Future<Map<String, dynamic>> jukeboxShuffle() => jukeboxControl('shuffle');
  Future<Map<String, dynamic>> jukeboxRemove(int index) =>
      jukeboxControl('remove', index: index);
  Future<Map<String, dynamic>> jukeboxSetGain(double gain) =>
      jukeboxControl('setGain', gain: gain);

  Future<List<RadioStation>> getInternetRadioStations() async {
    try {
      final response = await _request('getInternetRadioStations');
      final stationsData =
          response['internetRadioStations']?['internetRadioStation'];
      if (stationsData is List) {
        return stationsData
            .map((s) => RadioStation.fromJson(s as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<void> createInternetRadioStation({
    required String name,
    required String streamUrl,
    String? homePageUrl,
  }) async {
    final params = <String, String>{'name': name, 'streamUrl': streamUrl};
    if (homePageUrl != null && homePageUrl.isNotEmpty) {
      params['homepageUrl'] = homePageUrl;
    }
    await _request('createInternetRadioStation', params);
  }

  Future<void> updateInternetRadioStation({
    required String id,
    required String name,
    required String streamUrl,
    String? homePageUrl,
  }) async {
    final params = <String, String>{
      'id': id,
      'name': name,
      'streamUrl': streamUrl,
    };
    if (homePageUrl != null && homePageUrl.isNotEmpty) {
      params['homepageUrl'] = homePageUrl;
    }
    await _request('updateInternetRadioStation', params);
  }

  Future<void> deleteInternetRadioStation(String id) async {
    await _request('deleteInternetRadioStation', {'id': id});
  }

  Future<List<Song>> getSimilarSongs(String id, {int count = 50}) async {
    if (_jellyfin != null) return _jellyfin!.getSimilarSongs(id, count: count);
    if (_youtube != null) return _youtube!.getSimilarSongs(id, count: count);
    try {
      final response = await _request('getSimilarSongs2', {
        'id': id,
        'count': count.toString(),
      });
      final songsData = response['similarSongs2']?['song'];
      if (songsData is List) {
        return songsData
            .map((s) => Song.fromJson(s as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      try {
        final response = await _request('getSimilarSongs', {
          'id': id,
          'count': count.toString(),
        });
        final songsData = response['similarSongs']?['song'];
        if (songsData is List) {
          return songsData
              .map((s) => Song.fromJson(s as Map<String, dynamic>))
              .toList();
        }
      } catch (_) {}
      return [];
    }
  }

  Future<List<Song>> getArtistTopSongs(
    String artistId, {
    int count = 50,
  }) async {
    if (_jellyfin != null)
      return _jellyfin!.getArtistTopSongs(artistId, count: count);
    if (_youtube != null)
      return _youtube!.getArtistTopSongs(artistId, count: count);
    try {
      final artist = await getArtist(artistId);

      final response = await _request('getTopSongs', {
        'artist': artist.name,
        'count': count.toString(),
      });
      final songsData = response['topSongs']?['song'];
      if (songsData is List) {
        return songsData
            .map((s) => Song.fromJson(s as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      try {
        final albums = await getArtistAlbums(artistId);
        if (albums.isEmpty) return [];

        final songs = <Song>[];
        for (final album in albums.take(3)) {
          final albumSongs = await getAlbumSongs(album.id);
          songs.addAll(albumSongs);
          if (songs.length >= count) break;
        }
        return songs.take(count).toList();
      } catch (_) {
        return [];
      }
    }
  }
}

class SearchResult {
  final List<Artist> artists;
  final List<Album> albums;
  final List<Song> songs;

  SearchResult({
    required this.artists,
    required this.albums,
    required this.songs,
  });

  bool get isEmpty => artists.isEmpty && albums.isEmpty && songs.isEmpty;
}

class _TlsHttpOverrides extends HttpOverrides {
  final HttpClient Function() _factory;

  _TlsHttpOverrides(this._factory);

  @override
  HttpClient createHttpClient(SecurityContext? context) => _factory();
}
