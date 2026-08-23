import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/song.dart';
import '../models/connect_device.dart';

/// Single NTP measurement result.
class NTPMeasurement {
  final int t0; // Client departure
  final int t1; // Server arrival
  final int t2; // Server departure
  final int t3; // Client arrival
  final double roundTripDelay; // RTT in ms
  final double clockOffset; // Clock offset in ms

  NTPMeasurement({
    required this.t0,
    required this.t1,
    required this.t2,
    required this.t3,
    required this.roundTripDelay,
    required this.clockOffset,
  });

  factory NTPMeasurement.compute({
    required int t0,
    required int t1,
    required int t2,
    required int t3,
  }) {
    final offset = ((t1 - t0) + (t2 - t3)) / 2.0;
    final rtt = (t3 - t0) - (t2 - t1);
    return NTPMeasurement(
      t0: t0,
      t1: t1,
      t2: t2,
      t3: t3,
      roundTripDelay: max(0.0, rtt.toDouble()),
      clockOffset: offset,
    );
  }
}

/// Status of the BeatSync session.
enum BeatSyncRole { none, host, guest }

enum BeatSyncState { disconnected, connecting, calibratingClock, synchronized, inParty }

/// Precision NTP Clock Synchronization & Multi-Device Party Audio Synchronizer [BETA].
class BeatSyncService extends ChangeNotifier {
  static final BeatSyncService _instance = BeatSyncService._internal();
  factory BeatSyncService() => _instance;
  BeatSyncService._internal();

  BeatSyncRole _role = BeatSyncRole.none;
  BeatSyncState _state = BeatSyncState.disconnected;

  // NTP Measurements & Clock Offset
  final List<NTPMeasurement> _measurements = [];
  double _clockOffsetMs = 0.0;
  double _averageRttMs = 0.0;
  double _manualCalibrationNudgeMs = 0.0; // User manual slider ±50ms

  // Party Room info
  String _partyRoomName = 'Musly Party Room';
  final List<String> _connectedGuestNames = [];
  ConnectDevice? _hostDevice;

  // Scheduled Action callbacks
  Function(Song song, int startPositionMs)? onScheduledPlay;
  Function()? onScheduledPause;
  Function(int seekPositionMs)? onScheduledSeek;
  Function(double speed)? onSpeedNudge;

  Timer? _scheduledPlayTimer;
  Timer? _ntpHeartbeatTimer;

  // Getters
  BeatSyncRole get role => _role;
  BeatSyncState get state => _state;
  bool get isHost => _role == BeatSyncRole.host;
  bool get isGuest => _role == BeatSyncRole.guest;
  bool get isInParty => _role != BeatSyncRole.none;
  double get clockOffsetMs => _clockOffsetMs;
  double get averageRttMs => _averageRttMs;
  double get manualCalibrationNudgeMs => _manualCalibrationNudgeMs;
  String get partyRoomName => _partyRoomName;
  List<String> get connectedGuestNames => List.unmodifiable(_connectedGuestNames);
  ConnectDevice? get hostDevice => _hostDevice;

  // ──────────────────────────────────────────────────────────────────────────
  // Host Engine
  // ──────────────────────────────────────────────────────────────────────────

  void startHostingParty({String? roomName}) {
    _role = BeatSyncRole.host;
    _state = BeatSyncState.inParty;
    _partyRoomName = roomName ?? 'Party Room (${_getLocalHostName()})';
    _connectedGuestNames.clear();
    _clockOffsetMs = 0.0;
    _averageRttMs = 0.0;
    notifyListeners();
    debugPrint('[BeatSync] Started hosting room: $_partyRoomName');
  }

  void addGuest(String guestName) {
    if (!_connectedGuestNames.contains(guestName)) {
      _connectedGuestNames.add(guestName);
      notifyListeners();
    }
  }

  void removeGuest(String guestName) {
    _connectedGuestNames.remove(guestName);
    notifyListeners();
  }

