import 'package:flutter_chrome_cast/lib.dart';

extension GoogleCastAndroidDevices on GoogleCastAndroidDevice {
  static List<GoogleCastAndroidDevice> fromMap(List maps) {
    final devices =
        maps.map((e) => GoogleCastAndroidDevice.fromMap(e)).toList();
    return devices;
  }
}

class GoogleCastAndroidDevice extends GoogleCastDevice {
  GoogleCastAndroidDevice({
    required super.deviceID,
    required super.friendlyName,
    required super.modelName,
    required super.statusText,
    required super.deviceVersion,
    required super.isOnLocalNetwork,
    required super.category,
    required super.uniqueID,
  });

  factory GoogleCastAndroidDevice.fromMap(Map<String, dynamic> map) {
    return GoogleCastAndroidDevice(
      deviceID: map['id'],
      friendlyName: map['name'],
      modelName: map['model_name'],
      deviceVersion: map['device_version'],
      category: '',
      isOnLocalNetwork: map['is_on_local_network'],
      statusText: null,
      uniqueID: map['id'],
    );
  }
}
