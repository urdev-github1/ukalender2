// lib/models/event.dart

// Grundlegende UI-Komponenten importieren.
import 'package:flutter/material.dart';

// Importiert das Paket für die JSON-Annotationen. Diese werden benötigt,
// um dem Code-Generator mitzuteilen, wie die JSON-(De-)Serialisierung
// durchgeführt werden soll. 
import 'package:json_annotation/json_annotation.dart';

// Dies deklariert, dass die aktuelle Datei ein Teil einer anderen Datei ist.
// Diese '.g.dart'-Datei wird automatisch durch ein Build-Tool (build_runner)
// generiert und enthält die eigentliche Logik für die JSON-Umwandlung.
part 'event.g.dart'; 

// Die @JsonSerializable-Annotation markiert diese Klasse für den Code-Generator.
@JsonSerializable()
class Event {
  // 'final' bedeutet, dass diese Werte nach der Erstellung eines Event-Objekts 
  // nicht mehr geändert werden können.
  final String title;        // Der Titel des Events, muss angegeben werden.
  final String? description; // Eine optionale Beschreibung (kann null sein).
  final DateTime date;       // Das Datum des Events, muss angegeben werden.
  final bool isHoliday;      // Ein Flag, ob es sich um einen Feiertag handelt.

  // Die @JsonKey-Annotation ermöglicht eine benutzerdefinierte Konvertierung
  // für ein bestimmtes Feld. Da 'Color' kein Standard-JSON-Typ ist,
  // werden hier spezielle Funktionen zur Umwandlung bereitgestellt. 
  @JsonKey(
    toJson: _colorToJson,    // Diese Funktion wird aufgerufen, um das 'Color'-Objekt in ein JSON-Format (hier: int) umzuwandeln.
    fromJson: _colorFromJson, // Diese Funktion wird aufgerufen, um einen Wert aus JSON zurück in ein 'Color'-Objekt zu konvertieren.
  )

  final Color color;

  // Der Konstruktor der Klasse 'Event'.
  Event({
    required this.title,        // 'title' ist ein erforderlicher benannter Parameter.
    this.description,           // 'description' ist optional.
    required this.date,         // 'date' ist erforderlich.
    this.isHoliday = false,     // 'isHoliday' hat einen Standardwert von 'false'.
    this.color = Colors.blue, // 'color' hat einen Standardwert von Blau.
  });

  // Eine sogenannte "Factory"-Konstruktor-Methode, die ein neues 'Event'-Objekt
  // aus einer JSON-Struktur (repräsentiert als Map<String, dynamic>) erstellt. 
  // Sie ruft die generierte Funktion _$EventFromJson auf, die sich in 'event.g.dart' befindet.
  factory Event.fromJson(Map<String, dynamic> json) => _$EventFromJson(json);

  // Eine Methode, die das aktuelle 'Event'-Objekt in eine JSON-Map umwandelt. 
  // Sie ruft die generierte Funktion _$EventToJson auf, die sich ebenfalls in 'event.g.dart' befindet.
  Map<String, dynamic> toJson() => _$EventToJson(this);

  // Überschreibt die standardmäßige 'toString()'-Methode. Wenn ein 'Event'-Objekt
  // in einen String umgewandelt wird, gibt es nun den Titel zurück.
  @override
  String toString() => title;
}

// Hilfsfunktionen zur Konvertierung von 'Color', da dies kein Standard-JSON-Typ ist.
// Die Farbe wird als einzelner 32-Bit-Integer-Wert gespeichert, was in JSON problemlos möglich ist.

// Wandelt ein 'Color'-Objekt in einen Integer um (Alpha, Rot, Grün, Blau).
int _colorToJson(Color color) => color.toARGB32();
// Wandelt einen Integer-Wert zurück in ein 'Color'-Objekt.
Color _colorFromJson(int value) => Color(value);