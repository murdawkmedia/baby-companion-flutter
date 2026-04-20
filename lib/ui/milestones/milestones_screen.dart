import 'package:flutter/material.dart';

import '../../data/database.dart';
import '../../data/event.dart';
import '../../data/milestones_repo.dart';
import '../../domain/haptics.dart';
import '../../domain/time_format.dart';

class MilestonesScreen extends StatefulWidget {
  const MilestonesScreen({super.key, this.repo, this.database});

  /// Injectable for tests. Defaults used in production.
  final MilestonesRepo? repo;
  final AppDatabase? database;

  @override
  State<MilestonesScreen> createState() => _MilestonesScreenState();
}

class _MilestonesScreenState extends State<MilestonesScreen> {
  late final MilestonesRepo _repo = widget.repo ?? MilestonesRepo();
  late final AppDatabase _db = widget.database ?? AppDatabase.instance;

  Map<int, DateTime> _logged = const {};
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    Map<int, DateTime> logged;
    try {
      logged = await _repo.readAllLogged();
    } catch (_) {
      logged = const {};
    }
    if (!mounted) return;
    setState(() {
      _logged = logged;
      _loaded = true;
    });
  }

  Future<void> _toggle(int index) async {
    bool nowLogged;
    try {
      nowLogged = await _repo.toggle(index);
    } catch (_) {
      // DB unavailable (e.g. widget tests). Flip local state so the UI responds.
      nowLogged = !_logged.containsKey(index);
    }
    final next = Map<int, DateTime>.from(_logged);
    if (nowLogged) {
      final now = DateTime.now();
      next[index] = now;
      Haptics.logged();
      try {
        await _db.insertEvent(BabyEvent(
          type: EventType.milestone,
          startTime: now,
          side: index,
        ));
      } catch (_) {
        // Ignore DB write failure — the toggle state still persists via repo.
      }
    } else {
      next.remove(index);
      Haptics.tap();
    }
    if (!mounted) return;
    setState(() => _logged = next);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Milestones')),
      body: !_loaded
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: kMilestoneNames.length,
              itemBuilder: (_, i) {
                final loggedAt = _logged[i];
                return CheckboxListTile(
                  value: loggedAt != null,
                  title: Text(kMilestoneNames[i]),
                  subtitle:
                      loggedAt == null ? null : Text(formatTimeAgo(loggedAt)),
                  onChanged: (_) => _toggle(i),
                );
              },
            ),
    );
  }
}
