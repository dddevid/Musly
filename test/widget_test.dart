// This is a basic Flutter widget test.

import 'package:flutter_test/flutter_test.dart';

import 'package:musly/main.dart';

void main() {
  testWidgets('App should build', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MuslyApp());

    expect(find.text('Connecting...'), findsOneWidget);
  });
}