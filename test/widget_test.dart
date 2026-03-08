
import 'package:flutter_test/flutter_test.dart';

import 'package:musly/main.dart';

void main() {
  testWidgets('App should build', (WidgetTester tester) async {
    
    await tester.pumpWidget(const MuslyApp());

    expect(find.text('Connecting...'), findsOneWidget);
  });
}