import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/connect_device.dart';
import '../models/song.dart';
import '../services/beatsync_service.dart';

/// Core Service managing zero-config LAN device discovery, remote control, and BeatSync [BETA].
class MuslyConnectService extends ChangeNotifier {
  static final MuslyConnectService _instance = MuslyConnectService._internal();
  factory MuslyConnectService() => _instance;
  MuslyConnectService._internal();

  static const int _beaconPort = 43882;
  static const int _httpWsPort = 43883;

  // Local Device Identity
  late final String _localDeviceId;
  String _localDeviceName = 'Musly Device';
  ConnectMode _localMode = ConnectMode.webStream;
  String _localServerHash = 'web_stream';

  // State
  bool _isInitialized = false;
  final Map<String, ConnectDevice> _peers = {};
  ConnectDevice? _activeRemoteDevice;
  WebSocket? _remoteWsClient;
  final List<WebSocket> _connectedClientSockets = [];

  // Network Sockets & Timers
  RawDatagramSocket? _udpBeaconSocket;
  HttpServer? _httpServer;
  Timer? _beaconBroadcastTimer;
  Timer? _peerCleanupTimer;
  Timer? _statusBroadcastTimer;

  // Remote Control Callbacks
  Function()? onRemotePlay;
  Function()? onRemotePause;
  Function()? onRemoteTogglePlayPause;
  Function()? onRemoteNext;
  Function()? onRemotePrevious;
  Function(int seconds)? onRemoteSeek;
  Function(double volume)? onRemoteVolume;
  Function(List<Song> queue, int startIndex, int positionSeconds)? onRemoteTransferQueue;

  // Getters
  String get localDeviceId => _localDeviceId;
  String get localDeviceName => _localDeviceName;
  List<ConnectDevice> get allDiscoveredPeers => _peers.values.toList();
  ConnectDevice? get activeRemoteDevice => _activeRemoteDevice;
  bool get isControllingRemoteDevice => _activeRemoteDevice != null;

  /// Initialize Musly Connect LAN Discovery and Server.
  Future<void> initialize({
    required String deviceName,
    required ConnectMode mode,
    required String serverHash,
  }) async {
    if (_isInitialized) {
      updateLocalContext(mode: mode, serverHash: serverHash, deviceName: deviceName);
      return;
    }

    _localDeviceId = const Uuid().v4();
    _localDeviceName = deviceName;
    _localMode = mode;
    _localServerHash = serverHash;

    await _startHttpAndWebSocketServer();
    await _startUdpBeaconListener();
    _startBeaconBroadcaster();
    _startPeerCleanupTimer();

    _isInitialized = true;
    notifyListeners();
    debugPrint('[MuslyConnect] Initialized with device: $_localDeviceName ($_localDeviceId)');
  }

