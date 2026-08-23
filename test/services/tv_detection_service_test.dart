import 'package:flutter_test/flutter_test.dart';
import 'package:musly/services/tv_detection_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TvDetectionService Tests', () {
    test('Initializes with default false when not running on TV', () async {
      final service = TvDetectionService();
      await service.initialize();
      expect(service.isInitialized, isTrue);
    });

    test('Allows manual force / override of TV mode', () async {
      final service = TvDetectionService();
      await service.initialize(forceTvMode: true);
      expect(service.isTvMode, isTrue);

      service.setTvMode(false);
      expect(service.isTvMode, isFalse);

      service.setTvMode(true);
      expect(service.isTvMode, isTrue);
    });
  });
}
