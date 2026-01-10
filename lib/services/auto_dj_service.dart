import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/song.dart';
import 'bpm_analyzer_service.dart';
import 'subsonic_service.dart';
import 'recommendation_service.dart';

/// Auto DJ modes for automatic queue continuation
enum AutoDjMode {
  off,
  shuffleLibrary,
  similarSongs,
  sameGenre,
  sameArtist,
  smartMix,
}

class SongAnalysis {
  final String songId;
  final int bpm;
  final String? genre;
  final int? year;
  final double energy;
  final int duration;

  SongAnalysis({
    required this.songId,
    required this.bpm,
    this.genre,
    this.year,
    required this.energy,
    required this.duration,
  });

  Map<String, dynamic> toJson() => {
    'songId': songId,
    'bpm': bpm,
    'genre': genre,
    'year': year,
    'energy': energy,
    'duration': duration,
  };

  factory SongAnalysis.fromJson(Map<String, dynamic> json) => SongAnalysis(
    songId: json['songId'] as String,
    bpm: json['bpm'] as int,
    genre: json['genre'] as String?,
    year: json['year'] as int?,
    energy: (json['energy'] as num).toDouble(),
    duration: json['duration'] as int,
  );
}

class AutoDjService extends ChangeNotifier {
  static final AutoDjService _instance = AutoDjService._internal();
  factory AutoDjService() => _instance;
  AutoDjService._internal();

  final BpmAnalyzerService _bpmAnalyzer = BpmAnalyzerService();
  SharedPreferences? _prefs;
  bool _isInitialized = false;

  final Map<String, SongAnalysis> _analysisCache = {};

  // Auto-continue settings
  static const String _modeKey = 'auto_dj_mode';
  static const String _countKey = 'auto_dj_songs_to_add';
  static const String _thresholdKey = 'auto_dj_threshold';

  AutoDjMode _mode = AutoDjMode.off;
  int _songsToAdd = 5;
  int _triggerThreshold = 2;

  // Cache for avoiding repeated songs
  final Set<String> _recentlyAddedIds = {};
  static const int _maxRecentlyAdded = 100;

  SubsonicService? _subsonicService;
  RecommendationService? _recommendationService;

  bool _isAnalyzing = false;
  double _analysisProgress = 0.0;
  String _analysisStatus = '';

  VoidCallback? _onProgressUpdate;

  bool get isAnalyzing => _isAnalyzing;
  double get analysisProgress => _analysisProgress;
  String get analysisStatus => _analysisStatus;

  AutoDjMode get mode => _mode;
  int get songsToAdd => _songsToAdd;
  int get triggerThreshold => _triggerThreshold;
  bool get isEnabled => _mode != AutoDjMode.off;

  void setServices(
    SubsonicService subsonicService,
    RecommendationService? recommendationService,
  ) {
    _subsonicService = subsonicService;
    _recommendationService = recommendationService;
  }

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _prefs = await SharedPreferences.getInstance();
      await _bpmAnalyzer.initialize();
      await _loadAnalysisCache();

      // Load mode settings
      final modeIndex = _prefs?.getInt(_modeKey) ?? 0;
      _mode =
          AutoDjMode.values[modeIndex.clamp(0, AutoDjMode.values.length - 1)];
      _songsToAdd = _prefs?.getInt(_countKey) ?? 5;
      _triggerThreshold = _prefs?.getInt(_thresholdKey) ?? 2;

