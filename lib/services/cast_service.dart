import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_chrome_cast/flutter_chrome_cast.dart';

enum CastState { notConnected, connecting, connected, disconnecting }

class CastMediaState {
  final bool isPlaying;
  final Duration position;
  final Duration duration;
  final String? title;
  final String? artist;
  final String? imageUrl;
  final double volume;
  final CastMediaPlayerState? playerState;
  final GoogleCastMediaIdleReason? idleReason;

  CastMediaState({
    this.isPlaying = false,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.title,
    this.artist,
    this.imageUrl,
    this.volume = 1.0,
    this.playerState,
    this.idleReason,
  });

  CastMediaState copyWith({
    bool? isPlaying,
    Duration? position,
    Duration? duration,
    String? title,
    String? artist,
    String? imageUrl,
    double? volume,
    CastMediaPlayerState? playerState,
    GoogleCastMediaIdleReason? idleReason,
  }) {
    return CastMediaState(
      isPlaying: isPlaying ?? this.isPlaying,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      imageUrl: imageUrl ?? this.imageUrl,
      volume: volume ?? this.volume,
      playerState: playerState ?? this.playerState,
      idleReason: idleReason ?? this.idleReason,
    );
  }
}

class CastService extends ChangeNotifier {
  final GoogleCastSessionManagerPlatformInterface _sessionManager =
      GoogleCastSessionManager.instance;
  final GoogleCastRemoteMediaClientPlatformInterface _remoteMediaClient =
      GoogleCastRemoteMediaClient.instance;

  CastState _state = CastState.notConnected;
  CastMediaState _mediaState = CastMediaState();
  String? _deviceName;
  Timer? _positionTimer;
  StreamSubscription<GoggleCastMediaStatus?>? _mediaStatusSubscription;
  StreamSubscription<GoogleCastSession?>? _sessionSubscription;
  StreamSubscription<Duration>? _playerPositionSubscription;

  CastState get state => _state;
  bool get isConnected => _state == CastState.connected;
  bool get isConnecting => _state == CastState.connecting;
  CastMediaState get mediaState => _mediaState;
  String? get deviceName => _deviceName;

  CastService() {
    _initialize();
  }