  void updateLocalContext({
    ConnectMode? mode,
    String? serverHash,
    String? deviceName,
  }) {
    if (mode != null) _localMode = mode;
    if (serverHash != null) _localServerHash = serverHash;
    if (deviceName != null) _localDeviceName = deviceName;
    notifyListeners();
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Peer Compatibility Filtering
  // ──────────────────────────────────────────────────────────────────────────

  List<ConnectDevice> getCompatibleDevices() {
    return _peers.values.where((p) {
      if (p.id == _localDeviceId) return false;
      return p.isCompatibleWith(myMode: _localMode, myServerHash: _localServerHash);
    }).toList();
  }

  List<ConnectDevice> getAvailablePartyRooms() {
    return _peers.values.where((p) => p.isPartyHost && p.id != _localDeviceId).toList();
  }

  // ──────────────────────────────────────────────────────────────────────────
  // UDP Beacon Discovery
  // ──────────────────────────────────────────────────────────────────────────

  Future<void> _startUdpBeaconListener() async {
    try {
      _udpBeaconSocket = await RawDatagramSocket.bind(
        InternetAddress.anyIPv4,
        _beaconPort,
        reuseAddress: true,
        reusePort: !Platform.isWindows,
      );
      _udpBeaconSocket?.broadcastEnabled = true;

      _udpBeaconSocket?.listen((RawSocketEvent event) {
        if (event == RawSocketEvent.read) {
          final datagram = _udpBeaconSocket?.receive();
          if (datagram != null) {
            _handleIncomingBeacon(datagram);
          }
        }
      });
    } catch (e) {
      debugPrint('[MuslyConnect] UDP bind error (ignored): $e');
    }
  }

  void _startBeaconBroadcaster() {
    _beaconBroadcastTimer?.cancel();
    _beaconBroadcastTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      _broadcastLocalBeacon();
    });
  }

  void _broadcastLocalBeacon() {
    if (_udpBeaconSocket == null) return;

    final beatSync = BeatSyncService();
    final localDevice = ConnectDevice(
      id: _localDeviceId,
      name: _localDeviceName,
      platform: _getPlatformName(),
      ip: '127.0.0.1',
      port: _httpWsPort,
      mode: _localMode,
      serverHash: _localServerHash,
      isPartyHost: beatSync.isHost,
      partyRoomName: beatSync.isHost ? beatSync.partyRoomName : null,
      partyGuestCount: beatSync.connectedGuestNames.length,
    );

    final rawJson = jsonEncode(localDevice.toJson());
    final bytes = utf8.encode(rawJson);

    try {
      _udpBeaconSocket?.send(
        bytes,
        InternetAddress('255.255.255.255'),
        _beaconPort,
      );
    } catch (e) {
      // Ignored broadcast send error
    }
  }

  void _handleIncomingBeacon(Datagram datagram) {
    try {
      final raw = utf8.decode(datagram.data);
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final senderId = json['id'] as String?;

      if (senderId != null && senderId != _localDeviceId) {
        final peer = ConnectDevice.fromJson(json, overrideIp: datagram.address.address);
        _peers[peer.id] = peer;
        notifyListeners();
      }
    } catch (_) {
      // Ignore malformed beacons
    }
  }

  void _startPeerCleanupTimer() {
    _peerCleanupTimer?.cancel();
    _peerCleanupTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      final now = DateTime.now();
      final expiredIds = <String>[];

      for (final entry in _peers.entries) {
        if (now.difference(entry.value.lastSeen).inSeconds > 9) {
          expiredIds.add(entry.key);
        }
      }

      if (expiredIds.isNotEmpty) {
        for (final id in expiredIds) {
          _peers.remove(id);
        }
        notifyListeners();
      }
    });
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Embedded HTTP / WebSocket Server
  // ──────────────────────────────────────────────────────────────────────────

  Future<void> _startHttpAndWebSocketServer() async {
    try {
      _httpServer = await HttpServer.bind(InternetAddress.anyIPv4, _httpWsPort);
      _httpServer?.listen(_handleHttpRequest);
      debugPrint('[MuslyConnect] Server listening on port $_httpWsPort');
    } catch (e) {
      debugPrint('[MuslyConnect] Server bind error: $e');
    }
  }

  void _handleHttpRequest(HttpRequest request) async {
    if (request.uri.path == '/ws') {
      if (WebSocketTransformer.isUpgradeRequest(request)) {
        final socket = await WebSocketTransformer.upgrade(request);
        _handleNewWebSocketClient(socket);
      } else {
        request.response.statusCode = HttpStatus.badRequest;
        request.response.close();
      }
    } else if (request.uri.path == '/status') {
      request.response
        ..headers.contentType = ContentType.json
        ..write(jsonEncode({'status': 'ok', 'device': _localDeviceName, 'id': _localDeviceId}))
        ..close();
    } else if (request.uri.path == '/transfer' && request.method == 'POST') {
      try {
        final body = await utf8.decodeStream(request);
        final json = jsonDecode(body) as Map<String, dynamic>;
        final message = ConnectMessage.fromJson(json);
        _dispatchIncomingMessage(message, null);
        request.response
          ..headers.contentType = ContentType.json
          ..write(jsonEncode({'success': true}))
          ..close();
      } catch (e) {
        debugPrint('[MuslyConnect] /transfer error: $e');
        request.response
          ..statusCode = HttpStatus.badRequest
          ..write(jsonEncode({'error': e.toString()}))
          ..close();
      }
    } else {
      request.response
        ..statusCode = HttpStatus.notFound
        ..close();
    }
  }

  void _handleNewWebSocketClient(WebSocket socket) {
    _connectedClientSockets.add(socket);

    socket.listen(
      (data) {
        if (data is String) {
          final message = ConnectMessage.deserialize(data);
          if (message != null) {
            _dispatchIncomingMessage(message, socket);
          }
        }
      },
      onDone: () => _connectedClientSockets.remove(socket),
      onError: (_) => _connectedClientSockets.remove(socket),
    );
  }

  void _dispatchIncomingMessage(ConnectMessage message, WebSocket? socket) {
    final beatSync = BeatSyncService();

    switch (message.type) {
      case ConnectCommandType.play:
        onRemotePlay?.call();
        break;
      case ConnectCommandType.pause:
        onRemotePause?.call();
        break;
      case ConnectCommandType.togglePlayPause:
        onRemoteTogglePlayPause?.call();
        break;
      case ConnectCommandType.next:
        onRemoteNext?.call();
        break;
      case ConnectCommandType.previous:
        onRemotePrevious?.call();
        break;
      case ConnectCommandType.seek:
        final seconds = message.payload['seconds'] as int? ?? 0;
        onRemoteSeek?.call(seconds);
        break;
      case ConnectCommandType.setVolume:
        final vol = (message.payload['volume'] as num?)?.toDouble() ?? 1.0;
        onRemoteVolume?.call(vol);
        break;
      case ConnectCommandType.transferQueue:
        final rawSongs = (message.payload['queue'] as List<dynamic>?) ?? [];
        final songs = rawSongs.map((s) => Song.fromJson(s as Map<String, dynamic>)).toList();
        final index = message.payload['startIndex'] as int? ?? 0;
        final posSec = message.payload['positionSeconds'] as int? ?? 0;
        debugPrint('[MuslyConnect] ⇋ Incoming playback transfer: ${songs.length} tracks, index=$index, pos=${posSec}s');
        onRemoteTransferQueue?.call(songs, index, posSec);
        break;

      // ── BeatSync [BETA] NTP Protocol ──────────────────────────────────────
      case ConnectCommandType.ntpProbe:
        final t0 = message.payload['t0'] as int;
        final t1 = DateTime.now().millisecondsSinceEpoch;
        final t2 = DateTime.now().millisecondsSinceEpoch;
        final response = ConnectMessage(
          type: ConnectCommandType.ntpResponse,
          payload: {'t0': t0, 't1': t1, 't2': t2},
          senderId: _localDeviceId,
        );
        socket?.add(response.serialize());
        break;

      case ConnectCommandType.ntpResponse:
        final t3 = DateTime.now().millisecondsSinceEpoch;
        final t0 = message.payload['t0'] as int;
        final t1 = message.payload['t1'] as int;
        final t2 = message.payload['t2'] as int;
        final measurement = NTPMeasurement.compute(t0: t0, t1: t1, t2: t2, t3: t3);
        beatSync.recordNtpMeasurement(measurement);
        break;

      case ConnectCommandType.beatSyncSchedulePlay:
        final songJson = message.payload['song'] as Map<String, dynamic>;
        final song = Song.fromJson(songJson);
        final targetEpochMs = message.payload['targetEpochMs'] as int;
        final startPosMs = message.payload['startPositionMs'] as int? ?? 0;
        beatSync.schedulePlay(
          song: song,
          targetEpochMs: targetEpochMs,
          startPositionMs: startPosMs,
        );
        break;

      case ConnectCommandType.beatSyncSchedulePause:
        beatSync.onScheduledPause?.call();
        break;

      case ConnectCommandType.joinParty:
        final guestName = message.payload['guestName'] as String? ?? 'Guest';
        beatSync.addGuest(guestName);
        break;

      case ConnectCommandType.leaveParty:
        final guestName = message.payload['guestName'] as String? ?? 'Guest';
        beatSync.removeGuest(guestName);
        break;

      default:
        break;
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Remote Controller Client
  // ──────────────────────────────────────────────────────────────────────────

  Future<bool> connectToRemoteDevice(ConnectDevice device) async {
    disconnectRemote();

    try {
      final wsUri = 'ws://${device.ip}:${device.port}/ws';
      _remoteWsClient = await WebSocket.connect(wsUri).timeout(const Duration(seconds: 4));
      _activeRemoteDevice = device;

      _remoteWsClient?.listen(
        (data) {
          if (data is String) {
            final message = ConnectMessage.deserialize(data);
            if (message != null) {
              _dispatchIncomingMessage(message, _remoteWsClient!);
            }
          }
        },
        onDone: () => disconnectRemote(),
        onError: (_) => disconnectRemote(),
      );

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('[MuslyConnect] Failed to connect to ${device.name}: $e');
      disconnectRemote();
      return false;
    }
  }

  void disconnectRemote() {
    _remoteWsClient?.close();
    _remoteWsClient = null;
    _activeRemoteDevice = null;
    notifyListeners();
  }

  void sendCommand(ConnectCommandType type, [Map<String, dynamic>? payload]) {
    if (_remoteWsClient == null || _remoteWsClient!.readyState != WebSocket.open) return;

    final message = ConnectMessage(
      type: type,
      payload: payload ?? {},
      senderId: _localDeviceId,
    );

    _remoteWsClient?.add(message.serialize());
  }

  /// Sends a playback transfer payload to migrate active playback seamlessly.
  Future<bool> transferPlaybackToRemote(
    List<Song> queue,
    int startIndex,
    int positionSeconds, {
    ConnectDevice? targetDevice,
  }) async {
    final payload = {
      'queue': queue.map((s) => s.toJson()).toList(),
      'startIndex': startIndex,
      'positionSeconds': positionSeconds,
    };

    bool delivered = false;

    // 1. WebSocket Delivery
    if (_remoteWsClient != null && _remoteWsClient!.readyState == WebSocket.open) {
      sendCommand(ConnectCommandType.transferQueue, payload);
      delivered = true;
    }

    // 2. HTTP POST Fallback Delivery
    final target = targetDevice ?? _activeRemoteDevice;
    if (target != null) {
      try {
        final client = HttpClient();
        client.connectionTimeout = const Duration(seconds: 3);
        final uri = Uri.parse('http://${target.ip}:${target.port}/transfer');
        final request = await client.postUrl(uri);
        request.headers.contentType = ContentType.json;
        final message = ConnectMessage(
          type: ConnectCommandType.transferQueue,
          payload: payload,
          senderId: _localDeviceId,
        );
        request.write(message.serialize());
        final response = await request.close();
        if (response.statusCode == HttpStatus.ok) {
          delivered = true;
        }
      } catch (e) {
        debugPrint('[MuslyConnect] HTTP transfer error: $e');
      }
    }

    return delivered;
  }

  // ──────────────────────────────────────────────────────────────────────────
  // BeatSync Broadcast Helper (Host -> All Guests)
  // ──────────────────────────────────────────────────────────────────────────

  void broadcastBeatSyncSchedulePlay(Song song, int targetEpochMs, int startPositionMs) {
    final message = ConnectMessage(
      type: ConnectCommandType.beatSyncSchedulePlay,
      payload: {
        'song': song.toJson(),
        'targetEpochMs': targetEpochMs,
        'startPositionMs': startPositionMs,
      },
      senderId: _localDeviceId,
    );

    final raw = message.serialize();
    for (final socket in _connectedClientSockets) {
      if (socket.readyState == WebSocket.open) {
        socket.add(raw);
      }
    }
  }

  void broadcastBeatSyncSchedulePause() {
    final message = ConnectMessage(
      type: ConnectCommandType.beatSyncSchedulePause,
      payload: {},
      senderId: _localDeviceId,
    );
    final raw = message.serialize();
    for (final socket in _connectedClientSockets) {
      if (socket.readyState == WebSocket.open) {
        socket.add(raw);
      }
    }
  }

  /// Sends NTP probe to Host WebSocket.
  void sendNtpProbeToHost() {
    if (_remoteWsClient == null || _remoteWsClient!.readyState != WebSocket.open) return;

    final message = ConnectMessage(
      type: ConnectCommandType.ntpProbe,
      payload: {'t0': DateTime.now().millisecondsSinceEpoch},
      senderId: _localDeviceId,
    );

    _remoteWsClient?.add(message.serialize());
  }

  String _getPlatformName() {
    if (Platform.isAndroid) return 'android';
    if (Platform.isIOS) return 'ios';
    if (Platform.isWindows) return 'windows';
    if (Platform.isMacOS) return 'macos';
    if (Platform.isLinux) return 'linux';
    return 'mobile';
  }

  @override
  void dispose() {
    _beaconBroadcastTimer?.cancel();
    _peerCleanupTimer?.cancel();
    _statusBroadcastTimer?.cancel();
    _udpBeaconSocket?.close();
    _httpServer?.close();
    _remoteWsClient?.close();
    for (final s in _connectedClientSockets) {
      s.close();
    }
    super.dispose();
  }
}
