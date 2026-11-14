import 'dart:async';

import 'package:flutter/services.dart';
import 'package:just_audio_platform_interface/just_audio_platform_interface.dart';

/// Stands in for the native just_audio player so tests can watch what the app
/// actually asks it to do. Without it every AudioPlayer call throws a
/// MissingPluginException, which the player code swallows, so a test could not
/// tell "played the restored track" from "played nothing".
///
/// Install with `JustAudioPlatform.instance = FakeJustAudioPlatform()`.
class FakeJustAudioPlatform extends JustAudioPlatform {
  final players = <FakeAudioPlayerPlatform>[];

  /// Makes every player created from now on fail its loads.
  bool failLoads = false;

  /// How many of the next play requests, on any player, fail the way a
  /// native player reports a source it cannot play.
  int failPlays = 0;

  /// Called on every load with the number of loads so far across all
  /// players, before the load completes. Lets a test act mid-load.
  void Function(int loads)? onLoad;

  /// Called on every volume change, before it completes. The app sets the
  /// replay gain volume just before it starts playback.
  void Function()? onSetVolume;

  int _loadCount = 0;

  /// The player most recently created by an [AudioPlayer].
  FakeAudioPlayerPlatform get player => players.last;

  @override
  Future<AudioPlayerPlatform> init(InitRequest request) async {
    final player = FakeAudioPlayerPlatform(request.id, this)
      ..failLoads = failLoads;
    players.add(player);
    return player;
  }

  @override
  Future<DisposePlayerResponse> disposePlayer(
    DisposePlayerRequest request,
  ) async {
    return DisposePlayerResponse();
  }

  @override
  Future<DisposeAllPlayersResponse> disposeAllPlayers(
    DisposeAllPlayersRequest request,
  ) async {
    return DisposeAllPlayersResponse();
  }
}

/// Records loads and play/pause calls, and reports playback state the way the
/// native players do: loading, then ready once a source is loaded.
class FakeAudioPlayerPlatform extends AudioPlayerPlatform {
  FakeAudioPlayerPlatform(super.id, this._owner);

  final FakeJustAudioPlatform _owner;

  final _events = StreamController<PlaybackEventMessage>.broadcast();
  final _data = StreamController<PlayerDataMessage>.broadcast();

  /// Every source the app loaded, in order.
  final loads = <AudioSourceMessage>[];

  /// When set, every load fails the way a native player reports an
  /// unreachable or missing source.
  bool failLoads = false;

  /// Whether a play request is in force (true from play() until pause()).
  bool playing = false;

  /// play() calls that arrived while no source was loaded: the silent
  /// "playing nothing" state a media button could leave the player in.
  int playsWithoutSource = 0;

  ProcessingStateMessage _state = ProcessingStateMessage.idle;
  Duration _position = Duration.zero;
  int? _index;

  @override
  Stream<PlaybackEventMessage> get playbackEventMessageStream => _events.stream;

  @override
  Stream<PlayerDataMessage> get playerDataMessageStream => _data.stream;

  void _emit() {
    _events.add(
      PlaybackEventMessage(
        processingState: _state,
        updateTime: DateTime.now(),
        updatePosition: _position,
        bufferedPosition: _position,
        duration: const Duration(minutes: 2),
        icyMetadata: null,
        currentIndex: _index,
        androidAudioSessionId: null,
      ),
    );
  }

  @override
  Future<LoadResponse> load(LoadRequest request) async {
    loads.add(request.audioSourceMessage);
    _owner.onLoad?.call(++_owner._loadCount);
    if (failLoads) {
      throw PlatformException(code: '0', message: 'Source error');
    }
    _index = request.initialIndex ?? 0;
    _position = request.initialPosition ?? Duration.zero;
    _state = ProcessingStateMessage.loading;
    _emit();
    _state = ProcessingStateMessage.ready;
    _emit();
    return LoadResponse(duration: const Duration(minutes: 2));
  }

  @override
  Future<PlayResponse> play(PlayRequest request) async {
    if (_owner.failPlays > 0) {
      _owner.failPlays--;
      throw PlatformException(code: '0', message: 'Playback error');
    }
    if (loads.isEmpty) playsWithoutSource++;
    playing = true;
    return PlayResponse();
  }

  @override
  Future<PauseResponse> pause(PauseRequest request) async {
    playing = false;
    return PauseResponse();
  }

  @override
  Future<SeekResponse> seek(SeekRequest request) async {
    _position = request.position ?? Duration.zero;
    _index = request.index ?? _index;
    _emit();
    return SeekResponse();
  }

  @override
  Future<SetVolumeResponse> setVolume(SetVolumeRequest request) async {
    _owner.onSetVolume?.call();
    return SetVolumeResponse();
  }

  @override
  Future<SetSpeedResponse> setSpeed(SetSpeedRequest request) async =>
      SetSpeedResponse();

  @override
  Future<SetLoopModeResponse> setLoopMode(SetLoopModeRequest request) async =>
      SetLoopModeResponse();

  @override
  Future<SetShuffleModeResponse> setShuffleMode(
    SetShuffleModeRequest request,
  ) async =>
      SetShuffleModeResponse();

  @override
  Future<SetShuffleOrderResponse> setShuffleOrder(
    SetShuffleOrderRequest request,
  ) async =>
      SetShuffleOrderResponse();

  @override
  Future<SetAndroidAudioAttributesResponse> setAndroidAudioAttributes(
    SetAndroidAudioAttributesRequest request,
  ) async =>
      SetAndroidAudioAttributesResponse();

  @override
  Future<SetAutomaticallyWaitsToMinimizeStallingResponse>
      setAutomaticallyWaitsToMinimizeStalling(
    SetAutomaticallyWaitsToMinimizeStallingRequest request,
  ) async =>
          SetAutomaticallyWaitsToMinimizeStallingResponse();

  @override
  Future<SetCanUseNetworkResourcesForLiveStreamingWhilePausedResponse>
      setCanUseNetworkResourcesForLiveStreamingWhilePaused(
    SetCanUseNetworkResourcesForLiveStreamingWhilePausedRequest request,
  ) async =>
          SetCanUseNetworkResourcesForLiveStreamingWhilePausedResponse();

  @override
  Future<SetPreferredPeakBitRateResponse> setPreferredPeakBitRate(
    SetPreferredPeakBitRateRequest request,
  ) async =>
      SetPreferredPeakBitRateResponse();

  @override
  Future<ConcatenatingInsertAllResponse> concatenatingInsertAll(
    ConcatenatingInsertAllRequest request,
  ) async =>
      ConcatenatingInsertAllResponse();

  @override
  Future<ConcatenatingRemoveRangeResponse> concatenatingRemoveRange(
    ConcatenatingRemoveRangeRequest request,
  ) async =>
      ConcatenatingRemoveRangeResponse();

  @override
  Future<ConcatenatingMoveResponse> concatenatingMove(
    ConcatenatingMoveRequest request,
  ) async =>
      ConcatenatingMoveResponse();

  @override
  Future<DisposeResponse> dispose(DisposeRequest request) async {
    await _events.close();
    await _data.close();
    return DisposeResponse();
  }
}
