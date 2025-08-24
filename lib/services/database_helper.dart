// lib/services/database_helper.dart

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/event.dart';

/// Singleton-Klasse für die Datenbankverwaltung
class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  // Privater Konstruktor
  DatabaseHelper._init();

  /// Zugriff auf die Datenbank
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('events.db');
    return _database!;
  }

  /// Initialisierung der Datenbank
  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  /// Erstellung der Datenbanktabellen
  Future _createDB(Database db, int version) async {
    const idType = 'TEXT PRIMARY KEY';
    const textType = 'TEXT NOT NULL';
    const textNullableType = 'TEXT NULL';
    const integerType = 'INTEGER NOT NULL';

    await db.execute('''
      CREATE TABLE events (
      id $idType,
      title $textType,
      description $textNullableType,
      date $textType,
      isHoliday $integerType,
      color $integerType,
      isBirthday $integerType DEFAULT 0
      )
      ''');
  }

  /// Datenbank-Upgrade-Logik
  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute(
        'ALTER TABLE events ADD COLUMN isBirthday INTEGER NOT NULL DEFAULT 0',
      );
    }
  }

  // Diese Methode fügt einen neuen Termin hinzu.
  Future<void> insertEvent(Event event) async {
    final db = await instance.database;
    await db.insert(
      'events',
      event.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Diese Methode aktualisiert einen bestehenden Termin.
  Future<void> updateEvent(Event event) async {
    final db = await instance.database;
    await db.update(
      'events',
      event.toJson(),
      where: 'id = ?',
      whereArgs: [event.id],
    );
  }

  /// Diese Methode ruft alle Termine ab.
  Future<List<Event>> getAllEvents() async {
    final db = await instance.database;
    final result = await db.query('events');
    return result.map((json) => Event.fromJson(json)).toList();
  }

  /// Diese Methode löscht einen Termin anhand seiner ID.
  Future<void> deleteEvent(String id) async {
    final db = await instance.database;
    await db.delete('events', where: 'id = ?', whereArgs: [id]);
  }

  /// Diese Methode löscht alle Termine.
  Future<void> deleteAllEvents() async {
    final db = await instance.database;
    await db.delete('events');
  }
}
