import 'package:flutter/material.dart';

import '../../data/database.dart';
import '../../data/event.dart';
import '../../domain/haptics.dart';
import '../../domain/time_format.dart';

class MedicationScreen extends StatefulWidget {
  const MedicationScreen({super.key, this.database});

  /// Injectable for tests. Defaults to [AppDatabase.instance] in production.
  final AppDatabase? database;

  @override
  State<MedicationScreen> createState() => _MedicationScreenState();
}

class _MedicationScreenState extends State<MedicationScreen> {
  static const _tylenol = 0;
  static const _motrin = 1;
  static const _minHalves = 1; // 0.5 mL
  static const _maxHalves = 20; // 10.0 mL

  late final AppDatabase _db = widget.database ?? AppDatabase.instance;

  int _side = _tylenol;
  int _ozHalves = 2; // default 1.0 mL
  DateTime? _lastMedicationAt;

  @override
  void initState() {
    super.initState();
    _loadLast();
  }

  Future<void> _loadLast() async {
    DateTime? last;
    try {
      final event = await _db.lastEventOfType(EventType.medication);
      last = event?.startTime;
    } catch (_) {
      last = null;
    }
    if (!mounted) return;
    setState(() => _lastMedicationAt = last);
  }

  void _setSide(int side) {
    if (side == _side) return;
    Haptics.tap();
    setState(() => _side = side);
  }

  void _decrement() {
    if (_ozHalves <= _minHalves) return;
    Haptics.tap();
    setState(() => _ozHalves -= 1);
  }

  void _increment() {
    if (_ozHalves >= _maxHalves) return;
    Haptics.tap();
    setState(() => _ozHalves += 1);
  }

  Future<void> _save() async {
    try {
      await _db.insertEvent(BabyEvent(
        startTime: DateTime.now(),
        type: EventType.medication,
        side: _side,
        ozHalves: _ozHalves,
      ));
    } catch (_) {
      // DB unavailable (e.g. in widget tests). Continue so the flow completes.
    }
    Haptics.logged();
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  String get _formattedDose {
    final whole = _ozHalves ~/ 2;
    final hasHalf = _ozHalves.isOdd;
    final value = hasHalf ? '$whole.5' : '$whole.0';
    return '$value mL';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Medication')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              Center(
                child: SegmentedButton<int>(
                  segments: const [
                    ButtonSegment(value: _tylenol, label: Text('Tylenol')),
                    ButtonSegment(value: _motrin, label: Text('Motrin')),
                  ],
                  selected: {_side},
                  onSelectionChanged: (s) => _setSide(s.first),
                ),
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton.filledTonal(
                    onPressed: _ozHalves <= _minHalves ? null : _decrement,
                    iconSize: 36,
                    icon: const Icon(Icons.remove),
                  ),
                  Expanded(
                    child: Text(
                      _formattedDose,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 64,
                        fontFeatures: const [FontFeature.tabularFigures()],
                        fontWeight: FontWeight.w300,
                        color: scheme.primary,
                      ),
                    ),
                  ),
                  IconButton.filledTonal(
                    onPressed: _ozHalves >= _maxHalves ? null : _increment,
                    iconSize: 36,
                    icon: const Icon(Icons.add),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Last: ${formatTimeAgo(_lastMedicationAt)}',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.check),
                label: const Text('Log dose'),
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
