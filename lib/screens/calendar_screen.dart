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
  DateTime getEndTime(int index) =>
      (appointments![index] as Event).date.add(const Duration(hours: 1));
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
  // MODIFIZIERT: Getrennte Listen für eine saubere Zustandsverwaltung
  List<Event> _userEvents = [];
  List<Event> _holidays = [];

  // Diese Liste wird immer die Kombination aus den beiden oberen sein
  List<Event> _allEvents = [];

  late EventDataSource _dataSource;
  final CalendarView _calendarView = CalendarView.month;

  // MODIFIZIERT: Zustandsvariablen für das aktuelle Datum und Jahr
  DateTime _focusedDay = DateTime.now();
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

  // Lädt die initialen Daten: gespeicherte Termine und Feiertage für das aktuelle Jahr
  Future<void> _loadInitialData() async {
    _userEvents = await _storageService.loadEvents();
    await _loadHolidaysForYear(_currentYear);
  }

  // Lädt die Feiertage für ein bestimmtes Jahr von der API
  Future<void> _loadHolidaysForYear(int year) async {
    final stateCode = await _storageService.getSelectedState();
    _holidays = await _holidayService.getHolidays(year, stateCode);
    _rebuildEventListAndRefreshDataSource();
  }

  // Kombiniert Nutzer-Events und Feiertage und aktualisiert die Kalenderansicht
  void _rebuildEventListAndRefreshDataSource() {
    setState(() {
      _allEvents = [..._userEvents, ..._holidays];
      _dataSource = EventDataSource(_allEvents);
      // Ein Reset ist hier am sichersten, da sich potenziell viele Daten (alle Feiertage) ändern
      _dataSource.notifyListeners(CalendarDataSourceAction.reset, _allEvents);
    });
  }

  void _onCalendarTapped(CalendarTapDetails details) {
    setState(() {
      _selectedDay = details.date;
    });
  }

  // Fügt einen neuen Termin hinzu (nur zur _userEvents-Liste)
  void _addEvent(Event event) {
    setState(() {
      _userEvents.add(event);
      _rebuildEventListAndRefreshDataSource();
    });
    _saveUserEvents();
  }

  // Löscht einen Termin basierend auf seiner eindeutigen ID
  void _deleteEvent(Event event) {
    if (event.isHoliday) return;
    setState(() {
      _userEvents.removeWhere((e) => e.id == event.id);
      _rebuildEventListAndRefreshDataSource();
    });
    _saveUserEvents();
  }

  // Aktualisiert einen Termin basierend auf seiner eindeutigen ID
  void _updateEvent(Event oldEvent, Event newEvent) {
    setState(() {
      final index = _userEvents.indexWhere((e) => e.id == oldEvent.id);
      if (index != -1) {
        _userEvents[index] = newEvent;
        _rebuildEventListAndRefreshDataSource();
      }
    });
    _saveUserEvents();
  }

  // Speichert nur die Termine des Nutzers, nicht die Feiertage
  void _saveUserEvents() {
    _storageService.saveEvents(_userEvents);
  }

  // Importiert neue Termine und fügt sie zur Liste der Nutzer-Events hinzu
  void _importEvents() async {
    final List<Event> importedEvents = await _calendarService.importEvents();
    if (importedEvents.isNotEmpty) {
      setState(() {
        _userEvents.addAll(importedEvents);
        _rebuildEventListAndRefreshDataSource();
      });
      _saveUserEvents();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${importedEvents.length} Termin(e) erfolgreich importiert.',
            ),
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Import abgebrochen oder keine Termine gefunden.'),
          ),
        );
      }
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

  // Der Dialog zum Bearbeiten/Löschen bleibt funktional gleich
  void _showEventDialog(Event event) {
    if (event.isHoliday) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(event.title),
        content: const Text(
          'Möchten Sie diesen Termin bearbeiten oder löschen?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Abbrechen'),
          ),
          TextButton(
            child: const Text('Löschen'),
            onPressed: () async {
              Navigator.of(context).pop(); // Schließt den ersten Dialog
              final bool? shouldDelete = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Löschen bestätigen'),
                  content: const Text(
                    'Möchten Sie diesen Termin wirklich löschen?',
                  ),
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
          ),
          TextButton(
            child: const Text('Bearbeiten'),
            onPressed: () async {
              Navigator.of(context).pop(); // Schließt den ersten Dialog
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
          ),
        ],
      ),
    );
  }

  // Die _monthCellBuilder-Methode bleibt unverändert
  Widget _monthCellBuilder(BuildContext context, MonthCellDetails details) {
    // ... (Keine Änderungen hier notwendig)
    // Der Code aus der Originaldatei kann hier 1:1 übernommen werden.
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
    if (isSelected) {
      dayNumberColor = Colors.white;
    } else if (!isCurrentMonth) {
      dayNumberColor = Colors.black26;
    } else if (isWeekend && !isHoliday) {
      dayNumberColor = Colors.red.withAlpha(204);
    } else {
      dayNumberColor = Colors.black87;
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
                    color: Colors.blue.withAlpha(230),
                    shape: BoxShape.circle,
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
                  return GestureDetector(
                    onLongPress: () => _showEventDialog(event),
                    child: Container(
                      margin: const EdgeInsets.only(top: 2.0),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 3.0,
                        vertical: 2.0,
                      ),
                      decoration: BoxDecoration(
                        color: event.color.withAlpha(204),
                        borderRadius: BorderRadius.circular(4.0),
                      ),
                      child: Text(
                        event.title,
                        overflow: TextOverflow.clip,
                        maxLines: 1,
                        textAlign: TextAlign.center,
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

  void _openSettings() async {
    final shouldReload = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const SettingsScreen()),
    );
    if (shouldReload == true) {
      // Lädt die Feiertage für das aktuell ausgewählte Jahr neu
      _loadHolidaysForYear(_currentYear);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Terminkalender'),
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
        firstDayOfWeek: 1, // Montag
        headerStyle: const CalendarHeaderStyle(textAlign: TextAlign.center),
        monthCellBuilder: _monthCellBuilder,
        monthViewSettings: const MonthViewSettings(
          appointmentDisplayMode: MonthAppointmentDisplayMode.none,
          numberOfWeeksInView: 6,
          showAgenda: false,
        ),
        // NEU: Dynamisches Nachladen der Feiertage bei Jahreswechsel
        onViewChanged: (ViewChangedDetails details) {
          // Nimmt das erste Datum im sichtbaren Bereich als Referenz
          final newYear = details.visibleDates.first.year;
          if (newYear != _currentYear) {
            _currentYear = newYear;
            _loadHolidaysForYear(newYear);
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
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
