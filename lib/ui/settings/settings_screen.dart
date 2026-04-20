import 'package:flutter/material.dart';

import '../../data/baby_profile_repo.dart';
import '../../data/settings_repo.dart';
import '../../domain/haptics.dart';
import 'date_picker_screen.dart';
import 'name_picker_screen.dart';

// TODO: theme changes do not take effect until app restart; live swap requires
// lifting state into BabyCompanionApp.

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, this.settings, this.profile});

  /// Injectable for tests. Defaults used in production.
  final SettingsRepo? settings;
  final BabyProfileRepo? profile;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final SettingsRepo _settings = widget.settings ?? SettingsRepo();
  late final BabyProfileRepo _profile = widget.profile ?? BabyProfileRepo();

  AppTheme _theme = AppTheme.neutral;
  ReminderMode _reminder = ReminderMode.off;
  ContractionRule _rule = ContractionRule.fiveOneOne;
  BabyProfile _babyProfile = const BabyProfile();
  bool _loaded = false;

  static const _appVersion = '1.0.0';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    AppTheme theme = AppTheme.neutral;
    ReminderMode reminder = ReminderMode.off;
    ContractionRule rule = ContractionRule.fiveOneOne;
    BabyProfile profile = const BabyProfile();
    try {
      theme = await _settings.readTheme();
    } catch (_) {}
    try {
      reminder = await _settings.readReminder();
    } catch (_) {}
    try {
      rule = await _settings.readContractionRule();
    } catch (_) {}
    try {
      profile = await _profile.read();
    } catch (_) {}
    if (!mounted) return;
    setState(() {
      _theme = theme;
      _reminder = reminder;
      _rule = rule;
      _babyProfile = profile;
      _loaded = true;
    });
  }

  Future<void> _cycleTheme() async {
    Haptics.tap();
    final next = AppTheme.values[(_theme.index + 1) % AppTheme.values.length];
    setState(() => _theme = next);
    try {
      await _settings.writeTheme(next);
    } catch (_) {}
  }

  Future<void> _cycleReminder() async {
    Haptics.tap();
    final next =
        ReminderMode.values[(_reminder.index + 1) % ReminderMode.values.length];
    setState(() => _reminder = next);
    try {
      await _settings.writeReminder(next);
    } catch (_) {}
  }

  Future<void> _toggleRule() async {
    Haptics.tap();
    final next = _rule == ContractionRule.fiveOneOne
        ? ContractionRule.fourOneOne
        : ContractionRule.fiveOneOne;
    setState(() => _rule = next);
    try {
      await _settings.writeContractionRule(next);
    } catch (_) {}
  }

  Future<void> _pickName() async {
    final result = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => NamePickerScreen(initial: _babyProfile.name),
      ),
    );
    if (result == null) return;
    final updated = _babyProfile.copyWith(name: result);
    setState(() => _babyProfile = updated);
    try {
      await _profile.write(updated);
    } catch (_) {}
  }

  Future<void> _pickDate() async {
    final result = await Navigator.of(context).push<DateTime>(
      MaterialPageRoute(
        builder: (_) => DatePickerScreen(initial: _babyProfile.birthDate),
      ),
    );
    if (result == null) return;
    final updated = BabyProfile(
      name: _babyProfile.name,
      birthMonth: result.month,
      birthDay: result.day,
      birthYear: result.year,
    );
    setState(() => _babyProfile = updated);
    try {
      await _profile.write(updated);
    } catch (_) {}
  }

  String _themeLabel(AppTheme t) => switch (t) {
        AppTheme.neutral => 'Neutral',
        AppTheme.boy => 'Boy',
        AppTheme.girl => 'Girl',
      };

  String _reminderLabel(ReminderMode m) => switch (m) {
        ReminderMode.off => 'Off',
        ReminderMode.h1 => '1h',
        ReminderMode.h2 => '2h',
        ReminderMode.h2m30 => '2h 30m',
        ReminderMode.h3 => '3h',
        ReminderMode.h3m30 => '3h 30m',
        ReminderMode.h4 => '4h',
      };

  String _ruleLabel(ContractionRule r) => switch (r) {
        ContractionRule.fiveOneOne => '5-1-1',
        ContractionRule.fourOneOne => '4-1-1',
      };

  String _nameLabel() {
    final n = _babyProfile.name;
    if (n == null || n.isEmpty) return 'Not set';
    return n;
  }

  String _birthDateLabel() {
    final d = _babyProfile.birthDate;
    if (d == null) return 'Not set';
    final mm = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    return '$mm/$dd/${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: !_loaded
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                ListTile(
                  title: const Text('Theme'),
                  trailing: Text(_themeLabel(_theme)),
                  onTap: _cycleTheme,
                ),
                ListTile(
                  title: const Text('Reminder'),
                  trailing: Text(_reminderLabel(_reminder)),
                  onTap: _cycleReminder,
                ),
                ListTile(
                  title: const Text('Baby Name'),
                  trailing: Text(_nameLabel()),
                  onTap: _pickName,
                ),
                ListTile(
                  title: const Text('Birth Date'),
                  trailing: Text(_birthDateLabel()),
                  onTap: _pickDate,
                ),
                ListTile(
                  title: const Text('Contraction Rule'),
                  trailing: Text(_ruleLabel(_rule)),
                  onTap: _toggleRule,
                ),
                const ListTile(
                  title: Text('Version'),
                  trailing: Text(_appVersion),
                ),
              ],
            ),
    );
  }
}
