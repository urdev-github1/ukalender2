// lib/services/calendar_service.dart

import 'dart:io';
import 'dart:convert'; // Für JSON-Kodierung und -Dekodierung
import 'package:add_2_calendar/add_2_calendar.dart' as a2c;
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:icalendar_parser/icalendar_parser.dart' as ical_parser;
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../models/event.dart' as my_event;

/// Service-Klasse für Kalenderbezogene Funktionen wie Export, Import und Backup von Terminen.
class CalendarService {
  final Uuid _uuid = const Uuid();

  /// Fügt ein Ereignis zum Gerätekalender hinzu.
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

  /// Exportiert eine Liste von Ereignissen in eine .ics-Datei und teilt diese Datei.
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

  // ANGEPASST: Umbenannt, um den Zweck (File Picker) klarer zu machen.
  /// Importiert Ereignisse aus einer vom Benutzer über den Datei-Picker ausgewählten .ics-Datei.
  Future<List<my_event.Event>> importEventsFromPicker() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.any,
    );

    if (result == null || result.files.single.path == null) {
      return []; // Benutzer hat den Dialog abgebrochen
    }

    final path = result.files.single.path!;

    // Ruft die neue, wiederverwendbare Methode zur Verarbeitung der Datei auf.
    return parseIcsFile(path);
  }

  // NEU: Die gesamte Parsing-Logik wurde in diese wiederverwendbare Methode ausgelagert.
  /// Parst eine .ics-Datei vom gegebenen Pfad und gibt eine Liste von Events zurück.
  /// Diese Methode wird sowohl vom File Picker als auch vom Share Handler verwendet.
  Future<List<my_event.Event>> parseIcsFile(String path) async {
    // Überprüfen, ob es sich um eine .ics-Datei handelt.
    if (!path.toLowerCase().endsWith('.ics')) {
      //print('CalendarService [ERROR]: Datei ist keine .ics-Datei: $path');
      return [];
    }

    final file = File(path);
    final List<my_event.Event> importedEvents = [];

    try {
      if (!await file.exists()) {
        //print('CalendarService [ERROR]: Datei existiert nicht am Pfad: $path');
        return [];
      }

      final icsString = await file.readAsString();
      final iCalendar = ical_parser.ICalendar.fromString(icsString);

      if (iCalendar.data.isEmpty) {
        // print(
        //   'CalendarService [WARN]: ICS-Datei ist gültig, enthält aber keine Termine.',
        // );
        return [];
      }

      for (var data in iCalendar.data) {
        try {
          if (!data.containsKey('dtstart')) {
            continue; // Ungültiger Eintrag ohne Startdatum
          }
          final ical_parser.IcsDateTime? icsDate = data['dtstart'];
          final DateTime? startDate = icsDate?.toDateTime();
          if (startDate == null) {
            continue; // Ungültiges Startdatum
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
          //   'CalendarService [WARN]: Überspringe fehlerhaften Eintrag im ICS: $e',
          // );
          continue;
        }
      }
      // print(
      //   'CalendarService [SUCCESS]: ${importedEvents.length} Termin(e) erfolgreich geparst.',
      // );
      return importedEvents;
    } catch (e) {
      // print(
      //   'CalendarService [CRITICAL ERROR]: Fehler beim Parsen der ICS-Datei: $e',
      // );
      return [];
    }
  }

  /// Erstellt ein vollständiges, app-internes Backup aller User-Termine in einer JSON-Datei.
  Future<void> createInternalBackup(List<my_event.Event> events) async {
    if (events.isEmpty) {
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
        return [];
      }
    }
    return [];
  }
}
