import 'package:flutter/material.dart';

import '../../data/database.dart';
import '../../data/event.dart';
import '../../data/milestones_repo.dart';
import '../../domain/time_format.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key, this.database});

  /// Injectable for tests. Defaults to [AppDatabase.instance] in production.
  final AppDatabase? database;

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late final AppDatabase _db = widget.database ?? AppDatabase.instance;

  List<BabyEvent> _events = const [];
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    List<BabyEvent> events;
    try {
      events = await _db.recentEvents(limit: 50);
    } catch (_) {
      events = const [];
    }
    if (!mounted) return;
    setState(() {
      _events = events;
      _loaded = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('History')),
      body: !_loaded
          ? const Center(child: CircularProgressIndicator())
          : _events.isEmpty
              ? const Center(child: Text('No entries yet.'))
              : ListView.builder(
                  itemCount: _events.length,
                  itemBuilder: (_, i) => _eventTile(_events[i]),
                ),
    );
  }

  Widget _eventTile(BabyEvent event) {
    final ago = formatTimeAgo(event.startTime);
    return ListTile(
      leading: Icon(_iconFor(event.type)),
      title: Text(_titleFor(event.type)),
      subtitle: Text(_subtitleFor(event, ago)),
    );
  }

  IconData _iconFor(EventType t) => switch (t) {
        EventType.nursing => Icons.child_care,
        EventType.formula => Icons.local_drink,
        EventType.milestone => Icons.emoji_events,
        EventType.diaper => Icons.water_drop,
        EventType.sleep => Icons.bedtime,
        EventType.medication => Icons.medication,
        EventType.colic => Icons.timer,
        EventType.contraction => Icons.pregnant_woman,
      };

  String _titleFor(EventType t) => switch (t) {
        EventType.nursing => 'Nursing',
        EventType.formula => 'Formula',
        EventType.milestone => 'Milestone',
        EventType.diaper => 'Diaper',
        EventType.sleep => 'Sleep',
        EventType.medication => 'Medication',
        EventType.colic => 'Colic',
        EventType.contraction => 'Contraction',
      };

  String _subtitleFor(BabyEvent event, String ago) {
    switch (event.type) {
      case EventType.nursing:
        final side = event.side == 1 ? 'Right' : 'Left';
        final duration = _nursingDuration(event.durationSeconds);
        return duration == null
            ? '$side \u00B7 $ago'
            : '$side \u00B7 $duration \u00B7 $ago';
      case EventType.formula:
        final oz = _ozLabel(event.ozHalves);
        return oz == null ? ago : '$oz \u00B7 $ago';
      case EventType.milestone:
        final idx = event.side;
        final name = (idx != null && idx >= 0 && idx < kMilestoneNames.length)
            ? kMilestoneNames[idx]
            : 'Milestone';
        return '$name \u00B7 $ago';
      case EventType.diaper:
        final label = event.side == 1 ? 'Dirty' : 'Wet';
        return '$label \u00B7 $ago';
      case EventType.sleep:
        final dur = _nursingDuration(event.durationSeconds);
        return dur == null ? ago : '$dur \u00B7 $ago';
      case EventType.medication:
        final med = event.side == 1 ? 'Motrin' : 'Tylenol';
        final dose = _medDoseLabel(event.ozHalves);
        return dose == null
            ? '$med \u00B7 $ago'
            : '$med \u00B7 $dose \u00B7 $ago';
      case EventType.colic:
        final seconds = event.durationSeconds;
        if (seconds == null) return ago;
        return '${formatElapsed(Duration(seconds: seconds))} \u00B7 $ago';
      case EventType.contraction:
        final seconds = event.durationSeconds;
        if (seconds == null) return ago;
        return '${formatElapsed(Duration(seconds: seconds))} \u00B7 $ago';
    }
  }

  /// Compact duration label like "12m" or "1h 5m" — suitable for nursing/sleep.
  String? _nursingDuration(int? seconds) {
    if (seconds == null || seconds <= 0) return null;
    final d = Duration(seconds: seconds);
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    if (h > 0) return '${h}h ${m}m';
    if (m > 0) return '${m}m';
    return '${d.inSeconds}s';
  }

  String? _ozLabel(int? ozHalves) {
    if (ozHalves == null || ozHalves <= 0) return null;
    final oz = ozHalves / 2;
    final trimmed = oz == oz.roundToDouble()
        ? oz.toStringAsFixed(0)
        : oz.toStringAsFixed(1);
    return '$trimmed oz';
  }

  String? _medDoseLabel(int? ozHalves) {
    if (ozHalves == null || ozHalves <= 0) return null;
    final ml = ozHalves / 2;
    final trimmed = ml == ml.roundToDouble()
        ? ml.toStringAsFixed(0)
        : ml.toStringAsFixed(1);
    return '$trimmed mL';
  }
}
