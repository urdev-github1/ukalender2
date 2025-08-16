// lib/screens/calendar_screen.dart

import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import '../models/event.dart';
import '../services/holiday_service.dart';
import 'add_event_screen.dart';
import '../services/storage_service.dart';
import '../services/calendar_service.dart';
import '../screens/settings_screen.dart';

// Die EventDataSource-Klasse bleibt unverändert.
class EventDataSource extends CalendarDataSource {
  EventDataSource(List<Event> source) {
    appointments = source;
  }
  @override
  DateTime getStartTime(int index) => (appointments![index] as Event).date;
  @override
  DateTime getEndTime(int index) => (appointments![index] as Event).date.add(const Duration(hours: 1));
  @override
  String getSubject(int index) => (appointments![index] as Event).title;
  @override
  Color getColor(int index) => (appointments![index] as Event).color;
  @override
  bool isAllDay(int index) => (appointments![index] as Event).isHoliday;
}

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  List<Event> _allEvents = [];
  late EventDataSource _dataSource;
  final CalendarView _calendarView = CalendarView.month; 
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  final HolidayService _holidayService = HolidayService();
  final StorageService _storageService = StorageService();
  final CalendarService _calendarService = CalendarService();

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _dataSource = EventDataSource([]);
    _loadAllEvents();
  }

  void _loadAllEvents() async {
    final stateCode = await _storageService.getSelectedState();
    print('Lade Feiertage für: $stateCode');

    final holidays = await _holidayService.getHolidays(_focusedDay.year, stateCode);
    final savedEvents = await _storageService.loadEvents();

    setState(() {
      _allEvents = [...holidays, ...savedEvents];
      _dataSource = EventDataSource(_allEvents);
    });
  }

  void _onCalendarTapped(CalendarTapDetails details) {
    setState(() {
      _selectedDay = details.date;
    });
  }

  void _addEvent(Event event) {
     setState(() {
       _allEvents.add(event);
       _dataSource = EventDataSource(_allEvents);
       _dataSource.notifyListeners(CalendarDataSourceAction.reset, _allEvents);
     });
     _saveUserEvents();
  }

  void _deleteEvent(Event event) {
    if (event.isHoliday) return;

    setState(() {
      _allEvents.remove(event);
      _dataSource = EventDataSource(_allEvents);
      _dataSource.notifyListeners(CalendarDataSourceAction.reset, _allEvents);
    });
  
    _saveUserEvents();
  }

  void _updateEvent(Event oldEvent, Event newEvent) {
    setState(() {
      final index = _allEvents.indexOf(oldEvent);
      if (index != -1) {
        _allEvents[index] = newEvent;
        _dataSource = EventDataSource(_allEvents);
        _dataSource.notifyListeners(CalendarDataSourceAction.reset, _allEvents);
      }
    });
    _saveUserEvents();
  }
  
  void _saveUserEvents() {
    final allUserEvents = _allEvents.where((event) => !event.isHoliday).toList();
    _storageService.saveEvents(allUserEvents);
  }

  void _importEvents() async {
    final List<Event> importedEvents = await _calendarService.importEvents();

    if (importedEvents.isNotEmpty) {
      setState(() {
        _allEvents.addAll(importedEvents);
        _dataSource = EventDataSource(_allEvents);
        _dataSource.notifyListeners(CalendarDataSourceAction.reset, _allEvents);
      });
      _saveUserEvents();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${importedEvents.length} Termin(e) erfolgreich importiert.'),
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Import abgebrochen oder es wurden keine Termine gefunden.'),
          ),
        );
      }
    }
  }

  void _exportEvents() async {
    final userEvents = _allEvents.where((event) => !event.isHoliday).toList();

    if (userEvents.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Es sind keine Termine zum Exportieren vorhanden.'),
        ),
      );
      return;
    }

    await _calendarService.exportEvents(userEvents);
  }

  void _showEventDialog(Event event) {
    if (event.isHoliday) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(event.title),
        content: const Text('Möchten Sie diesen Termin bearbeiten oder löschen?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Abbrechen'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              final bool? shouldDelete = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Löschen bestätigen'),
                  content: const Text('Möchten Sie diesen Termin wirklich löschen?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Nein'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text('Ja, löschen'),
                    ),
                  ],
                ),
              );
              if (shouldDelete == true) {
                _deleteEvent(event);
              }
            },
            child: const Text('Löschen'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              final updatedEvent = await Navigator.push<Event>(
                context,
                MaterialPageRoute(
                  builder: (_) => AddEventScreen(
                    selectedDate: event.date,
                    eventToEdit: event,
                  ),
                ),
              );

              if (updatedEvent != null) {
                _updateEvent(event, updatedEvent);
              }
            },
            child: const Text('Bearbeiten'),
          ),
        ],
      ),
    );
  }

  Widget _monthCellBuilder(BuildContext context, MonthCellDetails details) {
    final bool isHoliday = details.appointments.any((appointment) => (appointment as Event).isHoliday);
    final bool isWeekend = details.date.weekday == DateTime.saturday || details.date.weekday == DateTime.sunday;
    final bool isCurrentMonth = details.date.month == _focusedDay.month;
    final bool isSelected = _selectedDay != null && _selectedDay!.year == details.date.year && _selectedDay!.month == details.date.month && _selectedDay!.day == details.date.day;

    Color dayNumberColor;
    if (isSelected) {
      dayNumberColor = Colors.white;
    } else if (!isCurrentMonth) {
      dayNumberColor = Colors.black26;
    } else if (isWeekend && !isHoliday) {
      dayNumberColor = Colors.red.withOpacity(0.8);
    } else {
      dayNumberColor = Colors.black87;
    }

    return Container(
      decoration: BoxDecoration(
        color: isHoliday ? Colors.green.withOpacity(0.15) : Colors.transparent,
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
            decoration: isSelected ? BoxDecoration(color: Colors.blue.withOpacity(0.9), shape: BoxShape.circle) : null,
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
                  
                  return GestureDetector(
                    onLongPress: () => _showEventDialog(event),
                    child: Container(
                      margin: const EdgeInsets.only(top: 2.0),
                      padding: const EdgeInsets.symmetric(horizontal: 3.0, vertical: 2.0),
                      decoration: BoxDecoration(
                        color: event.color.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(4.0),
                      ),
                      child: Text(
                        event.title,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11.0,
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

  void _openSettings() async {
    final shouldReload = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const SettingsScreen()),
    );

    if (shouldReload == true) {
      _loadAllEvents();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Terminkalender'),
        // =======================================================================
        // KORREKTUR: Die Reihenfolge der Aktions-Buttons wurde geändert.
        // =======================================================================
        actions: [
          IconButton(
            icon: const Icon(Icons.input), // Icon für den Import.
            tooltip: 'Termine importieren (.ics)', // Hilfetext bei langem Drücken.
            onPressed: _importEvents, // Ruft die Import-Methode auf.
          ),
          IconButton(
            icon: const Icon(Icons.output), // Icon für den Export.
            tooltip: 'Termine exportieren (.ics)', // Hilfetext bei langem Drücken.
            onPressed: _exportEvents, // Ruft die neue Export-Methode auf.
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
        headerStyle: const CalendarHeaderStyle(
          textAlign: TextAlign.center,
          textStyle: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
        viewHeaderStyle: const ViewHeaderStyle(
          dayTextStyle: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black54,
          ),
        ),
        todayHighlightColor: Colors.blue,
        selectionDecoration: const BoxDecoration(
          color: Colors.transparent,
        ),
        monthCellBuilder: _monthCellBuilder,
        monthViewSettings: const MonthViewSettings(
          appointmentDisplayMode: MonthAppointmentDisplayMode.none,
          numberOfWeeksInView: 6,
          showAgenda: false, 
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push<Event>(
            context,
            MaterialPageRoute(builder: (_) => AddEventScreen(selectedDate: _selectedDay ?? DateTime.now())),
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

enum ExportChoice { all, dateRange }