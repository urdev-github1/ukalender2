// lib/screens/calendar_screen.dart

// Importiert die notwendigen Pakete für Flutter-UI-Komponenten.
import 'package:flutter/material.dart';
// Importiert das syncfusion_flutter_calendar-Paket.
import 'package:syncfusion_flutter_calendar/calendar.dart';

// Die restlichen Importe bleiben unverändert.
import '../models/event.dart';
import '../services/holiday_service.dart';
import 'add_event_screen.dart';
import '../services/storage_service.dart';
import '../services/calendar_service.dart';

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
  String getSubject(int index) => '';
  @override
  Color getColor(int index) => Colors.transparent;
  @override
  bool isAllDay(int index) => (appointments![index] as Event).isHoliday;
}

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  // State-Variablen und Service-Instanzen bleiben gleich.
  List<Event> _allEvents = [];
  late EventDataSource _dataSource;
  CalendarView _calendarView = CalendarView.month;
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

  // =======================================================================
  // Logik-Methoden (Erweitert)
  // =======================================================================

  void _loadAllEvents() async {
    final holidays = await _holidayService.getHolidays(_focusedDay.year, 'BY');
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

  // NEU: Methode zum Löschen eines Events
  void _deleteEvent(Event event) {
    if (event.isHoliday) return; // Feiertage können nicht gelöscht werden

    setState(() {
      _allEvents.remove(event);
      _dataSource = EventDataSource(_allEvents);
      _dataSource.notifyListeners(CalendarDataSourceAction.reset, _allEvents);
    });
  
    _saveUserEvents();
  }

  // NEU: Methode zum Aktualisieren eines Events
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

  // Import- und Export-Methoden bleiben unverändert...
  void _importEvents() async { /* ... unverändert ... */ }
  void _exportEvents() async { /* ... unverändert ... */ }


  // NEU: Methode, die den Dialog anzeigt
  void _showEventDialog(Event event) {
    // Feiertage können nicht bearbeitet oder gelöscht werden
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
              Navigator.of(context).pop(); // Dialog schließen
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
              Navigator.of(context).pop(); // Hauptdialog schließen
              // Navigiere zum Bearbeiten-Bildschirm und warte auf das Ergebnis
              final updatedEvent = await Navigator.push<Event>(
                context,
                MaterialPageRoute(
                  builder: (_) => AddEventScreen(
                    selectedDate: event.date,
                    eventToEdit: event, // Übergabe des zu bearbeitenden Events
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

  // =======================================================================
  // Builder-Methode für die Zellen (Angepasst mit GestureDetector)
  // =======================================================================
  Widget _monthCellBuilder(BuildContext context, MonthCellDetails details) {
    final bool isWeekend = details.date.weekday == DateTime.saturday || details.date.weekday == DateTime.sunday;
    final bool isCurrentMonth = details.date.month == _focusedDay.month;
    final bool isSelected = _selectedDay != null && _selectedDay!.year == details.date.year && _selectedDay!.month == details.date.month && _selectedDay!.day == details.date.day;
    Color dayNumberColor;
    if (isSelected) dayNumberColor = Colors.white;
    else if (!isCurrentMonth) dayNumberColor = Colors.black26;
    else if (isWeekend) dayNumberColor = Colors.red.withOpacity(0.8);
    else dayNumberColor = Colors.black87;

    return Container(
      padding: const EdgeInsets.all(2.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            width: 24, height: 24,
            alignment: Alignment.center,
            decoration: isSelected ? BoxDecoration(color: Colors.blue.withOpacity(0.9), shape: BoxShape.circle) : null,
            child: Text(details.date.day.toString(), style: TextStyle(color: dayNumberColor, fontSize: 14)),
          ),
          const SizedBox(height: 2),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: details.appointments.take(3).map((appointment) {
                  final event = appointment as Event;
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

  @override
  Widget build(BuildContext context) {
    // =======================================================================
    // KORREKTUR: Die build-Methode ist hier wieder vollständig
    // =======================================================================
    return Scaffold(
      appBar: AppBar(
        title: const Text('Terminkalender'),
        actions: [
          PopupMenuButton<CalendarView>(
            icon: const Icon(Icons.view_module),
            onSelected: (CalendarView value) {
              setState(() {
                _calendarView = value;
              });
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<CalendarView>>[
              const PopupMenuItem<CalendarView>(
                value: CalendarView.month,
                child: Text('Monat'),
              ),
              const PopupMenuItem<CalendarView>(
                value: CalendarView.week,
                child: Text('Woche'),
              ),
              const PopupMenuItem<CalendarView>(
                value: CalendarView.day,
                child: Text('Tag'),
              ),
              const PopupMenuItem<CalendarView>(
                value: CalendarView.schedule,
                child: Text('Agenda'),
              ),
            ],
          ),
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
        ],
      ),
      body: SfCalendar(
        view: _calendarView,
        dataSource: _dataSource,
        initialDisplayDate: _focusedDay,
        initialSelectedDate: _selectedDay,
        onTap: _onCalendarTapped,
        firstDayOfWeek: 1,
        cellBorderColor: Colors.transparent,
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
          appointmentDisplayMode: MonthAppointmentDisplayMode.appointment,
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