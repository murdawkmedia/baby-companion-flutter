import '../data/settings_repo.dart';

class ContractionSample {
  final Duration duration;
  final Duration intervalSinceLast;
  const ContractionSample(this.duration, this.intervalSinceLast);
}

class ContractionRuleResult {
  final bool shouldGoToHospital;
  final Duration averageDuration;
  final Duration averageInterval;
  final Duration trackedSpan;
  const ContractionRuleResult({
    required this.shouldGoToHospital,
    required this.averageDuration,
    required this.averageInterval,
    required this.trackedSpan,
  });
}

ContractionRuleResult evaluateRule(
  List<ContractionSample> samples,
  ContractionRule rule,
) {
  if (samples.isEmpty) {
    return const ContractionRuleResult(
      shouldGoToHospital: false,
      averageDuration: Duration.zero,
      averageInterval: Duration.zero,
      trackedSpan: Duration.zero,
    );
  }
  final avgDur = samples.fold<Duration>(
          Duration.zero, (a, s) => a + s.duration) ~/
      samples.length;
  final avgInt = samples.fold<Duration>(
          Duration.zero, (a, s) => a + s.intervalSinceLast) ~/
      samples.length;
  final span = samples.fold<Duration>(
      Duration.zero, (a, s) => a + s.intervalSinceLast);

  final intervalThreshold = switch (rule) {
    ContractionRule.fiveOneOne => const Duration(minutes: 5),
    ContractionRule.fourOneOne => const Duration(minutes: 4),
  };

  final should = avgInt <= intervalThreshold &&
      avgDur >= const Duration(minutes: 1) &&
      span >= const Duration(hours: 1);

  return ContractionRuleResult(
    shouldGoToHospital: should,
    averageDuration: avgDur,
    averageInterval: avgInt,
    trackedSpan: span,
  );
}
