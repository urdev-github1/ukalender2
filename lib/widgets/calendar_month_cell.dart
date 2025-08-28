// lib/widgets/calendar_month_cell

import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import '../models/event.dart';
import '../screens/add_event_screen.dart'; // Für AddEventScreen
import '../utils/app_colors.dart';
import '../utils/calendar_color_logic.dart';

/// Ein Widget, das die Darstellung einer einzelnen Monatszelle im Kalender übernimmt.
class CalendarMonthCell extends StatelessWidget {
  final MonthCellDetails details;
  final DateTime focusedDay; // Wird für isCurrentMonth benötigt
  final DateTime? selectedDay; // Wird für isSelected benötigt
  final List<Event>
  userEvents; // Wird benötigt, um originalEvent für Tap zu finden
  final Function(Event originalEvent, Event newEvent) onUpdateEvent;
  final Function(Event eventToDelete) onDeleteEvent;

  const CalendarMonthCell({
    super.key,
    required this.details,
    required this.focusedDay,
    required this.selectedDay,
    required this.userEvents,
    required this.onUpdateEvent,
    required this.onDeleteEvent,
  });

  @override
  Widget build(BuildContext context) {
    final DateTime now = DateTime.now();
    final bool isToday =
        details.date.year == now.year &&
        details.date.month == now.month &&
        details.date.day == now.day;
    final bool isHoliday = details.appointments.any(
      (appointment) => (appointment as Event).isHoliday,
    );
    final bool isWeekend =
        details.date.weekday == DateTime.saturday ||
        details.date.weekday == DateTime.sunday;
    final bool isCurrentMonth = details.date.month == focusedDay.month;
    final bool isSelected =
        selectedDay != null &&
        selectedDay!.year == details.date.year &&
        selectedDay!.month == details.date.month &&
        selectedDay!.day == details.date.day;

    Color dayNumberColor;
    if (isSelected) {
      dayNumberColor = AppColors.dayNumberColor;
    } else if (!isCurrentMonth) {
      dayNumberColor = AppColors.dayNumberInactive;
    } else if (isWeekend && !isHoliday) {
      dayNumberColor = AppColors.weekendDay;
    } else {
      dayNumberColor = AppColors.textPrimary;
    }

    return Container(
      decoration: BoxDecoration(
        color: isHoliday ? AppColors.holidayBackground : Colors.transparent,
        border: Border(
          top: BorderSide(color: AppColors.calendarGridBorder, width: 0.5),
          left: BorderSide(color: AppColors.calendarGridBorder, width: 0.5),
        ),
      ),
      padding: const EdgeInsets.all(2.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: isSelected
                ? BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    shape: BoxShape.circle,
                  )
                : isToday
                ? BoxDecoration(
                    shape: BoxShape.rectangle,
                    border: Border.all(
                      color: Theme.of(context).colorScheme.tertiary,
                      width: 2.0,
                    ),
                  )
                : null,
            child: Text(
              details.date.day.toString(),
              style: TextStyle(color: dayNumberColor, fontSize: 14),
            ),
          ),
          const SizedBox(height: 2),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: details.appointments.map((appointment) {
                  final event = appointment as Event;
                  if (event.isHoliday) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 2.0),
                      child: Text(
                        event.title,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.holidayText,
                          fontSize: 10.0,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );
                  }

                  final Color eventColor = CalendarColorLogic.getEventColor(
                    event,
                  );
                  return GestureDetector(
                    onTap: () async {
                      // Hier suchen wir das Original-Event in der _userEvents-Liste
                      // Wichtig: Verwende die übergebene userEvents Liste
                      final Event originalEvent = userEvents.firstWhere(
                        (e) => e.id == event.id,
                        orElse: () =>
                            event, // Fallback, sollte aber nicht passieren
                      );
                      final result = await Navigator.push<dynamic>(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AddEventScreen(
                            selectedDate: originalEvent.date,
                            eventToEdit: originalEvent,
                          ),
                        ),
                      );
                      if (result is Event) {
                        onUpdateEvent(originalEvent, result);
                      } else if (result is bool && result == true) {
                        onDeleteEvent(originalEvent);
                      }
                    },
                    child: Container(
                      margin: const EdgeInsets.only(top: 2.0),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 3.0,
                        vertical: 2.0,
                      ),
                      decoration: BoxDecoration(
                        color: eventColor.withAlpha(204),
                        borderRadius: BorderRadius.circular(0),
                      ),
                      child: Text(
                        event.title,
                        overflow: TextOverflow.clip,
                        softWrap: false,
                        maxLines: 1,
                        textAlign: TextAlign.left,
                        style: const TextStyle(
                          color: AppColors.dayNumberColor,
                          fontSize: 12.2,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
