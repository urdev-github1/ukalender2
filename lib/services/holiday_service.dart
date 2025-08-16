// lib/services/holiday_service.dart

// Importiert notwendige Pakete.
import 'dart:convert'; // Für die Umwandlung von JSON-Daten.
import 'package:http/http.dart'
    as http; // Für das Senden von HTTP-Anfragen (API-Aufrufe).
// NEU: Import für die UUID-Generierung
import 'package:uuid/uuid.dart';
import '../models/event.dart'; // Importiert das Event-Model, um Event-Objekte erstellen zu können.
import 'package:flutter/material.dart'; // Importiert das Material-Design-Paket von Flutter, hier für die Farbe 'Colors.green'.

/// Dieser Service ist dafür zuständig, Feiertagsdaten von einer externen API abzurufen.
class HolidayService {
  // NEU: Eine Instanz des UUID-Generators
  final Uuid _uuid = const Uuid();

  /// Holt eine Liste von Feiertagen für ein bestimmtes Jahr und Bundesland.
  Future<List<Event>> getHolidays(int year, String stateCode) async {
    final url = Uri.parse(
      'https://feiertage-api.de/api/?jahr=$year&nur_land=$stateCode',
    );

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<Event> holidays = [];
        data.forEach((key, value) {
          holidays.add(
            // MODIFIZIERT: 'id' wird jetzt hinzugefügt.
            Event(
              id: _uuid
                  .v4(), // KORREKTUR: Eindeutige ID für den Feiertag generieren
              title: key,
              date: DateTime.parse(value['datum']),
              isHoliday: true,
              color: Colors.green,
            ),
          );
        });
        return holidays;
      } else {
        // Fehlerbehandlung
        return [];
      }
    } catch (e) {
      // Fehlerbehandlung
      return [];
    }
  }
}
