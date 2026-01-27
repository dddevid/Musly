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

    test('saveHideSupportDialog saves value', () async {
      await storageService.saveHideSupportDialog(true);
      expect(await storageService.getHideSupportDialog(), true);
    });

    test('getHideSupportDialog returns false by default', () async {
      expect(await storageService.getHideSupportDialog(), false);
    });

    test('saveHideSupportDialog updates value', () async {
      await storageService.saveHideSupportDialog(true);
      expect(await storageService.getHideSupportDialog(), true);
      await storageService.saveHideSupportDialog(false);
      expect(await storageService.getHideSupportDialog(), false);
    });
  });
}
