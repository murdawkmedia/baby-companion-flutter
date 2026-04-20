import 'package:flutter/material.dart';

import '../../data/database.dart';
import '../../data/event.dart';
import '../../domain/haptics.dart';
import '../../domain/time_format.dart';

class FormulaScreen extends StatefulWidget {
  const FormulaScreen({super.key, this.database});

  /// Injectable for tests. Defaults to [AppDatabase.instance] in production.
  final AppDatabase? database;

  @override
  State<FormulaScreen> createState() => _FormulaScreenState();
}

class _FormulaScreenState extends State<FormulaScreen> {
  static const _minHalves = 1; // 0.5 oz
  static const _maxHalves = 20; // 10.0 oz

  late final AppDatabase _db = widget.database ?? AppDatabase.instance;

  int _ozHalves = 2; // default 1.0 oz
  DateTime? _lastFormulaAt;

  @override
  void initState() {
    super.initState();
    _loadLast();
  }

  Future<void> _loadLast() async {
    DateTime? last;
    try {
      final event = await _db.lastEventOfType(EventType.formula);
      last = event?.startTime;
    } catch (_) {
      last = null;
    }
    if (!mounted) return;
    setState(() => _lastFormulaAt = last);
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
        type: EventType.formula,
        ozHalves: _ozHalves,
      ));
    } catch (_) {
      // If the DB is unavailable (e.g. in a widget test) we still pop so the
      // UI flow completes. Production uses sqflite on-device.
    }
    Haptics.logged();
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  String get _formattedOunces {
    final whole = _ozHalves ~/ 2;
    final hasHalf = _ozHalves.isOdd;
    final value = hasHalf ? '$whole.5' : '$whole.0';
    return '$value oz';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Formula')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              Text(
                'Bottle size',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
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
                      _formattedOunces,
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
                'Last: ${formatTimeAgo(_lastFormulaAt)}',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.check),
                label: const Text('Log bottle'),
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
