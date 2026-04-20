import 'package:baby_companion/domain/haptics.dart';
import 'package:baby_companion/ui/colic/colic_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    Haptics.disable();
    SharedPreferences.setMockInitialValues({});
  });

  Future<void> pumpScreen(WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: ColicScreen()));
    // First pump: widget builds with loading indicator.
    // Second pump: shared_preferences future resolves, state updates.
    await tester.pump();
    await tester.pump();
  }

  testWidgets('starts in idle state with "Start" button', (tester) async {
    await pumpScreen(tester);

    expect(find.text('Colic Timer'), findsOneWidget);
    expect(find.text('Start'), findsOneWidget);
    expect(find.text('Ready'), findsOneWidget);
    expect(find.text('00:00'), findsOneWidget);
  });

  testWidgets('auto-resumes when a colic session is already running',
      (tester) async {
    final start = DateTime.now().subtract(const Duration(seconds: 45));
    SharedPreferences.setMockInitialValues({
      'active_colic_start': start.millisecondsSinceEpoch,
    });

    await pumpScreen(tester);

    expect(find.text('Save'), findsOneWidget);
    expect(find.text('Crying'), findsAtLeastNWidgets(1));

    // Elapsed reads at 45±1 seconds — accept both to avoid timing flakes.
    final elapsedFinder = find.textContaining(RegExp(r'^00:4[4-6]$'));
    expect(elapsedFinder, findsOneWidget);
  });
}
