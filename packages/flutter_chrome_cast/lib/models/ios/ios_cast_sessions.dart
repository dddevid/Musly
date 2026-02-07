import 'package:flutter_chrome_cast/entities/cast_session.dart';
import 'package:flutter_chrome_cast/enums/connection_satate.dart';
import 'package:flutter_chrome_cast/models/ios/ios_cast_device.dart';

class IOSGoogleCastSessions extends GoogleCastSession {
  IOSGoogleCastSessions({
    required super.device,
    required super.sessionID,
    required super.connectionState,
    required super.currentDeviceMuted,
    required super.currentDeviceVolume,
    required super.deviceStatusText,
  });

  static IOSGoogleCastSessions? fromMap(Map<String, dynamic>? json) {
    if (json == null) return null;
    return IOSGoogleCastSessions(
      device: GoogleCastIosDevice.fromMap(
          Map<String, dynamic>.from(json['device'])),
      sessionID: json['sessionID'],
      connectionState: GoogleCastConnectState.values[json['connectionState']],
      currentDeviceMuted: json['currentDeviceMuted'],
      currentDeviceVolume: json['currentDeviceVolume'],
      deviceStatusText: json['deviceStatusText'] ?? '',
    );
  }
}
