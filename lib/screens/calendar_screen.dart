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

  @override
  void initState() {
    super.initState();
    // Beim Initialisieren des States wird der heutige Tag als ausgewählt gesetzt.
    _selectedDay = _focusedDay;
    // Initialisiert die Map für die Events und die Liste für die ausgewählten Events.
    _events = {};
    _selectedEvents = [];
    // Ruft die Methode auf, um die Feiertage zu laden.
    _fetchHolidays();
  }

  // Asynchrone Methode zum Abrufen der Feiertage.
  void _fetchHolidays() async {
    // Beispiel: Ruft Feiertage für das aktuelle Jahr und das Bundesland Bayern ('BY') ab.
    final holidays = await _holidayService.getHolidays(_focusedDay.year, 'BY');
    // Aktualisiert den State, um die UI mit den geladenen Feiertagen neu zu zeichnen.
    setState(() {
      // Iteriert durch die Liste der abgerufenen Feiertage.
      for (var holiday in holidays) {
        // Normalisiert das Datum auf UTC, um Zeitzonenprobleme zu vermeiden.
        final day = DateTime.utc(holiday.date.year, holiday.date.month, holiday.date.day);
        // Wenn für dieses Datum noch keine Event-Liste existiert, wird eine neue erstellt.
        if (_events[day] == null) {
          _events[day] = [];
        }
        // Fügt den Feiertag als Event zur Liste für dieses Datum hinzu.
        _events[day]!.add(holiday);
      }
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

  // Fügt ein neues Event zur Event-Map hinzu.
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
  }

  @override
  Widget build(BuildContext context) {
    // Das Scaffold ist die Grundstruktur des Bildschirms.
    return Scaffold(
      appBar: AppBar(
        title: const Text('Terminkalender'),
        // Hier könnten zukünftig Aktionen wie Import/Export hinzugefügt werden.
      ),
      // Der Hauptinhalt des Bildschirms ist eine Spalte (Column).
      body: Column(
        children: [
          // Das `TableCalendar`-Widget zur Anzeige des Kalenders.
          TableCalendar<Event>(
            firstDay: DateTime.utc(2020, 1, 1), // Frühestes anzeigbares Datum.
            lastDay: DateTime.utc(2030, 12, 31), // Spätestes anzeigbares Datum.
            focusedDay: _focusedDay, // Welcher Monat/Woche ist aktuell im Fokus.
            // Bestimmt, welcher Tag als "ausgewählt" markiert wird.
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            calendarFormat: _calendarFormat, // Das aktuelle Format (Monat/Woche).
            // Funktion, die dem Kalender mitteilt, welche Events an welchem Tag stattfinden.
            eventLoader: _getEventsForDay,
            startingDayOfWeek: StartingDayOfWeek.monday, // Wochenstart am Montag.
            onDaySelected: _onDaySelected, // Callback für die Auswahl eines Tages.
            // Callback, wenn der Benutzer das Kalenderformat ändert.
            onFormatChanged: (format) {
              if (_calendarFormat != format) {
                setState(() {
                  _calendarFormat = format;
                });
              }
            },
            // Callback, wenn der Benutzer zu einer anderen Seite (Monat/Woche) wechselt.
            onPageChanged: (focusedDay) {
              _focusedDay = focusedDay;
              // Optional: Hier könnte man Feiertage für das neue Jahr/Monat nachladen.
            },
            // Definiert das Aussehen von bestimmten Kalenderelementen.
            calendarStyle: const CalendarStyle(
              // Heutiger Tag wird orange und kreisförmig hervorgehoben.
              todayDecoration: BoxDecoration(
                color: Colors.orange,
                shape: BoxShape.circle,
              ),
              // Ausgewählter Tag wird blau und kreisförmig hervorgehoben.
              selectedDecoration: BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
              ),
            ),
            // `calendarBuilders` wird verwendet, um benutzerdefinierte UI-Komponenten im Kalender zu erstellen.
            calendarBuilders: CalendarBuilders(
              // `markerBuilder` erstellt die Markierungen unter den Kalendertagen.
              markerBuilder: (context, date, events) {
                // Wenn es Events an diesem Tag gibt...
                if (events.isNotEmpty) {
                  // ...wird eine Markierung (Marker) angezeigt.
                  return Positioned(
                    right: 1,
                    bottom: 1,
                    child: _buildEventsMarker(date, events),
                  );
                }
                // Ansonsten wird nichts angezeigt.
                return null;
              },
            ),
          ),
          const SizedBox(height: 8.0), // Ein kleiner Abstand.
          // `Expanded` sorgt dafür, dass die ListView den restlichen verfügbaren Platz einnimmt.
          Expanded(
            // Zeigt die Liste der Events für den ausgewählten Tag an.
            child: ListView.builder(
              itemCount: _selectedEvents.length, // Anzahl der Elemente in der Liste.
              // `itemBuilder` baut jedes einzelne Listenelement.
              itemBuilder: (context, index) {
                final event = _selectedEvents[index];
                // Jeder Listeneintrag ist ein Container mit etwas Styling.
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
                  decoration: BoxDecoration(
                    border: Border.all(),
                    borderRadius: BorderRadius.circular(12.0),
                    // Setzt die Hintergrundfarbe des Events mit einer Transparenz von 30%.
                    color: event.color.withAlpha(77),
                  ),
                  // Das `ListTile` ist eine Standard-Zeile in einer Flutter-Liste.
                  child: ListTile(
                    onTap: () => print('${event.title} gedrückt'), // Aktion bei Klick.
                    title: Text(event.title), // Der Titel des Events.
                    // Zeigt die Beschreibung an, falls eine vorhanden ist.
                    subtitle: event.description != null ? Text(event.description!) : null,
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
          // Navigiert zum `AddEventScreen`. `await` wartet, bis der Bildschirm geschlossen wird
          // und ein Ergebnis zurückgibt.
          final result = await Navigator.push<Event>(
            context,
            MaterialPageRoute(builder: (_) => AddEventScreen(selectedDate: _selectedDay ?? DateTime.now())),
          );

          // Wenn der `AddEventScreen` ein Event zurückgegeben hat (d.h. der Benutzer hat gespeichert)...
          if (result != null) {
            // ...wird das neue Event zur Liste hinzugefügt.
            _addEvent(result);
          }
        },
        child: const Icon(Icons.add), // Das Plus-Icon auf dem Button.
      ),
    );
  }

  // Hilfsmethode, die das Widget für die Event-Markierung unter einem Kalendertag erstellt.
  Widget _buildEventsMarker(DateTime date, List<Event> events) {
    // `AnimatedContainer` sorgt für eine sanfte Animation bei Änderungen.
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        shape: BoxShape.circle, // Die Markierung ist ein Kreis.
        color: Colors.blue[400], // Mit blauer Hintergrundfarbe.
      ),
      width: 16.0,
      height: 16.0,
      // Zentriert den Inhalt des Containers.
      child: Center(
        // Zeigt die Anzahl der Events an diesem Tag an.
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