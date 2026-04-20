import '../data/settings_repo.dart';

Duration? reminderDurationFor(ReminderMode mode) => switch (mode) {
      ReminderMode.off => null,
      ReminderMode.h1 => const Duration(hours: 1),
      ReminderMode.h2 => const Duration(hours: 2),
      ReminderMode.h2m30 => const Duration(hours: 2, minutes: 30),
      ReminderMode.h3 => const Duration(hours: 3),
      ReminderMode.h3m30 => const Duration(hours: 3, minutes: 30),
      ReminderMode.h4 => const Duration(hours: 4),
    };

class ReminderScheduler {
  Future<void> scheduleFeedReminder({
    required DateTime feedStart,
    required ReminderMode mode,
  }) async {
    // TODO: wire up flutter_local_notifications + android_alarm_manager_plus.
  }

  Future<void> cancelAll() async {
    // TODO
  }
}
