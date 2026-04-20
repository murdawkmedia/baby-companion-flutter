import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

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
}
