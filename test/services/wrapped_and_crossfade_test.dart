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
        WrappedService.isWrappedSeason(
          customDate: DateTime(2026, 11, 23, 23, 59),
          checkPlatform: false,
        ),
        isFalse,
      );
      // Summer
      expect(
        WrappedService.isWrappedSeason(
          customDate: DateTime(2026, 7, 15),
          checkPlatform: false,
        ),
        isFalse,
      );
      // January after mid-month
      expect(
        WrappedService.isWrappedSeason(
          customDate: DateTime(2027, 1, 16, 0, 1),
          checkPlatform: false,
        ),
        isFalse,
      );
      // February
      expect(
        WrappedService.isWrappedSeason(
          customDate: DateTime(2027, 2, 1),
          checkPlatform: false,
        ),
        isFalse,
      );
    });

    test('Correctly unlocks during active seasonal window (Late Nov - Mid Jan)', () {
      // November 24 (Start of seasonal window)
      expect(
        WrappedService.isWrappedSeason(
          customDate: DateTime(2026, 11, 24, 0, 0),
          checkPlatform: false,
        ),
        isTrue,
      );
      // November 30
      expect(
        WrappedService.isWrappedSeason(
          customDate: DateTime(2026, 11, 30),
          checkPlatform: false,
        ),
        isTrue,
      );
      // December middle & end
      expect(
        WrappedService.isWrappedSeason(
          customDate: DateTime(2026, 12, 15),
          checkPlatform: false,
        ),
        isTrue,
      );
      expect(
        WrappedService.isWrappedSeason(
          customDate: DateTime(2026, 12, 31, 23, 59),
          checkPlatform: false,
        ),
        isTrue,
      );
      // January 1
      expect(
        WrappedService.isWrappedSeason(
          customDate: DateTime(2027, 1, 1, 10, 0),
          checkPlatform: false,
        ),
        isTrue,
      );
      // January 15 (Last day of active window)
      expect(
        WrappedService.isWrappedSeason(
          customDate: DateTime(2027, 1, 15, 23, 59),
          checkPlatform: false,
        ),
        isTrue,
      );
    });

    test('Dev preview override always returns true', () {
      expect(
        WrappedService.isWrappedSeason(
          devPreview: true,
          customDate: DateTime(2026, 6, 10),
          checkPlatform: false,
        ),
        isTrue,
      );
    });

    test('Desktop is excluded by default', () {
      if (WrappedService.isDesktop) {
        expect(
          WrappedService.isWrappedSeason(
            customDate: DateTime(2026, 12, 15),
            checkPlatform: true,
          ),
          isFalse,
        );
      }
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

  group('50-Song Milestone Storage Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('Tracks listened songs count and increments correctly', () async {
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('listened_songs_count') ?? 0, equals(0));

      await prefs.setInt('listened_songs_count', 49);
      final next = (prefs.getInt('listened_songs_count') ?? 0) + 1;
      await prefs.setInt('listened_songs_count', next);

      expect(next, equals(50));
      expect(prefs.getBool('milestone_50_songs_shown') ?? false, isFalse);

      await prefs.setBool('milestone_50_songs_shown', true);
      expect(prefs.getBool('milestone_50_songs_shown'), isTrue);
    });
  });

  group('Wrapped Archetype & Model Tests', () {
    test('PersonalityArchetype initializes and provides valid properties', () {
      const archetype = PersonalityArchetype(
        id: 'luminary',
        name: 'The Luminary',
        emoji: '✨',
        badge: 'SONIC EXPLORER',
        title: 'The Luminary',
        description: 'You shine light on diverse genres.',
        traits: ['Eclectic Taste', 'Genre Fluid'],
        gradientColors: [],
      );

      expect(archetype.id, equals('luminary'));
      expect(archetype.name, equals('The Luminary'));
      expect(archetype.emoji, equals('✨'));
      expect(archetype.badge, equals('SONIC EXPLORER'));
      expect(archetype.traits.length, equals(2));
    });
  });
}
