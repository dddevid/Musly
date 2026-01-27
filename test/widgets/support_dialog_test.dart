import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musly/widgets/support_dialog.dart';
import 'package:musly/services/storage_service.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('SupportDialog', () {
    late StorageService storageService;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      storageService = StorageService();
    });

    testWidgets('shows checkbox and close button', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Provider<StorageService>.value(
            value: storageService,
            child: const SupportDialog(),
          ),
        ),
      );

      // Verify close button is present
      expect(find.byIcon(Icons.close), findsOneWidget);

      // Verify checkbox is present
      final checkboxFinder = find.byType(Checkbox);
      await tester.ensureVisible(checkboxFinder);
      expect(find.text("Don't show again"), findsOneWidget);
      expect(checkboxFinder, findsOneWidget);
    });

    testWidgets('toggling checkbox saves preference', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Provider<StorageService>.value(
            value: storageService,
            child: const SupportDialog(),
          ),
        ),
      );

      final checkboxFinder = find.byType(Checkbox);

      // Ensure the checkbox is visible by scrolling if necessary
      await tester.ensureVisible(checkboxFinder);
      await tester.pumpAndSettle();

      // Check the checkbox
      await tester.tap(checkboxFinder);
      await tester.pump();

      // Verify it was saved
      expect(await storageService.getHideSupportDialog(), true);
    });
  });
}
