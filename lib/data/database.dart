import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import 'event.dart';

class AppDatabase {
  AppDatabase._();
  static final AppDatabase instance = AppDatabase._();

  Database? _db;

  Future<Database> get db async => _db ??= await _open();

  Future<Database> _open() async {
    final dir = await getDatabasesPath();
    return openDatabase(
      p.join(dir, 'baby_companion.db'),
      version: 1,
      onCreate: (db, _) async {
        await db.execute('''
          CREATE TABLE events (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            start_time INTEGER NOT NULL,
            type INTEGER NOT NULL,
            duration_seconds INTEGER,
            side INTEGER,
            oz_halves INTEGER
          )
        ''');
        await db.execute('CREATE INDEX idx_events_type ON events(type)');
        await db.execute(
            'CREATE INDEX idx_events_start_time ON events(start_time)');

        await db.execute('''
          CREATE TABLE baby_profile (
            id INTEGER PRIMARY KEY CHECK (id = 1),
            name TEXT,
            birth_month INTEGER,
            birth_day INTEGER,
            birth_year INTEGER
          )
        ''');

        await db.execute('''
          CREATE TABLE milestones_logged (
            milestone_index INTEGER PRIMARY KEY,
            logged_at INTEGER NOT NULL
          )
        ''');
      },
    );
  }

  Future<int> insertEvent(BabyEvent event) async {
    final database = await db;
    final map = event.toMap()..remove('id');
    return database.insert('events', map);
  }

  Future<List<BabyEvent>> recentEvents({int limit = 10}) async {
    final database = await db;
    final rows = await database.query(
      'events',
      orderBy: 'start_time DESC',
      limit: limit,
    );
    return rows.map(BabyEvent.fromMap).toList();
  }

  Future<List<BabyEvent>> recentEventsOfType(
    EventType type, {
    int limit = 10,
  }) async {
    final database = await db;
    final rows = await database.query(
      'events',
      where: 'type = ?',
      whereArgs: [type.index],
      orderBy: 'start_time DESC',
      limit: limit,
    );
    return rows.map(BabyEvent.fromMap).toList();
  }

  Future<BabyEvent?> lastEventOfType(EventType type) async {
    final rows = await recentEventsOfType(type, limit: 1);
    return rows.isEmpty ? null : rows.first;
  }

  Future<List<BabyEvent>> eventsOfTypeSince(
    EventType type,
    DateTime since,
  ) async {
    final database = await db;
    final rows = await database.query(
      'events',
      where: 'type = ? AND start_time >= ?',
      whereArgs: [type.index, since.millisecondsSinceEpoch],
      orderBy: 'start_time DESC',
    );
    return rows.map(BabyEvent.fromMap).toList();
  }

  Future<int> countEventsOfTypeSince(
    EventType type,
    DateTime since, {
    int? side,
  }) async {
    final database = await db;
    final where = StringBuffer('type = ? AND start_time >= ?');
    final args = <Object>[type.index, since.millisecondsSinceEpoch];
    if (side != null) {
      where.write(' AND side = ?');
      args.add(side);
    }
    final rows = await database.rawQuery(
      'SELECT COUNT(*) AS c FROM events WHERE $where',
      args,
    );
    return (rows.first['c'] as int?) ?? 0;
  }
}
