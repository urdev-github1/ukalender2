// lib/models/event.dart

import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';
import '../utils/app_colors.dart';

part 'event.g.dart';

@JsonSerializable()
class Event {
  // NEU: Ein eindeutiger Identifikator für jeden Termin.
  // Dies ist entscheidend für die Bearbeitung, das Löschen und die Benachrichtigungen.
  final String id;

  final String title;
  final String? description;
  final DateTime date;
  final bool isHoliday;

  @JsonKey(toJson: _colorToJson, fromJson: _colorFromJson)
  final Color color;

  // MODIFIZIERT: Der Konstruktor erfordert jetzt eine 'id'.
  Event({
    required this.id, // ID ist jetzt ein erforderlicher Parameter
    required this.title,
    this.description,
    required this.date,
    this.isHoliday = false,
    this.color = AppColors.orange,
  });

  // Die Factory und die toJson-Methode bleiben unverändert, aber der Code-Generator
  // wird sie an das neue 'id'-Feld anpassen.
  factory Event.fromJson(Map<String, dynamic> json) => _$EventFromJson(json);
  Map<String, dynamic> toJson() => _$EventToJson(this);

  @override
  String toString() => title;
}

// Hilfsfunktionen für die Farbe bleiben unverändert.
int _colorToJson(Color color) => color.value;
Color _colorFromJson(int value) => Color(value);
