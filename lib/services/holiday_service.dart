// lib/services/holiday_service.dart

// Importiert notwendige Pakete.
import 'dart:convert'; // Für die Umwandlung von JSON-Daten.
import 'package:http/http.dart' as http; // Für das Senden von HTTP-Anfragen (API-Aufrufe).
import '../models/event.dart'; // Importiert das Event-Model, um Event-Objekte erstellen zu können.
import 'package:flutter/material.dart'; // Importiert das Material-Design-Paket von Flutter, hier für die Farbe 'Colors.green'.

/// Dieser Service ist dafür zuständig, Feiertagsdaten von einer externen API abzurufen.
/// In diesem Beispiel wird die öffentliche API von feiertage-api.de verwendet.
class HolidayService {
  /// Holt eine Liste von Feiertagen für ein bestimmtes Jahr und Bundesland.
  ///
  /// [year]: Das Jahr, für das die Feiertage abgerufen werden sollen.
  /// [stateCode]: Der Ländercode für das Bundesland (z.B. "BY" für Bayern, "NW" für NRW).
  /// Gibt eine `Future<List<Event>>` zurück. Das bedeutet, das Ergebnis ist eine Liste
  /// von Event-Objekten, die asynchron (in der Zukunft) zur Verfügung gestellt wird.
  Future<List<Event>> getHolidays(int year, String stateCode) async {
    // Erstellt die URL für die API-Anfrage. Die Parameter 'jahr' und 'nur_land' werden
    // dynamisch mit den übergebenen Werten für Jahr und Bundesland gefüllt.
    final url = Uri.parse('https://feiertage-api.de/api/?jahr=$year&nur_land=$stateCode');

    // Ein try-catch-Block wird verwendet, um mögliche Fehler abzufangen,
    // die bei der Netzwerkkommunikation auftreten können (z.B. keine Internetverbindung).
    try {
      // Sendet eine asynchrone GET-Anfrage an die erstellte URL und wartet auf die Antwort.
      final response = await http.get(url);

      // Überprüft, ob die Anfrage erfolgreich war. Der HTTP-Statuscode 200 bedeutet "OK".
      if (response.statusCode == 200) {
        // Dekodiert den JSON-String aus dem Body der Antwort in eine Dart-Map.
        // Die Map hat Strings als Schlüssel und dynamische Typen als Werte.
        final Map<String, dynamic> data = json.decode(response.body);

        // Erstellt eine leere Liste, in der die Feiertags-Events gespeichert werden.
        final List<Event> holidays = [];

        // Iteriert über jeden Eintrag in der dekodierten Daten-Map.
        // 'key' ist der Name des Feiertags (z.B. "Neujahrstag"),
        // 'value' ist eine weitere Map mit Details zum Feiertag (z.B. {'datum': '2024-01-01'}).
        data.forEach((key, value) {
          // Fügt der 'holidays'-Liste ein neues Event-Objekt hinzu.
          holidays.add(Event(
            title: key, // Der Name des Feiertags.
            date: DateTime.parse(value['datum']), // Das Datum wird aus dem String geparst.
            isHoliday: true, // Setzt die Eigenschaft, dass es sich um einen Feiertag handelt.
            color: Colors.green, // Weist dem Event eine grüne Farbe zu.
          ));
        });

        // Gibt die gefüllte Liste mit den Feiertagen zurück.
        return holidays;
      } else {
        // Wenn der Statuscode nicht 200 ist (z.B. 404 Not Found), wird die Fehlerbehandlung ausgeführt.
        // In diesem Fall wird eine leere Liste zurückgegeben, um einen App-Absturz zu verhindern.
        print('Fehler beim Abrufen der Feiertage: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      // Fängt Fehler ab, die während der HTTP-Anfrage auftreten (z.B. Netzwerkprobleme).
      // Gibt den Fehler auf der Konsole aus.
      print('Netzwerkfehler: $e');
      // Gibt ebenfalls eine leere Liste zurück, um die App stabil zu halten.
      return [];
    }
  }
}