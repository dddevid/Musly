import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FavoritePlaylistsService extends ChangeNotifier {
  static const String _prefsKey = 'favorite_playlist_ids';

  final Set<String> _favoriteIds = {};
  bool _initialized = false;

  static final FavoritePlaylistsService _instance =
      FavoritePlaylistsService._internal();
  factory FavoritePlaylistsService() => _instance;
  FavoritePlaylistsService._internal();

  Future<void> initialize() async {
    if (_initialized) return;

    final prefs = await SharedPreferences.getInstance();
    final savedIds = prefs.getStringList(_prefsKey);
    if (savedIds != null) {
      _favoriteIds.addAll(savedIds);
    }
    _initialized = true;
    notifyListeners();
  }

  bool isFavorite(String playlistId) {
    return _favoriteIds.contains(playlistId);
  }

  Future<void> toggleFavorite(String playlistId) async {
    if (_favoriteIds.contains(playlistId)) {
      _favoriteIds.remove(playlistId);
    } else {
      _favoriteIds.add(playlistId);
    }

    await _saveFavorites();
    notifyListeners();
  }

  Future<void> addFavorite(String playlistId) async {
    if (!_favoriteIds.contains(playlistId)) {
      _favoriteIds.add(playlistId);
      await _saveFavorites();
      notifyListeners();
    }
  }

  Future<void> removeFavorite(String playlistId) async {
    if (_favoriteIds.contains(playlistId)) {
      _favoriteIds.remove(playlistId);
      await _saveFavorites();
      notifyListeners();
    }
  }

  List<String> getFavoriteIds() {
    return List.unmodifiable(_favoriteIds);
  }

  int get favoriteCount => _favoriteIds.length;

  bool get hasFavorites => _favoriteIds.isNotEmpty;

  Future<void> _saveFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_prefsKey, _favoriteIds.toList());
  }

  Future<void> clearAll() async {
    _favoriteIds.clear();
    await _saveFavorites();
    notifyListeners();
  }
}
