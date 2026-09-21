import 'dart:async';
import 'package:audioplayers/audioplayers.dart' as ap;
import 'package:just_audio_platform_interface/just_audio_platform_interface.dart';

class TizenJustAudioPlatform extends JustAudioPlatform {
  @override
  Future<AudioPlayerPlatform> init(InitRequest request) async {
    return TizenAudioPlayer(request.id);
  }

  @override
  Future<DisposePlayerResponse> disposePlayer(DisposePlayerRequest request) async {
    return DisposePlayerResponse();
  }

  @override
  Future<DisposeAllPlayersResponse> disposeAllPlayers(DisposeAllPlayersRequest request) async {
    return DisposeAllPlayersResponse();
  }
}

class TizenAudioPlayer extends AudioPlayerPlatform {
  final ap.AudioPlayer _player = ap.AudioPlayer();
  final StreamController<PlaybackEventMessage> _eventController = StreamController.broadcast();
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  ProcessingStateMessage _processingState = ProcessingStateMessage.idle;

  DateTime _lastPositionUpdate = DateTime.now();

  TizenAudioPlayer(String id) : super(id) {
    _player.onDurationChanged.listen((d) {
      _duration = d;
      _broadcast();
    });
    _player.onPositionChanged.listen((p) {
      final now = DateTime.now();
      if (now.difference(_lastPositionUpdate) >= const Duration(milliseconds: 250)) {
        _lastPositionUpdate = now;
        _position = p;
        _broadcast();
      }
    });
    _player.onPlayerStateChanged.listen((state) {
      switch (state) {
        case ap.PlayerState.playing:
          _processingState = ProcessingStateMessage.ready;
          break;
        case ap.PlayerState.paused:
          _processingState = ProcessingStateMessage.ready;
          break;
        case ap.PlayerState.stopped:
          _processingState = ProcessingStateMessage.idle;
          break;
        case ap.PlayerState.completed:
          _processingState = ProcessingStateMessage.completed;
          break;
        case ap.PlayerState.disposed:
          break;
      }
      _broadcast();
    });
  }

  void _broadcast() {
    _eventController.add(PlaybackEventMessage(
      processingState: _processingState,
      updatePosition: _position,
      updateTime: DateTime.now(),
      bufferedPosition: _position,
      icyMetadata: null,
      duration: _duration,
      currentIndex: 0,
      androidAudioSessionId: null,
    ));
  }

  @override
  Stream<PlaybackEventMessage> get playbackEventMessageStream => _eventController.stream;

  @override
  Future<LoadResponse> load(LoadRequest request) async {
    _processingState = ProcessingStateMessage.buffering;
    _broadcast();
    
    final source = request.audioSourceMessage;
    if (source is UriAudioSourceMessage) {
      await _player.setSourceUrl(source.uri);
    } else if (source is ConcatenatingAudioSourceMessage) {
       if (source.children.isNotEmpty) {
         final first = source.children.first as UriAudioSourceMessage;
         await _player.setSourceUrl(first.uri);
       }
    }
    
    final d = await _player.getDuration();
    if (d != null) _duration = d;
    _processingState = ProcessingStateMessage.ready;
    _broadcast();
    return LoadResponse(duration: _duration);
  }

  @override
  Future<PlayResponse> play(PlayRequest request) async {
    await _player.resume();
    return PlayResponse();
  }

  @override
  Future<PauseResponse> pause(PauseRequest request) async {
    await _player.pause();
    return PauseResponse();
  }

  @override
  Future<SeekResponse> seek(SeekRequest request) async {
    if (request.position != null) {
      await _player.seek(request.position!);
    }
    return SeekResponse();
  }

  @override
  Future<SetVolumeResponse> setVolume(SetVolumeRequest request) async {
    await _player.setVolume(request.volume);
    return SetVolumeResponse();
  }

  @override
  Future<SetSpeedResponse> setSpeed(SetSpeedRequest request) async {
    await _player.setPlaybackRate(request.speed);
    return SetSpeedResponse();
  }

  @override
  Future<SetLoopModeResponse> setLoopMode(SetLoopModeRequest request) async {
    // Loop mode is handled at the provider level for gapless/Tizen
    return SetLoopModeResponse();
  }

  @override
  Future<SetShuffleModeResponse> setShuffleMode(SetShuffleModeRequest request) async {
    // Shuffle is handled at the provider level
    return SetShuffleModeResponse();
  }
  @override
  Future<SetPitchResponse> setPitch(SetPitchRequest request) async {
    return SetPitchResponse();
  }

  @override
  Future<SetSkipSilenceResponse> setSkipSilence(SetSkipSilenceRequest request) async {
    return SetSkipSilenceResponse();
  }

  @override
  Future<SetShuffleOrderResponse> setShuffleOrder(SetShuffleOrderRequest request) async {
    return SetShuffleOrderResponse();
  }

  @override
  Future<SetAndroidAudioAttributesResponse> setAndroidAudioAttributes(SetAndroidAudioAttributesRequest request) async {
    return SetAndroidAudioAttributesResponse();
  }

  @override
  Future<SetAutomaticallyWaitsToMinimizeStallingResponse> setAutomaticallyWaitsToMinimizeStalling(SetAutomaticallyWaitsToMinimizeStallingRequest request) async {
    return SetAutomaticallyWaitsToMinimizeStallingResponse();
  }

  @override
  Future<DisposeResponse> dispose(DisposeRequest request) async {
    await _player.dispose();
    _eventController.close();
    return DisposeResponse();
  }
}

