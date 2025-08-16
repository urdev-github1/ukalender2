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

// =======================================================================
// Datenquelle für den Syncfusion Kalender
// =======================================================================
/// Diese Klasse dient als Adapter zwischen Ihrer `Event`-Liste und dem
/// `SfCalendar`-Widget.
class EventDataSource extends CalendarDataSource {
  /// Erstellt eine Datenquelle basierend auf einer Liste von `Event`-Objekten.
  EventDataSource(List<Event> source) {
    appointments = source;
  }

  @override
  DateTime getStartTime(int index) {
    return (appointments![index] as Event).date;
  }

  @override
  DateTime getEndTime(int index) {
    // Nimmt an, dass jeder Termin eine Stunde dauert.
    return (appointments![index] as Event).date.add(const Duration(hours: 1));
  }

  @override
  String getSubject(int index) {
    return (appointments![index] as Event).title;
  }

  @override
  Color getColor(int index) {
    return (appointments![index] as Event).color;
  }

  @override
  bool isAllDay(int index) {
    return (appointments![index] as Event).isHoliday;
  }
}


// Das StatefulWidget bleibt strukturell gleich.
class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}


class _CalendarScreenState extends State<CalendarScreen> {
  // State-Variablen
  List<Event> _allEvents = [];
  late EventDataSource _dataSource;
  late List<Event> _selectedEvents;

  CalendarView _calendarView = CalendarView.month;
  
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  // Service-Instanzen
  final HolidayService _holidayService = HolidayService();
  final StorageService _storageService = StorageService();
  final CalendarService _calendarService = CalendarService();


  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _selectedEvents = [];
    _dataSource = EventDataSource([]);
    
