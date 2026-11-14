import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musly/screens/main/main_screen.dart';

void main() {
  testWidgets('PlayPauseAction is disabled when TextField is focused (#280)',
      (tester) async {
    final focusNode = FocusNode();
    final textController = TextEditingController();

    late BuildContext capturedContext;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            capturedContext = context;
            return Scaffold(
              body: TextField(
                focusNode: focusNode,
                controller: textController,
              ),
            );
          },
        ),
      ),
    );

    // Focus the text field
    focusNode.requestFocus();
    await tester.pump();
    expect(FocusManager.instance.primaryFocus, isNotNull);
    expect(focusNode.hasFocus, isTrue);

    final action = PlayPauseAction(capturedContext);
    expect(action.isEnabled(const PlayPauseIntent()), isFalse);

    // Unfocus
    focusNode.unfocus();
    await tester.pump();
    expect(focusNode.hasFocus, isFalse);
    expect(action.isEnabled(const PlayPauseIntent()), isTrue);
  });
}
