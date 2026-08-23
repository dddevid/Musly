import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:musly/services/wrapped_service.dart';
import 'package:musly/services/crossfade_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('WrappedService Seasonal Window Tests', () {
    test('Correctly identifies dates outside seasonal window', () {
      // November before last week
      expect(
        WrappedService.isWrappedSeason(customDate: DateTime(2026, 11, 23, 23, 59)),
        isFalse,
      );
      // Summer
      expect(
        WrappedService.isWrappedSeason(customDate: DateTime(2026, 7, 15)),
        isFalse,
      );
      // January after mid-month
      expect(
        WrappedService.isWrappedSeason(customDate: DateTime(2027, 1, 16, 0, 1)),
        isFalse,
      );
      // February
      expect(
        WrappedService.isWrappedSeason(customDate: DateTime(2027, 2, 1)),
        isFalse,
      );
    });

    test('Correctly unlocks during active seasonal window (Late Nov - Mid Jan)', () {
      // November 24 (Start of seasonal window)
      expect(
        WrappedService.isWrappedSeason(customDate: DateTime(2026, 11, 24, 0, 0)),
        isTrue,
      );
      // November 30
      expect(
        WrappedService.isWrappedSeason(customDate: DateTime(2026, 11, 30)),
        isTrue,
      );
      // December middle & end
      expect(
        WrappedService.isWrappedSeason(customDate: DateTime(2026, 12, 15)),
        isTrue,
      );
      expect(
        WrappedService.isWrappedSeason(customDate: DateTime(2026, 12, 31, 23, 59)),
        isTrue,
      );
      // January 1
      expect(
        WrappedService.isWrappedSeason(customDate: DateTime(2027, 1, 1, 10, 0)),
        isTrue,
      );
      // January 15 (Last day of active window)
      expect(
        WrappedService.isWrappedSeason(customDate: DateTime(2027, 1, 15, 23, 59)),
        isTrue,
      );
    });

    test('Dev preview override always returns true', () {
      expect(
        WrappedService.isWrappedSeason(
          devPreview: true,
          customDate: DateTime(2026, 6, 10),
        ),
        isTrue,
      );
    });

    test('Computes correct wrapped year in December vs January', () {
      expect(
        WrappedService.getWrappedYear(DateTime(2026, 12, 5)),
        equals(2026),
      );
      expect(
        WrappedService.getWrappedYear(DateTime(2027, 1, 8)),
        equals(2026),
      );
    });
  });

  group('CrossfadeService Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('Initializes with default 0 (Off)', () async {
      final service = CrossfadeService();
      await service.initialize();
      expect(service.getCrossfadeSeconds(), equals(0));
      expect(service.isEnabled, isFalse);
    });

    test('Sets and persists crossfade seconds with clamping', () async {
      final service = CrossfadeService();
      await service.initialize();

      await service.setCrossfadeSeconds(5);
      expect(service.getCrossfadeSeconds(), equals(5));
      expect(service.isEnabled, isTrue);

      await service.setCrossfadeSeconds(20); // Clamped to 12
      expect(service.getCrossfadeSeconds(), equals(12));

      await service.setCrossfadeSeconds(-3); // Clamped to 0
      expect(service.getCrossfadeSeconds(), equals(0));
      expect(service.isEnabled, isFalse);
    });
  });
}
