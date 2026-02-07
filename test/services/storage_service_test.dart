import 'package:flutter_test/flutter_test.dart';
import 'package:musly/services/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('StorageService', () {
    late StorageService storageService;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      storageService = StorageService();
    });

    test('saveDiscordRpcEnabled saves value', () async {
      await storageService.saveDiscordRpcEnabled(true);
      expect(await storageService.getDiscordRpcEnabled(), true);
    });

    test('getDiscordRpcEnabled returns true by default', () async {
      expect(await storageService.getDiscordRpcEnabled(), true);
    });

    test('saveDiscordRpcEnabled updates value', () async {
      await storageService.saveDiscordRpcEnabled(true);
      expect(await storageService.getDiscordRpcEnabled(), true);
      await storageService.saveDiscordRpcEnabled(false);
      expect(await storageService.getDiscordRpcEnabled(), false);
    });
  });
}
