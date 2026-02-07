import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_chrome_cast/_discovery_manager/discovery_manager_platform_interface.dart';
import 'package:flutter_chrome_cast/entities/cast_device.dart';
import 'package:flutter_chrome_cast/models/android/cast_device.dart';
import 'package:rxdart/subjects.dart';

class GoogleCastDiscoveryManagerMethodChannelAndroid
    implements GoogleCastDiscoveryManagerPlatformInterface {
  GoogleCastDiscoveryManagerMethodChannelAndroid() {
    _channel.setMethodCallHandler(_onMethodCallHandler);
  }

  final _channel =
      const MethodChannel('com.felnanuke.google_cast.discovery_manager');

  final _devicesStreamController = BehaviorSubject<List<GoogleCastDevice>>()
    ..add([]);

  @override
  List<GoogleCastDevice> get devices => _devicesStreamController.value;

  @override
  Stream<List<GoogleCastDevice>> get devicesStream =>
      _devicesStreamController.stream;

  @override
  Future<bool> isDiscoveryActiveForDeviceCategory(String deviceCategory) {
    throw UnimplementedError('IOS Only');
  }

  @override
  Future<void> startDiscovery() async {
    _channel.invokeMethod('startDiscovery');
    return;
  }

  @override
  Future<void> stopDiscovery() async {
    _channel.invokeMethod('stopDiscovery');
    return;
  }

  Future _onMethodCallHandler(MethodCall call) async {
    switch (call.method) {
      case 'onDevicesChanged':
        return _onDevicesChanged(call.arguments);

      default:
    }
  }

  _onDevicesChanged(arguments) {
    try {
      arguments as String;
      final list = jsonDecode(arguments);
      final listMap = List.from(list);
      final devices =
          GoogleCastAndroidDevices.fromMap(listMap).toSet().toList();
      _devicesStreamController.add(devices);
    } catch (e) {
      rethrow;
    }
  }
}
