import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/household.dart';

/// Single shared connection to the on-device SQLite database.
///
/// Everything here works fully offline — this matters because survey and
/// delivery staff will often be in areas with weak or no signal. Later,
/// a separate "sync" step can push this local data up to a shared server
/// whenever a connection is available, without changing how this class works.
class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._internal();
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'rashan_survey.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE households (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        surveyorName TEXT NOT NULL,
        surveyDate TEXT NOT NULL,
        headOfHouseholdName TEXT NOT NULL,
        cnic TEXT NOT NULL,
        phoneNumber TEXT NOT NULL,
        address TEXT NOT NULL,
        totalFamilyMembers INTEGER NOT NULL,
        childrenUnder18 INTEGER NOT NULL,
        elderlyOver60 INTEGER NOT NULL,
        notes TEXT
      )
    ''');
  }

  Future<int> insertHousehold(Household household) async {
    final db = await database;
    return await db.insert('households', household.toMap());
  }

  Future<List<Household>> getAllHouseholds() async {
    final db = await database;
    final maps = await db.query('households', orderBy: 'surveyDate DESC');
    return maps.map((map) => Household.fromMap(map)).toList();
  }

  Future<int> deleteHousehold(int id) async {
    final db = await database;
    return await db.delete('households', where: 'id = ?', whereArgs: [id]);
  }

  /// Basic de-duplication check, per the SOP requirement to avoid the same
  /// household being registered (and receiving rashan) more than once.
  Future<bool> cnicExists(String cnic) async {
    final db = await database;
    final result =
        await db.query('households', where: 'cnic = ?', whereArgs: [cnic]);
    return result.isNotEmpty;
  }
}
