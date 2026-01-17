import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';

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

  static const String _clientName = 'Musly';
  static const String _apiVersion = '1.16.1';

  SubsonicService() : _dio = Dio() {
    _dio.options.connectTimeout = const Duration(seconds: 30);
    _dio.options.receiveTimeout = const Duration(seconds: 30);
  }

  void configure(ServerConfig config) {
    _config = config;
    _configureCertificateValidation(
      config.allowSelfSignedCertificates,
      config.customCertificatePath,
    );
  }

  void _configureCertificateValidation(
    bool allowSelfSigned, [
    String? customCertPath,
  ]) {
    _dio = Dio();
    _dio.options.connectTimeout = const Duration(seconds: 30);
    _dio.options.receiveTimeout = const Duration(seconds: 30);

    if (customCertPath != null && customCertPath.isNotEmpty) {
      // Use custom certificate
      (_dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
        try {
          final file = File(customCertPath);
          if (file.existsSync()) {
            final bytes = file.readAsBytesSync();
            final context = SecurityContext();
            context.setTrustedCertificatesBytes(bytes);
            return HttpClient(context: context);
          }
        } catch (e) {
          print('Failed to load custom certificate: $e');
        }
        // Fallback to default client
        return HttpClient();
      };
    } else if (allowSelfSigned) {
      // Bypass certificate validation
      (_dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
        final client = HttpClient();
        client.badCertificateCallback = (cert, host, port) => true;
        return client;
      };
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
      final token = md5
          .convert(utf8.encode('${_config!.password}$salt'))
          .toString();
      params['t'] = token;
      params['s'] = salt;
    }

    return params;
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
      throw Exception('Network error: ${e.message}');
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
    if (coverArt == null || _config == null) {
      return '';
    }
    return _buildUrl('getCoverArt', {'id': coverArt, 'size': size.toString()});
  }

  String getStreamUrl(String songId, {int? maxBitRate, String? format}) {
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

  Future<Artist> getArtist(String id) async {
    final response = await _request('getArtist', {'id': id});
    return Artist.fromJson(response['artist'] as Map<String, dynamic>);
  }

  Future<List<Album>> getAlbumList({
    String type = 'recent',
    int size = 20,
    int offset = 0,
  }) async {
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
    final response = await _request('getAlbum', {'id': id});
    return Album.fromJson(response['album'] as Map<String, dynamic>);
  }

  Future<List<Song>> getAlbumSongs(String albumId) async {
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
    final response = await _request('getPlaylist', {'id': id});
    return Playlist.fromJson(response['playlist'] as Map<String, dynamic>);
  }

  Future<void> createPlaylist({
    required String name,
    List<String>? songIds,
  }) async {
    final params = <String, String>{'name': name};
    if (songIds != null && songIds.isNotEmpty) {
      for (int i = 0; i < songIds.length; i++) {
        params['songId[$i]'] = songIds[i];
      }
    }
    await _request('createPlaylist', params);
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

    print('updatePlaylist URL: $url');

    try {
      final response = await _dio.get(url);
      final data = response.data;

      final subsonicResponse = data is String
          ? json.decode(data)
          : data['subsonic-response'];
      if (subsonicResponse == null) {
        throw Exception('Invalid response format');
      }

      if (subsonicResponse['status'] != 'ok') {
        final error = subsonicResponse['error'];
        throw Exception(error?['message'] ?? 'Unknown error');
      }

      print('updatePlaylist successful');
    } on DioException catch (e) {
      print('updatePlaylist DioException: ${e.message}');
      throw Exception('Network error: ${e.message}');
    }
  }

  Future<void> deletePlaylist(String id) async {
    await _request('deletePlaylist', {'id': id});
  }

  Future<SearchResult> search(
    String query, {
    int artistCount = 20,
    int albumCount = 20,
    int songCount = 20,
  }) async {
    final response = await _request('search3', {
      'query': query,
      'artistCount': artistCount.toString(),
      'albumCount': albumCount.toString(),
      'songCount': songCount.toString(),
    });

    final searchResult = response['searchResult3'];

    final artists =
        (searchResult?['artist'] as List?)
            ?.map((a) => Artist.fromJson(a as Map<String, dynamic>))
            .toList() ??
        [];

    final albums =
        (searchResult?['album'] as List?)
            ?.map((a) => Album.fromJson(a as Map<String, dynamic>))
            .toList() ??
        [];

    final songs =
        (searchResult?['song'] as List?)
            ?.map((s) => Song.fromJson(s as Map<String, dynamic>))
            .toList() ??
        [];

    return SearchResult(artists: artists, albums: albums, songs: songs);
  }

  Future<List<Song>> getRandomSongs({int size = 20, String? genre}) async {
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
    final params = <String, String>{};
    if (id != null) params['id'] = id;
    if (albumId != null) params['albumId'] = albumId;
    if (artistId != null) params['artistId'] = artistId;
    await _request('star', params);
  }

  Future<void> unstar({String? id, String? albumId, String? artistId}) async {
    final params = <String, String>{};
    if (id != null) params['id'] = id;
    if (albumId != null) params['albumId'] = albumId;
    if (artistId != null) params['artistId'] = artistId;
    await _request('unstar', params);
  }

  /// Set rating for a song (1-5 stars, 0 to remove rating)
  Future<void> setRating(String id, int rating) async {
    if (rating < 0 || rating > 5) {
      throw ArgumentError('Rating must be between 0 and 5');
    }
    await _request('setRating', {'id': id, 'rating': rating.toString()});
  }

  Future<SearchResult> getStarred() async {
    final response = await _request('getStarred2');
    final starred = response['starred2'];

    final artists =
        (starred?['artist'] as List?)
            ?.map((a) => Artist.fromJson(a as Map<String, dynamic>))
            .toList() ??
        [];

    final albums =
        (starred?['album'] as List?)
            ?.map((a) => Album.fromJson(a as Map<String, dynamic>))
            .toList() ??
        [];

    final songs =
        (starred?['song'] as List?)
            ?.map((s) => Song.fromJson(s as Map<String, dynamic>))
            .toList() ??
        [];

    return SearchResult(artists: artists, albums: albums, songs: songs);
  }

  Future<void> scrobble(String id, {bool submission = true}) async {
    await _request('scrobble', {'id': id, 'submission': submission.toString()});
  }

  Future<Map<String, dynamic>?> getLyrics({
    String? artist,
    String? title,
  }) async {
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
    try {
      final response = await _request('getLyricsBySongId', {'id': songId});
      return response['lyricsList'] as Map<String, dynamic>?;
    } catch (e) {
      return null;
    }
  }

  Future<List<String>> getGenres() async {
    final response = await _request('getGenres');
    final genresData = response['genres']?['genre'];
    if (genresData is List) {
      return genresData
          .map((g) => g['value']?.toString() ?? '')
          .where((g) => g.isNotEmpty)
          .toList();
    }
    return [];
  }

  Future<List<Song>> getSongsByGenre(
    String genre, {
    int count = 50,
    int offset = 0,
  }) async {
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

  /// Get all internet radio stations from the server.
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
      // Server might not support radio stations
      return [];
    }
  }

  /// Create a new internet radio station.
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

  /// Update an existing internet radio station.
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

  /// Delete an internet radio station.
  Future<void> deleteInternetRadioStation(String id) async {
    await _request('deleteInternetRadioStation', {'id': id});
  }

  /// Get songs similar to a given song.
  Future<List<Song>> getSimilarSongs(String id, {int count = 50}) async {
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
      // Fallback to getSimilarSongs (older API)
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

  /// Get top songs for an artist.
  Future<List<Song>> getArtistTopSongs(
    String artistId, {
    int count = 50,
  }) async {
    try {
      // First get artist name
      final artist = await getArtist(artistId);
      if (artist == null) return [];

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
      // Fallback: get songs from artist's albums
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
