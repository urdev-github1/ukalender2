// lib/services/calendar_service.dart

import 'dart:io';
import 'package:add_2_calendar/add_2_calendar.dart' as a2c;
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

// Importe mit Präfixen, um Namenskonflikte zu lösen.
import 'package:icalendar_parser/icalendar_parser.dart' as icalParser;
import 'package:icalendar_plus/icalendar.dart' as icalPlus;

import '../models/event.dart' as my_event;

class CalendarService {
  
  Future<void> addToDeviceCalendar(my_event.Event event) async {
    final a2c.Event a2cEvent = a2c.Event(
      title: event.title,
      description: event.description ?? '',
      startDate: event.date,
      endDate: event.date.add(const Duration(hours: 1)),
    );
    await a2c.Add2Calendar.addEvent2Cal(a2cEvent);
  }
  
  // Diese Funktion ist nun vollständig korrigiert.
  Future<void> exportEvents(List<my_event.Event> events) async {
    // KORREKTUR 1: Erstellen der notwendigen Kalender-Header.
    final headers = icalPlus.CalHeaders(
      prodId: '-//My Flutter App//DE',
      version: '2.0',
    );

    // Übergeben der Header an die 'instance'-Methode.
    final iCalendar = icalPlus.ICalendar.instance(headers);
    
    for (var event in events) {
      if (!event.isHoliday) { 
        
        // KORREKTUR 3: Die Klasse für ein Event heißt 'VEvent'.
        final iCalEvent = icalPlus.VEvent(
          uid: '${DateTime.now().millisecondsSinceEpoch}@meine.app', // Eindeutige ID ist empfohlen
          dtstamp: DateTime.now(),
          dtstart: event.date,
          dtend: event.date.add(const Duration(hours: 1)),
          summary: event.title,
          description: event.description,
        );

        // KORREKTUR 4: Die Methode zum Hinzufügen heißt 'add'.
        iCalendar.add(iCalEvent);
      }
    }
    
    final directory = await getTemporaryDirectory();
    final path = '${directory.path}/termine.ics';
    final file = File(path);
    await file.writeAsString(iCalendar.serialize());
    
    await Share.shareXFiles([XFile(path)], text: 'Hier sind deine Termine');
  }

  // Diese Funktion war bereits korrekt und bleibt unverändert.
  Future<List<my_event.Event>> importEvents() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.any,
    );

    if (result != null) {
      final path = result.files.single.path;
      if (path != null) {
        final file = File(path);
        final icsString = await file.readAsString();
        
        final iCalendar = icalParser.ICalendar.fromString(icsString);

        final List<my_event.Event> importedEvents = [];
        for (var data in iCalendar.data) {
          if (data.containsKey('summary') && data.containsKey('dtstart')) {
            importedEvents.add(my_event.Event(
              title: data['summary'],
              description: data['description'] ?? '',
              date: (data['dtstart'] as icalParser.IcsDateTime).toDateTime()!,
            ));
          }
        }
        return importedEvents;
      }
    }
    return [];
  }
}