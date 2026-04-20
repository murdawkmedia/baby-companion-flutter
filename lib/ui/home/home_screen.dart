import 'package:flutter/material.dart';

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

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Baby Companion')),
      body: ListView(
        children: [
          _section(context, 'Feeding'),
          _tile(context, 'Start/Resume Nursing', const NursingScreen()),
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
        onTap: () => Navigator.of(ctx).push(
          MaterialPageRoute(builder: (_) => screen),
        ),
      );
}
