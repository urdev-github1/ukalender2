// lib/models/event.dart

import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';
import '../utils/app_colors.dart';

part 'event.g.dart';

// Hilfsfunktionen
String _dateToJson(DateTime date) => date.toUtc().toIso8601String();
DateTime _dateFromJson(String dateString) =>
    DateTime.parse(dateString).toLocal();

int _colorToJson(Color color) => color.toARGB32();
Color _colorFromJson(int value) => Color(value);

int _boolToInt(bool b) => b ? 1 : 0;
bool _intToBool(int i) => i == 1;

@JsonSerializable()
class Event {
  final String id;
  final String title;
  final String? description;

  @JsonKey(toJson: _boolToInt, fromJson: _intToBool)
  final bool isHoliday;

  @JsonKey(defaultValue: false, toJson: _boolToInt, fromJson: _intToBool)
  final bool isBirthday;

  @JsonKey(toJson: _dateToJson, fromJson: _dateFromJson)
  final DateTime date;

  @JsonKey(toJson: _colorToJson, fromJson: _colorFromJson)
  final Color color;

  Event({
    required this.id,
    required this.title,
    this.description,
    required this.date,
    this.isHoliday = false,
    this.isBirthday = false,
    this.color = AppColors.lightBlue,
  });

  factory Event.fromJson(Map<String, dynamic> json) => _$EventFromJson(json);

  Map<String, dynamic> toJson() => _$EventToJson(this);

  // copyWith-Methode bleibt unverändert...
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
