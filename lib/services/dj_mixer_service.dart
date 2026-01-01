import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/song.dart';
import 'auto_dj_service.dart';

enum TransitionType {
  crossfade,
  cutTransition,
  echo,
  spinDown,
  beatSync,
}

class DjMixerConfig {

  final double crossfadeDuration;

  final double transitionPoint;

  final bool enableBeatMatching;

  final double maxTempoAdjustment;

  final TransitionType transitionType;

  final bool autoDjEnabled;

  const DjMixerConfig({
    this.crossfadeDuration = 8.0,
    this.transitionPoint = 12.0,
    this.enableBeatMatching = true,
    this.maxTempoAdjustment = 0.08,
    this.transitionType = TransitionType.beatSync,
    this.autoDjEnabled = false,
  });

  DjMixerConfig copyWith({
    double? crossfadeDuration,
    double? transitionPoint,
    bool? enableBeatMatching,
    double? maxTempoAdjustment,
    TransitionType? transitionType,
    bool? autoDjEnabled,
  }) {
    return DjMixerConfig(
      crossfadeDuration: crossfadeDuration ?? this.crossfadeDuration,
      transitionPoint: transitionPoint ?? this.transitionPoint,
      enableBeatMatching: enableBeatMatching ?? this.enableBeatMatching,
      maxTempoAdjustment: maxTempoAdjustment ?? this.maxTempoAdjustment,
      transitionType: transitionType ?? this.transitionType,
      autoDjEnabled: autoDjEnabled ?? this.autoDjEnabled,
    );
  }
}

class DjMixerService {
  static final DjMixerService _instance = DjMixerService._internal();
  factory DjMixerService() => _instance;
  DjMixerService._internal();

  AudioPlayer? _deckA;
  AudioPlayer? _deckB;

  bool _deckAIsLive = true;

  double _deckAVolume = 1.0;
  double _deckBVolume = 0.0;

  DjMixerConfig _config = const DjMixerConfig();

  bool _isInitialized = false;
  bool _isTransitioning = false;
  bool _autoDjActive = false;
  Timer? _transitionTimer;
  Timer? _monitorTimer;

  final AutoDjService _autoDjService = AutoDjService();
  SharedPreferences? _prefs;

  VoidCallback? _onTransitionStart;
  VoidCallback? _onTransitionEnd;
  void Function(Song nextSong)? _onNextSongPrepared;
  void Function(double progress)? _onTransitionProgress;

  Song? _deckASong;
  Song? _deckBSong;

  List<Song> _djQueue = [];
  int _queueIndex = 0;

  bool get isInitialized => _isInitialized;
  bool get isTransitioning => _isTransitioning;
  bool get autoDjActive => _autoDjActive;
  DjMixerConfig get config => _config;
  AudioPlayer? get activeDeck => _deckAIsLive ? _deckA : _deckB;
  AudioPlayer? get cueDeck => _deckAIsLive ? _deckB : _deckA;
  Song? get currentSong => _deckAIsLive ? _deckASong : _deckBSong;
  Song? get nextSong => _deckAIsLive ? _deckBSong : _deckASong;
  List<Song> get djQueue => _djQueue;
  double get crossfaderPosition => _deckAIsLive ? _deckAVolume : _deckBVolume;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _deckA = AudioPlayer();
      _deckB = AudioPlayer();
      _prefs = await SharedPreferences.getInstance();
      await _autoDjService.initialize();

      await _loadConfig();

      _setupDeckListeners();

