import 'package:sqflite/sqflite.dart' show ConflictAlgorithm;

import 'database.dart';

class BabyProfile {
  final String? name;
  final int? birthMonth;
  final int? birthDay;
  final int? birthYear;

  const BabyProfile({
    this.name,
    this.birthMonth,
    this.birthDay,
    this.birthYear,
  });

  bool get isEmpty =>
      (name == null || name!.isEmpty) &&
      birthMonth == null &&
      birthDay == null &&
      birthYear == null;

  DateTime? get birthDate =>
      (birthMonth != null && birthDay != null && birthYear != null)
          ? DateTime(birthYear!, birthMonth!, birthDay!)
          : null;

  BabyProfile copyWith({
    String? name,
    int? birthMonth,
    int? birthDay,
    int? birthYear,
  }) =>
      BabyProfile(
        name: name ?? this.name,
        birthMonth: birthMonth ?? this.birthMonth,
        birthDay: birthDay ?? this.birthDay,
        birthYear: birthYear ?? this.birthYear,
      );
}

class BabyProfileRepo {
  BabyProfileRepo({AppDatabase? database})
      : _db = database ?? AppDatabase.instance;

  final AppDatabase _db;

  Future<BabyProfile> read() async {
    final database = await _db.db;
    final rows = await database.query('baby_profile', where: 'id = 1');
    if (rows.isEmpty) return const BabyProfile();
    final m = rows.first;
    return BabyProfile(
      name: m['name'] as String?,
      birthMonth: m['birth_month'] as int?,
      birthDay: m['birth_day'] as int?,
      birthYear: m['birth_year'] as int?,
    );
  }

  Future<void> write(BabyProfile profile) async {
    final database = await _db.db;
    await database.insert(
      'baby_profile',
      {
        'id': 1,
        'name': profile.name,
        'birth_month': profile.birthMonth,
        'birth_day': profile.birthDay,
        'birth_year': profile.birthYear,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
