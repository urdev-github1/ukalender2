// lib/models/event.dart

import 'package:flutter/material.dart';

// Ein einfaches Datenmodell für Termine und Feiertage.
class Event {
  final String title;
  final String? description;
  final DateTime date;
  final bool isHoliday;
  final Color color;

  Event({
    required this.title,
    this.description,
    required this.date,
    this.isHoliday = false,
    this.color = Colors.blue,
  });

  @override
  String toString() => title;
}