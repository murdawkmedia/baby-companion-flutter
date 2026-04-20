import 'package:baby_companion/data/milestones_repo.dart';
import 'package:baby_companion/domain/haptics.dart';
import 'package:baby_companion/ui/milestones/milestones_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    Haptics.disable();
    SharedPreferences.setMockInitialValues({});
  });

  Future<void> pumpScreen(WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: MilestonesScreen()));
    // Allow the initState DB lookup to resolve. Errors are swallowed so the
    // screen still renders an empty-checked list without native sqflite.
    await tester.pump();
    await tester.pump();
  }

  testWidgets('renders the Milestones app bar', (tester) async {
    await pumpScreen(tester);

    expect(find.text('Milestones'), findsOneWidget);
  });

  testWidgets('renders all 15 milestone names', (tester) async {
    await pumpScreen(tester);

    // The default test viewport is too short to show all 15 tiles at once,
    // so scroll each name into view before asserting it exists.
    final listFinder = find.byType(Scrollable);
    for (final name in kMilestoneNames) {
      await tester.scrollUntilVisible(
        find.text(name),
        80,
        scrollable: listFinder,
      );
      expect(find.text(name), findsOneWidget);
    }
  });

  testWidgets('tapping a milestone toggles its checkbox on', (tester) async {
    await pumpScreen(tester);

    // Before: unchecked.
    final firstCheckbox = tester.widget<CheckboxListTile>(
      find.byType(CheckboxListTile).first,
    );
    expect(firstCheckbox.value, false);

    await tester.tap(find.text(kMilestoneNames.first));
    await tester.pumpAndSettle();

    final updated = tester.widget<CheckboxListTile>(
      find.byType(CheckboxListTile).first,
    );
    expect(updated.value, true);
  });
}
