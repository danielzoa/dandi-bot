import 'package:dandi_bot/widgets/chat_input.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Enter sends chat message', (tester) async {
    String? sentMessage;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChatInput(onSend: (message) => sentMessage = message),
        ),
      ),
    );

    await tester.enterText(find.byType(TextField), 'Analise PETR4');
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();

    expect(sentMessage, 'Analise PETR4');
    expect(find.text('Analise PETR4'), findsNothing);
  });

  testWidgets('Shift Enter does not send chat message', (tester) async {
    String? sentMessage;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChatInput(onSend: (message) => sentMessage = message),
        ),
      ),
    );

    await tester.enterText(find.byType(TextField), 'Primeira linha');
    await tester.sendKeyDownEvent(LogicalKeyboardKey.shift);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shift);
    await tester.pump();

    expect(sentMessage, isNull);
  });
}
