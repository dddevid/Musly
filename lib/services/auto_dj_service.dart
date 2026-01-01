import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/song.dart';
import 'bpm_analyzer_service.dart';

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

class AutoDjService {
  static final AutoDjService _instance = AutoDjService._internal();
  factory AutoDjService() => _instance;
  AutoDjService._internal();

  final BpmAnalyzerService _bpmAnalyzer = BpmAnalyzerService();
  SharedPreferences? _prefs;
  bool _isInitialized = false;

  final Map<String, SongAnalysis> _analysisCache = {};

  bool _isAnalyzing = false;
  double _analysisProgress = 0.0;
  String _analysisStatus = '';

  VoidCallback? _onProgressUpdate;

  bool get isAnalyzing => _isAnalyzing;
  double get analysisProgress => _analysisProgress;
  String get analysisStatus => _analysisStatus;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _prefs = await SharedPreferences.getInstance();
      await _bpmAnalyzer.initialize();
      await _loadAnalysisCache();
      _isInitialized = true;
    } catch (e) {
      debugPrint('Error initializing AutoDJ: $e');
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