  /// Calculates scheduled epoch time for playback sync (1500ms in future).
  int calculateScheduledPlayEpoch({int leadTimeMs = 1500}) {
    return DateTime.now().millisecondsSinceEpoch + leadTimeMs;
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Guest Engine & NTP Clock Synchronization
  // ──────────────────────────────────────────────────────────────────────────

  void joinPartyAsGuest(ConnectDevice host) {
    _role = BeatSyncRole.guest;
    _hostDevice = host;
    _state = BeatSyncState.calibratingClock;
    _measurements.clear();
    _clockOffsetMs = 0.0;
    _averageRttMs = 0.0;
    notifyListeners();
    debugPrint('[BeatSync] Joining party hosted by ${host.name} at ${host.ip}:${host.port}');
  }

  void recordNtpMeasurement(NTPMeasurement m) {
    _measurements.add(m);
    if (_measurements.length > 10) {
      _measurements.removeAt(0);
    }
    _recalculateBestClockOffset();
  }

  void _recalculateBestClockOffset() {
    if (_measurements.isEmpty) return;

    // Filter by lowest RTT (Min-RTT selection RFC 5905)
    double minRtt = double.infinity;
    double bestOffset = 0.0;
    double totalRtt = 0.0;

    for (final m in _measurements) {
      totalRtt += m.roundTripDelay;
      if (m.roundTripDelay < minRtt) {
        minRtt = m.roundTripDelay;
        bestOffset = m.clockOffset;
      }
    }

    _clockOffsetMs = bestOffset;
    _averageRttMs = totalRtt / _measurements.length;
    _state = BeatSyncState.synchronized;
    notifyListeners();

    debugPrint(
      '[BeatSync NTP] Offset: ${_clockOffsetMs.toStringAsFixed(2)}ms | Min RTT: ${minRtt.toStringAsFixed(1)}ms | Avg RTT: ${_averageRttMs.toStringAsFixed(1)}ms',
    );
  }

  /// Schedules audio playback synchronized with the Host at targetEpochMs.
  void schedulePlay({
    required Song song,
    required int targetEpochMs,
    required int startPositionMs,
  }) {
    _scheduledPlayTimer?.cancel();

    final localNow = DateTime.now().millisecondsSinceEpoch;
    final estimatedHostNow = localNow + _clockOffsetMs;
    final waitMs = (targetEpochMs - estimatedHostNow + _manualCalibrationNudgeMs).round();

    debugPrint(
      '[BeatSync] Received schedulePlay for "${song.title}" at $targetEpochMs (waiting ${waitMs}ms)',
    );

    if (waitMs <= 0) {
      // If we received late, play immediately adjusted for elapsed time
      final elapsedSinceTarget = (-waitMs);
      final adjustedPosition = startPositionMs + elapsedSinceTarget;
      onScheduledPlay?.call(song, adjustedPosition);
    } else {
      _scheduledPlayTimer = Timer(Duration(milliseconds: waitMs), () {
        onScheduledPlay?.call(song, startPositionMs);
      });
    }
  }

  /// Sets manual user audio sync calibration nudge (e.g. for Bluetooth latency, ±50ms).
  void setManualCalibrationNudge(double ms) {
    _manualCalibrationNudgeMs = ms.clamp(-50.0, 50.0);
    notifyListeners();
  }

  /// Handles continuous drift check from Host heartbeat.
  void handleHeartbeat({required int hostPositionMs, required int guestPositionMs}) {
    if (!isGuest) return;

    final driftMs = (guestPositionMs - hostPositionMs).abs();
    if (driftMs > 35 && driftMs < 300) {
      // Apply micro speed nudge
      final nudgeSpeed = guestPositionMs > hostPositionMs ? 0.98 : 1.02;
      onSpeedNudge?.call(nudgeSpeed);
      Timer(const Duration(milliseconds: 600), () {
        onSpeedNudge?.call(1.0); // Reset to normal
      });
    } else if (driftMs >= 300) {
      // Hard seek to resynchronize
      onScheduledSeek?.call(hostPositionMs);
    }
  }

  void leaveParty() {
    _scheduledPlayTimer?.cancel();
    _ntpHeartbeatTimer?.cancel();
    _role = BeatSyncRole.none;
    _state = BeatSyncState.disconnected;
    _hostDevice = null;
    _connectedGuestNames.clear();
    _measurements.clear();
    notifyListeners();
    debugPrint('[BeatSync] Left party session');
  }

  String _getLocalHostName() {
    return 'Musly Host';
  }
}
