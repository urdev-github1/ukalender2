// lib/models/event.dart

import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';
import '../utils/app_colors.dart';

part 'event.g.dart';

// Benutzerdefinierte Serialisierungsfunktionen
String _dateToJson(DateTime date) => date.toUtc().toIso8601String();

// Datum als ISO8601 String speichern und in lokale Zeit umwandeln
DateTime _dateFromJson(String dateString) =>
    DateTime.parse(dateString).toLocal();

// Farbe als ARGB int speichern
int _colorToJson(Color color) => color.toARGB32();
Color _colorFromJson(int value) => Color(value);

// Bool als int (0/1) speichern
int _boolToInt(bool b) => b ? 1 : 0;
bool _intToBool(int i) => i == 1;

/// Event Modell mit JSON-Serialisierung
@JsonSerializable()
class Event {
  final String id;
  final String title;
  final String? description;

  // Feiertag als int (0/1) in der DB speichern
  @JsonKey(toJson: _boolToInt, fromJson: _intToBool)
  final bool isHoliday;

  // Geburtstag als int (0/1) in der DB speichern
  @JsonKey(defaultValue: false, toJson: _boolToInt, fromJson: _intToBool)
  final bool isBirthday;

  // Datum als ISO8601 String in der DB speichern
  @JsonKey(toJson: _dateToJson, fromJson: _dateFromJson)
  final DateTime date;

  // Farbe als ARGB int in der DB speichern
  @JsonKey(toJson: _colorToJson, fromJson: _colorFromJson)
  final Color color;

  // Konstruktor
  Event({
    required this.id,
    required this.title,
    this.description,
    required this.date,
    this.isHoliday = false,
    this.isBirthday = false,
    this.color = AppColors.lightBlue,
  });

  // JSON-Deserialisierung (Ein Event-Objekt aus einem Json erzeugen.)
  factory Event.fromJson(Map<String, dynamic> json) => _$EventFromJson(json);

  // JSON-Serialisierung (Ein Json aus einem Event-Objekt erzeugen.)
  Map<String, dynamic> toJson() => _$EventToJson(this);

  // Kopiert das Event mit optionalen neuen Werten
  Event copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? date,
    bool? isHoliday,
    bool? isBirthday,
    Color? color,
  }) {
    return Event(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      date: date ?? this.date,
      isHoliday: isHoliday ?? this.isHoliday,
      isBirthday: isBirthday ?? this.isBirthday,
      color: color ?? this.color,
    );
  }
}
