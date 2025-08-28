// lib/screens/calendar_screen/widgets/calendar_main_body.dart
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:ukalender2/calendar/event_data_source.dart';
import 'package:ukalender2/models/event.dart';
import 'package:ukalender2/widgets/calendar_month_cell.dart';

class CalendarMainBody extends StatelessWidget {
  final CalendarController calendarController;
  final EventDataSource dataSource;
  final DateTime initialDisplayDate;
  final DateTime? selectedDay;
  final Function(CalendarTapDetails) onCalendarTapped;
  final List<Event> userEvents;
  final Function(Event oldEvent, Event newEvent) onUpdateEvent;
  final Function(Event event) onDeleteEvent;
  final Function(ViewChangedDetails) onViewChanged;
  final Color startColor;
  final Color endColor;
  final DateTime focusedDay;

  const CalendarMainBody({
    super.key,
    required this.calendarController,
    required this.dataSource,
    required this.initialDisplayDate,
    this.selectedDay,
    required this.onCalendarTapped,
    required this.userEvents,
    required this.onUpdateEvent,
    required this.onDeleteEvent,
    required this.onViewChanged,
    required this.startColor,
    required this.endColor,
    required this.focusedDay,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [startColor, endColor],
        ),
      ),
      padding: EdgeInsets.only(
        // Hier wird das Padding weiter angepasst, um den Kalenderinhalt anzuheben
        // Experimentieren Sie mit diesem Wert, um den besten Abstand zu finden.
        // Ein Wert von -45.0 ist ein Startpunkt, da kToolbarHeight etwa 56.0 ist.
        top: MediaQuery.of(context).padding.top + kToolbarHeight - 70.0,
      ),
      child: SfCalendar(
        controller: calendarController,
        view: CalendarView.month,
        dataSource: dataSource,
        initialDisplayDate: initialDisplayDate,
        initialSelectedDate: selectedDay,
        onTap: onCalendarTapped,
        firstDayOfWeek: 1,
        // Reduziert die Höhe des integrierten Kalender-Headers
        headerHeight: 40.0, // Standard ist 40.0. Dies verringert den Platz.
        headerStyle: CalendarHeaderStyle(
          textAlign: TextAlign.center,
          backgroundColor: Colors.transparent,
          textStyle: TextStyle(
            fontSize:
                18, // Gegebenenfalls Schriftgröße anpassen, wenn Header kleiner wird
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        monthCellBuilder: (context, details) {
          return CalendarMonthCell(
            details: details,
            focusedDay: focusedDay,
            selectedDay: selectedDay,
            userEvents: userEvents,
            onUpdateEvent: onUpdateEvent,
            onDeleteEvent: onDeleteEvent,
          );
        },
        monthViewSettings: const MonthViewSettings(
          appointmentDisplayMode: MonthAppointmentDisplayMode.none,
          numberOfWeeksInView: 6,
          showAgenda: false,
        ),
        onViewChanged: onViewChanged,
      ),
    );
  }
}
