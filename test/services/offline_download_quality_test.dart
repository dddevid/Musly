import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musly/services/offline_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../bootstrap.dart';

void main() {
  initializeTestEnvironment();

  late Directory appDir;
  setUpAll(() {
    appDir = Directory.systemTemp.createTempSync('musly_quality_test_');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (_) async => appDir.path,
    );
  });

  final offline = OfflineService();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await offline.initialize();
  });

  test('default download bitrate is 0 (original)', () {
    expect(offline.getDownloadBitrate(), 0);
  });

  test('setDownloadBitrate persists configured bitrate', () async {
    await offline.setDownloadBitrate(320);
    expect(offline.getDownloadBitrate(), 320);

    await offline.setDownloadBitrate(192);
    expect(offline.getDownloadBitrate(), 192);

    await offline.setDownloadBitrate(0);
    expect(offline.getDownloadBitrate(), 0);
  });
}
