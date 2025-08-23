// lib/services/calendar_service.dart

// Import von Dart-Standardbibliotheken
import 'dart:io';
import 'dart:convert'; // Für JSON-Kodierung und -Dekodierung

// Import von Drittanbieter-Paketen
import 'package:add_2_calendar/add_2_calendar.dart' as a2c;
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:icalendar_parser/icalendar_parser.dart' as ical_parser;
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

// Import des eigenen Event-Modells
import '../models/event.dart' as my_event;

/// CalendarService ist eine Klasse, die alle Operationen im Zusammenhang mit
/// dem Gerätekalender und dem Import/Export von Terminen kapselt.
class CalendarService {
  final Uuid _uuid = const Uuid();

  /// Fügt ein einzelnes Event zum nativen Kalender des Geräts hinzu.
  Future<void> addToDeviceCalendar(my_event.Event event) async {
    final a2c.Event a2cEvent = a2c.Event(
      title: event.title,
      description: event.description ?? '',
      startDate: event.date,
      endDate: event.date.add(const Duration(hours: 1)),
      allDay: event.isBirthday,
    );
    await a2c.Add2Calendar.addEvent2Cal(a2cEvent);
  }

  // =======================================================================
  // ==== METHODEN FÜR .ICS (KOMPATIBILITÄT MIT ANDEREN KALENDERN) =========
  // =======================================================================

  /// Exportiert eine Liste von Events durch manuelles Erstellen des iCalendar-Strings.
  Future<void> exportEvents(List<my_event.Event> events) async {
    final StringBuffer icsContent = StringBuffer();

    icsContent.writeln('BEGIN:VCALENDAR');
    icsContent.writeln('VERSION:2.0');
    icsContent.writeln('PRODID:-//My Flutter App//DE');

    String escapeText(String? text) {
      if (text == null || text.isEmpty) return '';
      return text.replaceAll('\n', '\\n');
    }

    for (var event in events) {
      if (event.isHoliday) continue;

      final uid = event.id;
      final title = escapeText(event.title);
      final description = escapeText(event.description);
      final dtstamp = DateFormat(
        "yyyyMMdd'T'HHmmss'Z'",
      ).format(DateTime.now().toUtc());

      icsContent.writeln('BEGIN:VEVENT');
      icsContent.writeln('UID:$uid@meine.app');
      icsContent.writeln('DTSTAMP:$dtstamp');
      icsContent.writeln('SUMMARY:$title');
      if (description.isNotEmpty) {
        icsContent.writeln('DESCRIPTION:$description');
      }

      if (event.isBirthday) {
        final date = event.date;
        final nextDay = DateTime(
          date.year,
          date.month,
          date.day,
        ).add(const Duration(days: 1));
        final dtstart = DateFormat('yyyyMMdd').format(date);
        final dtend = DateFormat('yyyyMMdd').format(nextDay);
        icsContent.writeln('DTSTART;VALUE=DATE:$dtstart');
        icsContent.writeln('DTEND;VALUE=DATE:$dtend');
        icsContent.writeln('RRULE:FREQ=YEARLY');
      } else {
        final dtstart = DateFormat(
          "yyyyMMdd'T'HHmmss'Z'",
        ).format(event.date.toUtc());
        final dtend = DateFormat(
          "yyyyMMdd'T'HHmmss'Z'",
        ).format(event.date.add(const Duration(hours: 1)).toUtc());
        icsContent.writeln('DTSTART:$dtstart');
        icsContent.writeln('DTEND:$dtend');
      }

      icsContent.writeln('END:VEVENT');
    }

    icsContent.writeln('END:VCALENDAR');

    final directory = await getTemporaryDirectory();
    final timestamp = DateFormat('yyMMdd-HHmm').format(DateTime.now());
    final path = '${directory.path}/Termine_$timestamp.ics';
    final file = File(path);
    await file.writeAsString(icsContent.toString());

    await SharePlus.instance.share(
      ShareParams(text: 'Hier sind deine Termine', files: [XFile(path)]),
    );
  }

  // =======================================================================
  // ==================== HIER IST DIE ÜBERARBEITETE FUNKTION ================
  // =======================================================================
  /// Temporäre Debug-Version von importEvents, um das Problem einzugrenzen.
  Future<List<my_event.Event>> importEvents() async {
    //print("--- Starte den ICS-Import-Prozess ---");

    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.any,
    );

    if (result == null || result.files.single.path == null) {
      //print("Import abgebrochen: Keine Datei ausgewählt.");
      return [];
    }

