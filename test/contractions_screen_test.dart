import 'package:baby_companion/domain/haptics.dart';
import 'package:baby_companion/ui/contractions/contractions_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    Haptics.disable();
    SharedPreferences.setMockInitialValues({});
  });

  Future<void> pumpScreen(WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: ContractionsScreen()));
    // First pump: widget builds with loading indicator.
    // Second pump: shared_preferences future resolves, state updates.
    await tester.pump();
    await tester.pump();
  }

  testWidgets('renders idle state with Start button', (tester) async {
    await pumpScreen(tester);

    expect(find.text('Contractions'), findsOneWidget);
    expect(find.text('Start'), findsOneWidget);
    expect(find.text('Ready'), findsOneWidget);
    expect(find.text('00:00'), findsOneWidget);
    // No samples yet → no stats block, no hospital banner.
    expect(find.text('Go to hospital'), findsNothing);
  });

  testWidgets('auto-resumes when a contraction is in progress',
      (tester) async {
    final start = DateTime.now().subtract(const Duration(seconds: 45));
    SharedPreferences.setMockInitialValues({
      'active_contraction_start': start.millisecondsSinceEpoch,
    });

    await pumpScreen(tester);

    expect(find.text('Stop'), findsOneWidget);
    expect(find.text('Contraction'), findsAtLeastNWidgets(1));

    final elapsedFinder = find.textContaining(RegExp(r'^00:4[4-6]$'));
    expect(elapsedFinder, findsOneWidget);
  });
}
