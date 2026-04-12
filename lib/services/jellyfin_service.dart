import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/foundation.dart';
import '../models/models.dart';
import 'subsonic_service.dart' show PingResult, SearchResult;

class JellyfinService {
  Dio _dio = Dio();
  String _baseUrl = '';
  String? _token;
  String? _userId;
  String _deviceId = 'musly-app';
  bool _allowSelfSigned = false;

  static const _clientName = 'Musly';
  static const _clientVersion = '1.0.0';

  String get _authHeader {
    final parts = [
      'Client="$_clientName"',
      'Device="Musly"',
      'DeviceId="$_deviceId"',
      'Version="$_clientVersion"',
      if (_token != null) 'Token="$_token"',
    ];
    return 'MediaBrowser ${parts.join(', ')}';
  }

  void configure(ServerConfig config) {
    _baseUrl = config.normalizedUrl;
    _token = config.apiToken;
    _userId = config.userId;
    _deviceId = 'musly-${config.username}-${config.serverUrl.hashCode.abs()}';
    _allowSelfSigned = config.allowSelfSignedCertificates;
    _buildDio();
  }

  void _buildDio() {
    _dio = Dio();
    _dio.options.connectTimeout = const Duration(seconds: 15);
    _dio.options.receiveTimeout = const Duration(seconds: 30);
    _dio.options.headers = {'Authorization': _authHeader};
    if (!kIsWeb && _allowSelfSigned) {
      (_dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
        final client = HttpClient();
        client.badCertificateCallback = (cert, host, port) => true;
        return client;
      };
    }
  }

  Future<Map<String, dynamic>> _get(
    String path, {
    Map<String, dynamic>? params,
  }) async {
    final resp = await _dio.get(
      '$_baseUrl$path',
      queryParameters: params,
      options: Options(headers: {'Authorization': _authHeader}),
    );
    return resp.data as Map<String, dynamic>;
  }

  Future<Response> _post(String path, dynamic body) async {
    return _dio.post(
      '$_baseUrl$path',
      data: body,
      options: Options(headers: {'Authorization': _authHeader}),
    );
  }

  Future<void> _delete(String path) async {
    await _dio.delete(
      '$_baseUrl$path',
      options: Options(headers: {'Authorization': _authHeader}),
    );
  }

  Future<PingResult> pingWithError() async {
    try {
      final resp = await _dio.get(
        '$_baseUrl/System/Info/Public',
        options: Options(
          headers: {'Authorization': _authHeader},
          receiveTimeout: const Duration(seconds: 10),
          sendTimeout: const Duration(seconds: 10),
        ),
      );
      final data = resp.data as Map<String, dynamic>;
      final product = (data['ProductName'] as String? ?? '').toLowerCase();
      final serverType = product.contains('emby') ? 'Emby' : 'Jellyfin';
      final version = data['Version'] as String?;
      return PingResult(
        success: true,
        serverType: serverType,
        serverVersion: version,
      );
    } catch (e) {
      return PingResult(success: false, error: e.toString());
    }
  }

  Future<Map<String, dynamic>?> authenticate(
    String username,
    String password,
  ) async {
    try {
      final resp = await _dio.post(
        '$_baseUrl/Users/AuthenticateByName',
        data: {'Username': username, 'Pw': password},
        options: Options(
          headers: {
            'Authorization': _authHeader,
            'Content-Type': 'application/json',
          },
        ),
      );
      return resp.data as Map<String, dynamic>;
    } catch (e) {
      debugPrint('[Jellyfin] authenticate error: $e');
      return null;
    }
  }

  String getCoverArtUrl(String? itemId, {int size = 300}) {
    if (itemId == null || itemId.isEmpty) return '';
    return '$_baseUrl/Items/$itemId/Images/Primary'
        '?fillHeight=$size&fillWidth=$size&quality=90'
        '${_token != null ? '&api_key=$_token' : ''}';
  }

