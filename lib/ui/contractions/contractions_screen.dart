import 'dart:async';

import 'package:flutter/material.dart';

import '../../data/active_session.dart';
import '../../data/database.dart';
import '../../data/event.dart';
import '../../data/settings_repo.dart';
import '../../domain/contraction_rule.dart';
import '../../domain/haptics.dart';
import '../../domain/time_format.dart';

/// Live contraction stopwatch.
///
/// Two-state behaviour:
/// - While a contraction is running: big elapsed timer counts up.
/// - Between contractions: "Waiting" message + secondary clock showing
///   time since the previous contraction's start (i.e. the running interval).
///
/// Each completed contraction is saved as its own [BabyEvent] row with
/// `type = contraction`, `durationSeconds = <seconds>`, and `ozHalves` set to
/// the interval-in-minutes since the previous contraction's start (per
/// MIGRATION.md §1).
///
/// The running average duration / interval + rule verdict are computed from an
/// in-memory list of samples collected during the current screen session. The
/// very first contraction has no previous one; its `intervalSinceLast` is set
/// to [Duration.zero] and it is excluded from average-interval math.
class ContractionsScreen extends StatefulWidget {
  const ContractionsScreen({
    super.key,
    this.sessionStore,
    this.database,
    this.settings,
  });

  /// Injectable for tests. Defaults used in production.
  final ActiveSessionStore? sessionStore;
  final AppDatabase? database;
  final SettingsRepo? settings;

  @override
  State<ContractionsScreen> createState() => _ContractionsScreenState();
}

class _ContractionsScreenState extends State<ContractionsScreen> {
  late final ActiveSessionStore _sessions =
      widget.sessionStore ?? ActiveSessionStore();
  late final AppDatabase _db = widget.database ?? AppDatabase.instance;
  late final SettingsRepo _settingsRepo = widget.settings ?? SettingsRepo();

  /// Current contraction start (null while waiting between contractions).
  DateTime? _currentStart;

  /// Start time of the previously completed contraction. Used to compute the
  /// interval for the next contraction and the "time since last" clock while
  /// waiting.
  DateTime? _previousStart;

  /// Samples collected during this screen session. Rebuilt on each Stop.
  final List<ContractionSample> _samples = [];

