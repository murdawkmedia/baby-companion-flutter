import 'package:baby_companion/app.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Home screen renders menu sections', (tester) async {
    await tester.pumpWidget(const BabyCompanionApp());
    await tester.pump();

    expect(find.text('Baby Companion'), findsOneWidget);
    expect(find.text('FEEDING'), findsOneWidget);
    expect(find.text('TRACK'), findsOneWidget);
  });
}
