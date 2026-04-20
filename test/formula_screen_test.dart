import 'package:baby_companion/domain/haptics.dart';
import 'package:baby_companion/ui/formula/formula_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    Haptics.disable();
    SharedPreferences.setMockInitialValues({});
  });

  Future<void> pumpScreen(WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: FormulaScreen()));
    // Allow initState futures (DB lookup) to resolve. Errors are swallowed
    // by the screen's try/catch so it doesn't crash on missing sqflite.
    await tester.pump();
    await tester.pump();
  }

  testWidgets('renders default 1.0 oz value', (tester) async {
    await pumpScreen(tester);

    expect(find.text('Formula'), findsOneWidget);
    expect(find.text('1.0 oz'), findsOneWidget);
  });

  testWidgets('tapping the plus button increments in 0.5 oz steps',
      (tester) async {
    await pumpScreen(tester);

    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();
    expect(find.text('1.5 oz'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();
    expect(find.text('2.0 oz'), findsOneWidget);
  });

  testWidgets('tapping the minus button decrements and stops at 0.5 oz',
      (tester) async {
    await pumpScreen(tester);

    // Default is 1.0 oz. Minus once -> 0.5 oz.
    await tester.tap(find.byIcon(Icons.remove));
    await tester.pump();
    expect(find.text('0.5 oz'), findsOneWidget);

    // Tapping again at the minimum should not go lower.
    await tester.tap(find.byIcon(Icons.remove));
    await tester.pump();
    expect(find.text('0.5 oz'), findsOneWidget);
  });
}