  String getStreamUrl(String songId, {int? maxBitRate, String? format}) {
    final params = StringBuffer(
      '$_baseUrl/Audio/$songId/universal'
      '?audioCodec=aac,mp3,flac,opus,ogg'
      '&transcodingContainer=mp4'
      '&transcodingProtocol=http'
      '&maxStreamingBitrate=${(maxBitRate ?? 0) * 1000}'
      '&userId=${_userId ?? ''}'
      '&deviceId=$_deviceId',
    );
    if (_token != null) params.write('&api_key=$_token');
    return params.toString();
  }

  Song _songFromItem(Map<String, dynamic> item) {
    final ticks = item['RunTimeTicks'] as int?;
    final durationSec = ticks != null ? (ticks / 10000000).round() : null;
    final artists = item['ArtistItems'] as List<dynamic>?;
    final artistId =
        artists?.isNotEmpty == true
            ? (artists!.first as Map<String, dynamic>)['Id'] as String?
            : null;
    final genres = item['Genres'] as List<dynamic>?;
    return Song(
      id: item['Id'] as String? ?? '',
      title: item['Name'] as String? ?? 'Unknown',
      album: item['Album'] as String?,
      albumId: item['AlbumId'] as String?,
      artist: item['AlbumArtist'] as String? ??
          (item['ArtistItems'] != null &&
                  (item['ArtistItems'] as List).isNotEmpty
              ? ((item['ArtistItems'] as List).first
                      as Map<String, dynamic>)['Name'] as String?
              : null),
      artistId: artistId,
      track: item['IndexNumber'] as int?,
      year: item['ProductionYear'] as int?,
      genre: genres?.isNotEmpty == true ? genres!.first.toString() : null,
      coverArt: item['Id'] as String?,
      duration: durationSec,
      starred: item['UserData']?['IsFavorite'] as bool?,
    );
  }

  Album _albumFromItem(Map<String, dynamic> item) {
    final ticks = item['RunTimeTicks'] as int?;
    final durationSec = ticks != null ? (ticks / 10000000).round() : null;
    final genres = item['Genres'] as List<dynamic>?;
    return Album(
      id: item['Id'] as String? ?? '',
      name: item['Name'] as String? ?? 'Unknown Album',
      artist: item['AlbumArtist'] as String?,
      artistId: item['AlbumArtistId'] as String?,
      coverArt: item['Id'] as String?,
      songCount: item['ChildCount'] as int?,
      duration: durationSec,
      year: item['ProductionYear'] as int?,
      genre: genres?.isNotEmpty == true ? genres!.first.toString() : null,
    );
  }

  Artist _artistFromItem(Map<String, dynamic> item) {
    return Artist(
      id: item['Id'] as String? ?? '',
      name: item['Name'] as String? ?? 'Unknown Artist',
      coverArt: item['Id'] as String?,
      albumCount: item['AlbumCount'] as int?,
    );
  }

