// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:linux_assistant/main.dart';

import 'package:flutter/material.dart';

class _DummyPage extends StatelessWidget {
  const _DummyPage();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Smoke Test')),
    );
  }
}

void main() {
  testWidgets('App shell smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(MyApp(
      firstPage: const _DummyPage(),
    ));

    expect(find.byType(MyApp), findsOneWidget);
    expect(find.text('Smoke Test'), findsOneWidget);
  });
}