    final path = result.files.single.path!;
    final file = File(path);
    final List<my_event.Event> importedEvents = [];

    //print("Datei ausgewählt: $path");

    try {
      final icsString = await file.readAsString();
      // print(
      //   "Datei erfolgreich gelesen. Inhalt hat ${icsString.length} Zeichen.",
      // );

      final iCalendar = ical_parser.ICalendar.fromString(icsString);
      // print(
      //   "ICS-Datei geparst. Anzahl der gefundenen Roh-Events: ${iCalendar.data.length}",
      // );

      if (iCalendar.data.isEmpty) {
        //print("WARNUNG: Keine Event-Einträge (VEVENT) in der Datei gefunden.");
        return [];
      }

      // Wir geben nur das erste Event aus, um die Konsole nicht zu überfluten
      bool firstEventPrinted = false;

      for (var data in iCalendar.data) {
        if (!firstEventPrinted) {
          // print("\n--- Inhalt des ersten Roh-Events ---");
          // print(data);
          // print("----------------------------------\n");
          firstEventPrinted = true;
        }

        try {
          if (!data.containsKey('dtstart')) {
            //print("Event wird übersprungen: Kein 'dtstart'-Feld gefunden.");
            continue;
          }

          // **Hier ist der kritische Punkt:** Was ist der Typ von 'dtstart'?
          // print(
          //   "Verarbeite Event... 'dtstart' ist vom Typ: ${data['dtstart'].runtimeType}",
          // );

          final ical_parser.IcsDateTime? icsDate = data['dtstart'];
          final DateTime? startDate = icsDate?.toDateTime();

          if (startDate == null) {
            // print(
            //   "FEHLER: Datum konnte nicht verarbeitet werden. 'startDate' ist null. Event wird übersprungen.",
            // );
            continue;
          }

          final bool isYearly =
              data['rrule']?.toString().contains('FREQ=YEARLY') ?? false;

          importedEvents.add(
            my_event.Event(
              id: data['uid']?.toString() ?? _uuid.v4(),
              title: data['summary']?.toString() ?? '(Ohne Titel)',
              description: data['description']?.toString() ?? '',
              date: startDate.toLocal(),
              isBirthday: isYearly,
            ),
          );
        } catch (e) {
          // print(
          //   "FEHLER bei der Verarbeitung eines einzelnen Events: $e. Wird übersprungen.",
          // );
          continue;
        }
      }

      // print(
      //   "--- Import abgeschlossen. ${importedEvents.length} Events wurden erfolgreich verarbeitet. ---",
      // );
      return importedEvents;
    } catch (e) {
      //print("FATALER FEHLER beim Lesen oder Parsen der gesamten Datei: $e");
      return [];
    }
  }

  // =======================================================================
  // === METHODEN FÜR APP-INTERNES BACKUP/RESTORE (VERLUSTFREI) ======
  // =======================================================================

  /// Erstellt ein vollständiges, app-internes Backup aller User-Termine in einer JSON-Datei.
  Future<void> createInternalBackup(List<my_event.Event> events) async {
    if (events.isEmpty) {
      //print("Keine Termine zum Sichern vorhanden.");
      return;
    }

    final List<Map<String, dynamic>> jsonList = events
        .map((event) => event.toJson())
        .toList();

    const jsonEncoder = JsonEncoder.withIndent('  ');
    final jsonString = jsonEncoder.convert(jsonList);

    final directory = await getTemporaryDirectory();
    final timestamp = DateFormat('yyMMdd-HHmm').format(DateTime.now());
    final path = '${directory.path}/kalender_backup_$timestamp.json';
    final file = File(path);
    await file.writeAsString(jsonString);

    await SharePlus.instance.share(
      ShareParams(text: 'Mein Kalender-Backup', files: [XFile(path)]),
    );
  }

  /// Stellt Termine aus einer app-internen JSON-Backup-Datei wieder her.
  Future<List<my_event.Event>> restoreFromInternalBackup() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );

    if (result != null && result.files.single.path != null) {
      final path = result.files.single.path!;
      final file = File(path);

      try {
        final jsonString = await file.readAsString();
        final List<dynamic> jsonList = jsonDecode(jsonString);

        final List<my_event.Event> restoredEvents = jsonList
            .map(
              (json) => my_event.Event.fromJson(json as Map<String, dynamic>),
            )
            .toList();

        return restoredEvents;
      } catch (e) {
        //print('Fehler beim Wiederherstellen des Backups: $e');
        return [];
      }
    }
    return [];
  }
}
