// lib/screens/calendar_screen.dart

// Importiert die notwendigen Pakete für Flutter-UI-Komponenten.
import 'package:flutter/material.dart';
// Importiert das `table_calendar`-Paket für die Kalenderansicht.
import 'package:table_calendar/table_calendar.dart';

// Importiert das Datenmodell für ein Event (Termin/Ereignis).
import '../models/event.dart';
// Importiert den Service, der für das Abrufen von Feiertagsdaten zuständig ist.
import '../services/holiday_service.dart';
// Importiert den Bildschirm zum Hinzufügen eines neuen Events.
import 'add_event_screen.dart';
// Importiert den Service für das lokale Speichern und Laden von Events.
import '../services/storage_service.dart';
// Importiert den Service für den Import/Export von Kalenderdaten.
import '../services/calendar_service.dart';

// Definiert ein StatefulWidget, da sich der Zustand des Bildschirms (z.B. ausgewähltes Datum) ändern kann.
class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  // Erstellt den zugehörigen State für das Widget.
  State<CalendarScreen> createState() => _CalendarScreenState();
}

// Dies ist die State-Klasse für CalendarScreen, die die Logik und den Zustand des Bildschirms enthält.
class _CalendarScreenState extends State<CalendarScreen> {
  // Eine Map, die Termine speichert. Der Schlüssel ist das Datum (DateTime),
  // und der Wert ist eine Liste von Events an diesem Tag.
  late Map<DateTime, List<Event>> _events;
  // Eine Liste, die die Events für das aktuell ausgewählte Datum enthält.
  late List<Event> _selectedEvents;
  // Steuert das Anzeigeformat des Kalenders (Monat, 2 Wochen, Woche).
  CalendarFormat _calendarFormat = CalendarFormat.month;
  // Das Datum, das im Kalender gerade im Fokus steht (z.B. der angezeigte Monat).
  DateTime _focusedDay = DateTime.now();
  // Das vom Benutzer explizit ausgewählte Datum. Kann null sein.
  DateTime? _selectedDay;

  // Eine Instanz des HolidayService, um Feiertage abzurufen.
  final HolidayService _holidayService = HolidayService();
  // Eine Instanz des StorageService, um Termine zu speichern und zu laden.
  final StorageService _storageService = StorageService();
  // Eine Instanz des CalendarService für den Import/Export.
  final CalendarService _calendarService = CalendarService();


  @override
  void initState() {
    super.initState();
    // Beim Initialisieren des States wird der heutige Tag als ausgewählt gesetzt.
    _selectedDay = _focusedDay;
    // Initialisiert die Map für die Events und die Liste für die ausgewählten Events.
    _events = {};
    _selectedEvents = [];
    
    // Ruft die Methode auf, die sowohl Feiertage als auch lokal
    // gespeicherte Termine lädt.
    _loadAllEvents();
  }

  // Diese Methode kombiniert das Laden von Feiertagen von der API
  // und das Laden von benutzerdefinierten Terminen aus dem lokalen Speicher.
  void _loadAllEvents() async {
    // 1. Feiertage von der API für das aktuell fokussierte Jahr abrufen.
    final holidays = await _holidayService.getHolidays(_focusedDay.year, 'BY');
    
    // 2. Lokal gespeicherte Termine aus der JSON-Datei laden.
    final savedEvents = await _storageService.loadEvents();

    // Den State aktualisieren, um die UI neu zu zeichnen.
    setState(() {
      _events = {}; // Die Event-Map vor dem Befüllen leeren.
      
      // Die geladenen Feiertage zur Map hinzufügen.
      for (var holiday in holidays) {
        final day = DateTime.utc(holiday.date.year, holiday.date.month, holiday.date.day);
        if (_events[day] == null) _events[day] = [];
        _events[day]!.add(holiday);
      }
      
      // Die geladenen, gespeicherten Termine ebenfalls zur Map hinzufügen.
      for (var event in savedEvents) {
        final day = DateTime.utc(event.date.year, event.date.month, event.date.day);
        if (_events[day] == null) _events[day] = [];
        _events[day]!.add(event);
      }
      
      // Die Event-Liste für den aktuell ausgewählten Tag aktualisieren.
      _selectedEvents = _getEventsForDay(_selectedDay!);
    });
  }

