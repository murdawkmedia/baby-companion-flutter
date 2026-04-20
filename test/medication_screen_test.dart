import 'package:baby_companion/domain/haptics.dart';
import 'package:baby_companion/ui/medication/medication_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    Haptics.disable();
    SharedPreferences.setMockInitialValues({});
  });

  Future<void> pumpScreen(WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: MedicationScreen()));
    // Allow the initState DB lookup to resolve. Errors are swallowed so the
    // test still renders a valid UI without native sqflite.
    await tester.pump();
    await tester.pump();
  }

  testWidgets('renders default 1.0 mL dose with Tylenol selected',
      (tester) async {
    await pumpScreen(tester);

    expect(find.text('Medication'), findsOneWidget);
    expect(find.text('Tylenol'), findsOneWidget);
    expect(find.text('Motrin'), findsOneWidget);
    expect(find.text('1.0 mL'), findsOneWidget);

    final button = tester.widget<SegmentedButton<int>>(
      find.byType(SegmentedButton<int>),
    );
    expect(button.selected, {0});
  });

  testWidgets('tapping plus increments in 0.5 mL steps', (tester) async {
    await pumpScreen(tester);

    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();
    expect(find.text('1.5 mL'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();
    expect(find.text('2.0 mL'), findsOneWidget);
  });

  testWidgets('tapping Motrin updates the selected segment', (tester) async {
    await pumpScreen(tester);

    await tester.tap(find.text('Motrin'));
    await tester.pumpAndSettle();

    final button = tester.widget<SegmentedButton<int>>(
      find.byType(SegmentedButton<int>),
    );
    expect(button.selected, {1});
  });
}
