import 'package:baby_companion/domain/time_format.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('formatTimeAgo', () {
    final now = DateTime(2026, 4, 20, 12, 0, 0);

    test('null returns "No entries yet"', () {
      expect(formatTimeAgo(null, now: now), 'No entries yet');
    });

    test('<90s returns "Just now"', () {
      expect(
        formatTimeAgo(now.subtract(const Duration(seconds: 5)), now: now),
        'Just now',
      );
      expect(
        formatTimeAgo(now.subtract(const Duration(seconds: 89)), now: now),
        'Just now',
      );
    });

    test('<1h returns minutes', () {
      expect(
        formatTimeAgo(now.subtract(const Duration(minutes: 5)), now: now),
        '5m ago',
      );
      expect(
        formatTimeAgo(now.subtract(const Duration(minutes: 59)), now: now),
        '59m ago',
      );
    });

    test('<24h returns hours + minutes', () {
      expect(
        formatTimeAgo(
          now.subtract(const Duration(hours: 2, minutes: 15)),
          now: now,
        ),
        '2h 15m ago',
      );
    });

    test('>=24h returns days', () {
      expect(
        formatTimeAgo(now.subtract(const Duration(days: 3)), now: now),
        '3d ago',
      );
    });
  });

  group('formatElapsed', () {
    test('under an hour uses mm:ss', () {
      expect(formatElapsed(const Duration(seconds: 5)), '00:05');
      expect(
        formatElapsed(const Duration(minutes: 12, seconds: 3)),
        '12:03',
      );
    });

    test('over an hour uses h:mm:ss', () {
      expect(
        formatElapsed(const Duration(hours: 1, minutes: 2, seconds: 3)),
        '1:02:03',
      );
    });
  });
}
