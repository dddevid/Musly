import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:musly/main.dart';
import 'package:musly/providers/auth_provider.dart';
import 'package:musly/services/services.dart';

void main() {
  group('Musly App Integration Tests', () {
    testWidgets('should display login screen when not authenticated', (
      tester,
    ) async {
      final storageService = StorageService();
      final subsonicService = SubsonicService();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<StorageService>.value(value: storageService),
            Provider<SubsonicService>.value(value: subsonicService),
            ChangeNotifierProvider(
              create: (_) => AuthProvider(subsonicService, storageService),
            ),
          ],
          child: const MaterialApp(home: MuslyApp()),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Musly'), findsWidgets);
      expect(find.text('Connect to your Subsonic server'), findsOneWidget);
    });

    testWidgets('should have login form fields', (tester) async {
      final storageService = StorageService();
      final subsonicService = SubsonicService();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<StorageService>.value(value: storageService),
            Provider<SubsonicService>.value(value: subsonicService),
            ChangeNotifierProvider(
              create: (_) => AuthProvider(subsonicService, storageService),
            ),
          ],
          child: const MaterialApp(home: MuslyApp()),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Server URL'), findsOneWidget);
      expect(find.text('Username'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Connect'), findsOneWidget);
    });

    testWidgets('should validate empty form fields', (tester) async {
      final storageService = StorageService();
      final subsonicService = SubsonicService();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<StorageService>.value(value: storageService),
            Provider<SubsonicService>.value(value: subsonicService),
            ChangeNotifierProvider(
              create: (_) => AuthProvider(subsonicService, storageService),
            ),
          ],
          child: const MaterialApp(home: MuslyApp()),
        ),
      );

      await tester.pumpAndSettle();

      final connectButton = find.text('Connect');
      await tester.tap(connectButton);
      await tester.pumpAndSettle();

      expect(find.text('Please enter server URL'), findsOneWidget);
      expect(find.text('Please enter username'), findsOneWidget);
      expect(find.text('Please enter password'), findsOneWidget);
    });
  });
}