      _isInitialized = true;
      debugPrint('DJ Mixer initialized with dual decks');
    } catch (e) {
      debugPrint('Error initializing DJ Mixer: $e');
    }
  }

  void _setupDeckListeners() {

    _deckA?.positionStream.listen((position) {
      if (!_autoDjActive || _isTransitioning) return;
      _checkTransitionPoint(_deckA!, _deckASong, true, position);
    });

    _deckB?.positionStream.listen((position) {
      if (!_autoDjActive || _isTransitioning) return;
      _checkTransitionPoint(_deckB!, _deckBSong, false, position);
    });
  }

  void _checkTransitionPoint(
    AudioPlayer deck,
    Song? song,
    bool isDeckA,
    Duration position,
  ) {
    if (song == null) return;
    if (isDeckA != _deckAIsLive) return;

    final duration = deck.duration ?? Duration.zero;
    if (duration == Duration.zero) return;

    final timeRemaining = duration - position;
    final transitionPointDuration = Duration(
      seconds: _config.transitionPoint.toInt(),
    );

    if (timeRemaining <= transitionPointDuration && !_isTransitioning) {
      _startAutoTransition();
    }
  }

  void setCallbacks({
    VoidCallback? onTransitionStart,
    VoidCallback? onTransitionEnd,
    void Function(Song nextSong)? onNextSongPrepared,
    void Function(double progress)? onTransitionProgress,
  }) {
    _onTransitionStart = onTransitionStart;
    _onTransitionEnd = onTransitionEnd;
    _onNextSongPrepared = onNextSongPrepared;
    _onTransitionProgress = onTransitionProgress;
  }

  Future<void> updateConfig(DjMixerConfig config) async {
    _config = config;
    await _saveConfig();
  }

  Future<void> _loadConfig() async {
    _config = DjMixerConfig(
      crossfadeDuration: _prefs?.getDouble('dj_crossfade_duration') ?? 8.0,
      transitionPoint: _prefs?.getDouble('dj_transition_point') ?? 12.0,
      enableBeatMatching: _prefs?.getBool('dj_beat_matching') ?? true,
      maxTempoAdjustment: _prefs?.getDouble('dj_max_tempo_adj') ?? 0.08,
      transitionType:
          TransitionType.values[_prefs?.getInt('dj_transition_type') ?? 3],
      autoDjEnabled: _prefs?.getBool('dj_auto_enabled') ?? false,
    );
  }

  Future<void> _saveConfig() async {
    await _prefs?.setDouble('dj_crossfade_duration', _config.crossfadeDuration);
    await _prefs?.setDouble('dj_transition_point', _config.transitionPoint);
    await _prefs?.setBool('dj_beat_matching', _config.enableBeatMatching);
    await _prefs?.setDouble('dj_max_tempo_adj', _config.maxTempoAdjustment);
    await _prefs?.setInt('dj_transition_type', _config.transitionType.index);
    await _prefs?.setBool('dj_auto_enabled', _config.autoDjEnabled);
  }

  Future<void> startAutoDj({
    required List<Song> songs,
    required String Function(String songId) getStreamUrl,
    int startIndex = 0,
    DjMixerConfig? config,
  }) async {
    if (!_isInitialized) await initialize();
    if (songs.isEmpty) return;

    if (config != null) {
      _config = config;
      await _saveConfig();
    }

    _djQueue = List.from(songs);
    _queueIndex = startIndex;
    _autoDjActive = true;

    final firstSong = _djQueue[_queueIndex];
    await _loadSongOnDeck(
      deck: _deckA!,
      song: firstSong,
      url: getStreamUrl(firstSong.id),
      isDeckA: true,
    );

    if (_queueIndex + 1 < _djQueue.length) {
      final nextSong = _djQueue[_queueIndex + 1];
      await _loadSongOnDeck(
        deck: _deckB!,
        song: nextSong,
        url: getStreamUrl(nextSong.id),
        isDeckA: false,
      );
      _onNextSongPrepared?.call(nextSong);
    }

    _deckAIsLive = true;
    _deckAVolume = 1.0;
    _deckBVolume = 0.0;
    await _deckA?.setVolume(1.0);
    await _deckB?.setVolume(0.0);
    await _deckA?.play();

    debugPrint('AutoDJ started with ${songs.length} songs');
  }

  Future<void> _loadSongOnDeck({
    required AudioPlayer deck,
    required Song song,
    required String url,
    required bool isDeckA,
  }) async {
    try {
      await deck.setUrl(url);

      if (isDeckA) {
        _deckASong = song;
      } else {
        _deckBSong = song;
      }

      if (_config.enableBeatMatching) {
        await _calculateBeatMatchTempo(song, isDeckA);
      }

      debugPrint('Loaded ${song.title} on Deck ${isDeckA ? 'A' : 'B'}');
    } catch (e) {
      debugPrint('Error loading song on deck: $e');
    }
  }

  Future<void> _calculateBeatMatchTempo(Song song, bool isDeckA) async {
    final analysis = _autoDjService.getAnalysis(song.id);
    if (analysis == null) return;

    final otherSong = isDeckA ? _deckBSong : _deckASong;
    if (otherSong == null) return;

    final otherAnalysis = _autoDjService.getAnalysis(otherSong.id);
    if (otherAnalysis == null) return;

    final currentBpm = analysis.bpm.toDouble();
    final targetBpm = otherAnalysis.bpm.toDouble();

    if (currentBpm == 0 || targetBpm == 0) return;

    double tempoRatio = targetBpm / currentBpm;

    tempoRatio = tempoRatio.clamp(
      1.0 - _config.maxTempoAdjustment,
      1.0 + _config.maxTempoAdjustment,
    );

    if (isDeckA) {
      await _deckA?.setSpeed(tempoRatio);
    } else {
      await _deckB?.setSpeed(tempoRatio);
    }

    debugPrint(
      'Beat match: ${song.title} tempo adjusted to ${(tempoRatio * 100).toStringAsFixed(1)}%',
    );
  }

  Future<void> _startAutoTransition() async {
    if (_isTransitioning || !_autoDjActive) return;

    _queueIndex++;
    if (_queueIndex >= _djQueue.length) {

      _autoDjActive = false;
      return;
    }

    await performTransition();
  }

  Future<void> performTransition({
    String Function(String songId)? getStreamUrl,
  }) async {
    if (_isTransitioning) return;

    _isTransitioning = true;
    _onTransitionStart?.call();

    final targetDeck = _deckAIsLive ? _deckB! : _deckA!;
    final sourceDeck = _deckAIsLive ? _deckA! : _deckB!;

    if (targetDeck.duration == null || targetDeck.duration == Duration.zero) {
      debugPrint('Target deck not ready, skipping transition');
      _isTransitioning = false;
      return;
    }

    if (_config.enableBeatMatching) {
      final incomingSong = _deckAIsLive ? _deckBSong : _deckASong;
      if (incomingSong != null) {
        await _calculateBeatMatchTempo(incomingSong, !_deckAIsLive);
      }
    }

    await targetDeck.play();

    switch (_config.transitionType) {
      case TransitionType.crossfade:
        await _performCrossfade(sourceDeck, targetDeck);
        break;
      case TransitionType.cutTransition:
        await _performCutTransition(sourceDeck, targetDeck);
        break;
      case TransitionType.echo:
        await _performEchoTransition(sourceDeck, targetDeck);
        break;
      case TransitionType.spinDown:
        await _performSpinDownTransition(sourceDeck, targetDeck);
        break;
      case TransitionType.beatSync:
        await _performBeatSyncTransition(sourceDeck, targetDeck);
        break;
    }

    _deckAIsLive = !_deckAIsLive;

    await sourceDeck.pause();
    await sourceDeck.seek(Duration.zero);

    await sourceDeck.setSpeed(1.0);

    _isTransitioning = false;
    _onTransitionEnd?.call();

    if (getStreamUrl != null && _queueIndex + 1 < _djQueue.length) {
      final nextSong = _djQueue[_queueIndex + 1];
      await _loadSongOnDeck(
        deck: sourceDeck,
        song: nextSong,
        url: getStreamUrl(nextSong.id),
        isDeckA: _deckAIsLive,
      );
      _onNextSongPrepared?.call(nextSong);
    }

    debugPrint('Transition complete. Now playing: ${currentSong?.title}');
  }

  Future<void> _performCrossfade(AudioPlayer source, AudioPlayer target) async {
    final steps = 50;
    final stepDuration = Duration(
      milliseconds: (_config.crossfadeDuration * 1000 / steps).round(),
    );

    for (int i = 0; i <= steps; i++) {
      final progress = i / steps;

      final fadeProgress = _sCurve(progress);

      final sourceVolume = 1.0 - fadeProgress;
      final targetVolume = fadeProgress;

      await source.setVolume(sourceVolume);
      await target.setVolume(targetVolume);

      _onTransitionProgress?.call(progress);

      await Future.delayed(stepDuration);
    }
  }

  Future<void> _performCutTransition(
    AudioPlayer source,
    AudioPlayer target,
  ) async {

    for (int i = 10; i >= 0; i--) {
      await source.setVolume(i / 10);
      await Future.delayed(const Duration(milliseconds: 30));
    }

    await target.setVolume(1.0);
    _onTransitionProgress?.call(1.0);
  }

  Future<void> _performEchoTransition(
    AudioPlayer source,
    AudioPlayer target,
  ) async {

    final steps = 30;

    for (int i = 0; i <= steps; i++) {
      final progress = i / steps;

      final pulse = sin(progress * pi * 4) * 0.3 + 0.7;
      final sourceVolume = (1.0 - progress) * pulse;
      final targetVolume = progress;

      await source.setVolume(sourceVolume.clamp(0.0, 1.0));
      await target.setVolume(targetVolume);

      _onTransitionProgress?.call(progress);

      await Future.delayed(
        Duration(
          milliseconds: (_config.crossfadeDuration * 1000 / steps).round(),
        ),
      );
    }
  }

  Future<void> _performSpinDownTransition(
    AudioPlayer source,
    AudioPlayer target,
  ) async {

    final steps = 40;

    for (int i = 0; i <= steps; i++) {
      final progress = i / steps;

      final speedFactor = 1.0 - (progress * 0.5);
      await source.setSpeed(speedFactor.clamp(0.5, 1.0));

      final sourceVolume = 1.0 - progress;
      final targetVolume = _sCurve(progress);

      await source.setVolume(sourceVolume);
      await target.setVolume(targetVolume);

      _onTransitionProgress?.call(progress);

      await Future.delayed(
        Duration(
          milliseconds: (_config.crossfadeDuration * 1000 / steps).round(),
        ),
      );
    }

    await source.setSpeed(1.0);
  }

  Future<void> _performBeatSyncTransition(
    AudioPlayer source,
    AudioPlayer target,
  ) async {
    final steps = 60;
    final stepDuration = Duration(
      milliseconds: (_config.crossfadeDuration * 1000 / steps).round(),
    );

    for (int i = 0; i <= steps; i++) {
      final progress = i / steps;

      double sourceVolume;
      double targetVolume;

      if (progress < 0.3) {

        sourceVolume = 1.0;
        targetVolume = progress / 0.3 * 0.4;
      } else if (progress < 0.7) {

        final midProgress = (progress - 0.3) / 0.4;
        sourceVolume = 1.0 - (midProgress * 0.6);
        targetVolume = 0.4 + (midProgress * 0.5);
      } else {

        final endProgress = (progress - 0.7) / 0.3;
        sourceVolume = 0.4 - (endProgress * 0.4);
        targetVolume = 0.9 + (endProgress * 0.1);
      }

      await source.setVolume(sourceVolume.clamp(0.0, 1.0));
      await target.setVolume(targetVolume.clamp(0.0, 1.0));

      _onTransitionProgress?.call(progress);

      await Future.delayed(stepDuration);
    }
  }

  double _sCurve(double t) {
    return t * t * (3 - 2 * t);
  }

  Future<void> stopAutoDj() async {
    _autoDjActive = false;
    _transitionTimer?.cancel();
    _monitorTimer?.cancel();

    await _deckA?.pause();
    await _deckB?.pause();

    debugPrint('AutoDJ stopped');
  }

  AudioPlayer? getActivePlayer() {
    return activeDeck;
  }

  Future<void> togglePlayPause() async {
    final deck = activeDeck;
    if (deck == null) return;

    if (deck.playing) {
      await deck.pause();
    } else {
      await deck.play();
    }
  }

  Future<void> seek(Duration position) async {
    await activeDeck?.seek(position);
  }

  Future<void> dispose() async {
    _transitionTimer?.cancel();
    _monitorTimer?.cancel();
    await _deckA?.dispose();
    await _deckB?.dispose();
    _isInitialized = false;
  }
}