// ── BeatSync Precision NTP & Connect Tests ───────────────────────────────────
// Inspired by: https://github.com/freeman-jiang/beatsync
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter_test/flutter_test.dart';
import 'package:musly/models/connect_device.dart';
import 'package:musly/services/beatsync_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('NTP Measurement & Precision Math Tests', () {
    test('Correctly computes clock offset and round trip delay (RTT)', () {
      // t0 = 1000, t1 = 1050, t2 = 1060, t3 = 1110
      // offset = ((1050 - 1000) + (1060 - 1110)) / 2 = (50 - 50) / 2 = 0 ms
      // RTT = (1110 - 1000) - (1060 - 1050) = 110 - 10 = 100 ms
      final m = NTPMeasurement.compute(t0: 1000, t1: 1050, t2: 1060, t3: 1110);
      expect(m.clockOffset, equals(0.0));
      expect(m.roundTripDelay, equals(100.0));
    });

    test('Correctly computes positive clock offset when server is ahead', () {
      // Guest clock = 1000, Host clock = 1200 (Host is 200ms ahead)
      // t0 = 1000, t1 = 1220, t2 = 1225, t3 = 1045
      // offset = ((1220 - 1000) + (1225 - 1045)) / 2 = (220 + 180) / 2 = +200 ms
      // RTT = (1045 - 1000) - (1225 - 1220) = 45 - 5 = 40 ms
      final m = NTPMeasurement.compute(t0: 1000, t1: 1220, t2: 1225, t3: 1045);
      expect(m.clockOffset, equals(200.0));
      expect(m.roundTripDelay, equals(40.0));
    });
  });

  group('BeatSyncService State & Calibration Tests', () {
    late BeatSyncService service;

    setUp(() {
      service = BeatSyncService();
      service.leaveParty();
    });

    test('Starts hosting party correctly', () {
      service.startHostingParty(roomName: 'Living Room Party');
      expect(service.isHost, isTrue);
      expect(service.isGuest, isFalse);
      expect(service.isInParty, isTrue);
      expect(service.partyRoomName, equals('Living Room Party'));
      expect(service.connectedGuestNames, isEmpty);

      service.addGuest('Phone A');
      service.addGuest('Phone B');
      expect(service.connectedGuestNames.length, equals(2));

      service.removeGuest('Phone A');
      expect(service.connectedGuestNames, equals(['Phone B']));
    });

    test('Recalculates best clock offset using Min-RTT filter (RFC 5905)', () {
      final host = ConnectDevice(
        id: 'host-1',
        name: 'Host DJ',
        platform: 'windows',
        ip: '192.168.1.50',
        port: 43883,
        mode: ConnectMode.subsonic,
        serverHash: 'subsonic_hash_abc',
      );

      service.joinPartyAsGuest(host);
      expect(service.isGuest, isTrue);
      expect(service.state, equals(BeatSyncState.calibratingClock));

      // Sample 1: Jittery high RTT
      service.recordNtpMeasurement(NTPMeasurement(
        t0: 1000,
        t1: 1060,
        t2: 1070,
        t3: 1200,
        roundTripDelay: 130.0,
        clockOffset: -35.0,
      ));

      // Sample 2: Clean low RTT sample
      service.recordNtpMeasurement(NTPMeasurement(
        t0: 2000,
        t1: 2025,
        t2: 2030,
        t3: 2055,
        roundTripDelay: 20.0,
        clockOffset: 0.0,
      ));

      // Best offset should come from the lowest RTT sample (Sample 2: offset = 0.0)
      expect(service.clockOffsetMs, equals(0.0));
      expect(service.state, equals(BeatSyncState.synchronized));
    });

    test('Clamps manual calibration nudge to ±50ms', () {
      service.setManualCalibrationNudge(25.0);
      expect(service.manualCalibrationNudgeMs, equals(25.0));

      service.setManualCalibrationNudge(120.0);
      expect(service.manualCalibrationNudgeMs, equals(50.0));

      service.setManualCalibrationNudge(-80.0);
      expect(service.manualCalibrationNudgeMs, equals(-50.0));
    });
  });

  group('ConnectDevice Compatibility & Serialization Tests', () {
    test('Matches compatible devices on same mode and server hash', () {
      final deviceA = ConnectDevice(
        id: 'dev-1',
        name: 'Phone',
        platform: 'android',
        ip: '192.168.1.10',
        port: 43883,
        mode: ConnectMode.subsonic,
        serverHash: 'http://nas.local:4533',
      );

      // Same mode, same server -> Compatible
      expect(
        deviceA.isCompatibleWith(
          myMode: ConnectMode.subsonic,
          myServerHash: 'http://nas.local:4533',
        ),
        isTrue,
      );

      // Different server -> Incompatible
      expect(
        deviceA.isCompatibleWith(
          myMode: ConnectMode.subsonic,
          myServerHash: 'http://remote.server.com',
        ),
        isFalse,
      );

      // Different mode -> Incompatible
      expect(
        deviceA.isCompatibleWith(
          myMode: ConnectMode.webStream,
          myServerHash: 'http://nas.local:4533',
        ),
        isFalse,
      );
    });

    test('Serializes and deserializes ConnectMessage correctly', () {
      final msg = ConnectMessage(
        type: ConnectCommandType.beatSyncSchedulePlay,
        payload: {
          'targetEpochMs': 1700000000000,
          'startPositionMs': 4500,
        },
        senderId: 'client-123',
      );

      final raw = msg.serialize();
      final decoded = ConnectMessage.deserialize(raw);

      expect(decoded, isNotNull);
      expect(decoded!.type, equals(ConnectCommandType.beatSyncSchedulePlay));
      expect(decoded.senderId, equals('client-123'));
      expect(decoded.payload['targetEpochMs'], equals(1700000000000));
      expect(decoded.payload['startPositionMs'], equals(4500));
    });
  });
}
