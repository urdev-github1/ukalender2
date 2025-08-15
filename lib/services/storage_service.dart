// lib/services/storage_service.dart

import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/event.dart';

class StorageService {
  // Findet den lokalen Pfad zum Speichern von Anwendungsdokumenten.
  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  // Erstellt einen Verweis auf die Speicherdatei.
  Future<File> get _localFile async {
    final path = await _localPath;
    return File('$path/events.json');
  }

  // Liest alle Events aus der JSON-Datei.
  Future<List<Event>> loadEvents() async {
    try {
      final file = await _localFile;
      // Liest den Inhalt der Datei.
      final contents = await file.readAsString();
      // Wandelt den JSON-String in eine Liste von Maps um.
      final List<dynamic> json = jsonDecode(contents);
      // Wandelt jede Map in ein Event-Objekt um.
      return json.map((e) => Event.fromJson(e)).toList();
    } catch (e) {
      // Wenn die Datei nicht existiert oder ein Fehler auftritt,
      // wird eine leere Liste zurückgegeben.
      return [];
    }
  }

  // Speichert eine Liste von Events in der JSON-Datei.
  Future<File> saveEvents(List<Event> events) async {
    final file = await _localFile;
    // Wandelt die Liste von Event-Objekten in eine Liste von Maps um.
    final List<Map<String, dynamic>> json = events.map((e) => e.toJson()).toList();
    // Wandelt die Liste in einen formatierten JSON-String um und schreibt ihn in die Datei.
    return file.writeAsString(jsonEncode(json));
  }
}