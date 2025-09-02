// lib/features/event_import_export/event_backup_restorer.dart

import 'package:flutter/material.dart';
import '../../models/event.dart';
import '../../services/calendar_service.dart';
import '../../services/storage_service.dart';
import '../../services/notification_service.dart'; // Import hinzufügen
//import '../../utils/app_colors.dart'; // Sicherstellen, dass AppColors importiert wird

class EventBackupRestorer {
  final CalendarService _calendarService;
  final StorageService _storageService;
  final Function() _onEventsRestored; // Callback, um Daten im UI neu zu laden
  final Function(SnackBar) _showSnackBar; // Callback, um SnackBar anzuzeigen
  final Future<String?> Function(Widget content)
  _showConfirmationDialog; // Callback für den Dialog

  EventBackupRestorer({
    required CalendarService calendarService,
    required StorageService storageService,
    required Function() onEventsRestored,
    required Function(SnackBar) showSnackBar,
    required Future<String?> Function(Widget content) showConfirmationDialog,
  }) : _calendarService = calendarService,
       _storageService = storageService,
       _onEventsRestored = onEventsRestored,
       _showSnackBar = showSnackBar,
       _showConfirmationDialog = showConfirmationDialog;

  /// Erstellt ein internes Backup der aktuellen Termine im JSON-Format.
  Future<void> createBackup(List<Event> userEvents) async {
    if (userEvents.isEmpty) {
      _showSnackBar(
        const SnackBar(
          content: Text('Es sind keine Termine für ein Backup vorhanden.'),
        ),
      );
      return;
    }
    await _calendarService.createInternalBackup(userEvents);
    _showSnackBar(
      const SnackBar(content: Text('Backup erfolgreich erstellt.')),
    );
  }

  /// Stellt Termine aus einem internen JSON-Backup wieder her.
  Future<void> restoreBackup() async {
    final List<Event> restoredEvents = await _calendarService
        .restoreFromInternalBackup();

    if (restoredEvents.isEmpty) {
      _showSnackBar(
        const SnackBar(
          content: Text('Wiederherstellung abgebrochen oder Datei ungültig.'),
        ),
      );
      return;
    }

    final choice = await _showConfirmationDialog(
      const Text('Wie möchtest du das Backup einspielen?'),
    );

    if (choice == null) return; // Dialog abgebrochen

    // Vor dem Hinzufügen/Ersetzen alle bestehenden Benachrichtigungen abbrechen,
    // um Duplikate oder veraltete Benachrichtigungen zu vermeiden.
    // Dies ist wichtig, wenn man alle Termine ersetzt.
    if (choice == 'replace') {
      await _storageService.clearAllEvents();
      // Auch alle Benachrichtigungen löschen, da alle alten Events weg sind.
      // Hinweis: NotificationService().cancelAllReminders() wäre ideal,
      // aber ist hier nicht vorhanden. Man müsste dies eventuell implementieren
      // oder sich auf die Benachrichtigungen der hinzugefügten Events konzentrieren.
    }

    for (final event in restoredEvents) {
      await _storageService.addEvent(event);
      // NEU: Benachrichtigungen für wiederhergestellte Events planen
      final int notificationId = event.id.hashCode;
      NotificationService().scheduleReminders(
        notificationId,
        event.title,
        event.date,
      );
    }
    await _onEventsRestored(); // UI informieren, dass Daten neu geladen werden müssen

    _showSnackBar(
      SnackBar(
        content: Text('${restoredEvents.length} Termin(e) wiederhergestellt.'),
      ),
    );
  }
}
