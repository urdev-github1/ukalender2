// lib/services/storage_service.dart

import '../models/event.dart';
import 'database_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart'; // HINZUGEFÜGT für ThemeMode

class StorageService {
  final dbHelper = DatabaseHelper.instance;

  Future<List<Event>> loadEvents() async {
    return await dbHelper.getAllEvents();
  }

  Future<void> addEvent(Event event) async {
    await dbHelper.insertEvent(event);
  }

  Future<void> updateEvent(Event event) async {
    await dbHelper.updateEvent(event);
  }

  Future<void> deleteEvent(String id) async {
    await dbHelper.deleteEvent(id);
  }

  // === SharedPreferences für einfache Einstellungen ===
  static const _stateCodeKey = 'user_state_code';
  static const _reminder1MinutesKey = 'reminder_1_minutes';
  static const _reminder2MinutesKey = 'reminder_2_minutes';
  static const _themeModeKey = 'app_theme_mode';

  Future<void> saveSelectedState(String stateCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_stateCodeKey, stateCode);
  }

  Future<String> getSelectedState() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_stateCodeKey) ?? 'NW';
  }

  /// Speichert den ausgewählten Theme-Modus.
  Future<void> saveThemeMode(ThemeMode themeMode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeModeKey, themeMode.name);
  }

  /// Lädt den gespeicherten Theme-Modus.
  Future<ThemeMode> getThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final themeName = prefs.getString(_themeModeKey);
    switch (themeName) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        // Standardwert, falls nichts gespeichert ist.
        return ThemeMode.system;
    }
  }

  Future<void> saveReminderMinutes(int reminder1, int reminder2) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_reminder1MinutesKey, reminder1);
    await prefs.setInt(_reminder2MinutesKey, reminder2);
  }

  Future<Map<String, int>> getReminderMinutes() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      // 1. Erinnerung (die weiter entfernte) ist standardmäßig 10 Minuten vorher.
      'reminder1': prefs.getInt(_reminder1MinutesKey) ?? 10,
      // 2. Erinnerung (die nähere) ist standardmäßig 5 Minuten vorher.
      'reminder2': prefs.getInt(_reminder2MinutesKey) ?? 5,
    };
  }
}
