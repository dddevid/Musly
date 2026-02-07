import 'package:flutter/services.dart';
import 'package:flutter_chrome_cast/entities/cast_device.dart';
import 'package:flutter_chrome_cast/models/ios/ios_cast_device.dart';
import 'package:rxdart/subjects.dart';
import 'discovery_manager_platform_interface.dart';

class GoogleCastDiscoveryManagerMethodChannelIOS
    implements GoogleCastDiscoveryManagerPlatformInterface {
  GoogleCastDiscoveryManagerMethodChannelIOS() {
    _channel.setMethodCallHandler(_handleMethodCall);
  }

  final _channel = const MethodChannel('google_cast.discovery_manager');

  final _devicesStreamController = BehaviorSubject<List<GoogleCastDevice>>()
    ..add([]);

  @override
  List<GoogleCastDevice> get devices => _devicesStreamController.value;

  @override
  Stream<List<GoogleCastDevice>> get devicesStream =>
      _devicesStreamController.stream;

  @override
  Future<bool> isDiscoveryActiveForDeviceCategory(String deviceCategory) async {
    return await _channel.invokeMethod('isDiscoveryActiveForDeviceCategory', {
      'deviceCategory': deviceCategory,
    });
  }

  @override
  Future<void> startDiscovery() {
    return _channel.invokeMethod('startDiscovery');
  }

  @override
  Future<void> stopDiscovery() {
    return _channel.invokeMethod('stopDiscovery');
  }

  void _onDevicesChanged(List arguments) {
    final devices = List.from(arguments)
        .map((device) => GoogleCastIosDevice.fromMap(Map.from(device)))
        .toList();

    _devicesStreamController.add(devices);
  }

  Future _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'onDevicesChanged':
        _onDevicesChanged(call.arguments);
        break;
      default:
        // ignore: avoid_print
        print('No Handler for method ${call.method}');
    }
  }
}
