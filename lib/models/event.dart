// lib/models/event.dart

import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';
import '../utils/app_colors.dart';

part 'event.g.dart';

// =======================================================================
// ==================== HIER BEGINNEN DIE ÄNDERUNGEN =====================
// =======================================================================

// Hilfsfunktionen für das Datum, die von @JsonKey verwendet werden
// Speichert das Datum als ISO-String in der universellen UTC-Zeitzone.
String _dateToJson(DateTime date) => date.toUtc().toIso8601String();

// Liest das Datum als String und konvertiert es sofort in die lokale Zeit des Geräts.
// Dies ist die entscheidende Korrektur für das Zeitzonen-Problem.
DateTime _dateFromJson(String dateString) =>
    DateTime.parse(dateString).toLocal();

// Hilfsfunktionen für die Farbe, die von @JsonKey verwendet werden
//int _colorToJson(Color color) => color.value;
int _colorToJson(Color color) => color.toARGB32();
Color _colorFromJson(int value) => Color(value);

// =======================================================================
// ===================== HIER ENDEN DIE ÄNDERUNGEN =======================
// =======================================================================

@JsonSerializable()
class Event {
  final String id;
  final String title;
  final String? description;
  final bool isHoliday;

  // Wende die benutzerdefinierte Konvertierungsfunktion auf das 'date'-Feld an.
  @JsonKey(toJson: _dateToJson, fromJson: _dateFromJson)
  final DateTime date;

  // Wende die benutzerdefinierte Konvertierungsfunktion auf das 'color'-Feld an.
  @JsonKey(toJson: _colorToJson, fromJson: _colorFromJson)
  final Color color;

  Event({
    required this.id,
    required this.title,
    this.description,
    required this.date,
    this.isHoliday = false,
    this.color = AppColors.lightBlue,
  });

  factory Event.fromJson(Map<String, dynamic> json) => _$EventFromJson(json);

  Map<String, dynamic> toJson() => _$EventToJson(this);
}
