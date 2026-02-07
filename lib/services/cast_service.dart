import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_chrome_cast/lib.dart';

enum CastState { notConnected, connecting, connected, disconnecting }

class CastMediaState {
  final bool isPlaying;
  final Duration position;
  final Duration duration;
  final String? title;
  final String? artist;
  final String? imageUrl;
  final double volume;

  CastMediaState({
    this.isPlaying = false,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.title,
    this.artist,
    this.imageUrl,
    this.volume = 1.0,
  });

  CastMediaState copyWith({
    bool? isPlaying,
    Duration? position,
    Duration? duration,
    String? title,
    String? artist,
    String? imageUrl,
    double? volume,
  }) {
    return CastMediaState(
      isPlaying: isPlaying ?? this.isPlaying,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      imageUrl: imageUrl ?? this.imageUrl,
      volume: volume ?? this.volume,
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

  CastState get state => _state;
  bool get isConnected => _state == CastState.connected;
  bool get isConnecting => _state == CastState.connecting;
  CastMediaState get mediaState => _mediaState;
  String? get deviceName => _deviceName;

  CastService() {
    _initialize();
  }

  Future<void> _initialize() async {
    // Listen to session changes
    _sessionSubscription = _sessionManager.currentSessionStream.listen((
      session,
    ) {
      _handleSessionChange(session);
    });

    // Listen to media status changes
    _mediaStatusSubscription = _remoteMediaClient.mediaStatusStream.listen((
      status,
    ) {
      _handleMediaStatusChange(status);
    });

    try {
      await GoogleCastContext.instance.setSharedInstanceWithOptions(
        GoogleCastOptions(appId: 'CC1AD845'),
      );
      debugPrint('CastService: Context initialized successfully');

      // Check initial state
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
      position: _mediaState.position, // Keep current position, update via timer
      duration: mediaInfo?.duration ?? Duration.zero,
      title: title,
      artist: artist,
      imageUrl: metadata?.images?.firstOrNull?.url.toString(),
      volume: status.volume.toDouble(),
    );

    debugPrint(
      'CastService: Media state updated - Playing: ${_mediaState.isPlaying}',
    );

    notifyListeners();
  }

  void _startPositionTimer() {
    _stopPositionTimer();
    _positionTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_mediaState.isPlaying && _state == CastState.connected) {
        // Update position locally for smoother UI
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

  // Connect to a Cast device
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

  // Disconnect from Cast device
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

  // Load media
  Future<bool> loadMedia({
    required String url,
    required String title,
    required String artist,
    required String imageUrl,
    Duration? duration,
    bool autoPlay = true,
  }) async {
    if (!isConnected) {
      debugPrint('CastService: Cannot load media - not connected');
      return false;
    }

    try {
      debugPrint('CastService: Loading media: $title by $artist');

      // Use generic metadata for video-style display like Spotify
      // This shows album art on the Cast device screen instead of just playing audio
      final metadata = GoogleCastGenericMediaMetadata(
        title: title,
        subtitle: artist,
        images: [
          GoogleCastImage(url: Uri.parse(imageUrl), width: 1280, height: 720),
        ],
      );

      final mediaInfo = GoogleCastMediaInformation(
        contentId: url,
        streamType: CastMediaStreamType.BUFFERED,
        // Use video/mp4 for visual display like Spotify
        // Cast receiver will show album art as the "video" content
        contentType: 'video/mp4',
        metadata: metadata,
        duration: duration,
      );

      await _remoteMediaClient.loadMedia(mediaInfo, autoPlay: autoPlay);
      debugPrint('CastService: Media loaded successfully');

      return true;
    } catch (e) {
      debugPrint('CastService: Error loading media: $e');
      return false;
    }
  }

  // Playback controls
  Future<void> play() async {
    if (!isConnected) return;

    try {
      await _remoteMediaClient.play();
      debugPrint('CastService: Play command sent');
    } catch (e) {
      debugPrint('CastService: Error playing: $e');
    }
  }

  Future<void> pause() async {
    if (!isConnected) return;

    try {
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
      await _remoteMediaClient.seek(
        GoogleCastMediaSeekOption(position: position),
      );
      debugPrint('CastService: Seek to ${position.inSeconds}s');
    } catch (e) {
      debugPrint('CastService: Error seeking: $e');
    }
  }

  // Volume control - simplified for compatibility
  Future<void> setVolume(double volume) async {
    if (!isConnected) return;
    debugPrint(
      'CastService: Volume control via device (${volume.toStringAsFixed(2)})',
    );
    // Note: Volume control depends on the Cast SDK implementation
    // Some methods may not be available in all versions
  }

  @override
  void dispose() {
    _stopPositionTimer();
    _mediaStatusSubscription?.cancel();
    _sessionSubscription?.cancel();
    super.dispose();
  }
}
