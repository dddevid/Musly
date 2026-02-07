import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_chrome_cast/lib.dart';

class CastService extends ChangeNotifier {
  final GoogleCastSessionManagerPlatformInterface _sessionManager =
      GoogleCastSessionManager.instance;
  final GoogleCastRemoteMediaClientPlatformInterface _remoteMediaClient =
      GoogleCastRemoteMediaClient.instance;

  bool _isConnected = false;

  bool get isConnected => _isConnected;

  CastService() {
    initContext();
  }

  @visibleForTesting
  Future<void> initContext() async {
    // Register listener immediately
    _sessionManager.currentSessionStream.listen((session) {
      final connected = session != null;
      if (_isConnected != connected) {
        _isConnected = connected;
        debugPrint('CastService: Connection state changed: $_isConnected');
        notifyListeners();
      }
    });

    try {
      await GoogleCastContext.instance.setSharedInstanceWithOptions(
        GoogleCastOptions(appId: 'CC1AD845'),
      );
      debugPrint('CastService: Context initialized');
    } catch (e) {
      debugPrint('CastService: Error initializing context: $e');
    }

    // Also check initial state
    if (_sessionManager.hasConnectedSession) {
      _isConnected = true;
      notifyListeners();
    }
  }

  Future<void> loadMedia({
    required String url,
    required String title,
    required String artist,
    required String imageUrl,
    int? durationMillis,
    bool autoPlay = true,
  }) async {
    if (!_isConnected) return;

    debugPrint('CastService: Loading media: $title, $url');
    try {
      final metadata = GoogleCastMusicMediaMetadata(
        title: title,
        artist: artist,
        albumArtist: artist,
        images: [
          GoogleCastImage(url: Uri.parse(imageUrl), width: 400, height: 400),
        ],
      );

      final mediaInfo = GoogleCastMediaInformation(
        contentId: url,
        streamType: CastMediaStreamType.BUFFERED,
        contentType: 'audio/mpeg',
        metadata: metadata,
        duration: durationMillis != null
            ? Duration(milliseconds: durationMillis)
            : null,
      );

      await _remoteMediaClient.loadMedia(mediaInfo, autoPlay: autoPlay);
    } catch (e) {
      debugPrint('CastService: Error loading media: $e');
    }
  }

  Future<void> play() async {
    if (!_isConnected) return;
    await _remoteMediaClient.play();
  }

  Future<void> pause() async {
    if (!_isConnected) return;
    await _remoteMediaClient.pause();
  }

  Future<void> stop() async {
    if (!_isConnected) return;
    try {
      await _remoteMediaClient.stop();
    } catch (e) {
      debugPrint('CastService: Error stopping: $e');
    }
  }

  Future<void> disconnect() async {
    await _sessionManager.endSession();
  }

  Future<void> seek(Duration position) async {
    if (!_isConnected) return;
    await _remoteMediaClient.seek(
      GoogleCastMediaSeekOption(position: position),
    );
  }

  // Helper for UI to start session if they implement their own picker
  Future<void> startSession(GoogleCastDevice device) async {
    debugPrint(
      'CastService: Starting session with device ${device.friendlyName}',
    );
    final result = await _sessionManager.startSessionWithDevice(device);
    debugPrint('CastService: startSession result: $result');
    if (result) {
      // Wait for stream update?
    }
  }
}
