import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/user.dart';
import '../models/air_quality_record.dart';

class DatabaseService {
  static Database? _db;

  static Future<Database> get database async {
    _db ??= await _initDb();
    return _db!;
  }

  static Future<Database> _initDb() async {
    final path = join(await getDatabasesPath(), 'air_quality.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            username TEXT UNIQUE NOT NULL,
            password_hash TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE air_quality_records (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER NOT NULL,
            latitude REAL NOT NULL,
            longitude REAL NOT NULL,
            location_name TEXT NOT NULL,
            aqi REAL NOT NULL,
            pm25 REAL NOT NULL,
            pm10 REAL NOT NULL,
            o3 REAL NOT NULL,
            no2 REAL NOT NULL,
            so2 REAL NOT NULL,
            co REAL NOT NULL,
            ai_advice TEXT NOT NULL,
            record_time TEXT NOT NULL,
            FOREIGN KEY (user_id) REFERENCES users(id)
          )
        ''');
      },
    );
  }

  static Future<User?> createUser(String username, String passwordHash) async {
    final db = await database;
    try {
      final id = await db.insert('users', {
        'username': username,
        'password_hash': passwordHash,
      });
      return User(id: id, username: username, passwordHash: passwordHash);
    } catch (_) {
      return null;
    }
  }

  static Future<User?> getUser(String username, String passwordHash) async {
    final db = await database;
    final maps = await db.query(
      'users',
      where: 'username = ? AND password_hash = ?',
      whereArgs: [username, passwordHash],
    );
    if (maps.isEmpty) return null;
    return User.fromMap(maps.first);
  }

  static Future<bool> usernameExists(String username) async {
    final db = await database;
    final maps = await db.query('users', where: 'username = ?', whereArgs: [username]);
    return maps.isNotEmpty;
  }

  static Future<int> insertRecord(AirQualityRecord record) async {
    final db = await database;
    return db.insert('air_quality_records', record.toMap());
  }

  static Future<List<AirQualityRecord>> getRecords(int userId) async {
    final db = await database;
    final maps = await db.query(
      'air_quality_records',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'record_time DESC',
    );
    return maps.map(AirQualityRecord.fromMap).toList();
  }

  static Future<List<AirQualityRecord>> getWeekRecords(int userId) async {
    final db = await database;
    final weekAgo = DateTime.now().subtract(const Duration(days: 7)).toIso8601String();
    final maps = await db.query(
      'air_quality_records',
      where: 'user_id = ? AND record_time >= ?',
      whereArgs: [userId, weekAgo],
      orderBy: 'record_time ASC',
    );
    return maps.map(AirQualityRecord.fromMap).toList();
  }

  static Future<void> deleteRecord(int id) async {
    final db = await database;
    await db.delete('air_quality_records', where: 'id = ?', whereArgs: [id]);
  }
}
