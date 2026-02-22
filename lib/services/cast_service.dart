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
    String? albumName,
    int? trackNumber,
    Duration? duration,
    bool autoPlay = true,
  }) async {
    if (!isConnected) {
      debugPrint('CastService: Cannot load media - not connected');
      return false;
    }

    try {
      debugPrint('CastService: Loading media: $title by $artist');

      // Use MusicTrackMediaMetadata (type 3) so Cast devices show proper
      // Now Playing card with artist, album, and cover art.
      final metadata = GoogleCastMusicMediaMetadata(
        title: title,
        artist: artist,
        albumArtist: artist,
        albumName: albumName,
        trackNumber: trackNumber,
        images: [
          GoogleCastImage(url: Uri.parse(imageUrl), width: 1280, height: 720),
        ],
      );

      // Detect MIME type from URL for correct Cast receiver handling.
      final contentType = _mimeTypeFromUrl(url);

      final mediaInfo = GoogleCastMediaInformation(
        // contentId is a logical identifier; actual stream URL goes in contentUrl.
        contentId: url,
        contentUrl: Uri.tryParse(url),
        streamType: CastMediaStreamType.buffered,
        contentType: contentType,
        metadata: metadata,
        duration: duration,
      );

      await _remoteMediaClient.loadMedia(
        mediaInfo,
        autoPlay: autoPlay,
        playPosition: Duration.zero,
      );

      // Sync initial media state title immediately so the control dialog
      // shows the song before the first mediaStatus event arrives.
      _mediaState = _mediaState.copyWith(
        title: title,
        artist: artist,
        imageUrl: imageUrl,
        duration: duration ?? Duration.zero,
        isPlaying: autoPlay,
        position: Duration.zero,
      );
      notifyListeners();

      debugPrint('CastService: Media loaded successfully ($contentType)');
      return true;
    } catch (e) {
      debugPrint('CastService: Error loading media: $e');
      return false;
    }
  }

  /// Infer an appropriate MIME type from the stream URL.
  static String _mimeTypeFromUrl(String url) {
    final lower = url.toLowerCase().split('?').first;
    if (lower.endsWith('.flac')) return 'audio/flac';
    if (lower.endsWith('.ogg') || lower.endsWith('.oga')) return 'audio/ogg';
    if (lower.endsWith('.opus')) return 'audio/ogg; codecs=opus';
    if (lower.endsWith('.wav')) return 'audio/wav';
    if (lower.endsWith('.aac')) return 'audio/aac';
    if (lower.endsWith('.m4a')) return 'audio/mp4';
    if (lower.endsWith('.mp3')) return 'audio/mpeg';
    // Subsonic /rest/stream URLs: prefer audio/mpeg as the most universally
    // supported Cast audio type.
    return 'audio/mpeg';
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
