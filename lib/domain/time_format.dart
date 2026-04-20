String formatTimeAgo(DateTime? t, {DateTime? now}) {
  if (t == null) return 'No entries yet';
  final ref = now ?? DateTime.now();
  final diff = ref.difference(t);
  final s = diff.inSeconds;
  if (s < 90) return 'Just now';
  final m = diff.inMinutes;
  if (m < 60) return '${m}m ago';
  if (diff.inHours < 24) {
    final h = diff.inHours;
    final remM = m - h * 60;
    return '${h}h ${remM}m ago';
  }
  return '${diff.inDays}d ago';
}

String formatElapsed(Duration d) {
  final h = d.inHours;
  final m = d.inMinutes.remainder(60);
  final s = d.inSeconds.remainder(60);
  final mm = m.toString().padLeft(2, '0');
  final ss = s.toString().padLeft(2, '0');
  return h > 0 ? '$h:$mm:$ss' : '$mm:$ss';
}
