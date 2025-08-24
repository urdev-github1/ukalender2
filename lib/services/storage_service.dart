// lib/services/storage_service.dart

import 'package:shared_preferences/shared_preferences.dart';
import '../models/event.dart';
import '../services/database_helper.dart';

/// Dienst zur Verwaltung der Ereignisspeicherung und Benutzereinstellungen.
class StorageService {
  final dbHelper = DatabaseHelper.instance;

  /// Lädt alle Ereignisse aus der lokalen Datenbank.
  Future<List<Event>> loadEvents() async {
    return await dbHelper.getAllEvents();
  }

  /// Fügt ein neues Ereignis zur lokalen Datenbank hinzu.
  Future<void> addEvent(Event event) async {
    await dbHelper.insertEvent(event);
  }

  /// Aktualisiert ein bestehendes Ereignis in der lokalen Datenbank.
  Future<void> updateEvent(Event event) async {
    await dbHelper.updateEvent(event);
  }

  /// Löscht ein Ereignis aus der lokalen Datenbank anhand seiner ID.
  Future<void> deleteEvent(String id) async {
    await dbHelper.deleteEvent(id);
  }

  static const _stateCodeKey = 'user_state_code';
  static const _reminder1MinutesKey = 'reminder_1_minutes';
  static const _reminder2MinutesKey = 'reminder_2_minutes';
  static const _isTestNotificationKey = 'is_test_notification';

  /// Speichert, ob Testbenachrichtigungen aktiviert sind.
  Future<void> saveIsTestNotification(bool isTest) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isTestNotificationKey, isTest);
  }

  /// Liest, ob Testbenachrichtigungen aktiviert sind.
  Future<bool> getIsTestNotification() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isTestNotificationKey) ?? false;
  }

  /// Speichert den ausgewählten Bundeslandcode des Benutzers.
  Future<void> saveSelectedState(String stateCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_stateCodeKey, stateCode);
  }

  /// Liest den ausgewählten Bundeslandcode des Benutzers.
  Future<String> getSelectedState() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_stateCodeKey) ?? 'NW';
  }

  /// Speichert die Erinnerungszeiten in Minuten vor dem Ereignis.
  Future<void> saveReminderMinutes(int reminder1, int reminder2) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_reminder1MinutesKey, reminder1);
    await prefs.setInt(_reminder2MinutesKey, reminder2);
  }

  /// Liest die Erinnerungszeiten in Minuten vor dem Ereignis.
  Future<Map<String, int>> getReminderMinutes() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      // 1. Erinnerung: 24 Stunden (1440 Minuten) vorher.
      'reminder1': prefs.getInt(_reminder1MinutesKey) ?? 1440,
      // 2. Erinnerung: 1 Stunde (60 Minuten) vorher.
      'reminder2': prefs.getInt(_reminder2MinutesKey) ?? 60,
    };
  }

  /// Löscht alle Ereignisse aus der lokalen Datenbank.
  Future<void> clearAllEvents() async {
    await dbHelper.deleteAllEvents();
  }
}
