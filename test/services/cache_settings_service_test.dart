import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:musly/services/cache_settings_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CacheSettingsService Tests', () {
    late CacheSettingsService service;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      service = CacheSettingsService();
      await service.initialize();
    });

    test('formatBytes should format different sizes accurately', () {
      expect(service.formatBytes(0), '0 B');
      expect(service.formatBytes(512), '512 B');
      expect(service.formatBytes(1024), '1.0 KB');
      expect(service.formatBytes(1536), '1.5 KB');
      expect(service.formatBytes(1024 * 1024), '1.0 MB');
      expect(service.formatBytes(1024 * 1024 * 50), '50 MB');
      expect(service.formatBytes(1024 * 1024 * 1024), '1.0 GB');
    });

    test('Toggling caches modifies preferences correctly', () async {
      await service.setImageCacheEnabled(false);
      expect(service.getImageCacheEnabled(), false);

      await service.setMusicCacheEnabled(false);
      expect(service.getMusicCacheEnabled(), false);

      await service.setBpmCacheEnabled(false);
      expect(service.getBpmCacheEnabled(), false);
      expect(service.areAllCachesDisabled(), true);

      await service.enableAllCaches();
      expect(service.areAllCachesEnabled(), true);
    });
  });
}
