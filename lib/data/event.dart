enum EventType {
  nursing,
  formula,
  milestone,
  diaper,
  sleep,
  medication,
  colic,
  contraction,
}

class BabyEvent {
  final int? id;
  final DateTime startTime;
  final EventType type;
  final int? durationSeconds;
  final int? side;
  final int? ozHalves;

  const BabyEvent({
    this.id,
    required this.startTime,
    required this.type,
    this.durationSeconds,
    this.side,
    this.ozHalves,
  });

  Map<String, Object?> toMap() => {
        'id': id,
        'start_time': startTime.millisecondsSinceEpoch,
        'type': type.index,
        'duration_seconds': durationSeconds,
        'side': side,
        'oz_halves': ozHalves,
      };

  factory BabyEvent.fromMap(Map<String, Object?> m) => BabyEvent(
        id: m['id'] as int?,
        startTime:
            DateTime.fromMillisecondsSinceEpoch(m['start_time'] as int),
        type: EventType.values[m['type'] as int],
        durationSeconds: m['duration_seconds'] as int?,
        side: m['side'] as int?,
        ozHalves: m['oz_halves'] as int?,
      );
}
