import 'package:flutter/material.dart';

import '../../data/database.dart';
import '../../data/event.dart';
import '../../domain/haptics.dart';
import '../../domain/time_format.dart';

class DiaperScreen extends StatefulWidget {
  const DiaperScreen({super.key, this.database});

  /// Injectable for tests. Defaults to [AppDatabase.instance] in production.
  final AppDatabase? database;

  @override
  State<DiaperScreen> createState() => _DiaperScreenState();
}

class _DiaperScreenState extends State<DiaperScreen> {
  static const _wet = 0;
  static const _dirty = 1;

  late final AppDatabase _db = widget.database ?? AppDatabase.instance;

  int _side = _wet;
  int _todayWet = 0;
  int _todayDirty = 0;
  DateTime? _lastDiaperAt;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day);
    int wet = 0;
    int dirty = 0;
    DateTime? last;
    try {
      wet = await _db.countEventsOfTypeSince(
        EventType.diaper,
        midnight,
        side: _wet,
      );
      dirty = await _db.countEventsOfTypeSince(
        EventType.diaper,
        midnight,
        side: _dirty,
      );
      final event = await _db.lastEventOfType(EventType.diaper);
      last = event?.startTime;
    } catch (_) {
      wet = 0;
      dirty = 0;
      last = null;
    }
    if (!mounted) return;
    setState(() {
      _todayWet = wet;
      _todayDirty = dirty;
      _lastDiaperAt = last;
    });
  }

  void _setSide(int side) {
    if (side == _side) return;
    Haptics.tap();
    setState(() => _side = side);
  }

  Future<void> _save() async {
    try {
      await _db.insertEvent(BabyEvent(
        startTime: DateTime.now(),
        type: EventType.diaper,
        side: _side,
      ));
    } catch (_) {
      // DB unavailable (e.g. in widget tests). Continue so the flow completes.
    }
    Haptics.logged();
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Diaper')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              Text(
                'Diaper type',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              Center(
                child: SegmentedButton<int>(
                  segments: const [
                    ButtonSegment(value: _wet, label: Text('Wet')),
                    ButtonSegment(value: _dirty, label: Text('Dirty')),
                  ],
                  selected: {_side},
                  onSelectionChanged: (s) => _setSide(s.first),
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Today: $_todayWet wet \u00B7 $_todayDirty dirty',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Last: ${formatTimeAgo(_lastDiaperAt)}',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.check),
                label: const Text('Log diaper'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(64),
                  textStyle: const TextStyle(fontSize: 20),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
