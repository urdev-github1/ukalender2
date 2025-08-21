// lib/models/event.dart

import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';
import '../utils/app_colors.dart';

part 'event.g.dart';

@JsonSerializable()
class Event {
  final String id; // Wird in der DB als TEXT PRIMARY KEY gespeichert
  final String title; // Wird in der DB als TEXT gespeichert
  final String?
  description; // Wird in der DB als TEXT (kann NULL sein) gespeichert
  final DateTime date; // Wird als TEXT (ISO-8601 String) in der DB gespeichert
  final bool isHoliday; // Wird als INTEGER (0 oder 1) in der DB gespeichert

  @JsonKey(toJson: _colorToJson, fromJson: _colorFromJson)
  final Color color; // Wird als INTEGER (der Farbwert) in der DB gespeichert

  Event({
    required this.id,
    required this.title,
    this.description,
    required this.date,
    this.isHoliday = false,
    this.color = AppColors.lightBlue,
  });

  // Diese Factory wird von der Datenbank-Hilfsklasse (getAllEvents) verwendet,
  // um aus einer Map<String, dynamic> wieder ein Event-Objekt zu erstellen.
  factory Event.fromJson(Map<String, dynamic> json) => _$EventFromJson(json);

  // Diese Methode wird von der Datenbank-Hilfsklasse (insertEvent, updateEvent) verwendet,
  // um das Event-Objekt in eine Map<String, dynamic> umzuwandeln, die sqflite versteht.
  Map<String, dynamic> toJson() => _$EventToJson(this);
}

// Hilfsfunktionen für die Farbe, die von @JsonKey verwendet werden
int _colorToJson(Color color) => color.value;
Color _colorFromJson(int value) => Color(value);
