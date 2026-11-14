import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LidarrService {
  static const String _keyEnabled = 'lidarr_enabled';
  static const String _keyHost = 'lidarr_host';
  static const String _keyApiKey = 'lidarr_api_key';
  static const String _keyQualityProfileId = 'lidarr_quality_profile_id';
  static const String _keyMetadataProfileId = 'lidarr_metadata_profile_id';
  static const String _keyRootFolderPath = 'lidarr_root_folder_path';

  static final LidarrService _instance = LidarrService._internal();
  factory LidarrService() => _instance;
  LidarrService._internal();

  SharedPreferences? _prefs;

  final ValueNotifier<bool> enabledNotifier = ValueNotifier(false);
  final ValueNotifier<String> hostNotifier =
      ValueNotifier('http://localhost:8686');
  final ValueNotifier<String> apiKeyNotifier = ValueNotifier('');

  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      headers: {
        'Accept': 'application/json',
        'User-Agent': 'Musly-Lidarr-Integration/1.0',
      },
    ),
  );

  Future<void> initialize() async {
    _prefs ??= await SharedPreferences.getInstance();
    enabledNotifier.value = isEnabled;
    hostNotifier.value = host;
    apiKeyNotifier.value = apiKey;
  }

  bool get isEnabled => _prefs?.getBool(_keyEnabled) ?? false;
  String get host => _prefs?.getString(_keyHost) ?? 'http://localhost:8686';
  String get apiKey => _prefs?.getString(_keyApiKey) ?? '';
  int get qualityProfileId => _prefs?.getInt(_keyQualityProfileId) ?? 1;
  int get metadataProfileId => _prefs?.getInt(_keyMetadataProfileId) ?? 1;
  String get rootFolderPath => _prefs?.getString(_keyRootFolderPath) ?? '';

  Future<void> setEnabled(bool value) async {
    await initialize();
    await _prefs!.setBool(_keyEnabled, value);
    enabledNotifier.value = value;
  }

  Future<void> setHost(String value) async {
    await initialize();
    var clean = value.trim();
    if (clean.endsWith('/')) {
      clean = clean.substring(0, clean.length - 1);
    }
    await _prefs!.setString(_keyHost, clean);
    hostNotifier.value = clean;
  }

  Future<void> setApiKey(String value) async {
    await initialize();
    final clean = value.trim();
    await _prefs!.setString(_keyApiKey, clean);
    apiKeyNotifier.value = clean;
  }

  Future<void> setQualityProfileId(int value) async {
    await initialize();
    await _prefs!.setInt(_keyQualityProfileId, value);
  }

  Future<void> setMetadataProfileId(int value) async {
    await initialize();
    await _prefs!.setInt(_keyMetadataProfileId, value);
  }

  Future<void> setRootFolderPath(String value) async {
    await initialize();
    await _prefs!.setString(_keyRootFolderPath, value.trim());
  }

  String _cleanHost(String? rawHost) {
    var h = (rawHost ?? host).trim();
    if (h.endsWith('/')) {
      h = h.substring(0, h.length - 1);
    }
    return h;
  }

  String _cleanKey(String? rawKey) => (rawKey ?? apiKey).trim();

  Future<Map<String, dynamic>> testConnection({
    String? testHost,
    String? testApiKey,
  }) async {
    final h = _cleanHost(testHost);
    final key = _cleanKey(testApiKey);

    if (h.isEmpty || key.isEmpty) {
      return {'success': false, 'error': 'Missing host or API key'};
    }

    try {
      final response = await _dio.get<dynamic>(
        '$h/api/v1/system/status',
        options: Options(
          headers: {'X-Api-Key': key},
        ),
      );

      if (response.statusCode == 200 && response.data is Map) {
        final data = response.data as Map<String, dynamic>;
        final version = data['version']?.toString() ?? 'Unknown';
        final appName = data['appName']?.toString() ?? 'Lidarr';
        return {
          'success': true,
          'version': version,
          'appName': appName,
        };
      }
      return {
        'success': false,
        'error': 'Server responded with code ${response.statusCode}',
      };
    } catch (e) {
      debugPrint('[LidarrService] Connection test failed: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<List<Map<String, dynamic>>> getQualityProfiles() async {
    final h = _cleanHost(null);
    final key = _cleanKey(null);
    if (h.isEmpty || key.isEmpty) return [];

    try {
      final response = await _dio.get<dynamic>(
        '$h/api/v1/qualityprofile',
        options: Options(headers: {'X-Api-Key': key}),
      );
      if (response.data is List) {
        return (response.data as List)
            .map((item) => Map<String, dynamic>.from(item as Map))
            .toList();
      }
    } catch (e) {
      debugPrint('[LidarrService] getQualityProfiles error: $e');
    }
    return [];
  }

  Future<List<Map<String, dynamic>>> getMetadataProfiles() async {
    final h = _cleanHost(null);
    final key = _cleanKey(null);
    if (h.isEmpty || key.isEmpty) return [];

    try {
      final response = await _dio.get<dynamic>(
        '$h/api/v1/metadataprofile',
        options: Options(headers: {'X-Api-Key': key}),
      );
      if (response.data is List) {
        return (response.data as List)
            .map((item) => Map<String, dynamic>.from(item as Map))
            .toList();
      }
    } catch (e) {
      debugPrint('[LidarrService] getMetadataProfiles error: $e');
    }
    return [];
  }

  Future<List<Map<String, dynamic>>> getRootFolders() async {
    final h = _cleanHost(null);
    final key = _cleanKey(null);
    if (h.isEmpty || key.isEmpty) return [];

    try {
      final response = await _dio.get<dynamic>(
        '$h/api/v1/rootfolder',
        options: Options(headers: {'X-Api-Key': key}),
      );
      if (response.data is List) {
        return (response.data as List)
            .map((item) => Map<String, dynamic>.from(item as Map))
            .toList();
      }
    } catch (e) {
      debugPrint('[LidarrService] getRootFolders error: $e');
    }
    return [];
  }

  Future<List<Map<String, dynamic>>> searchAlbums(String query) async {
    final h = _cleanHost(null);
    final key = _cleanKey(null);
    final term = query.trim();
    if (h.isEmpty || key.isEmpty || term.isEmpty) return [];

    try {
      final response = await _dio.get<dynamic>(
        '$h/api/v1/album/lookup',
        queryParameters: {'term': term},
        options: Options(headers: {'X-Api-Key': key}),
      );
      if (response.data is List) {
        return (response.data as List)
            .map((item) => Map<String, dynamic>.from(item as Map))
            .toList();
      }
    } catch (e) {
      debugPrint('[LidarrService] searchAlbums error: $e');
    }
    return [];
  }

  Future<List<Map<String, dynamic>>> searchArtists(String query) async {
    final h = _cleanHost(null);
    final key = _cleanKey(null);
    final term = query.trim();
    if (h.isEmpty || key.isEmpty || term.isEmpty) return [];

    try {
      final response = await _dio.get<dynamic>(
        '$h/api/v1/artist/lookup',
        queryParameters: {'term': term},
        options: Options(headers: {'X-Api-Key': key}),
      );
      if (response.data is List) {
        return (response.data as List)
            .map((item) => Map<String, dynamic>.from(item as Map))
            .toList();
      }
    } catch (e) {
      debugPrint('[LidarrService] searchArtists error: $e');
    }
    return [];
  }

  Future<Map<String, dynamic>> addAlbumToLidarr(
    Map<String, dynamic> albumData, {
    int? customQualityProfileId,
    String? customRootFolderPath,
  }) async {
    final h = _cleanHost(null);
    final key = _cleanKey(null);
    if (h.isEmpty || key.isEmpty) {
      return {'success': false, 'error': 'Lidarr is not configured'};
    }

    try {
      final effectiveQualityId = customQualityProfileId ?? qualityProfileId;
      var effectiveRootFolder = customRootFolderPath ?? rootFolderPath;

      if (effectiveRootFolder.isEmpty) {
        final roots = await getRootFolders();
        if (roots.isNotEmpty && roots[0]['path'] != null) {
          effectiveRootFolder = roots[0]['path'].toString();
        }
      }

      final foreignAlbumId = albumData['foreignAlbumId']?.toString() ??
          albumData['id']?.toString() ??
          '';

      final artistData = albumData['artist'] is Map
          ? Map<String, dynamic>.from(albumData['artist'] as Map)
          : null;

      final artistName = artistData?['artistName']?.toString() ??
          albumData['artistName']?.toString() ??
          '';
      final foreignArtistId = artistData?['foreignArtistId']?.toString() ?? '';

      // Check if artist already exists in Lidarr
      final existingArtistsResponse = await _dio.get<dynamic>(
        '$h/api/v1/artist',
        options: Options(headers: {'X-Api-Key': key}),
      );

      Map<String, dynamic>? matchingArtist;
      if (existingArtistsResponse.data is List) {
        for (final item in existingArtistsResponse.data as List) {
          if (item is Map) {
            final existingForeignId = item['foreignArtistId']?.toString();
            final existingName = item['artistName']?.toString().toLowerCase();
            if ((foreignArtistId.isNotEmpty &&
                    existingForeignId == foreignArtistId) ||
                (artistName.isNotEmpty &&
                    existingName == artistName.toLowerCase())) {
              matchingArtist = Map<String, dynamic>.from(item);
              break;
            }
          }
        }
      }

      int? artistId;
      if (matchingArtist != null) {
        artistId = matchingArtist['id'] as int?;
      } else if (artistData != null) {
        // Add new artist to Lidarr
        final newArtistPayload = {
          ...artistData,
          'qualityProfileId': effectiveQualityId,
          'metadataProfileId': metadataProfileId,
          'rootFolderPath': effectiveRootFolder,
          'monitored': true,
          'addOptions': {
            'monitor': 'all',
            'searchForMissingEpisodes': false,
            if (foreignAlbumId.isNotEmpty)
              'albumsToMonitor': [foreignAlbumId],
          },
        };

        final addArtistResponse = await _dio.post<dynamic>(
          '$h/api/v1/artist',
          data: newArtistPayload,
          options: Options(headers: {'X-Api-Key': key}),
        );
        if (addArtistResponse.data is Map) {
          artistId = addArtistResponse.data['id'] as int?;
        }
      }

      // Trigger search command for this album / artist
      if (artistId != null) {
        try {
          await _dio.post<dynamic>(
            '$h/api/v1/command',
            data: {
              'name': 'ArtistSearch',
              'artistId': artistId,
            },
            options: Options(headers: {'X-Api-Key': key}),
          );
        } catch (_) {}
      }

      return {
        'success': true,
        'message': 'Album added to Lidarr successfully',
        'artistId': artistId,
      };
    } catch (e) {
      debugPrint('[LidarrService] addAlbumToLidarr error: $e');
      return {'success': false, 'error': e.toString()};
    }
  }
}
