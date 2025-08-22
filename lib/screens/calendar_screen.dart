// lib/screens/calendar_screen.dart

import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import '../models/event.dart';
import '../services/holiday_service.dart';
import 'add_event_screen.dart';
import '../services/storage_service.dart';
import '../services/calendar_service.dart';
import '../screens/settings_screen.dart';
import '../services/notification_service.dart';

class EventDataSource extends CalendarDataSource {
  EventDataSource(List<Event> source) {
    appointments = source;
  }
  @override
  DateTime getStartTime(int index) => (appointments![index] as Event).date;
  @override
  DateTime getEndTime(int index) =>
      (appointments![index] as Event).date.add(const Duration(hours: 1));
  @override
  String getSubject(int index) => (appointments![index] as Event).title;

  @override
  Color getColor(int index) {
    final Event event = appointments![index] as Event;

    if (event.isHoliday) {
      return event.color;
    }

    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    final DateTime eventDate = DateTime(
      event.date.year,
      event.date.month,
      event.date.day,
    );

    if (eventDate.isBefore(today)) {
      return const Color(0xFF00854D); // AppColors.green
    }

    return event.color;
  }

  @override
  bool isAllDay(int index) => (appointments![index] as Event).isHoliday;
}

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  List<Event> _userEvents = [];
  List<Event> _holidays = [];
  List<Event> _allEvents = [];
  late EventDataSource _dataSource;
  final CalendarView _calendarView = CalendarView.month;
  final DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  late int _currentYear;
  final HolidayService _holidayService = HolidayService();
  final StorageService _storageService = StorageService();
  final CalendarService _calendarService = CalendarService();
  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _currentYear = _focusedDay.year;
    _dataSource = EventDataSource([]);
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    _userEvents = await _storageService.loadEvents();
    await _loadHolidaysForYear(_currentYear);
  }

  Future<void> _loadHolidaysForYear(int year) async {
    final stateCode = await _storageService.getSelectedState();
    _holidays = await _holidayService.getHolidays(year, stateCode);
    _rebuildEventListAndRefreshDataSource();
  }

  void _rebuildEventListAndRefreshDataSource() {
    setState(() {
      _allEvents = [..._userEvents, ..._holidays];
      _dataSource = EventDataSource(_allEvents);
      _dataSource.notifyListeners(CalendarDataSourceAction.reset, _allEvents);
    });
  }

  void _onCalendarTapped(CalendarTapDetails details) {
    setState(() {
      _selectedDay = details.date;
    });
  }

  void _addEvent(Event event) {
    _storageService.addEvent(event).then((_) {
      if (!mounted) return;
      setState(() {
        _userEvents.add(event);
        _rebuildEventListAndRefreshDataSource();
      });
    });
  }

  void _deleteEvent(Event event) {
    if (event.isHoliday) return;
    final int notificationId = event.id.hashCode;
    NotificationService().cancelReminders(notificationId);

    _storageService.deleteEvent(event.id).then((_) {
      if (!mounted) return;
      setState(() {
        _userEvents.removeWhere((e) => e.id == event.id);
        _rebuildEventListAndRefreshDataSource();
      });
    });
  }

  void _updateEvent(Event oldEvent, Event newEvent) {
    final int oldNotificationId = oldEvent.id.hashCode;
    NotificationService().cancelReminders(oldNotificationId);

    _storageService.updateEvent(newEvent).then((_) {
      if (!mounted) return;
      setState(() {
        final index = _userEvents.indexWhere((e) => e.id == oldEvent.id);
        if (index != -1) {
          _userEvents[index] = newEvent;
          _rebuildEventListAndRefreshDataSource();
        }
      });
    });
  }

  void _importEvents() async {
    final List<Event> importedEvents = await _calendarService.importEvents();

    if (importedEvents.isNotEmpty) {
      for (final event in importedEvents) {
        await _storageService.addEvent(event);
      }

      if (!mounted) return;

      setState(() {
        _userEvents.addAll(importedEvents);
        _rebuildEventListAndRefreshDataSource();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${importedEvents.length} Termin(e) erfolgreich importiert.',
          ),
        ),
      );
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Import abgebrochen oder keine Termine gefunden.'),
        ),
      );
    }
  }

  void _exportEvents() async {
    if (_userEvents.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Es sind keine Termine zum Exportieren vorhanden.'),
        ),
      );
      return;
    }
    await _calendarService.exportEvents(_userEvents);
  }

  // =======================================================================
  // ==================== HIER BEGINNT DIE KORREKTUR =======================
  // =======================================================================
  Widget _monthCellBuilder(BuildContext context, MonthCellDetails details) {
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
    final bool isCurrentMonth = details.date.month == _focusedDay.month;
    final bool isSelected =
        _selectedDay != null &&
        _selectedDay!.year == details.date.year &&
        _selectedDay!.month == details.date.month &&
        _selectedDay!.day == details.date.day;

    Color dayNumberColor;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    if (isSelected) {
      dayNumberColor = Colors.white;
    } else if (!isCurrentMonth) {
      dayNumberColor = isDark ? Colors.white24 : Colors.black26;
    } else if (isWeekend && !isHoliday) {
      dayNumberColor = Colors.red.withAlpha(204);
    } else {
      dayNumberColor = isDark ? Colors.white70 : Colors.black87;
    }

    return Container(
      decoration: BoxDecoration(
        color: isHoliday ? Colors.green.withAlpha(38) : Colors.transparent,
        border: Border(
          top: BorderSide(color: Colors.grey[300]!, width: 0.5),
          left: BorderSide(color: Colors.grey[300]!, width: 0.5),
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
                          color: Colors.green[800],
                          fontSize: 10.0,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );
                  }

                  final Color eventColor;
                  final DateTime now = DateTime.now();
                  final DateTime today = DateTime(now.year, now.month, now.day);
                  final DateTime eventDate = DateTime(
                    event.date.year,
                    event.date.month,
                    event.date.day,
                  );

                  if (eventDate.isBefore(today)) {
                    eventColor = const Color(0xFF00854D);
                  } else {
                    eventColor = event.color;
                  }

                  return GestureDetector(
                    onTap: () async {
                      final result = await Navigator.push<dynamic>(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AddEventScreen(
                            selectedDate: event.date,
                            eventToEdit: event,
                          ),
                        ),
                      );

                      if (!mounted) return;
                      if (result is Event) {
                        _updateEvent(event, result);
                      } else if (result is bool && result == true) {
                        _deleteEvent(event);
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
                          color: Colors.white,
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
  // =======================================================================
  // ===================== HIER ENDET DIE KORREKTUR ========================
  // =======================================================================

  void _openSettings() async {
    final shouldReload = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const SettingsScreen()),
    );
    if (shouldReload == true) {
      _loadHolidaysForYear(_currentYear);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Kalender',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.input),
            tooltip: 'Termine importieren (.ics)',
            onPressed: _importEvents,
          ),
          IconButton(
            icon: const Icon(Icons.output),
            tooltip: 'Termine exportieren (.ics)',
            onPressed: _exportEvents,
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Einstellungen',
            onPressed: _openSettings,
          ),
        ],
      ),
      body: SfCalendar(
        view: _calendarView,
        dataSource: _dataSource,
        initialDisplayDate: _focusedDay,
        initialSelectedDate: _selectedDay,
        onTap: _onCalendarTapped,
        firstDayOfWeek: 1,
        headerStyle: CalendarHeaderStyle(
          textAlign: TextAlign.center,
          backgroundColor: Colors.transparent,
          textStyle: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        monthCellBuilder: _monthCellBuilder,
        monthViewSettings: const MonthViewSettings(
          appointmentDisplayMode: MonthAppointmentDisplayMode.none,
          numberOfWeeksInView: 6,
          showAgenda: false,
        ),
        onViewChanged: (ViewChangedDetails details) {
          final newYear = details.visibleDates.first.year;
          if (newYear != _currentYear) {
            _currentYear = newYear;
            _loadHolidaysForYear(newYear);
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color.fromARGB(255, 131, 185, 201),
        onPressed: () async {
          final result = await Navigator.push<Event>(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  AddEventScreen(selectedDate: _selectedDay ?? DateTime.now()),
            ),
          );
          if (result != null) {
            _addEvent(result);
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
