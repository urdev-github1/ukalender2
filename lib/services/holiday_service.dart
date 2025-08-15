// lib/services/holiday_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/event.dart';
import 'package:flutter/material.dart';

// Dieser Service ruft die Feiertage von einer öffentlichen API ab. Hier wird beispielhaft die api.feiertage-api.de genutzt.
class HolidayService {
  Future<List<Event>> getHolidays(int year, String stateCode) async {
    // stateCode z.B. "BY" für Bayern, "NW" für NRW
    final url = Uri.parse('https://feiertage-api.de/api/?jahr=$year&nur_land=$stateCode');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<Event> holidays = [];
        data.forEach((key, value) {
          holidays.add(Event(
            title: key,
            date: DateTime.parse(value['datum']),
            isHoliday: true,
            color: Colors.green,
          ));
        });
        return holidays;
      } else {
        // Fehlerbehandlung
        return [];
      }
    } catch (e) {
      // Fehlerbehandlung für Netzwerkprobleme
      print(e);
      return [];
    }
  }
}