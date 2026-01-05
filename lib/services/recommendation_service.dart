import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';

class RecommendationService extends ChangeNotifier {
  static const String _dataKey = 'rec_data_v2';
  static const String _skipKey = 'rec_skips';
  static const String _timeKey = 'rec_time';
  static const String _enabledKey = 'recommendations_enabled';

  bool _enabled = true;
  Map<String, SongProfile> _profiles = {};
  Map<String, double> _artistAffinity = {};
  Map<String, double> _genreAffinity = {};
  Map<String, int> _skipCounts = {};
  Map<int, Map<String, double>> _timePatterns = {};
  List<String> _recentlyPlayed = [];

  bool get enabled => _enabled;
  Map<String, SongProfile> get profiles => _profiles;

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _enabled = prefs.getBool(_enabledKey) ?? true;

    final dataJson = prefs.getString(_dataKey);
    if (dataJson != null) {
      try {
        final Map<String, dynamic> data = json.decode(dataJson);
        _profiles =
            (data['profiles'] as Map<String, dynamic>?)?.map(
              (k, v) => MapEntry(k, SongProfile.fromJson(v)),
            ) ??
            {};
        _artistAffinity = Map<String, double>.from(data['artists'] ?? {});
        _genreAffinity = Map<String, double>.from(data['genres'] ?? {});
        _recentlyPlayed = List<String>.from(data['recent'] ?? []);
      } catch (e) {
        debugPrint('Error loading data: $e');
      }
    }

    final skipJson = prefs.getString(_skipKey);
    if (skipJson != null) {
      try {
        _skipCounts = Map<String, int>.from(json.decode(skipJson));
      } catch (e) {
        debugPrint('Error loading skips: $e');
      }
    }

    final timeJson = prefs.getString(_timeKey);
    if (timeJson != null) {
      try {
        final Map<String, dynamic> timeData = json.decode(timeJson);
        _timePatterns = timeData.map(
          (k, v) => MapEntry(int.parse(k), Map<String, double>.from(v)),
        );
      } catch (e) {
        debugPrint('Error loading time: $e');
      }
    }

