import 'dart:async';

import 'package:flutter/material.dart';

import '../../data/active_session.dart';
import '../../data/database.dart';
import '../../data/event.dart';
import '../../domain/time_format.dart';
import '../colic/colic_screen.dart';
import '../contractions/contractions_screen.dart';
import '../diaper/diaper_screen.dart';
import '../formula/formula_screen.dart';
import '../history/history_screen.dart';
import '../medication/medication_screen.dart';
import '../milestones/milestones_screen.dart';
import '../nursing/nursing_screen.dart';
import '../settings/settings_screen.dart';
import '../sleep/sleep_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  final _sessions = ActiveSessionStore();
  final _db = AppDatabase.instance;

  bool _nursingActive = false;
  DateTime? _lastNursingAt;
  Timer? _clock;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refresh();
    // Repaint once a minute so the "time-ago" label stays fresh.
    _clock = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _clock?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refresh();
  }

  Future<void> _refresh() async {
    DateTime? active;
    try {
      active = await _sessions.readStart(SessionKind.nursing);
    } catch (_) {
      active = null;
    }
    DateTime? last;
    try {
      final ev = await _db.lastEventOfType(EventType.nursing);
      last = ev?.startTime;
    } catch (_) {
      last = null;
    }
    if (!mounted) return;
    setState(() {
      _nursingActive = active != null;
      _lastNursingAt = last;
    });
  }

  Future<void> _open(BuildContext ctx, Widget screen) async {
    await Navigator.of(ctx).push(MaterialPageRoute(builder: (_) => screen));
    if (mounted) _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Baby Companion')),
      body: ListView(
        children: [
          _section(context, 'Feeding'),
          ListTile(
            title: Text(_nursingActive ? 'Resume Nursing' : 'Start Nursing'),
            subtitle: Text(formatTimeAgo(_lastNursingAt)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _open(context, const NursingScreen()),
          ),
          _tile(context, 'Log Formula', const FormulaScreen()),
          _tile(context, 'Log Diaper', const DiaperScreen()),
          _tile(context, 'Log Medication', const MedicationScreen()),
          _section(context, 'Track'),
          _tile(context, 'History', const HistoryScreen()),
          _tile(context, 'Sleep', const SleepScreen()),
          _tile(context, 'Colic Timer', const ColicScreen()),
          _tile(context, 'Contractions', const ContractionsScreen()),
          _tile(context, 'Milestones', const MilestonesScreen()),
          _tile(context, 'Settings', const SettingsScreen()),
        ],
      ),
    );
  }

  Widget _section(BuildContext ctx, String label) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
        child: Text(label.toUpperCase(),
            style: Theme.of(ctx).textTheme.labelSmall),
      );

  Widget _tile(BuildContext ctx, String label, Widget screen) => ListTile(
        title: Text(label),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => _open(ctx, screen),
      );
}
