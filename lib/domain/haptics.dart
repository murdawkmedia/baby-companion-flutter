import 'package:flutter/foundation.dart';
import 'package:vibration/vibration.dart';

/// Thin wrapper around the `vibration` package so UI code can stay oblivious to
/// hardware availability and test-environment channel errors.
class Haptics {
  Haptics._();

  static bool _disabled = false;
  static bool? _hasVibratorCache;

  /// Disable all vibration output. Intended for tests.
  @visibleForTesting
  static void disable() {
    _disabled = true;
  }

  static Future<bool> _canVibrate() async {
    if (_disabled) return false;
    if (_hasVibratorCache != null) return _hasVibratorCache!;
    try {
      _hasVibratorCache = await Vibration.hasVibrator();
    } catch (_) {
      _hasVibratorCache = false;
    }
    return _hasVibratorCache!;
  }

  static Future<void> _run({int? duration, List<int>? pattern}) async {
    if (!await _canVibrate()) return;
    try {
      if (pattern != null) {
        await Vibration.vibrate(pattern: pattern);
      } else {
        await Vibration.vibrate(duration: duration ?? 20);
      }
    } catch (_) {
      // swallow — haptics are best-effort
    }
  }

  /// Short pulse for a UI tap (button toggle, value adjust).
  static Future<void> tap() => _run(duration: 20);

  /// Double pulse signalling a log entry was saved.
  static Future<void> logged() => _run(pattern: [0, 40, 60, 40]);

  /// Long pulse signalling an important state change (session start/stop).
  static Future<void> important() => _run(duration: 120);
}
