// lib/services/holiday_service.dart

// Importiert notwendige Pakete.
import 'dart:convert'; // Für die Umwandlung von JSON-Daten.
import 'package:http/http.dart' as http; // Für das Senden von HTTP-Anfragen (API-Aufrufe).
import '../models/event.dart'; // Importiert das Event-Model, um Event-Objekte erstellen zu können.
import 'package:flutter/material.dart'; // Importiert das Material-Design-Paket von Flutter, hier für die Farbe 'Colors.green'.

/// Dieser Service ist dafür zuständig, Feiertagsdaten von einer externen API abzurufen.
class HolidayService {
  /// Holt eine Liste von Feiertagen für ein bestimmtes Jahr und Bundesland.
  Future<List<Event>> getHolidays(int year, String stateCode) async {
    final url = Uri.parse('https://feiertage-api.de/api/?jahr=$year&nur_land=$stateCode');
    
    // KORREKTUR: Hinzugefügter Debug-Print
    print('Rufe Feiertage ab von: $url');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        
        // KORREKTUR: Hinzugefügter Debug-Print für erfolgreichen Abruf
        print('Erfolgreich ${data.length} Feiertage von der API erhalten.');

        final List<Event> holidays = [];
        data.forEach((key, value) {
          holidays.add(Event(
            title: key,
            date: DateTime.parse(value['datum']),
            isHoliday: true,
            color: Colors.green,
          ));
        });
        return holidays;
      } else {
        // Der Fehler wird jetzt deutlicher auf der Konsole angezeigt.
        print('API-FEHLER: Fehler beim Abrufen der Feiertage. Statuscode: ${response.statusCode}');
        print('Antwort des Servers: ${response.body}');
        return [];
      }
    } catch (e) {
      // Der Netzwerkfehler wird jetzt deutlicher auf der Konsole angezeigt.
      print('NETZWERKFEHLER: Die Feiertage konnten nicht geladen werden. Prüfen Sie die Internetverbindung und die App-Berechtigungen. Fehler: $e');
      return [];
    }
  }
}