  // Eine Hilfsmethode, die eine Liste von Events für ein bestimmtes Datum zurückgibt.
  List<Event> _getEventsForDay(DateTime day) {
    // Normalisiert das angefragte Datum ebenfalls auf UTC.
    // Gibt die Liste der Events für dieses Datum zurück oder eine leere Liste, falls keine vorhanden sind.
    return _events[DateTime.utc(day.year, day.month, day.day)] ?? [];
  }

  // Wird aufgerufen, wenn der Benutzer einen Tag im Kalender auswählt.
  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    // Prüft, ob ein anderer Tag als der bereits ausgewählte angetippt wurde.
    if (!isSameDay(_selectedDay, selectedDay)) {
      // Aktualisiert den State mit dem neuen ausgewählten und fokussierten Datum.
      setState(() {
        _selectedDay = selectedDay;
        _focusedDay = focusedDay;
        // Lädt die Events für den neu ausgewählten Tag in die `_selectedEvents`-Liste.
        _selectedEvents = _getEventsForDay(selectedDay);
      });
    }
  }

  // Fügt ein neues Event hinzu und speichert die aktualisierte Liste.
  void _addEvent(Event event) {
     // Normalisiert das Datum des Events auf UTC.
     final day = DateTime.utc(event.date.year, event.date.month, event.date.day);
     // Aktualisiert den State.
     setState(() {
       // Erstellt eine neue Liste für das Datum, falls noch keine existiert.
       if (_events[day] == null) {
         _events[day] = [];
       }
       // Fügt das neue Event hinzu.
       _events[day]!.add(event);
       // Aktualisiert die Liste der angezeigten Events, falls das neue Event am aktuell ausgewählten Tag ist.
       _selectedEvents = _getEventsForDay(_selectedDay!);
     });

     // Ruft die Methode auf, um die benutzerdefinierten Events zu speichern.
     _saveUserEvents();
  }

  // Eine Hilfsmethode, die nur die Termine (nicht die Feiertage)
  // sammelt und im lokalen Speicher ablegt.
  void _saveUserEvents() {
    // Erstellt eine flache Liste aller Events und filtert dann nach denen,
    // die keine Feiertage sind (`isHoliday == false`).
    final allUserEvents = _events.values
        .expand((eventList) => eventList)
        .where((event) => !event.isHoliday)
        .toList();
        
    // Übergibt die gefilterte Liste an den StorageService zum Speichern.
    _storageService.saveEvents(allUserEvents);
  }

  // Diese Methode startet den Importvorgang.
  void _importEvents() async {
    // Öffnet den Dateimanager und wartet, bis der Benutzer eine .ics-Datei auswählt.
    final List<Event> importedEvents = await _calendarService.importEvents();
  
    // Prüfen, ob Termine importiert wurden.
    if (importedEvents.isNotEmpty) {
      // Jeden importierten Termin über die _addEvent Methode hinzufügen.
      // Diese kümmert sich um die Aktualisierung des States und das Speichern.
      for (final event in importedEvents) {
        _addEvent(event);
      }
  
      // Dem Benutzer eine Rückmeldung geben, dass der Import erfolgreich war.
      // Der `mounted`-Check ist eine gute Praxis in asynchronen Methoden,
      // um sicherzustellen, dass der Kontext noch gültig ist.
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${importedEvents.length} Termin(e) erfolgreich importiert!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } else {
      // Optional: Rückmeldung, wenn keine Datei gewählt oder die Datei leer war.
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Import abgebrochen oder keine Termine in der Datei gefunden.'),
          ),
        );
      }
    }
  }

  // NEU: Diese Methode startet den Exportvorgang.
  void _exportEvents() async {
    // Sammelt alle Events und filtert die Feiertage heraus.
    // Die Logik ist identisch zur `_saveUserEvents`-Methode.
    final userEvents = _events.values
        .expand((eventList) => eventList)
        .where((event) => !event.isHoliday)
        .toList();

    // Prüfen, ob überhaupt Termine zum Exportieren vorhanden sind.
    if (userEvents.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Keine eigenen Termine zum Exportieren vorhanden.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return; // Bricht die Methode hier ab.
    }
    
    // Ruft den Service auf, der die .ics-Datei erstellt und den Teilen-Dialog öffnet.
    await _calendarService.exportEvents(userEvents);
  }


  @override
  Widget build(BuildContext context) {
    // Das Scaffold ist die Grundstruktur des Bildschirms.
    return Scaffold(
      // MODIFIZIERT: Die AppBar wird um einen weiteren Button in der 'actions'-Liste erweitert.
      appBar: AppBar(
        title: const Text('Terminkalender'),
        // Fügt Aktionen (Buttons) auf der rechten Seite der AppBar hinzu.
        actions: [
          IconButton(
            icon: const Icon(Icons.input), // Icon für den Import.
            tooltip: 'Termine importieren (.ics)', // Hilfetext bei langem Drücken.
            onPressed: _importEvents, // Ruft die Import-Methode auf.
          ),
          // NEU: Der Button für den Export.
          IconButton(
            icon: const Icon(Icons.output), // Icon für den Export.
            tooltip: 'Termine exportieren (.ics)', // Hilfetext bei langem Drücken.
            onPressed: _exportEvents, // Ruft die neue Export-Methode auf.
          ),
        ],
      ),
      // Der Hauptinhalt des Bildschirms ist eine Spalte (Column).
      body: Column(
        children: [
          // Das `TableCalendar`-Widget zur Anzeige des Kalenders.
          TableCalendar<Event>(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            calendarFormat: _calendarFormat,
            eventLoader: _getEventsForDay,
            startingDayOfWeek: StartingDayOfWeek.monday,
            onDaySelected: _onDaySelected,
            onFormatChanged: (format) {
              if (_calendarFormat != format) {
                setState(() {
                  _calendarFormat = format;
                });
              }
            },
            onPageChanged: (focusedDay) {
              _focusedDay = focusedDay;
              // Hier könnte man zukünftig Feiertage für das neue Jahr nachladen,
              // falls die Performance optimiert werden muss.
            },
            calendarStyle: const CalendarStyle(
              todayDecoration: BoxDecoration(
                color: Colors.orange,
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
              ),
            ),
            calendarBuilders: CalendarBuilders(
              markerBuilder: (context, date, events) {
                if (events.isNotEmpty) {
                  return Positioned(
                    right: 1,
                    bottom: 1,
                    child: _buildEventsMarker(date, events),
                  );
                }
                return null;
              },
            ),
          ),
          const SizedBox(height: 8.0),
          // `Expanded` sorgt dafür, dass die ListView den restlichen verfügbaren Platz einnimmt.
          Expanded(
            child: ListView.builder(
              itemCount: _selectedEvents.length,
              itemBuilder: (context, index) {
                final event = _selectedEvents[index];
                return Container(
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
                );
              },
            ),
          ),
        ],
      ),
      // Der "Floating Action Button" (FAB) wird zum Hinzufügen neuer Events verwendet.
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

  // Hilfsmethode, die das Widget für die Event-Markierung unter einem Kalendertag erstellt.
  Widget _buildEventsMarker(DateTime date, List<Event> events) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.blue[400],
      ),
      width: 16.0,
      height: 16.0,
      child: Center(
        child: Text(
          '${events.length}',
          style: const TextStyle().copyWith(
            color: Colors.white,
            fontSize: 12.0,
          ),
        ),
      ),
    );
  }
}