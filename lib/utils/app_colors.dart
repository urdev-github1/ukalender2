// lib/utils/app_colors.dart

import 'package:flutter/material.dart';

/// Definiert eine Sammlung von Farben, die in der App verwendet werden.
class AppColors {
  static const Color orange = Color(0xFFFF5929); // HEX: #ff5929
  static const Color green = Color(0xFF00854D); // HEX: #00854d
  static const Color grey = Color(0xFF636363); // HEX: #636363
  static const Color violet = Color(0xFFAB54B2); // HEX: #ab54b2
  static const Color red = Color(0xFFDF0E07); // HEX: #df0e07
  static const Color blue = Color(0xFF404DAD); // HEX: #404dad
  static const Color lightBlue = Color(0xFF00A1EA); // HEX: #00a1ea

  // Abfrage im AddEventScreen
  static const Color birthdayColor = violet;
  static const Color defaultEventColor = lightBlue;

  /// Liste von Farben, die für Ereignisse verwendet werden können.
  static const List<Color> eventColors = [
    orange,
    green,
    grey,
    violet,
    red,
    blue,
    lightBlue,
  ];

  // Kalender-spezifische Farben
  static const Color pastEvent = Color(0xFF00854D);
  static const Color holidayBackground = Color(
    0x2600854D,
  ); // green.withAlpha(38)
  static const Color holidayText = Color(
    0xFF004D2B,
  ); // Etwas dunkleres Grün für Text
  static Color weekendDay = Colors.red.withAlpha(204);

  // UI-Element Farben
  static const Color floatingActionButton = Color.fromARGB(255, 131, 185, 201);
}