    notifyListeners();
  }

  Future<void> setEnabled(bool enabled) async {
    _enabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, enabled);
    notifyListeners();
  }

  Future<void> trackSongPlay(
    Song song, {
    int durationPlayed = 0,
    bool completed = false,
  }) async {
    if (!_enabled) return;

    final songId = song.id;
    final hour = DateTime.now().hour;

    if (_profiles.containsKey(songId)) {
      _profiles[songId]!.addPlay(
        durationPlayed: durationPlayed,
        completed: completed,
        hour: hour,
      );
    } else {
      _profiles[songId] =
          SongProfile(
            songId: songId,
            title: song.title,
            artist: song.artist,
            artistId: song.artistId,
            albumId: song.albumId,
            genre: song.genre,
            duration: song.duration,
          )..addPlay(
            durationPlayed: durationPlayed,
            completed: completed,
            hour: hour,
          );
    }

    _recentlyPlayed.remove(songId);
    _recentlyPlayed.insert(0, songId);
    if (_recentlyPlayed.length > 500) {
      _recentlyPlayed = _recentlyPlayed.take(500).toList();
    }

    if (song.artist != null) {
      final w = completed ? 1.5 : 0.8;
      _artistAffinity[song.artist!] = (_artistAffinity[song.artist!] ?? 0) + w;
    }

    if (song.genre != null) {
      final w = completed ? 1.2 : 0.6;
      _genreAffinity[song.genre!] = (_genreAffinity[song.genre!] ?? 0) + w;
    }

    _timePatterns.putIfAbsent(hour, () => {});
    if (song.genre != null) {
      _timePatterns[hour]![song.genre!] =
          (_timePatterns[hour]![song.genre!] ?? 0) + 1;
    }

    await _saveData();
    notifyListeners();
  }

  Future<void> trackSkip(Song song) async {
    if (!_enabled) return;

    _skipCounts[song.id] = (_skipCounts[song.id] ?? 0) + 1;

    if (song.artist != null) {
      _artistAffinity[song.artist!] =
          (_artistAffinity[song.artist!] ?? 0) - 0.3;
    }

    if (_profiles.containsKey(song.id)) {
      _profiles[song.id]!.skipCount++;
    }

    await _saveData();
  }

  double calculateSongScore(Song song, {int? currentHour}) {
    if (!_enabled) return 0.0;

    double score = 0.5;
    final profile = _profiles[song.id];
    final hour = currentHour ?? DateTime.now().hour;

    if (_artistAffinity.isNotEmpty && song.artist != null) {
      final maxA = _artistAffinity.values.reduce(max);
      final artistScore = _artistAffinity[song.artist] ?? 0;
      score += (artistScore / maxA) * 0.35;
    }

    if (_genreAffinity.isNotEmpty && song.genre != null) {
      final maxG = _genreAffinity.values.reduce(max);
      final genreScore = _genreAffinity[song.genre] ?? 0;
      score += (genreScore / maxG) * 0.25;
    }

    if (profile != null) {
      score += profile.completionRate * 0.15;
      score += profile.getHourPreference(hour) * 0.1;
      if (profile.playCount > 0) {
        score += min(profile.playCount / 10.0, 1.0) * 0.1;
      }
    }

    final skips = _skipCounts[song.id] ?? 0;
    if (skips > 0) {
      score -= min(skips * 0.05, 0.3);
    }

    final recentIdx = _recentlyPlayed.indexOf(song.id);
    if (recentIdx >= 0 && recentIdx < 20) {
      score -= (20 - recentIdx) * 0.015;
    }

    if (_timePatterns.containsKey(hour) && song.genre != null) {
      final hg = _timePatterns[hour]!;
      if (hg.isNotEmpty) {
        final maxHg = hg.values.reduce(max);
        score += ((hg[song.genre] ?? 0) / maxHg) * 0.05;
      }
    }

    return score.clamp(0.0, 1.0);
  }

  List<Song> getPersonalizedFeed(List<Song> allSongs, {int limit = 50}) {
    if (!_enabled || allSongs.isEmpty) return allSongs.take(limit).toList();

    final hour = DateTime.now().hour;
    final rnd = Random();

    final scored = allSongs.map((s) {
      final base = calculateSongScore(s, currentHour: hour);
      return MapEntry(s, base + rnd.nextDouble() * 0.15);
    }).toList();

    scored.sort((a, b) => b.value.compareTo(a.value));
    return scored.take(limit).map((e) => e.key).toList();
  }

  List<Song> getQuickPicks(List<Song> allSongs, {int limit = 20}) {
    if (!_enabled || allSongs.isEmpty) return [];

    final topArtists = _getTopArtists(5);
    final topGenres = _getTopGenres(3);

    final candidates = allSongs.where((s) {
      if (_recentlyPlayed.take(10).contains(s.id)) return false;
      if (topArtists.contains(s.artist)) return true;
      if (topGenres.contains(s.genre)) return true;
      return false;
    }).toList();

    if (candidates.isEmpty) return allSongs.take(limit).toList();

    final hour = DateTime.now().hour;
    candidates.sort((a, b) {
      final sa = calculateSongScore(a, currentHour: hour);
      final sb = calculateSongScore(b, currentHour: hour);
      return sb.compareTo(sa);
    });

    return candidates.take(limit).toList();
  }

  List<Song> getDiscoverMix(List<Song> allSongs, {int limit = 25}) {
    if (!_enabled || allSongs.isEmpty) return [];

    final knownIds = _profiles.keys.toSet();
    final knownArtists = _artistAffinity.keys.toSet();

    final newSongs = allSongs.where((s) {
      if (knownIds.contains(s.id)) return false;
      if (knownArtists.contains(s.artist)) return false;
      return true;
    }).toList();

    if (newSongs.isEmpty) {
      return allSongs
          .where((s) => !knownIds.contains(s.id))
          .take(limit)
          .toList();
    }

    final topGenres = _getTopGenres(5);
    final rnd = Random();
    final scored = newSongs.map((s) {
      double sc = 0.5;
      if (topGenres.contains(s.genre)) sc += 0.3;
      sc += rnd.nextDouble() * 0.2;
      return MapEntry(s, sc);
    }).toList();

    scored.sort((a, b) => b.value.compareTo(a.value));
    return scored.take(limit).map((e) => e.key).toList();
  }

  List<Song> getArtistMix(
    List<Song> allSongs,
    String artist, {
    int limit = 25,
  }) {
    if (!_enabled) return [];
    return allSongs.where((s) => s.artist == artist).take(limit).toList();
  }

  Map<String, List<Song>> generateMixes(List<Song> allSongs) {
    if (!_enabled || allSongs.isEmpty) return {};

    final mixes = <String, List<Song>>{};

    final quick = getQuickPicks(allSongs, limit: 20);
    if (quick.isNotEmpty) mixes['Quick Picks'] = quick;

    final discover = getDiscoverMix(allSongs, limit: 20);
    if (discover.isNotEmpty) mixes['Discover Mix'] = discover;

    final topArtists = _getTopArtists(3);
    for (final artist in topArtists) {
      final mix = getArtistMix(allSongs, artist, limit: 15);
      if (mix.length >= 5) mixes['$artist Mix'] = mix;
    }

    final hour = DateTime.now().hour;
    String timeLabel;
    if (hour >= 5 && hour < 12) {
      timeLabel = 'Morning';
    } else if (hour >= 12 && hour < 17) {
      timeLabel = 'Afternoon';
    } else if (hour >= 17 && hour < 21) {
      timeLabel = 'Evening';
    } else {
      timeLabel = 'Night';
    }

    if (_timePatterns.containsKey(hour)) {
      final hg = _timePatterns[hour]!;
      if (hg.isNotEmpty) {
        final topG = hg.entries.reduce((a, b) => a.value > b.value ? a : b).key;
        final timeSongs = allSongs
            .where((s) => s.genre == topG)
            .take(15)
            .toList();
        if (timeSongs.length >= 5) mixes['$timeLabel Vibes'] = timeSongs;
      }
    }

    return mixes;
  }

  List<String> _getTopArtists(int limit) {
    if (_artistAffinity.isEmpty) return [];
    final sorted = _artistAffinity.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(limit).map((e) => e.key).toList();
  }

  List<String> _getTopGenres(int limit) {
    if (_genreAffinity.isEmpty) return [];
    final sorted = _genreAffinity.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(limit).map((e) => e.key).toList();
  }

  List<String> getRecommendedArtists({int limit = 10}) => _getTopArtists(limit);
  List<String> getRecommendedGenres({int limit = 5}) => _getTopGenres(limit);

  Map<String, dynamic> getListeningStats() {
    int totalPlays = 0;
    int totalDuration = 0;
    for (final p in _profiles.values) {
      totalPlays += p.playCount;
      totalDuration += p.totalListenTime;
    }

    return {
      'totalPlays': totalPlays,
      'totalMinutes': totalDuration ~/ 60,
      'uniqueSongs': _profiles.length,
      'uniqueArtists': _artistAffinity.length,
      'uniqueGenres': _genreAffinity.length,
      'topArtists': _getTopArtists(5),
      'topGenres': _getTopGenres(5),
    };
  }

  Future<void> clearData() async {
    _profiles.clear();
    _artistAffinity.clear();
    _genreAffinity.clear();
    _skipCounts.clear();
    _timePatterns.clear();
    _recentlyPlayed.clear();

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_dataKey);
    await prefs.remove(_skipKey);
    await prefs.remove(_timeKey);

    notifyListeners();
  }

  Future<void> _saveData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final data = {
        'profiles': _profiles.map((k, v) => MapEntry(k, v.toJson())),
        'artists': _artistAffinity,
        'genres': _genreAffinity,
        'recent': _recentlyPlayed,
      };
      await prefs.setString(_dataKey, json.encode(data));
      await prefs.setString(_skipKey, json.encode(_skipCounts));

      final timeData = _timePatterns.map((k, v) => MapEntry(k.toString(), v));
      await prefs.setString(_timeKey, json.encode(timeData));
    } catch (e) {
      debugPrint('Error saving data: $e');
    }
  }
}

