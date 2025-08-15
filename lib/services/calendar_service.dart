// lib/services/calendar_service.dart

// Import von Dart-Standardbibliotheken für Dateioperationen (File)
import 'dart:io';
// Import für das Paket 'add_2_calendar', um Termine zum Gerätekalender hinzuzufügen.
// Das 'as a2c' gibt dem Import einen kurzen Alias, um Namenskonflikte zu vermeiden.
import 'package:add_2_calendar/add_2_calendar.dart' as a2c;
// Import für das Paket 'file_picker', um dem Benutzer die Auswahl einer Datei zu ermöglichen.
import 'package:file_picker/file_picker.dart';
// Import für das Paket 'path_provider', um auf Verzeichnisse im Dateisystem zuzugreifen (z.B. temporäre Ordner).
import 'package:path_provider/path_provider.dart';
// Import für das Paket 'share_plus', um die systemeigene "Teilen"-Funktion aufzurufen.
import 'package:share_plus/share_plus.dart';

// Importiert zwei verschiedene Pakete zur Verarbeitung von iCalendar (.ics) Daten.
// 'icalendar_parser' wird zum Einlesen (Parsen) von .ics-Dateien verwendet.
import 'package:icalendar_parser/icalendar_parser.dart' as ical_parser;
// 'icalendar_plus' wird zum Erstellen von .ics-Dateien verwendet.
import 'package:icalendar_plus/icalendar.dart' as ical_plus;
// Importiert das eigene Event-Modell aus der App. Der Alias 'my_event' wird verwendet,
// um klare Verhältnisse zu schaffen, da auch die Kalender-Pakete eine 'Event'-Klasse haben könnten.
import '../models/event.dart' as my_event;

/// CalendarService ist eine Klasse, die alle Operationen im Zusammenhang mit
/// dem Gerätekalender und dem Import/Export von Terminen kapselt.
class CalendarService {

  /// Fügt ein einzelnes Event zum nativen Kalender des Geräts hinzu.
  /// Nimmt ein app-internes `my_event.Event`-Objekt entgegen.
  Future<void> addToDeviceCalendar(my_event.Event event) async {
    // Konvertiert das app-interne Event-Objekt in ein `Event`-Objekt,
    // das vom `add_2_calendar`-Paket verstanden wird.
    final a2c.Event a2cEvent = a2c.Event(
      title: event.title,
      description: event.description ?? '', // Stellt sicher, dass die Beschreibung nie null ist.
      startDate: event.date,
      // Das Enddatum wird hier hartcodiert auf eine Stunde nach dem Startdatum gesetzt.
      endDate: event.date.add(const Duration(hours: 1)),
    );
    // Ruft die Funktion des Pakets auf, die den "Termin hinzufügen"-Dialog des Betriebssystems öffnet.
    await a2c.Add2Calendar.addEvent2Cal(a2cEvent);
  }

  /// Exportiert eine Liste von app-internen Events in eine .ics-Datei und teilt diese.
  Future<void> exportEvents(List<my_event.Event> events) async {
    // Erstellt die Kopfzeilen für die iCalendar-Datei.
    // Diese enthalten Metadaten über die erstellende Anwendung.
    final headers = ical_plus.CalHeaders( // KORREKTUR
      prodId: '-//My Flutter App//DE',
      version: '2.0',
    );

    // Initialisiert ein iCalendar-Objekt mit den zuvor erstellten Kopfzeilen.
    final iCalendar = ical_plus.ICalendar.instance(headers); // KORREKTUR

    // Iteriert durch die übergebene Liste von Events.
    for (var event in events) {
      // Es werden nur Termine exportiert, die keine Feiertage sind.
      if (!event.isHoliday) {

        // Erstellt für jeden Termin ein iCalendar-konformes VEvent-Objekt.
        final iCalEvent = ical_plus.VEvent( // KORREKTUR
          // Eine eindeutige ID (UID) ist wichtig, damit Kalenderprogramme Termine
          // korrekt zuordnen und aktualisieren können.
          uid: '${DateTime.now().millisecondsSinceEpoch}@meine.app',
          dtstamp: DateTime.now(), // Zeitstempel der Erstellung.
          dtstart: event.date, // Startzeitpunkt des Termins.
          dtend: event.date.add(const Duration(hours: 1)), // Endzeitpunkt (hier wieder +1 Stunde).
          summary: event.title, // Der Titel des Termins.
          description: event.description, // Die Beschreibung des Termins.
        );

        // Fügt das erstellte VEvent zum iCalendar-Objekt hinzu.
        iCalendar.add(iCalEvent);
      }
    }

    // Ermittelt ein temporäres Verzeichnis auf dem Gerät, um die Datei zu speichern.
    final directory = await getTemporaryDirectory();
    final path = '${directory.path}/termine.ics'; // Definiert den vollständigen Dateipfad.
    final file = File(path); // Erstellt ein File-Objekt.
    // Serialisiert das iCalendar-Objekt in einen String im .ics-Format und schreibt diesen in die Datei.
    await file.writeAsString(iCalendar.serialize());

    // Nutzt das 'share_plus'-Paket, um den systemeigenen Teilen-Dialog zu öffnen.
    // Übergibt einen Begleittext und die erstellte .ics-Datei.
    await SharePlus.instance.share(
      ShareParams(
        text: 'Hier sind deine Termine',
        files: [XFile(path)],
      ),
    );
  }

  /// Öffnet einen Dateiauswahldialog, um eine .ics-Datei zu importieren und
  /// die darin enthaltenen Termine in eine Liste von app-internen Events umzuwandeln.
  Future<List<my_event.Event>> importEvents() async {
    // Öffnet den systemeigenen Dateimanager, um eine Datei auszuwählen.
    // `type: FileType.any` erlaubt die Auswahl jeder Art von Datei,
    // die Verarbeitung im Anschluss ist aber auf .ics ausgelegt.
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.any,
    );

    // Prüft, ob der Benutzer eine Datei ausgewählt hat (result ist nicht null).
    if (result != null) {
      final path = result.files.single.path; // Holt sich den Pfad der ausgewählten Datei.
      if (path != null) {
        final file = File(path); // Erstellt ein File-Objekt aus dem Pfad.
        final icsString = await file.readAsString(); // Liest den gesamten Inhalt der Datei als String.

        // Parst den eingelesenen String mit dem 'icalendar_parser'-Paket.
        final iCalendar = ical_parser.ICalendar.fromString(icsString);

        // Initialisiert eine leere Liste, um die importierten Events zu speichern.
        final List<my_event.Event> importedEvents = [];
        // Iteriert über alle gefundenen Datenblöcke (Termine) in der .ics-Datei.
        for (var data in iCalendar.data) {
          // Stellt sicher, dass die wichtigsten Felder ('summary' für Titel und 'dtstart' für Datum) vorhanden sind.
          if (data.containsKey('summary') && data.containsKey('dtstart')) {
            // Fügt ein neues, app-internes Event-Objekt zur Liste hinzu.
            importedEvents.add(my_event.Event(
              title: data['summary'],
              description: data['description'] ?? '', // Fallback auf leeren String, falls keine Beschreibung vorhanden.
              // Wandelt das Datum aus dem iCalendar-Format in ein Dart-natives DateTime-Objekt um.
              date: (data['dtstart'] as ical_parser.IcsDateTime).toDateTime()!,
            ));
          }
        }
        // Gibt die Liste der erfolgreich importierten Events zurück.
        return importedEvents;
      }
    }
    // Gibt eine leere Liste zurück, wenn der Benutzer keine Datei ausgewählt hat oder ein Fehler auftrat.
    return [];
  }
}