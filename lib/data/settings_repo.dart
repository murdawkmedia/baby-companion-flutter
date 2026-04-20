import 'package:shared_preferences/shared_preferences.dart';

enum AppTheme { neutral, boy, girl }

enum ContractionRule { fiveOneOne, fourOneOne }

enum ReminderMode {
  off,
  h1,
  h2,
  h2m30,
  h3,
  h3m30,
  h4,
}

class SettingsRepo {
  static const _kTheme = 'theme_id';
  static const _kReminder = 'reminder_mode';
  static const _kRule = 'contraction_rule';

  Future<AppTheme> readTheme() async {
    final p = await SharedPreferences.getInstance();
    return AppTheme.values[p.getInt(_kTheme) ?? 0];
  }

  Future<void> writeTheme(AppTheme t) async {
    final p = await SharedPreferences.getInstance();
    await p.setInt(_kTheme, t.index);
  }

  Future<ReminderMode> readReminder() async {
    final p = await SharedPreferences.getInstance();
    return ReminderMode.values[p.getInt(_kReminder) ?? 0];
  }

  Future<void> writeReminder(ReminderMode m) async {
    final p = await SharedPreferences.getInstance();
    await p.setInt(_kReminder, m.index);
  }

  Future<ContractionRule> readContractionRule() async {
    final p = await SharedPreferences.getInstance();
    return ContractionRule.values[p.getInt(_kRule) ?? 0];
  }

  Future<void> writeContractionRule(ContractionRule r) async {
    final p = await SharedPreferences.getInstance();
    await p.setInt(_kRule, r.index);
  }
}
