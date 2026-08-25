import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:musly/main.dart';
import 'package:musly/providers/auth_provider.dart';
import 'package:musly/services/locale_service.dart';
import 'package:musly/services/theme_service.dart';
import 'package:musly/services/subsonic_service.dart';
import 'package:musly/services/storage_service.dart';
import 'package:musly/services/tv_detection_service.dart';
import 'bootstrap.dart';

void main() {
  initializeTestEnvironment();

  testWidgets('App should build', (WidgetTester tester) async {
    final subsonic = SubsonicService();
    final storage = StorageService();
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<LocaleService>(create: (_) => LocaleService()),
          ChangeNotifierProvider<ThemeService>(create: (_) => ThemeService()),
          ChangeNotifierProvider<TvDetectionService>.value(
            value: TvDetectionService(),
          ),
          ChangeNotifierProvider<AuthProvider>(
            create: (_) => AuthProvider(subsonic, storage),
          ),
        ],
        child: const MuslyApp(),
      ),
    );
    expect(find.byType(MuslyApp), findsOneWidget);
  });
}
