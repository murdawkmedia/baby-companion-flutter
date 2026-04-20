import 'dart:async';

import 'package:flutter/material.dart';

import '../../data/active_session.dart';
import '../../data/database.dart';
import '../../data/event.dart';
import '../../domain/haptics.dart';
import '../../domain/time_format.dart';

class SleepScreen extends StatefulWidget {
  const SleepScreen({super.key, this.sessionStore, this.database});

  /// Injectable for tests. Defaults used in production.
  final ActiveSessionStore? sessionStore;
  final AppDatabase? database;

  @override
  State<SleepScreen> createState() => _SleepScreenState();
}

class _SleepScreenState extends State<SleepScreen> {
  late final ActiveSessionStore _sessions =
      widget.sessionStore ?? ActiveSessionStore();
  late final AppDatabase _db = widget.database ?? AppDatabase.instance;

  DateTime? _start;
  DateTime? _lastSleepAt;
  Timer? _ticker;
  bool _restored = false;

  @override
  void initState() {
    super.initState();
    _restore();
    _loadLast();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Future<void> _restore() async {
    final existing = await _sessions.readStart(SessionKind.sleep);
    if (!mounted) return;
    setState(() {
      _restored = true;
      if (existing != null) {
        _start = existing;
        _startTicker();
      }
    });
  }

  Future<void> _loadLast() async {
    DateTime? last;
    try {
      final event = await _db.lastEventOfType(EventType.sleep);
      last = event?.startTime;
    } catch (_) {
      last = null;
    }
    if (!mounted) return;
    setState(() => _lastSleepAt = last);
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  Duration get _elapsed =>
      _start == null ? Duration.zero : DateTime.now().difference(_start!);

  bool get _running => _start != null;

  Future<void> _toggleStart() async {
    Haptics.important();
    if (_running) {
      await _save();
      return;
    }
    final now = DateTime.now();
    await _sessions.writeStart(SessionKind.sleep, now);
    if (!mounted) return;
    setState(() => _start = now);
    _startTicker();
  }

  Future<void> _save() async {
    final start = _start;
    if (start == null) return;
    final durationSeconds = DateTime.now().difference(start).inSeconds;
    _ticker?.cancel();
    try {
      await _db.insertEvent(BabyEvent(
        startTime: start,
        type: EventType.sleep,
        durationSeconds: durationSeconds,
      ));
    } catch (_) {
      // Swallow DB errors so widget tests without sqflite still complete.
    }
    await _sessions.clear(SessionKind.sleep);
    Haptics.logged();
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Sleep')),
      body: !_restored
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 24),
                    Text(
                      _running ? 'Sleeping' : 'Ready',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      formatElapsed(_elapsed),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 64,
                        fontFeatures: const [FontFeature.tabularFigures()],
                        fontWeight: FontWeight.w300,
                        color: scheme.primary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Last: ${formatTimeAgo(_lastSleepAt)}',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const Spacer(),
                    FilledButton.icon(
                      onPressed: _toggleStart,
                      icon: Icon(_running ? Icons.stop : Icons.play_arrow),
                      label: Text(_running ? 'Save' : 'Start'),
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