    _loadAllEvents();
  }

  // =======================================================================
  // Logik-Methoden (unverändert)
  // =======================================================================

  void _loadAllEvents() async {
    final holidays = await _holidayService.getHolidays(_focusedDay.year, 'BY');
    final savedEvents = await _storageService.loadEvents();

    setState(() {
      _allEvents = [...holidays, ...savedEvents];
      _dataSource = EventDataSource(_allEvents);
      _selectedEvents = _getEventsForDay(_selectedDay!);
    });
  }

  List<Event> _getEventsForDay(DateTime day) {
    return _allEvents.where((event) {
      return event.date.year == day.year &&
             event.date.month == day.month &&
             event.date.day == day.day;
    }).toList();
  }

  void _onCalendarTapped(CalendarTapDetails details) {
    setState(() {
      _selectedDay = details.date;
      _selectedEvents = _getEventsForDay(details.date!);
    });
  }

  void _addEvent(Event event) {
     setState(() {
       _allEvents.add(event);
       _dataSource = EventDataSource(_allEvents);
       _dataSource.notifyListeners(CalendarDataSourceAction.reset, _allEvents);
       _selectedEvents = _getEventsForDay(_selectedDay!);
     });

     _saveUserEvents();
  }
  
  void _deleteEvent(Event event) {
    if (event.isHoliday) return;
    
    setState(() {
      _allEvents.remove(event);
      _dataSource = EventDataSource(_allEvents);
      _dataSource.notifyListeners(CalendarDataSourceAction.reset, _allEvents);
      _selectedEvents = _getEventsForDay(_selectedDay!);
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
      for (final event in importedEvents) {
        _addEvent(event);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${importedEvents.length} Termin(e) erfolgreich importiert!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Import abgebrochen oder keine Termine in der Datei gefunden.'),
          ),
        );
      }
    }
  }

  void _exportEvents() async {
    final allUserEvents = _allEvents.where((event) => !event.isHoliday).toList();

    if (allUserEvents.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Keine eigenen Termine zum Exportieren vorhanden.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    final ExportChoice? choice = await showDialog<ExportChoice>(
      context: context,
      builder: (BuildContext context) {
        return SimpleDialog(
          title: const Text('Welche Termine exportieren?'),
          children: <Widget>[
            SimpleDialogOption(
              onPressed: () { Navigator.pop(context, ExportChoice.all); },
              child: const Text('Alle meine Termine'),
            ),
            SimpleDialogOption(
              onPressed: () { Navigator.pop(context, ExportChoice.dateRange); },
              child: const Text('Zeitraum auswählen...'),
            ),
          ],
        );
      },
    );

    if (!mounted) return;
    if (choice == null) return;

    List<Event> eventsToExport;
    if (choice == ExportChoice.all) {
      eventsToExport = allUserEvents;
    } else {
      final DateTimeRange? dateRange = await showDateRangePicker(
        context: context,
        firstDate: DateTime(2020),
        lastDate: DateTime(2030),
      );

      if (!mounted || dateRange == null) return;

      eventsToExport = allUserEvents.where((event) {
        final eventDate = DateTime.utc(event.date.year, event.date.month, event.date.day);
        final startDate = DateTime.utc(dateRange.start.year, dateRange.start.month, dateRange.start.day);
        final endDate = DateTime.utc(dateRange.end.year, dateRange.end.month, dateRange.end.day);
        return !eventDate.isBefore(startDate) && !eventDate.isAfter(endDate);
      }).toList();
    }
    
    if (eventsToExport.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Im ausgewählten Zeitraum wurden keine Termine gefunden.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    await _calendarService.exportEvents(eventsToExport);
  }

  // =======================================================================
  // Builder-Methode für die Zellen
  // =======================================================================
  /// Definiert das Aussehen für jede einzelne Zelle im Monatskalender.
  Widget _monthCellBuilder(BuildContext context, MonthCellDetails details) {
    final bool isWeekend = details.date.weekday == DateTime.saturday ||
                           details.date.weekday == DateTime.sunday;
    final bool isCurrentMonth = details.date.month == _focusedDay.month;

    final bool isSelected = _selectedDay != null &&
        _selectedDay!.year == details.date.year &&
        _selectedDay!.month == details.date.month &&
        _selectedDay!.day == details.date.day;

    Color dayNumberColor;

    if (isSelected) {
      dayNumberColor = Colors.white;
    } else if (!isCurrentMonth) {
      dayNumberColor = Colors.black26;
    } else if (isWeekend) {
      dayNumberColor = Colors.red.withOpacity(0.8);
    } else {
      dayNumberColor = Colors.black87;
    }

    return Container(
      padding: const EdgeInsets.all(2.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ===== TEIL 1: Die Tageszahl (mit Auswahl-Highlight) =====
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: isSelected
                ? BoxDecoration(
                    color: Colors.blue.withOpacity(0.9),
                    shape: BoxShape.circle,
                  )
                : null,
            child: Text(
              details.date.day.toString(),
              style: TextStyle(
                color: dayNumberColor,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(height: 2),

          // ===== TEIL 2: Die Liste der Termine =====
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: details.appointments.take(2).map((appointment) {
                  final event = appointment as Event;
                  return Container(
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
      body: Column(
        children: [
          Expanded(
            flex: 2, // Gibt dem Kalender 2/3 des verfügbaren Platzes
            child: SfCalendar(
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
                appointmentDisplayMode: MonthAppointmentDisplayMode.indicator,
                numberOfWeeksInView: 6,
                showAgenda: false, 
              ),
            ),
          ),
          const SizedBox(height: 8.0),
          Expanded(
            flex: 1, // Gibt der Liste 1/3 des verfügbaren Platzes
            child: ListView.builder(
              itemCount: _selectedEvents.length,
              itemBuilder: (context, index) {
                final event = _selectedEvents[index];
                return Dismissible(
                  // ===============================================================
                  // HIER WAR DER FEHLER: KORRIGIERT zu toIso8601String()
                  // ===============================================================
                  key: Key('${event.title}_${event.date.toIso8601String()}_$index'),
                  direction: event.isHoliday 
                    ? DismissDirection.none 
                    : DismissDirection.endToStart,
                  confirmDismiss: (direction) async {
                    return await showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: const Text('Löschen bestätigen'),
                          content: const Text('Möchten Sie diesen Termin wirklich löschen?'),
                          actions: <Widget>[
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(false),
                              child: const Text('Abbrechen'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(true),
                              child: const Text('Löschen'),
                            ),
                          ],
                        );
                      },
                    );
                  },
                  onDismissed: (direction) {
                    _deleteEvent(event);
                    if(mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('"${event.title}" gelöscht')),
                      );
                    }
                  },
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
                    decoration: BoxDecoration(
                      border: Border.all(),
                      borderRadius: BorderRadius.circular(12.0),
                      color: event.color.withAlpha(77),
                    ),
                    child: ListTile(
                      onTap: () => print('${event.title} gedrückt'),
                      title: Text(event.title),
                      subtitle: event.description != null && event.description!.isNotEmpty
                          ? Text(event.description!)
                          : null,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      // Der Floating Action Button.
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

// Enum für die Export-Funktion.
enum ExportChoice { all, dateRange }