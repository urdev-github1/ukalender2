// lib/utils/calendar_color_logic.dart

import 'package:flutter/material.dart';
import '../models/event.dart';
import '../utils/app_colors.dart';

/// Logik zur Bestimmung der Farben von Kalenderereignissen.
class CalendarColorLogic {
  /// Bestimmt die Farbe eines Ereignisses basierend auf seinem Datum.
  static Color getEventColor(Event event) {
    // Feiertage behalten ihre definierte Farbe
    if (event.isHoliday) {
      return event.color;
    }

    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    final DateTime eventDate = DateTime(
      event.date.year,
      event.date.month,
      event.date.day,
    );

    // Ereignisse in der Vergangenheit erhalten eine grüne Farbe
    if (eventDate.isBefore(today)) {
      return AppColors.pastEvent;
    }

    return event.color;
  }
}
