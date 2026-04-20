import 'package:sqflite/sqflite.dart' show ConflictAlgorithm;

import 'database.dart';

const List<String> kMilestoneNames = [
  'Social Smile',
  'First Laugh',
  'Holds Head Up',
  'Tracks Objects',
  'Rolls Fwd-Back',
  'Rolls Back-Fwd',
  'Sits w/ Support',
  'Sits Alone',
  'First Solid Food',
  'Crawling',
  'Pulls to Stand',
  'First Steps',
  'First Word',
  'Points at Things',
  'Waves Bye-Bye',
];

class MilestonesRepo {
  MilestonesRepo({AppDatabase? database})
      : _db = database ?? AppDatabase.instance;

  final AppDatabase _db;

  Future<Map<int, DateTime>> readAllLogged() async {
    final database = await _db.db;
    final rows = await database.query('milestones_logged');
    return {
      for (final r in rows)
        r['milestone_index'] as int:
            DateTime.fromMillisecondsSinceEpoch(r['logged_at'] as int),
    };
  }

  Future<bool> toggle(int index, {DateTime? at}) async {
    final database = await _db.db;
    final existing = await database.query(
      'milestones_logged',
      where: 'milestone_index = ?',
      whereArgs: [index],
    );
    if (existing.isNotEmpty) {
      await database.delete(
        'milestones_logged',
        where: 'milestone_index = ?',
        whereArgs: [index],
      );
      return false;
    }
    await database.insert(
      'milestones_logged',
      {
        'milestone_index': index,
        'logged_at': (at ?? DateTime.now()).millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return true;
  }
}
