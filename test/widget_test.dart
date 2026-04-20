import 'package:baby_companion/app.dart';
import 'package:baby_companion/domain/haptics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    Haptics.disable();
  });

  testWidgets('Home screen renders menu sections', (tester) async {
    await tester.pumpWidget(const BabyCompanionApp());
    await tester.pump();

    expect(find.text('Baby Companion'), findsOneWidget);
    expect(find.text('FEEDING'), findsOneWidget);
    expect(find.text('TRACK'), findsOneWidget);
  });

  testWidgets('Home shows "Start Nursing" with no active session',
      (tester) async {
    await tester.pumpWidget(const BabyCompanionApp());
    await tester.pump();
    await tester.pump();

    expect(find.text('Start Nursing'), findsOneWidget);
    expect(find.text('No entries yet'), findsOneWidget);
  });

  testWidgets('Home shows "Resume Nursing" when session is active',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      'active_nursing_start': DateTime.now().millisecondsSinceEpoch,
      'active_nursing_side': 0,
    });

    await tester.pumpWidget(const BabyCompanionApp());
    // Two pumps: one for theme load, one for session read.
    await tester.pump();
    await tester.pump();

    expect(find.text('Resume Nursing'), findsOneWidget);
  });
}