  Future<List<Album>> getAlbumList({
    String type = 'recent',
    int size = 20,
    int offset = 0,
  }) async {
    if (_userId == null) return [];
    String sortBy;
    String? filters;
    switch (type) {
      case 'alphabeticalByName':
        sortBy = 'SortName';
        break;
      case 'newest':
        sortBy = 'DateCreated';
        break;
      case 'frequent':
        sortBy = 'PlayCount';
        break;
      case 'recent':
        sortBy = 'DatePlayed';
        break;
      case 'starred':
        sortBy = 'SortName';
        filters = 'IsFavorite';
        break;
      default:
        sortBy = 'Random';
    }
    try {
      final data = await _get(
        '/Users/$_userId/Items',
        params: {
          'IncludeItemTypes': 'MusicAlbum',
          'Recursive': 'true',
          'SortBy': sortBy,
          'SortOrder': 'Descending',
          'Limit': size.toString(),
          'StartIndex': offset.toString(),
          if (filters != null) 'Filters': filters,
          'Fields': 'Genres,ChildCount',
        },
      );
      final items = data['Items'] as List<dynamic>? ?? [];
      return items
          .map((e) => _albumFromItem(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('[Jellyfin] getAlbumList error: $e');
      return [];
    }
  }

  Future<Album> getAlbum(String id) async {
    final data = await _get('/Users/$_userId/Items/$id');
    return _albumFromItem(data);
  }

  Future<List<Song>> getAlbumSongs(String albumId) async {
    if (_userId == null) return [];
    try {
      final data = await _get(
        '/Users/$_userId/Items',
        params: {
          'ParentId': albumId,
          'IncludeItemTypes': 'Audio',
          'Recursive': 'true',
          'SortBy': 'IndexNumber,SortName',
          'SortOrder': 'Ascending',
          'Fields': 'Genres,UserData',
        },
      );
      final items = data['Items'] as List<dynamic>? ?? [];
      return items.map((e) => _songFromItem(e as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint('[Jellyfin] getAlbumSongs error: $e');
      return [];
    }
  }

  Future<List<Artist>> getArtists() async {
    if (_userId == null) return [];
    try {
      final data = await _get(
        '/Artists',
        params: {
          'userId': _userId,
          'Recursive': 'true',
          'SortBy': 'SortName',
          'SortOrder': 'Ascending',
          'Limit': '1000',
          'Fields': 'AlbumCount',
        },
      );
      final items = data['Items'] as List<dynamic>? ?? [];
      return items
          .map((e) => _artistFromItem(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('[Jellyfin] getArtists error: $e');
      return [];
    }
  }

  Future<List<Album>> getArtistAlbums(String artistId) async {
    if (_userId == null) return [];
    try {
      final data = await _get(
        '/Users/$_userId/Items',
        params: {
          'ArtistIds': artistId,
          'IncludeItemTypes': 'MusicAlbum',
          'Recursive': 'true',
          'SortBy': 'ProductionYear,SortName',
          'SortOrder': 'Descending',
          'Fields': 'Genres,ChildCount',
        },
      );
      final items = data['Items'] as List<dynamic>? ?? [];
      return items
          .map((e) => _albumFromItem(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('[Jellyfin] getArtistAlbums error: $e');
      return [];
    }
  }

  Future<List<Playlist>> getPlaylists() async {
    if (_userId == null) return [];
    try {
      final data = await _get(
        '/Users/$_userId/Items',
        params: {
          'IncludeItemTypes': 'Playlist',
          'Recursive': 'true',
          'SortBy': 'SortName',
          'SortOrder': 'Ascending',
          'Fields': 'ChildCount',
        },
      );
      final items = data['Items'] as List<dynamic>? ?? [];
      return items.map((e) {
        final m = e as Map<String, dynamic>;
        return Playlist(
          id: m['Id'] as String? ?? '',
          name: m['Name'] as String? ?? '',
          songCount: m['ChildCount'] as int?,
          coverArt: m['Id'] as String?,
        );
      }).toList();
    } catch (e) {
      debugPrint('[Jellyfin] getPlaylists error: $e');
      return [];
    }
  }

  Future<Playlist> getPlaylist(String id) async {
    if (_userId == null) return Playlist(id: id, name: '');
    try {
      final meta = await _get('/Users/$_userId/Items/$id');
      final data = await _get(
        '/Playlists/$id/Items',
        params: {
          'userId': _userId,
          'Fields': 'Genres,UserData',
        },
      );
      final items = data['Items'] as List<dynamic>? ?? [];
      final songs = items
          .map((e) => _songFromItem(e as Map<String, dynamic>))
          .toList();
      return Playlist(
        id: id,
        name: meta['Name'] as String? ?? '',
        songCount: songs.length,
        coverArt: id,
        songs: songs,
      );
    } catch (e) {
      debugPrint('[Jellyfin] getPlaylist error: $e');
      return Playlist(id: id, name: '');
    }
  }

  Future<SearchResult> search(
    String query, {
    int songCount = 20,
    int albumCount = 20,
    int artistCount = 20,
  }) async {
    if (_userId == null) return SearchResult(songs: [], albums: [], artists: []);
    try {
      Future<List<T>> fetch<T>(
        String types,
        int limit,
        T Function(Map<String, dynamic>) mapper,
      ) async {
        if (limit == 0) return [];
        final data = await _get(
          '/Users/$_userId/Items',
          params: {
            'SearchTerm': query,
            'IncludeItemTypes': types,
            'Recursive': 'true',
            'Limit': limit.toString(),
            'Fields': 'Genres,ChildCount,UserData',
          },
        );
        return (data['Items'] as List<dynamic>? ?? [])
            .map((e) => mapper(e as Map<String, dynamic>))
            .toList();
      }

      final songs = await fetch('Audio', songCount, _songFromItem);
      final albums = await fetch('MusicAlbum', albumCount, _albumFromItem);
      final artists = await fetch('MusicArtist', artistCount, _artistFromItem);
      return SearchResult(songs: songs, albums: albums, artists: artists);
    } catch (e) {
      debugPrint('[Jellyfin] search error: $e');
      return SearchResult(songs: [], albums: [], artists: []);
    }
  }

  Future<List<Song>> getRandomSongs({int size = 50, String? genre}) async {
    if (_userId == null) return [];
    try {
      final data = await _get(
        '/Users/$_userId/Items',
        params: {
          'IncludeItemTypes': 'Audio',
          'Recursive': 'true',
          'SortBy': 'Random',
          'Limit': size.toString(),
          'Fields': 'Genres,UserData',
          if (genre != null) 'Genres': genre,
        },
      );
      final items = data['Items'] as List<dynamic>? ?? [];
      return items.map((e) => _songFromItem(e as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint('[Jellyfin] getRandomSongs error: $e');
      return [];
    }
  }

  Future<SearchResult> getStarred() async {
    if (_userId == null) return SearchResult(songs: [], albums: [], artists: []);
    try {
      Future<List<T>> fetch<T>(
        String types,
        T Function(Map<String, dynamic>) mapper,
      ) async {
        final data = await _get(
          '/Users/$_userId/Items',
          params: {
            'IncludeItemTypes': types,
            'Recursive': 'true',
            'Filters': 'IsFavorite',
            'Fields': 'Genres,ChildCount,UserData',
          },
        );
        return (data['Items'] as List<dynamic>? ?? [])
            .map((e) => mapper(e as Map<String, dynamic>))
            .toList();
      }

      final songs = await fetch('Audio', _songFromItem);
      final albums = await fetch('MusicAlbum', _albumFromItem);
      final artists = await fetch('MusicArtist', _artistFromItem);
      return SearchResult(songs: songs, albums: albums, artists: artists);
    } catch (e) {
      debugPrint('[Jellyfin] getStarred error: $e');
      return SearchResult(songs: [], albums: [], artists: []);
    }
  }

  Future<void> star({
    String? id,
    String? albumId,
    String? artistId,
  }) async {
    if (_userId == null) return;
    for (final itemId in [id, albumId, artistId].whereType<String>()) {
      try {
        await _post('/Users/$_userId/FavoriteItems/$itemId', null);
      } catch (e) {
        debugPrint('[Jellyfin] star error: $e');
      }
    }
  }

  Future<void> unstar({
    String? id,
    String? albumId,
    String? artistId,
  }) async {
    if (_userId == null) return;
    for (final itemId in [id, albumId, artistId].whereType<String>()) {
      try {
        await _delete('/Users/$_userId/FavoriteItems/$itemId');
      } catch (e) {
        debugPrint('[Jellyfin] unstar error: $e');
      }
    }
  }

  Future<void> scrobble(String id, {bool submission = true}) async {
    try {
      if (submission) {
        await _post('/Sessions/Playing/Stopped', {
          'ItemId': id,
          'PositionTicks': 0,
        });
      } else {
        await _post('/Sessions/Playing', {
          'ItemId': id,
          'CanSeek': true,
          'QueueableMediaTypes': ['Audio'],
        });
      }
    } catch (e) {
      debugPrint('[Jellyfin] scrobble error: $e');
    }
  }

  Future<List<Genre>> getGenres() async {
    if (_userId == null) return [];
    try {
      final data = await _get(
        '/Genres',
        params: {
          'userId': _userId,
          'IncludeItemTypes': 'Audio',
          'Recursive': 'true',
          'SortBy': 'SortName',
          'SortOrder': 'Ascending',
        },
      );
      final items = data['Items'] as List<dynamic>? ?? [];
      return items.map((e) {
        final m = e as Map<String, dynamic>;
        return Genre(
          value: m['Name'] as String? ?? '',
          songCount: m['SongCount'] as int? ?? 0,
          albumCount: m['AlbumCount'] as int? ?? 0,
        );
      }).toList();
    } catch (e) {
      debugPrint('[Jellyfin] getGenres error: $e');
      return [];
    }
  }

  Future<List<Song>> getSongsByGenre(
    String genre, {
    int size = 50,
    int offset = 0,
  }) async {
    if (_userId == null) return [];
    try {
      final data = await _get(
        '/Users/$_userId/Items',
        params: {
          'IncludeItemTypes': 'Audio',
          'Recursive': 'true',
          'Genres': genre,
          'Limit': size.toString(),
          'StartIndex': offset.toString(),
          'Fields': 'Genres,UserData',
        },
      );
      final items = data['Items'] as List<dynamic>? ?? [];
      return items.map((e) => _songFromItem(e as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint('[Jellyfin] getSongsByGenre error: $e');
      return [];
    }
  }

  Future<List<Album>> getAlbumsByGenre(
    String genre, {
    int size = 50,
    int offset = 0,
  }) async {
    if (_userId == null) return [];
    try {
      final data = await _get(
        '/Users/$_userId/Items',
        params: {
          'IncludeItemTypes': 'MusicAlbum',
          'Recursive': 'true',
          'Genres': genre,
          'Limit': size.toString(),
          'StartIndex': offset.toString(),
          'Fields': 'Genres,ChildCount',
        },
      );
      final items = data['Items'] as List<dynamic>? ?? [];
      return items
          .map((e) => _albumFromItem(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('[Jellyfin] getAlbumsByGenre error: $e');
      return [];
    }
  }

  Future<List<Song>> getSimilarSongs(String id, {int count = 50}) async {
    if (_userId == null) return [];
    try {
      final data = await _get(
        '/Items/$id/Similar',
        params: {
          'userId': _userId,
          'Limit': count.toString(),
          'Fields': 'Genres,UserData',
        },
      );
      final items = data['Items'] as List<dynamic>? ?? [];
      return items.map((e) => _songFromItem(e as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint('[Jellyfin] getSimilarSongs error: $e');
      return [];
    }
  }

  Future<List<Song>> getArtistTopSongs(
    String artistId, {
    int count = 50,
  }) async {
    if (_userId == null) return [];
    try {
      final data = await _get(
        '/Users/$_userId/Items',
        params: {
          'ArtistIds': artistId,
          'IncludeItemTypes': 'Audio',
          'Recursive': 'true',
          'SortBy': 'PlayCount',
          'SortOrder': 'Descending',
          'Limit': count.toString(),
          'Fields': 'Genres,UserData',
        },
      );
      final items = data['Items'] as List<dynamic>? ?? [];
      return items.map((e) => _songFromItem(e as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint('[Jellyfin] getArtistTopSongs error: $e');
      return [];
    }
  }

  Future<void> createPlaylist({
    required String name,
    String? comment,
    List<String>? songIds,
  }) async {
    if (_userId == null) return;
    try {
      await _post('/Playlists', {
        'Name': name,
        'UserId': _userId,
        'MediaType': 'Audio',
        if (songIds != null) 'Ids': songIds,
      });
    } catch (e) {
      debugPrint('[Jellyfin] createPlaylist error: $e');
    }
  }

  Future<void> deletePlaylist(String id) async {
    try {
      await _delete('/Items/$id');
    } catch (e) {
      debugPrint('[Jellyfin] deletePlaylist error: $e');
    }
  }

  Future<void> addSongsToPlaylist(String playlistId, List<String> ids) async {
    if (_userId == null) return;
    try {
      await _post(
        '/Playlists/$playlistId/Items'
        '?Ids=${ids.join(',')}&userId=$_userId',
        null,
      );
    } catch (e) {
      debugPrint('[Jellyfin] addSongsToPlaylist error: $e');
    }
  }

  Future<void> removeSongFromPlaylist(
    String playlistId,
    String entryId,
  ) async {
    try {
      await _delete('/Playlists/$playlistId/Items?EntryIds=$entryId');
    } catch (e) {
      debugPrint('[Jellyfin] removeSongFromPlaylist error: $e');
    }
  }
}