class SongProfile {
  final String songId;
  final String title;
  final String? artist;
  final String? artistId;
  final String? albumId;
  final String? genre;
  final int? duration;

  int playCount = 0;
  int skipCount = 0;
  int totalListenTime = 0;
  int completedPlays = 0;
  Map<int, int> hourlyPlays = {};
  DateTime lastPlayed = DateTime.now();

  SongProfile({
    required this.songId,
    required this.title,
    this.artist,
    this.artistId,
    this.albumId,
    this.genre,
    this.duration,
  });

  void addPlay({int durationPlayed = 0, bool completed = false, int? hour}) {
    playCount++;
    totalListenTime += durationPlayed;
    if (completed) completedPlays++;
    if (hour != null) {
      hourlyPlays[hour] = (hourlyPlays[hour] ?? 0) + 1;
    }
    lastPlayed = DateTime.now();
  }

  double get completionRate {
    if (playCount == 0) return 0.0;
    return completedPlays / playCount;
  }

  double getHourPreference(int hour) {
    if (hourlyPlays.isEmpty) return 0.0;
    final maxH = hourlyPlays.values.reduce(max);
    return (hourlyPlays[hour] ?? 0) / maxH;
  }

  Map<String, dynamic> toJson() => {
    'songId': songId,
    'title': title,
    'artist': artist,
    'artistId': artistId,
    'albumId': albumId,
    'genre': genre,
    'duration': duration,
    'playCount': playCount,
    'skipCount': skipCount,
    'totalListenTime': totalListenTime,
    'completedPlays': completedPlays,
    'hourlyPlays': hourlyPlays.map((k, v) => MapEntry(k.toString(), v)),
    'lastPlayed': lastPlayed.millisecondsSinceEpoch,
  };

  factory SongProfile.fromJson(Map<String, dynamic> json) {
    final p = SongProfile(
      songId: json['songId'],
      title: json['title'],
      artist: json['artist'],
      artistId: json['artistId'],
      albumId: json['albumId'],
      genre: json['genre'],
      duration: json['duration'],
    );
    p.playCount = json['playCount'] ?? 0;
    p.skipCount = json['skipCount'] ?? 0;
    p.totalListenTime = json['totalListenTime'] ?? 0;
    p.completedPlays = json['completedPlays'] ?? 0;
    p.hourlyPlays =
        (json['hourlyPlays'] as Map<String, dynamic>?)?.map(
          (k, v) => MapEntry(int.parse(k), v as int),
        ) ??
        {};
    p.lastPlayed = json['lastPlayed'] != null
        ? DateTime.fromMillisecondsSinceEpoch(json['lastPlayed'])
        : DateTime.now();
    return p;
  }
}