  Future<void> _initialize() async {
    if (Platform.isIOS) return;

    _sessionSubscription = _sessionManager.currentSessionStream.listen((
      session,
    ) {
      _handleSessionChange(session);
    });

    _mediaStatusSubscription = _remoteMediaClient.mediaStatusStream.listen((
      status,
    ) {
      _handleMediaStatusChange(status);
    });

    _playerPositionSubscription =
        _remoteMediaClient.playerPositionStream.listen((
      pos,
    ) {
      if (_state == CastState.connected &&
          (_mediaState.position - pos).abs() >
              const Duration(milliseconds: 250)) {
        _mediaState = _mediaState.copyWith(position: pos);
        notifyListeners();
      }
    });

    try {
      const appId = 'CC1AD845';
      GoogleCastOptions? options;
      if (Platform.isIOS) {
        options = IOSGoogleCastOptions(
          GoogleCastDiscoveryCriteriaInitialize.initWithApplicationID(appId),
        );
      } else if (Platform.isAndroid) {
        options = GoogleCastOptionsAndroid(appId: appId);
      }
      if (options != null) {
        await GoogleCastContext.instance.setSharedInstanceWithOptions(options);
      }
      debugPrint('CastService: Context initialized successfully');

      if (_sessionManager.hasConnectedSession) {
        _state = CastState.connected;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('CastService: Error initializing context: $e');
    }
  }

  void _handleSessionChange(GoogleCastSession? session) {
    debugPrint('CastService: Session changed');

    if (session != null && session.device != null) {
      _state = CastState.connected;
      _deviceName = session.device!.friendlyName;
      _startPositionTimer();
      debugPrint('CastService: Connected to ${session.device!.friendlyName}');
    } else {
      _state = CastState.notConnected;
      _deviceName = null;
      _stopPositionTimer();
      _mediaState = CastMediaState();
      debugPrint('CastService: Disconnected');
    }

    notifyListeners();
  }

  void _handleMediaStatusChange(GoggleCastMediaStatus? status) {
    if (status == null) {
      _mediaState = CastMediaState();
      notifyListeners();
      return;
    }

    final mediaInfo = status.mediaInformation;
    final metadata = mediaInfo?.metadata;

    String? title;
    String? artist;
    if (metadata is GoogleCastMusicMediaMetadata) {
      title = metadata.title;
      artist = metadata.artist;
    }

    _mediaState = CastMediaState(
      isPlaying: status.playerState == CastMediaPlayerState.playing,
      position: _mediaState.position,
      duration: mediaInfo?.duration ?? _mediaState.duration,
      title: title ?? _mediaState.title,
      artist: artist ?? _mediaState.artist,
      imageUrl:
          metadata?.images?.firstOrNull?.url.toString() ?? _mediaState.imageUrl,
      volume: status.volume.toDouble(),
      playerState: status.playerState,
      idleReason: status.idleReason,
    );

    debugPrint(
      'CastService: Media state updated - Playing: ${_mediaState.isPlaying}, State: ${status.playerState}, IdleReason: ${status.idleReason}',
    );

    notifyListeners();
  }

  void _startPositionTimer() {
    _stopPositionTimer();
    _positionTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_mediaState.isPlaying && _state == CastState.connected) {
        _mediaState = _mediaState.copyWith(
          position: _mediaState.position + const Duration(seconds: 1),
        );
        notifyListeners();
      }
    });
  }

  void _stopPositionTimer() {
    _positionTimer?.cancel();
    _positionTimer = null;
  }

  Future<bool> connectToDevice(GoogleCastDevice device) async {
    try {
      _state = CastState.connecting;
      notifyListeners();

      debugPrint('CastService: Connecting to ${device.friendlyName}');
      final success = await _sessionManager.startSessionWithDevice(device);

      if (!success) {
        _state = CastState.notConnected;
        notifyListeners();
      }

      return success;
    } catch (e) {
      debugPrint('CastService: Error connecting to device: $e');
      _state = CastState.notConnected;
      notifyListeners();
      return false;
    }
  }

  Future<void> disconnect() async {
    try {
      _state = CastState.disconnecting;
      notifyListeners();

      await _sessionManager.endSession();

      _state = CastState.notConnected;
      _deviceName = null;
      _mediaState = CastMediaState();
      _stopPositionTimer();

      debugPrint('CastService: Disconnected successfully');
    } catch (e) {
      debugPrint('CastService: Error disconnecting: $e');
      _state = CastState.notConnected;
    } finally {
      notifyListeners();
    }
  }

  Future<bool> loadMedia({
    required String url,
    required String title,
    required String artist,
    required String imageUrl,
    String? albumName,
    int? trackNumber,
    Duration? duration,
    Duration playPosition = Duration.zero,
    String? contentType,
    bool autoPlay = true,
  }) async {
    if (!isConnected) {
      debugPrint('CastService: Cannot load media - not connected');
      return false;
    }

    try {
      debugPrint(
          'CastService: Loading media: $title by $artist (playPos: ${playPosition.inSeconds}s)');

      final List<GoogleCastImage> images = [];
      if (imageUrl.isNotEmpty &&
          (imageUrl.startsWith('http://') || imageUrl.startsWith('https://'))) {
        final parsedUri = Uri.tryParse(imageUrl);
        if (parsedUri != null) {
          images.add(GoogleCastImage(url: parsedUri, width: 1280, height: 720));
        }
      }

      final metadata = GoogleCastMusicMediaMetadata(
        title: title,
        artist: artist,
        albumArtist: artist,
        albumName: albumName,
        trackNumber: trackNumber,
        images: images,
      );

      final resolvedContentType = contentType ?? mimeTypeFromUrl(url);

      final mediaInfo = GoogleCastMediaInformation(
        contentId: url,
        contentUrl: Uri.tryParse(url),
        streamType: CastMediaStreamType.buffered,
        contentType: resolvedContentType,
        metadata: metadata,
        duration: duration,
      );

      await _remoteMediaClient.loadMedia(
        mediaInfo,
        autoPlay: autoPlay,
        playPosition: playPosition,
      );

      _mediaState = _mediaState.copyWith(
        title: title,
        artist: artist,
        imageUrl: imageUrl,
        duration: duration ?? Duration.zero,
        isPlaying: autoPlay,
        position: playPosition,
        playerState: autoPlay
            ? CastMediaPlayerState.playing
            : CastMediaPlayerState.paused,
        idleReason: null,
      );
      notifyListeners();

      debugPrint(
          'CastService: Media loaded successfully ($resolvedContentType)');
      return true;
    } catch (e) {
      debugPrint('CastService: Error loading media: $e');
      return false;
    }
  }

  static String mimeTypeFromUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri != null) {
      final formatParam = uri.queryParameters['format']?.toLowerCase() ??
          uri.queryParameters['suffix']?.toLowerCase();
      if (formatParam != null) {
        if (formatParam == 'flac') return 'audio/flac';
        if (formatParam == 'ogg' || formatParam == 'oga') return 'audio/ogg';
        if (formatParam == 'opus') return 'audio/ogg; codecs=opus';
        if (formatParam == 'wav') return 'audio/wav';
        if (formatParam == 'aac') return 'audio/aac';
        if (formatParam == 'm4a' || formatParam == 'mp4') return 'audio/mp4';
        if (formatParam == 'mp3') return 'audio/mpeg';
      }
    }
    final lower = url.toLowerCase().split('?').first;
    if (lower.endsWith('.flac')) return 'audio/flac';
    if (lower.endsWith('.ogg') || lower.endsWith('.oga')) return 'audio/ogg';
    if (lower.endsWith('.opus')) return 'audio/ogg; codecs=opus';
    if (lower.endsWith('.wav')) return 'audio/wav';
    if (lower.endsWith('.aac')) return 'audio/aac';
    if (lower.endsWith('.m4a')) return 'audio/mp4';
    if (lower.endsWith('.mp3')) return 'audio/mpeg';

    return 'audio/mpeg';
  }

  Future<void> play() async {
    if (!isConnected) return;

    try {
      _mediaState = _mediaState.copyWith(
        isPlaying: true,
        playerState: CastMediaPlayerState.playing,
      );
      notifyListeners();
      await _remoteMediaClient.play();
      debugPrint('CastService: Play command sent');
    } catch (e) {
      debugPrint('CastService: Error playing: $e');
    }
  }

  Future<void> pause() async {
    if (!isConnected) return;

    try {
      _mediaState = _mediaState.copyWith(
        isPlaying: false,
        playerState: CastMediaPlayerState.paused,
      );
      notifyListeners();
      await _remoteMediaClient.pause();
      debugPrint('CastService: Pause command sent');
    } catch (e) {
      debugPrint('CastService: Error pausing: $e');
    }
  }

  Future<void> stop() async {
    if (!isConnected) return;

    try {
      await _remoteMediaClient.stop();
      _mediaState = CastMediaState();
      notifyListeners();
      debugPrint('CastService: Stop command sent');
    } catch (e) {
      debugPrint('CastService: Error stopping: $e');
    }
  }

  Future<void> seek(Duration position) async {
    if (!isConnected) return;

    try {
      _mediaState = _mediaState.copyWith(
        position: position,
      );
      notifyListeners();
      await _remoteMediaClient.seek(
        GoogleCastMediaSeekOption(position: position),
      );
      debugPrint('CastService: Seek to ${position.inSeconds}s');
    } catch (e) {
      debugPrint('CastService: Error seeking: $e');
    }
  }

  Future<void> setVolume(double volume) async {
    if (!isConnected) return;
    volume = volume.clamp(0.0, 1.0);
    _sessionManager.setDeviceVolume(volume);
    debugPrint('CastService: Volume set to ${volume.toStringAsFixed(2)}');
  }

  @override
  void dispose() {
    _stopPositionTimer();
    _playerPositionSubscription?.cancel();
    _mediaStatusSubscription?.cancel();
    _sessionSubscription?.cancel();
    super.dispose();
  }
}
