// lib/features/event_import_export/event_importer.dart

import 'package:flutter/material.dart';
import '../../models/event.dart';
import '../../services/calendar_service.dart';
import '../../services/storage_service.dart';
import '../../services/notification_service.dart'; // Import hinzufügen

class EventImporter {
  final CalendarService _calendarService;
  final StorageService _storageService;
  final Function() _onEventsImported; // Callback, um Daten im UI neu zu laden
  final Function(SnackBar) _showSnackBar; // Callback, um SnackBar anzuzeigen

  EventImporter({
    required CalendarService calendarService,
    required StorageService storageService,
    required Function() onEventsImported,
    required Function(SnackBar) showSnackBar,
  }) : _calendarService = calendarService,
       _storageService = storageService,
       _onEventsImported = onEventsImported,
       _showSnackBar = showSnackBar;

  Future<void> importEvents() async {
    final List<Event> importedEvents = await _calendarService
        .importEventsFromPicker();

    if (importedEvents.isNotEmpty) {
      for (final event in importedEvents) {
        await _storageService.addEvent(event);
        // NEU: Benachrichtigungen für importierte Events planen
        final int notificationId = event.id.hashCode;
        NotificationService().scheduleReminders(
          notificationId,
          event.title,
          event.date,
        );
      }
      await _onEventsImported(); // UI informieren, dass Daten neu geladen werden müssen
      _showSnackBar(
        SnackBar(
          content: Text(
            '${importedEvents.length} Termin(e) erfolgreich importiert/aktualisiert.',
          ),
        ),
      );
    } else {
      _showSnackBar(
        const SnackBar(
          content: Text('Import abgebrochen oder keine Termine gefunden.'),
        ),
      );
    }
  }
}
