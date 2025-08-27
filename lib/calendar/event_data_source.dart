import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import '../models/event.dart';
import '../utils/calendar_color_logic.dart'; // Wichtig: Passe den Pfad an, falls anders

/// EventDataSource dient als Schnittstelle zwischen den eigenen Event-Daten
/// (Modelklasse `Event`) und dem Syncfusion-Kalender-Widget.
///
/// Sie stellt sicher, dass der Kalender weiß:
/// - Wann ein Termin startet/endet
/// - Welcher Titel angezeigt werden soll
/// - Welche Farbe der Termin hat
/// - Ob es sich um einen Ganztagstermin handelt
class EventDataSource extends CalendarDataSource {
  /// Konstruktor: Übergibt die Eventliste an die `appointments`-Eigenschaft
  /// der Basisklasse `CalendarDataSource`.
  EventDataSource(List<Event> source) {
    appointments = source;
  }

  /// Liefert den Startzeitpunkt eines Termins zurück.
  @override
  DateTime getStartTime(int index) => (appointments![index] as Event).date;

  /// Liefert den Endzeitpunkt eines Termins zurück.
  /// Standardmäßig wird hier eine Stunde nach dem Start angenommen.
  @override
  DateTime getEndTime(int index) =>
      (appointments![index] as Event).date.add(const Duration(hours: 1));

  /// Gibt den Titel (Betreff) des Termins zurück, der im Kalender angezeigt wird.
  @override
  String getSubject(int index) => (appointments![index] as Event).title;

  /// Bestimmt die Farbe des Termins im Kalender.
  @override
  Color getColor(int index) {
    final Event event = appointments![index] as Event;
    return CalendarColorLogic.getEventColor(event);
  }

  /// Definiert, ob es sich bei dem Termin um einen Ganztagstermin handelt.
  @override
  bool isAllDay(int index) {
    final Event event = appointments![index] as Event;
    return event.isHoliday || event.isBirthday;
  }
}
