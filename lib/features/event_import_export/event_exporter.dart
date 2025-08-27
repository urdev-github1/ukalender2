// lib/features/event_import_export/event_exporter.dart

import 'package:flutter/material.dart';
import '../../models/event.dart';
import '../../services/calendar_service.dart';

class EventExporter {
  final CalendarService _calendarService;
  final Function(SnackBar) _showSnackBar;

  EventExporter({
    required CalendarService calendarService,
    required Function(SnackBar) showSnackBar,
  }) : _calendarService = calendarService,
       _showSnackBar = showSnackBar;

  Future<void> exportEvents(List<Event> userEvents) async {
    if (userEvents.isEmpty) {
      _showSnackBar(
        const SnackBar(
          content: Text('Es sind keine Termine zum Exportieren vorhanden.'),
        ),
      );
      return;
    }
    await _calendarService.exportEvents(userEvents);
    _showSnackBar(
      const SnackBar(content: Text('Termine erfolgreich exportiert.')),
    );
  }
}
