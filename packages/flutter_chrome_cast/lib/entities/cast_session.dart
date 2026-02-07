import 'package:flutter_chrome_cast/entities/cast_device.dart';
import 'package:flutter_chrome_cast/enums/connection_satate.dart';

abstract class GoogleCastSession {
  final GoogleCastDevice? device;
  final String? sessionID;
  final GoogleCastConnectState connectionState;
  final bool currentDeviceMuted;
  final double currentDeviceVolume;
  final String deviceStatusText;

  GoogleCastSession({
    required this.device,
    required this.sessionID,
    required this.connectionState,
    required this.currentDeviceMuted,
    required this.currentDeviceVolume,
    required this.deviceStatusText,
  });
}
