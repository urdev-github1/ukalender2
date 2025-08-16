// lib/utils/app_colors.dart

import 'package:flutter/material.dart';

// Diese Klasse dient als zentrale Anlaufstelle für die in der App
// verwendeten Event-Farben. Dies erleichtert die Wartung und sorgt
// für Konsistenz.
class AppColors {
  // Definition der 7 Event-Farben basierend auf den HEX-Werten.
  // In Flutter wird dem HEX-Wert '0xFF' vorangestellt, um ihn als
  // Farbe mit voller Deckkraft zu kennzeichnen.
  static const Color orange = Color(0xFFFF5929); // HEX: #ff5929
  static const Color green = Color(0xFF00854D); // HEX: #00854d
  static const Color grey = Color(0xFF636363); // HEX: #636363
  static const Color violet = Color(0xFFAB54B2); // HEX: #ab54b2
  static const Color red = Color(0xFFDF0E07); // HEX: #df0e07
  static const Color blue = Color(0xFF404DAD); // HEX: #404dad
  static const Color lightBlue = Color(0xFF00A1EA); // HEX: #00a1ea

  // Eine statische Liste, die alle verfügbaren Event-Farben enthält.
  // Diese Liste wird im "AddEventScreen" verwendet, um die
  // Farbauswahl-Widgets dynamisch zu generieren.
  static const List<Color> eventColors = [
    orange,
    green,
    grey,
    violet,
    red,
    blue,
    lightBlue,
  ];
}
