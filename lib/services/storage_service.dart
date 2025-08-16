// lib/services/storage_service

import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/event.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  // === Dateibasierte Speicherung für komplexe Event-Listen ===

  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  Future<File> get _localFile async {
    final path = await _localPath;
    return File('$path/events.json');
  }

  Future<List<Event>> loadEvents() async {
    try {
      final file = await _localFile;
      final contents = await file.readAsString();
      final List<dynamic> json = jsonDecode(contents);
      return json.map((e) => Event.fromJson(e)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<File> saveEvents(List<Event> events) async {
    final file = await _localFile;
    final List<Map<String, dynamic>> json = events
        .map((e) => e.toJson())
        .toList();
    return file.writeAsString(jsonEncode(json));
  }

  // === SharedPreferences für einfache Einstellungen (Bundesland) ===

  static const _stateCodeKey = 'user_state_code';

  Future<void> saveSelectedState(String stateCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_stateCodeKey, stateCode);
    // print('Bundesland gespeichert: $stateCode');
  }

  /// Lädt das gespeicherte Bundesland-Kürzel.
  /// Gibt 'NW' zurück, falls noch keine Auswahl getroffen wurde.
  Future<String> getSelectedState() async {
    final prefs = await SharedPreferences.getInstance();
    // KORREKTUR: Der Standardwert wurde von 'NATIONAL' auf 'NW' geändert.
    return prefs.getString(_stateCodeKey) ?? 'NW';
  }
}
