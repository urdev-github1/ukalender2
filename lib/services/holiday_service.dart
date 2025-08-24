// lib/services/holiday_service.dart

import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import '../models/event.dart';

/// Dieser Service ist dafür zuständig, Feiertagsdaten von einer externen API abzurufen.
class HolidayService {
  final Uuid _uuid = const Uuid();

  /// Holt eine Liste von Feiertagen für ein bestimmtes Jahr und Bundesland.
  Future<List<Event>> getHolidays(int year, String stateCode) async {
    final url = Uri.parse(
      'https://feiertage-api.de/api/?jahr=$year&nur_land=$stateCode',
    );

    try {
      final response = await http.get(url);

      // Überprüfen, ob die Anfrage erfolgreich war
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<Event> holidays = [];
        data.forEach((key, value) {
          holidays.add(
            Event(
              id: _uuid.v4(),
              title: key,
              date: DateTime.parse(value['datum']),
              isHoliday: true,
              color: Colors.green,
            ),
          );
        });
        return holidays;
      } else {
        return [];
      }
    } catch (e, s) {
      debugPrint('Fehler beim Laden der Feiertage: $e');
      debugPrint('StackTrace: $s');
      return [];
    }
  }
}
