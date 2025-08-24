// lib/services/storage_service.dart

import 'package:shared_preferences/shared_preferences.dart';
import '../models/event.dart';
import '../services/database_helper.dart';

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

  static const _stateCodeKey = 'user_state_code';
  static const _reminder1MinutesKey = 'reminder_1_minutes';
  static const _reminder2MinutesKey = 'reminder_2_minutes';
  static const _isTestNotificationKey = 'is_test_notification';

  Future<void> saveIsTestNotification(bool isTest) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isTestNotificationKey, isTest);
  }

  Future<bool> getIsTestNotification() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isTestNotificationKey) ?? false;
  }

  Future<void> saveSelectedState(String stateCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_stateCodeKey, stateCode);
  }

  Future<String> getSelectedState() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_stateCodeKey) ?? 'NW';
  }

  Future<void> saveReminderMinutes(int reminder1, int reminder2) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_reminder1MinutesKey, reminder1);
    await prefs.setInt(_reminder2MinutesKey, reminder2);
  }

  Future<Map<String, int>> getReminderMinutes() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      // 1. Erinnerung: 24 Stunden (1440 Minuten) vorher.
      'reminder1': prefs.getInt(_reminder1MinutesKey) ?? 1440,
      // 2. Erinnerung: 1 Stunde (60 Minuten) vorher.
      'reminder2': prefs.getInt(_reminder2MinutesKey) ?? 60,
    };
  }

  Future<void> clearAllEvents() async {
    await dbHelper.deleteAllEvents();
  }
}
