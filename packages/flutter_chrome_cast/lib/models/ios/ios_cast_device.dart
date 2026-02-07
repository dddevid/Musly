import 'package:flutter_chrome_cast/entities/cast_device.dart';

class GoogleCastIosDevice extends GoogleCastDevice {
  GoogleCastIosDevice({
    required super.deviceID,
    required super.friendlyName,
    required super.modelName,
    required super.statusText,
    required super.deviceVersion,
    required super.isOnLocalNetwork,
    required super.category,
    required super.uniqueID,
    required this.index,
  });
  final int? index;

  factory GoogleCastIosDevice.fromMap(Map<String, dynamic> map) {
    return GoogleCastIosDevice(
      deviceID: map['deviceID'] as String,
      friendlyName: map['friendlyName'] ?? '',
      modelName: map['modelName'],
      statusText: map['statusText'],
      deviceVersion: map['deviceVersion'] ?? '',
      isOnLocalNetwork: map['isOnLocalNetwork'] as bool,
      category: map['category'] as String,
      uniqueID: map['uniqueID'] as String,
      index: map['index'],
    );
  }
}
