import 'dart:async';

import 'package:flutter/material.dart';

import '../../data/active_session.dart';
import '../../data/database.dart';
import '../../data/event.dart';
import '../../domain/haptics.dart';
import '../../domain/time_format.dart';

class NursingScreen extends StatefulWidget {
  const NursingScreen({super.key, this.sessionStore, this.database});

  /// Injectable for tests. Defaults used in production.
  final ActiveSessionStore? sessionStore;
  final AppDatabase? database;

  @override
  State<NursingScreen> createState() => _NursingScreenState();
}

class _NursingScreenState extends State<NursingScreen> {
  static const _left = 0;
  static const _right = 1;

  late final ActiveSessionStore _sessions =
      widget.sessionStore ?? ActiveSessionStore();
  late final AppDatabase _db = widget.database ?? AppDatabase.instance;

  DateTime? _start;
  int _side = _left;
  Timer? _ticker;
  bool _restored = false;

  @override
  void initState() {
    super.initState();
    _restore();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Future<void> _restore() async {
    final existing = await _sessions.readStart(SessionKind.nursing);
    final side = await _sessions.readSide(SessionKind.nursing);
    if (!mounted) return;
    setState(() {
      _restored = true;
      _side = side ?? _left;
      if (existing != null) {
        _start = existing;
        _startTicker();
      }
    });
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
    await _sessions.writeStart(SessionKind.nursing, now, side: _side);
    if (!mounted) return;
    setState(() => _start = now);
    _startTicker();
  }

  Future<void> _setSide(int side) async {
    if (side == _side) return;
    Haptics.tap();
    setState(() => _side = side);
    if (_running) {
      await _sessions.writeStart(SessionKind.nursing, _start!, side: side);
    }
  }

  Future<void> _save() async {
    final start = _start;
    if (start == null) return;
    final durationSeconds = DateTime.now().difference(start).inSeconds;
    _ticker?.cancel();
    await _db.insertEvent(BabyEvent(
      startTime: start,
      type: EventType.nursing,
      durationSeconds: durationSeconds,
      side: _side,
    ));
    await _sessions.clear(SessionKind.nursing);
    Haptics.logged();
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Nursing')),
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
                      _running ? 'Nursing' : 'Ready',
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
                    const SizedBox(height: 32),
                    SegmentedButton<int>(
                      segments: const [
                        ButtonSegment(value: _left, label: Text('Left')),
                        ButtonSegment(value: _right, label: Text('Right')),
                      ],
                      selected: {_side},
                      onSelectionChanged: (s) => _setSide(s.first),
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
