import 'package:baby_companion/data/settings_repo.dart';
import 'package:baby_companion/domain/haptics.dart';
import 'package:baby_companion/ui/settings/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    Haptics.disable();
    SharedPreferences.setMockInitialValues({});
  });

  Future<void> pumpScreen(WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: SettingsScreen()));
    // Allow the initState reads to resolve.
    await tester.pump();
    await tester.pump();
  }

  testWidgets('renders the Settings app bar', (tester) async {
    await pumpScreen(tester);

    expect(find.text('Settings'), findsOneWidget);
  });

  testWidgets('renders all 6 settings rows', (tester) async {
    await pumpScreen(tester);

    expect(find.text('Theme'), findsOneWidget);
    expect(find.text('Reminder'), findsOneWidget);
    expect(find.text('Baby Name'), findsOneWidget);
    expect(find.text('Birth Date'), findsOneWidget);
    expect(find.text('Contraction Rule'), findsOneWidget);
    expect(find.text('Version'), findsOneWidget);
  });

  testWidgets('tapping Theme cycles the trailing label', (tester) async {
    await pumpScreen(tester);

    // Default is Neutral.
    expect(find.text('Neutral'), findsOneWidget);

    await tester.tap(find.text('Theme'));
    await tester.pumpAndSettle();

    expect(find.text('Boy'), findsOneWidget);

    // Persisted via SharedPreferences mock.
    expect(await SettingsRepo().readTheme(), AppTheme.boy);
  });

  testWidgets('tapping Contraction Rule toggles 5-1-1 <-> 4-1-1',
      (tester) async {
    await pumpScreen(tester);

    expect(find.text('5-1-1'), findsOneWidget);

    await tester.tap(find.text('Contraction Rule'));
    await tester.pumpAndSettle();

    expect(find.text('4-1-1'), findsOneWidget);
  });
}