  ContractionRule _rule = ContractionRule.fiveOneOne;

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
    ContractionRule rule = ContractionRule.fiveOneOne;
    try {
      rule = await _settingsRepo.readContractionRule();
    } catch (_) {
      // Fall back to 5-1-1 if prefs not available.
    }
    final existing = await _sessions.readStart(SessionKind.contraction);
    if (!mounted) return;
    setState(() {
      _restored = true;
      _rule = rule;
      if (existing != null) {
        _currentStart = existing;
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

  bool get _running => _currentStart != null;

  Duration get _elapsed => _currentStart == null
      ? Duration.zero
      : DateTime.now().difference(_currentStart!);

  Duration get _sinceLast => _previousStart == null
      ? Duration.zero
      : DateTime.now().difference(_previousStart!);

  Future<void> _onPrimary() async {
    if (_running) {
      await _stopContraction();
    } else {
      await _startContraction();
    }
  }

  Future<void> _startContraction() async {
    // Contraction start pattern from MIGRATION.md §4: 80-120-150 ms.
    Haptics.important();
    final now = DateTime.now();
    await _sessions.writeStart(SessionKind.contraction, now);
    if (!mounted) return;
    setState(() => _currentStart = now);
    _startTicker();
  }

  Future<void> _stopContraction() async {
    // Contraction stop pattern from MIGRATION.md §4: 300-100-100 ms.
    Haptics.important();
    final start = _currentStart;
    if (start == null) return;
    final end = DateTime.now();
    final duration = end.difference(start);
    final intervalSinceLast = _previousStart == null
        ? Duration.zero
        : start.difference(_previousStart!);

    _ticker?.cancel();

    // Persist event. For the first contraction of the session, ozHalves is 0
    // (no previous contraction to measure from).
    try {
      await _db.insertEvent(BabyEvent(
        startTime: start,
        type: EventType.contraction,
        durationSeconds: duration.inSeconds,
        ozHalves: intervalSinceLast.inMinutes,
      ));
    } catch (_) {
      // Swallow so tests without sqflite still work.
    }

    await _sessions.clear(SessionKind.contraction);

    if (!mounted) return;
    setState(() {
      _samples.add(ContractionSample(duration, intervalSinceLast));
      _previousStart = start;
      _currentStart = null;
    });
    // Keep ticker going so the "time since last" clock updates.
    _startTicker();
    Haptics.logged();
  }

  /// Samples used for the running-rule evaluation. Excludes the first sample's
  /// zero-interval so averages aren't dragged down by a placeholder.
  List<ContractionSample> get _samplesForRule =>
      _samples.length <= 1 ? _samples : _samples.sublist(1);

  ContractionRuleResult get _ruleResult =>
      evaluateRule(_samplesForRule, _rule);

  Future<bool> _confirmExit() async {
    if (_samples.isEmpty) return true;
    final result = _ruleResult;
    final verdict = result.shouldGoToHospital
        ? 'Rule met — consider going to hospital.'
        : 'Rule not met yet.';
    final avgDur = formatElapsed(result.averageDuration);
    final avgInt = formatElapsed(result.averageInterval);
    final shouldPop = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Session summary'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Contractions: ${_samples.length}'),
            Text('Avg duration: $avgDur'),
            Text('Avg interval: $avgInt'),
            const SizedBox(height: 8),
            Text(verdict),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: const Text('Keep tracking'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogCtx).pop(true),
            child: const Text('End session'),
          ),
        ],
      ),
    );
    return shouldPop ?? false;
  }

  Future<void> _endSession() async {
    // If a contraction is in progress, close it first so no data is lost.
    if (_running) {
      await _stopContraction();
    }
    final ok = await _confirmExit();
    if (!ok) return;
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final result = _ruleResult;
    final showBanner = result.shouldGoToHospital;

    return PopScope(
      canPop: _samples.isEmpty && !_running,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final navigator = Navigator.of(context);
        final ok = await _confirmExit();
        if (ok && mounted) navigator.pop(true);
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Contractions'),
          actions: [
            if (_samples.isNotEmpty || _running)
              TextButton(
                onPressed: _endSession,
                child: const Text('End'),
              ),
          ],
        ),
        body: !_restored
            ? const Center(child: CircularProgressIndicator())
            : SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (showBanner)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              vertical: 12, horizontal: 16),
                          decoration: BoxDecoration(
                            color: scheme.error,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Go to hospital',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: scheme.onError,
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      const SizedBox(height: 24),
                      Text(
                        _running
                            ? 'Contraction'
                            : (_previousStart == null
                                ? 'Ready'
                                : 'Waiting — tap Start to time next contraction'),
                        textAlign: TextAlign.center,
                        style: textTheme.titleMedium,
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
                      if (!_running && _previousStart != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Since last start: ${formatElapsed(_sinceLast)}',
                          textAlign: TextAlign.center,
                          style: textTheme.bodyMedium,
                        ),
                      ],
                      const SizedBox(height: 24),
                      if (_samples.isNotEmpty)
                        _StatsBlock(
                          count: _samples.length,
                          avgDuration: result.averageDuration,
                          avgInterval: result.averageInterval,
                          rule: _rule,
                        ),
                      const Spacer(),
                      FilledButton.icon(
                        onPressed: _onPrimary,
                        icon: Icon(_running ? Icons.stop : Icons.play_arrow),
                        label: Text(_running ? 'Stop' : 'Start'),
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
      ),
    );
  }
}

class _StatsBlock extends StatelessWidget {
  const _StatsBlock({
    required this.count,
    required this.avgDuration,
    required this.avgInterval,
    required this.rule,
  });

  final int count;
  final Duration avgDuration;
  final Duration avgInterval;
  final ContractionRule rule;

  @override
  Widget build(BuildContext context) {
    final ruleLabel = switch (rule) {
      ContractionRule.fiveOneOne => '5-1-1',
      ContractionRule.fourOneOne => '4-1-1',
    };
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Session stats ($ruleLabel)',
          textAlign: TextAlign.center,
          style: textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _Stat(label: 'Count', value: '$count'),
            _Stat(label: 'Avg dur', value: formatElapsed(avgDuration)),
            _Stat(label: 'Avg int', value: formatElapsed(avgInterval)),
          ],
        ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: textTheme.labelSmall),
        const SizedBox(height: 2),
        Text(
          value,
          style: textTheme.titleMedium?.copyWith(
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}
