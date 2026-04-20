import 'package:baby_companion/domain/haptics.dart';
import 'package:baby_companion/ui/diaper/diaper_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    Haptics.disable();
    SharedPreferences.setMockInitialValues({});
  });

  Future<void> pumpScreen(WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: DiaperScreen()));
    // Allow the initState DB lookup to resolve. Errors are swallowed so the
    // test still renders a valid UI without native sqflite.
    await tester.pump();
    await tester.pump();
  }

  testWidgets('renders with Wet selected by default', (tester) async {
    await pumpScreen(tester);

    expect(find.text('Diaper'), findsOneWidget);
    expect(find.text('Wet'), findsOneWidget);
    expect(find.text('Dirty'), findsOneWidget);
    expect(find.textContaining('Today:'), findsOneWidget);
  });

  testWidgets('tapping Dirty updates the selected segment', (tester) async {
    await pumpScreen(tester);

    // Locate the SegmentedButton and verify its initial selection.
    SegmentedButton<int> button = tester.widget(
      find.byType(SegmentedButton<int>),
    );
    expect(button.selected, {0});

    await tester.tap(find.text('Dirty'));
    await tester.pumpAndSettle();

    button = tester.widget(find.byType(SegmentedButton<int>));
    expect(button.selected, {1});
  });

  testWidgets('shows "No entries yet" when there is no prior diaper',
      (tester) async {
    await pumpScreen(tester);

    expect(find.text('Last: No entries yet'), findsOneWidget);
  });
}
