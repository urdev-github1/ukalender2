// lib/services/database_helper.dart

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/event.dart';

class DatabaseHelper {
  // 1. Das Singleton-Muster
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  // 2. Der Datenbank-Getter (Lazy Initialization)
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('events.db');
    return _database!;
  }

  // 3. Initialisierung der Datenbank
  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    // Die Datenbank-Version wird auf 2 erhöht.
    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  // 4. Erstellen der Tabelle(n)
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

  /// NEU: Diese Methode wird aufgerufen, wenn die Datenbank-Version erhöht wird.
  /// Sie fügt die neue Spalte 'isBirthday' zur bestehenden Tabelle hinzu,
  /// ohne dass die Nutzer ihre alten Daten verlieren.
  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute(
        'ALTER TABLE events ADD COLUMN isBirthday INTEGER NOT NULL DEFAULT 0',
      );
    }
  }

  // 5. CRUD-Operationen
  Future<void> insertEvent(Event event) async {
    final db = await instance.database;
    // Die to.Json() Methode aus dem Event-Model wird hier perfekt genutzt
    await db.insert('events', event.toJson());
  }

  Future<List<Event>> getAllEvents() async {
    final db = await instance.database;
    final result = await db.query('events');
    return result.map((json) => Event.fromJson(json)).toList();
  }

  Future<void> updateEvent(Event event) async {
    final db = await instance.database;
    await db.update(
      'events',
      event.toJson(),
      where: 'id = ?', // Das ? ist ein Platzhalter
      whereArgs: [event.id], // Der Wert für den Platzhalter
    );
  }

  Future<void> deleteEvent(String id) async {
    final db = await instance.database;
    await db.delete('events', where: 'id = ?', whereArgs: [id]);
  }
}
