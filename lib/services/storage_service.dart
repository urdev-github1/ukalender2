// lib/services/storage_service

// Importiere nicht mehr 'dart:io', 'dart:convert' oder 'path_provider'.
// Diese Details sind jetzt im DatabaseHelper gekapselt.
import '../models/event.dart';
import 'database_helper.dart'; // Der NEUE und wichtigste Import
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  // 1. Instanz des DatabaseHelper als einzige Verbindung zur Datenbank herstellen
  final dbHelper = DatabaseHelper.instance;

  // 2. loadEvents() wird stark vereinfacht
  Future<List<Event>> loadEvents() async {
    // Die gesamte Komplexität des Lesens wird an den dbHelper delegiert.
    // Wir sagen nur noch "gib mir alle Events", nicht mehr "lies diese Datei".
    return await dbHelper.getAllEvents();
  }

  // 3. Die ineffiziente saveEvents() Methode wird durch granulare Methoden ersetzt

  // Die alte Methode wird nicht mehr benötigt.
  /*
  Future<void> saveEvents(List<Event> events) async {
    // Diese Methode passt nicht mehr zum Datenbank-Ansatz.
  }
  */

  // NEUE Methode, um EINEN einzelnen Termin hinzuzufügen.
  Future<void> addEvent(Event event) async {
    await dbHelper.insertEvent(event);
  }

  // NEUE Methode, um EINEN einzelnen Termin zu aktualisieren.
  Future<void> updateEvent(Event event) async {
    await dbHelper.updateEvent(event);
  }

  // NEUE Methode, um EINEN einzelnen Termin anhand seiner ID zu löschen.
  Future<void> deleteEvent(String id) async {
    await dbHelper.deleteEvent(id);
  }

  // === SharedPreferences für einfache Einstellungen (Bundesland) ===
  // 4. Dieser Teil bleibt zu 100% identisch!
  static const _stateCodeKey = 'user_state_code';

  Future<void> saveSelectedState(String stateCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_stateCodeKey, stateCode);
  }

  Future<String> getSelectedState() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_stateCodeKey) ?? 'NW';
  }
}