      _isInitialized = true;
    } catch (e) {
      debugPrint('Error initializing AutoDJ: $e');
    }
  }

  Future<void> setMode(AutoDjMode mode) async {
    _mode = mode;
    await _prefs?.setInt(_modeKey, mode.index);
    notifyListeners();
  }

  Future<void> setSongsToAdd(int count) async {
    _songsToAdd = count.clamp(1, 20);
    await _prefs?.setInt(_countKey, _songsToAdd);
    notifyListeners();
  }

  Future<void> setTriggerThreshold(int threshold) async {
    _triggerThreshold = threshold.clamp(1, 10);
    await _prefs?.setInt(_thresholdKey, _triggerThreshold);
    notifyListeners();
  }

  /// Check if Auto DJ should add songs to the queue
  bool shouldAddSongs(int currentIndex, int queueLength) {
    if (!isEnabled) return false;
    final remaining = queueLength - currentIndex - 1;
    return remaining <= _triggerThreshold;
  }

  /// Get songs to add to the queue based on the current mode
  Future<List<Song>> getSongsToQueue({
    required Song? currentSong,
    required List<Song> currentQueue,
    List<Song>? availableSongs,
  }) async {
    if (!isEnabled || _subsonicService == null) return [];

    final existingIds = currentQueue.map((s) => s.id).toSet();

    try {
      switch (_mode) {
        case AutoDjMode.off:
          return [];

        case AutoDjMode.shuffleLibrary:
          return await _getShuffledLibrarySongs(existingIds);

        case AutoDjMode.similarSongs:
          if (currentSong == null)
            return await _getShuffledLibrarySongs(existingIds);
          return await _getSimilarSongs(currentSong, existingIds);

        case AutoDjMode.sameGenre:
          if (currentSong?.genre == null)
            return await _getShuffledLibrarySongs(existingIds);
          return await _getSameGenreSongs(currentSong!.genre!, existingIds);

        case AutoDjMode.sameArtist:
          if (currentSong?.artistId == null)
            return await _getShuffledLibrarySongs(existingIds);
          return await _getSameArtistSongs(currentSong!.artistId!, existingIds);

        case AutoDjMode.smartMix:
          return await _getSmartMixSongs(
            currentSong,
            existingIds,
            availableSongs,
          );
      }
    } catch (e) {
      debugPrint('Auto DJ error: $e');
      return await _getShuffledLibrarySongs(existingIds);
    }
  }

  Future<List<Song>> _getShuffledLibrarySongs(Set<String> existingIds) async {
    final songs = await _subsonicService!.getRandomSongs(size: _songsToAdd * 2);
    return _filterAndLimit(songs, existingIds);
  }

  Future<List<Song>> _getSimilarSongs(
    Song song,
    Set<String> existingIds,
  ) async {
    final similarSongs = await _subsonicService!.getSimilarSongs(
      song.id,
      count: _songsToAdd * 2,
    );

    if (similarSongs.isNotEmpty) {
      return _filterAndLimit(similarSongs, existingIds);
    }

    // Fallback: try same genre or artist
    if (song.genre != null) {
      final genreSongs = await _getSameGenreSongs(song.genre!, existingIds);
      if (genreSongs.isNotEmpty) return genreSongs;
    }

    if (song.artistId != null) {
      final artistSongs = await _getSameArtistSongs(
        song.artistId!,
        existingIds,
      );
      if (artistSongs.isNotEmpty) return artistSongs;
    }

    return await _getShuffledLibrarySongs(existingIds);
  }

  Future<List<Song>> _getSameGenreSongs(
    String genre,
    Set<String> existingIds,
  ) async {
    final songs = await _subsonicService!.getSongsByGenre(
      genre,
      count: _songsToAdd * 2,
    );
    final filtered = _filterAndLimit(songs, existingIds);

    if (filtered.isEmpty) {
      return await _getShuffledLibrarySongs(existingIds);
    }
    return filtered;
  }

  Future<List<Song>> _getSameArtistSongs(
    String artistId,
    Set<String> existingIds,
  ) async {
    final topSongs = await _subsonicService!.getArtistTopSongs(
      artistId,
      count: _songsToAdd * 2,
    );
    final filtered = _filterAndLimit(topSongs, existingIds);

    if (filtered.isEmpty) {
      return await _getShuffledLibrarySongs(existingIds);
    }
    return filtered;
  }

  Future<List<Song>> _getSmartMixSongs(
    Song? currentSong,
    Set<String> existingIds,
    List<Song>? availableSongs,
  ) async {
    final List<Song> results = [];
    final List<Future<List<Song>>> futures = [];

    if (currentSong != null) {
      // 40% similar songs
      futures.add(
        _subsonicService!.getSimilarSongs(
          currentSong.id,
          count: (_songsToAdd * 0.4).ceil(),
        ),
      );

      // 30% same genre
      if (currentSong.genre != null) {
        futures.add(
          _subsonicService!.getSongsByGenre(
            currentSong.genre!,
            count: (_songsToAdd * 0.3).ceil(),
          ),
        );
      }
    }

    // Use recommendation service for intelligent picks
    if (_recommendationService != null) {
      final topGenres = _recommendationService!.getRecommendedGenres(limit: 3);
      for (final genre in topGenres.take(2)) {
        futures.add(_subsonicService!.getSongsByGenre(genre, count: 3));
      }
    }

    // Add some random for variety
    futures.add(
      _subsonicService!.getRandomSongs(size: (_songsToAdd * 0.3).ceil()),
    );

    // If we have BPM analysis and available songs, use smart transition
    if (currentSong != null &&
        availableSongs != null &&
        _analysisCache.containsKey(currentSong.id)) {
      final smartQueue = generateQueue(
        seedSong: currentSong,
        availableSongs: availableSongs
            .where((s) => !existingIds.contains(s.id))
            .toList(),
        queueLength: _songsToAdd,
      );
      if (smartQueue.length > 1) {
        return smartQueue.skip(1).toList(); // Skip the seed song
      }
    }

    final allResults = await Future.wait(futures);
    for (final songList in allResults) {
      results.addAll(songList);
    }

    results.shuffle(Random());
    return _filterAndLimit(results, existingIds);
  }

  List<Song> _filterAndLimit(List<Song> songs, Set<String> existingIds) {
    final filtered = songs.where((s) {
      return !existingIds.contains(s.id) && !_recentlyAddedIds.contains(s.id);
    }).toList();

    filtered.shuffle(Random());
    final result = filtered.take(_songsToAdd).toList();

    // Add to recently added cache
    for (final song in result) {
      _recentlyAddedIds.add(song.id);
      if (_recentlyAddedIds.length > _maxRecentlyAdded) {
        _recentlyAddedIds.remove(_recentlyAddedIds.first);
      }
    }

    return result;
  }

  /// Clear the recently added cache
  void clearRecentlyAdded() {
    _recentlyAddedIds.clear();
  }

  /// Get display name for mode
  static String getModeDisplayName(AutoDjMode mode) {
    switch (mode) {
      case AutoDjMode.off:
        return 'Off';
      case AutoDjMode.shuffleLibrary:
        return 'Shuffle Library';
      case AutoDjMode.similarSongs:
        return 'Similar Songs';
      case AutoDjMode.sameGenre:
        return 'Same Genre';
      case AutoDjMode.sameArtist:
        return 'Same Artist';
      case AutoDjMode.smartMix:
        return 'Smart Mix';
    }
  }

  /// Get description for mode
  static String getModeDescription(AutoDjMode mode) {
    switch (mode) {
      case AutoDjMode.off:
        return 'Playback stops when queue ends';
      case AutoDjMode.shuffleLibrary:
        return 'Add random songs from your library';
      case AutoDjMode.similarSongs:
        return 'Add songs similar to what\'s playing';
      case AutoDjMode.sameGenre:
        return 'Add songs from the same genre';
      case AutoDjMode.sameArtist:
        return 'Add more songs by the same artist';
      case AutoDjMode.smartMix:
        return 'Intelligent mix based on tempo, genre, and listening habits';
    }
  }

  void setProgressCallback(VoidCallback? callback) {
    _onProgressUpdate = callback;
  }

  Future<void> _loadAnalysisCache() async {
    final keys = _prefs?.getKeys().where((k) => k.startsWith('autodj_')) ?? [];
    for (final key in keys) {
      final songId = key.replaceFirst('autodj_', '');
      final bpm = _prefs?.getInt('${key}_bpm') ?? 100;
      final energy = _prefs?.getDouble('${key}_energy') ?? 0.5;
      final genre = _prefs?.getString('${key}_genre');
      final year = _prefs?.getInt('${key}_year');
      final duration = _prefs?.getInt('${key}_duration') ?? 180;

      _analysisCache[songId] = SongAnalysis(
        songId: songId,
        bpm: bpm,
        genre: genre,
        year: year,
        energy: energy,
        duration: duration,
      );
    }
  }

  Future<void> _saveAnalysis(SongAnalysis analysis) async {
    final key = 'autodj_${analysis.songId}';
    await _prefs?.setInt('${key}_bpm', analysis.bpm);
    await _prefs?.setDouble('${key}_energy', analysis.energy);
    if (analysis.genre != null) {
      await _prefs?.setString('${key}_genre', analysis.genre!);
    }
    if (analysis.year != null) {
      await _prefs?.setInt('${key}_year', analysis.year!);
    }
    await _prefs?.setInt('${key}_duration', analysis.duration);
    await _prefs?.setBool(key, true);
  }

  Future<void> analyzeSongs(
    List<Song> songs,
    String Function(String?) getAudioUrl,
  ) async {
    if (_isAnalyzing) return;
    if (!_isInitialized) await initialize();

    _isAnalyzing = true;
    _analysisProgress = 0.0;
    _analysisStatus = 'Starting analysis...';
    _onProgressUpdate?.call();

    try {
      for (int i = 0; i < songs.length; i++) {
        final song = songs[i];

        if (!_analysisCache.containsKey(song.id)) {
          _analysisStatus = 'Analyzing: ${song.title}';
          _onProgressUpdate?.call();

          final audioUrl = getAudioUrl(song.id);
          final bpm = await _bpmAnalyzer.getBPM(song, audioUrl);

          final energy = _estimateEnergy(song, bpm);

          final analysis = SongAnalysis(
            songId: song.id,
            bpm: bpm,
            genre: song.genre,
            year: song.year,
            energy: energy,
            duration: song.duration ?? 180,
          );

          _analysisCache[song.id] = analysis;
          await _saveAnalysis(analysis);
        }

        _analysisProgress = (i + 1) / songs.length;
        _onProgressUpdate?.call();
      }

      _analysisStatus = 'Analysis complete!';
    } catch (e) {
      _analysisStatus = 'Error: $e';
      debugPrint('AutoDJ analysis error: $e');
    } finally {
      _isAnalyzing = false;
      _onProgressUpdate?.call();
    }
  }

  bool areSongsAnalyzed(List<Song> songs) {
    for (final song in songs) {
      if (!_analysisCache.containsKey(song.id)) {
        return false;
      }
    }
    return true;
  }

  SongAnalysis? getAnalysis(String songId) {
    return _analysisCache[songId];
  }

  double _estimateEnergy(Song song, int bpm) {
    double energy = 0.5;
    final genre = song.genre?.toLowerCase() ?? '';

    if (bpm >= 140) {
      energy = 0.9;
    } else if (bpm >= 120) {
      energy = 0.7;
    } else if (bpm >= 100) {
      energy = 0.5;
    } else if (bpm >= 80) {
      energy = 0.35;
    } else {
      energy = 0.2;
    }

    if (genre.contains('metal') ||
        genre.contains('punk') ||
        genre.contains('hardcore')) {
      energy = min(1.0, energy + 0.2);
    } else if (genre.contains('electronic') ||
        genre.contains('edm') ||
        genre.contains('dance')) {
      energy = min(1.0, energy + 0.15);
    } else if (genre.contains('ballad') ||
        genre.contains('acoustic') ||
        genre.contains('ambient')) {
      energy = max(0.0, energy - 0.2);
    } else if (genre.contains('classical') || genre.contains('jazz')) {
      energy = max(0.0, energy - 0.1);
    }

    return energy.clamp(0.0, 1.0);
  }

  List<Song> generateQueue({
    required Song seedSong,
    required List<Song> availableSongs,
    int queueLength = 20,
    double energyVariation = 0.15,
    int bpmVariation = 15,
  }) {
    if (!_isInitialized || availableSongs.isEmpty) return [];

    final seedAnalysis = _analysisCache[seedSong.id];
    if (seedAnalysis == null) return [];

    final queue = <Song>[seedSong];
    final usedIds = <String>{seedSong.id};

    final candidates = availableSongs
        .where((s) => s.id != seedSong.id)
        .toList();

    for (int i = 0; i < queueLength - 1 && candidates.isNotEmpty; i++) {
      final lastSong = queue.last;
      final lastAnalysis = _analysisCache[lastSong.id];

      if (lastAnalysis == null) break;

      Song? bestMatch;
      double bestScore = -1;

      for (final candidate in candidates) {
        if (usedIds.contains(candidate.id)) continue;

        final candidateAnalysis = _analysisCache[candidate.id];
        if (candidateAnalysis == null) continue;

        final score = _calculateTransitionScore(
          lastAnalysis,
          candidateAnalysis,
          seedAnalysis,
          energyVariation,
          bpmVariation,
        );

        if (score > bestScore) {
          bestScore = score;
          bestMatch = candidate;
        }
      }

      if (bestMatch != null) {
        queue.add(bestMatch);
        usedIds.add(bestMatch.id);
      }
    }

    return queue;
  }

  double _calculateTransitionScore(
    SongAnalysis from,
    SongAnalysis to,
    SongAnalysis seed,
    double energyVariation,
    int bpmVariation,
  ) {
    double score = 0.0;

    final bpmDiff = (from.bpm - to.bpm).abs();
    if (bpmDiff <= bpmVariation) {
      score += 1.0 - (bpmDiff / bpmVariation);
    }

    final energyDiff = (from.energy - to.energy).abs();
    if (energyDiff <= energyVariation) {
      score += 1.0 - (energyDiff / energyVariation);
    }

    final seedBpmDiff = (seed.bpm - to.bpm).abs();
    if (seedBpmDiff <= bpmVariation * 2) {
      score += 0.5 * (1.0 - (seedBpmDiff / (bpmVariation * 2)));
    }

    if (from.genre != null &&
        to.genre != null &&
        from.genre!.toLowerCase() == to.genre!.toLowerCase()) {
      score += 0.5;
    }

    if (from.year != null && to.year != null) {
      final yearDiff = (from.year! - to.year!).abs();
      if (yearDiff <= 5) {
        score += 0.3 * (1.0 - (yearDiff / 5));
      }
    }

    score += Random().nextDouble() * 0.2;

    return score;
  }

  Future<void> clearCache() async {
    final keys = _prefs?.getKeys().where((k) => k.startsWith('autodj_')) ?? [];
    for (final key in keys) {
      await _prefs?.remove(key);
      await _prefs?.remove('${key}_bpm');
      await _prefs?.remove('${key}_energy');
      await _prefs?.remove('${key}_genre');
      await _prefs?.remove('${key}_year');
      await _prefs?.remove('${key}_duration');
    }
    _analysisCache.clear();
  }
}
