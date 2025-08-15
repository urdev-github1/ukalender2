// lib/models/event.dart

// Importiert die Material-Design-Bibliothek von Flutter.
// Diese wird hier insbesondere für den Datentyp 'Color' benötigt.
import 'package:flutter/material.dart';

/// Ein einfaches Datenmodell, das einen Termin oder einen Feiertag repräsentiert.
/// Klassen wie diese werden verwendet, um Daten strukturiert zu speichern und im Code
/// einfacher handhaben zu können.
class Event {
  // Der Titel des Termins (z.B. "Team-Meeting").
  // 'final' bedeutet, dass dieser Wert nach der Erstellung des Objekts nicht mehr geändert werden kann.
  final String title;

  // Eine optionale Beschreibung für den Termin.
  // Das Fragezeichen '?' bedeutet, dass dieser Wert 'null' sein kann (also nicht zwingend angegeben werden muss).
  final String? description;

  // Das Datum des Termins. Der Datentyp 'DateTime' speichert Datum und Uhrzeit.
  final DateTime date;

  // Ein boolescher Wert (wahr/falsch), der angibt, ob es sich um einen Feiertag handelt.
  // Standardmäßig ist dieser Wert auf 'false' gesetzt.
  final bool isHoliday;

  // Die Farbe, die mit dem Termin im Kalender angezeigt werden soll.
  // Standardmäßig ist die Farbe Blau ('Colors.blue').
  final Color color;

  // Dies ist der Konstruktor der Klasse. Er wird aufgerufen, um ein neues 'Event'-Objekt zu erstellen.
  // Die geschweiften Klammern {} definieren benannte Parameter, was den Code lesbarer macht.
  Event({
    // 'required' bedeutet, dass dieser Parameter bei der Erstellung eines Objekts angegeben werden muss.
    required this.title,
    this.description, // Dieser Parameter ist optional, da er kein 'required' hat.
    required this.date,
    this.isHoliday = false, // Optionaler Parameter mit einem Standardwert von 'false'.
    this.color = Colors.blue, // Optionaler Parameter mit einem Standardwert von 'Colors.blue'.
  });

  // Diese Methode überschreibt die standardmäßige 'toString()'-Methode.
  // Wenn man nun ein 'Event'-Objekt z.B. mit print() ausgibt,
  // wird anstelle von "Instance of 'Event'" direkt der Titel des Termins angezeigt.
  // Das ist besonders nützlich für Debugging-Zwecke.
  @override
  String toString() => title;
}