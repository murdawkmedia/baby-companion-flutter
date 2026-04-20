import 'package:baby_companion/domain/haptics.dart';
import 'package:baby_companion/ui/history/history_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    Haptics.disable();
    SharedPreferences.setMockInitialValues({});
  });

  Future<void> pumpScreen(WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: HistoryScreen()));
    // Allow the initState DB lookup to resolve. Errors are swallowed so the
    // test still renders a valid UI without native sqflite.
    await tester.pump();
    await tester.pump();
  }

  testWidgets('renders the History app bar', (tester) async {
    await pumpScreen(tester);

    expect(find.text('History'), findsOneWidget);
  });

  testWidgets('shows "No entries yet." when DB is unavailable',
      (tester) async {
    await pumpScreen(tester);

    // sqflite is not available under flutter_test; recentEvents throws and the
    // screen falls back to an empty list.
    expect(find.text('No entries yet.'), findsOneWidget);
  });
}
