import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class AndroidAutoSettingsService {
  static const String _keyMaxItems = 'auto_max_items';
  static const String _keyShowRecent = 'auto_show_recent';
  static const String _keyShowFavorites = 'auto_show_favorites';
  static const String _keyShowAlbums = 'auto_show_albums';
  static const String _keyShowArtists = 'auto_show_artists';
  static const String _keyShowPlaylists = 'auto_show_playlists';
  static const String _keyShowGenres = 'auto_show_genres';
  static const String _keyShowRadio = 'auto_show_radio';
  static const String _keyShowDownloads = 'auto_show_downloads';

  static final AndroidAutoSettingsService _instance = AndroidAutoSettingsService._internal();
  factory AndroidAutoSettingsService() => _instance;
  AndroidAutoSettingsService._internal();

  SharedPreferences? _prefs;

  final ValueNotifier<int> maxItemsNotifier = ValueNotifier(100);
  final ValueNotifier<bool> showRecentNotifier = ValueNotifier(true);
  final ValueNotifier<bool> showFavoritesNotifier = ValueNotifier(true);
  final ValueNotifier<bool> showAlbumsNotifier = ValueNotifier(true);
  final ValueNotifier<bool> showArtistsNotifier = ValueNotifier(true);
  final ValueNotifier<bool> showPlaylistsNotifier = ValueNotifier(true);
  final ValueNotifier<bool> showGenresNotifier = ValueNotifier(true);
  final ValueNotifier<bool> showRadioNotifier = ValueNotifier(true);
  final ValueNotifier<bool> showDownloadsNotifier = ValueNotifier(true);

  Future<void> initialize() async {
    _prefs ??= await SharedPreferences.getInstance();
    maxItemsNotifier.value = getMaxItems();
    showRecentNotifier.value = getShowRecent();
    showFavoritesNotifier.value = getShowFavorites();
    showAlbumsNotifier.value = getShowAlbums();
    showArtistsNotifier.value = getShowArtists();
    showPlaylistsNotifier.value = getShowPlaylists();
    showGenresNotifier.value = getShowGenres();
    showRadioNotifier.value = getShowRadio();
    showDownloadsNotifier.value = getShowDownloads();
  }

  int getMaxItems() => _prefs?.getInt(_keyMaxItems) ?? 100;
  Future<void> setMaxItems(int value) async {
    await initialize();
    await _prefs!.setInt(_keyMaxItems, value);
    maxItemsNotifier.value = value;
  }

  bool getShowRecent() => _prefs?.getBool(_keyShowRecent) ?? true;
  Future<void> setShowRecent(bool value) async {
    await initialize();
    await _prefs!.setBool(_keyShowRecent, value);
    showRecentNotifier.value = value;
  }

  bool getShowFavorites() => _prefs?.getBool(_keyShowFavorites) ?? true;
  Future<void> setShowFavorites(bool value) async {
    await initialize();
    await _prefs!.setBool(_keyShowFavorites, value);
    showFavoritesNotifier.value = value;
  }

  bool getShowAlbums() => _prefs?.getBool(_keyShowAlbums) ?? true;
  Future<void> setShowAlbums(bool value) async {
    await initialize();
    await _prefs!.setBool(_keyShowAlbums, value);
    showAlbumsNotifier.value = value;
  }

  bool getShowArtists() => _prefs?.getBool(_keyShowArtists) ?? true;
  Future<void> setShowArtists(bool value) async {
    await initialize();
    await _prefs!.setBool(_keyShowArtists, value);
    showArtistsNotifier.value = value;
  }

  bool getShowPlaylists() => _prefs?.getBool(_keyShowPlaylists) ?? true;
  Future<void> setShowPlaylists(bool value) async {
    await initialize();
    await _prefs!.setBool(_keyShowPlaylists, value);
    showPlaylistsNotifier.value = value;
  }

  bool getShowGenres() => _prefs?.getBool(_keyShowGenres) ?? true;
  Future<void> setShowGenres(bool value) async {
    await initialize();
    await _prefs!.setBool(_keyShowGenres, value);
    showGenresNotifier.value = value;
  }

  bool getShowRadio() => _prefs?.getBool(_keyShowRadio) ?? true;
  Future<void> setShowRadio(bool value) async {
    await initialize();
    await _prefs!.setBool(_keyShowRadio, value);
    showRadioNotifier.value = value;
  }

  bool getShowDownloads() => _prefs?.getBool(_keyShowDownloads) ?? true;
  Future<void> setShowDownloads(bool value) async {
    await initialize();
    await _prefs!.setBool(_keyShowDownloads, value);
    showDownloadsNotifier.value = value;
  }

  String? getServerId() => _prefs?.getString('auto_server_id');
  Future<void> setServerId(String? id) async {
    if (id == null) {
      await _prefs?.remove('auto_server_id');
    } else {
      await _prefs?.setString('auto_server_id', id);
    }
  }
}
