import 'package:shared_preferences/shared_preferences.dart';

enum SessionKind { nursing, sleep, colic, contraction }

class ActiveSessionStore {
  String _startKey(SessionKind k) => 'active_${k.name}_start';
  String _sideKey(SessionKind k) => 'active_${k.name}_side';

  Future<DateTime?> readStart(SessionKind k) async {
    final p = await SharedPreferences.getInstance();
    final ms = p.getInt(_startKey(k));
    return ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms);
  }

  Future<void> writeStart(SessionKind k, DateTime start, {int? side}) async {
    final p = await SharedPreferences.getInstance();
    await p.setInt(_startKey(k), start.millisecondsSinceEpoch);
    if (side != null) await p.setInt(_sideKey(k), side);
  }

  Future<int?> readSide(SessionKind k) async {
    final p = await SharedPreferences.getInstance();
    return p.getInt(_sideKey(k));
  }

  Future<void> clear(SessionKind k) async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_startKey(k));
    await p.remove(_sideKey(k));
  }
}
