// lib/screens/calendar_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import '../models/event.dart';
import '../services/holiday_service.dart';
import '../screens/add_event_screen.dart';
import '../services/storage_service.dart';
import '../services/calendar_service.dart';
import '../screens/settings_screen.dart';
import '../services/notification_service.dart';
import '../utils/app_colors.dart';
import '../utils/calendar_color_logic.dart';

/// Kalenderdatenquelle, die Termine in der Kalenderansicht anzeigt.
class EventDataSource extends CalendarDataSource {
  // Erstellt eine neue Instanz der EventDataSource mit der angegebenen Liste von Terminen.
  EventDataSource(List<Event> source) {
    appointments = source;
  }

  @override
  // Gibt die Startzeit des Termins an der angegebenen Indexposition zurück.
  DateTime getStartTime(int index) => (appointments![index] as Event).date;

  @override
  /// Gibt die Endzeit des Termins an der angegebenen Indexposition zurück.
  DateTime getEndTime(int index) =>
      (appointments![index] as Event).date.add(const Duration(hours: 1));

  @override
  // Gibt den Betreff des Termins an der angegebenen Indexposition zurück.
  String getSubject(int index) => (appointments![index] as Event).title;

  @override
  // Gibt die Farbe des Termins an der angegebenen Indexposition zurück.
  Color getColor(int index) {
    final Event event = appointments![index] as Event;
    // Die ausgelagerte Logik zur Farbbestimmung wird hier aufgerufen.
    return CalendarColorLogic.getEventColor(event);
  }

  @override
  // Gibt zurück, ob der Termin an der angegebenen Indexposition ganztägig ist.
  bool isAllDay(int index) {
    final Event event = appointments![index] as Event;
    return event.isHoliday || event.isBirthday;
  }
}

/// Main-Screen, der den Kalender und die Terminverwaltung anzeigt.
class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

/// State-Klasse für den Kalenderbildschirm.
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

  /// Lädt die initialen Daten, einschließlich Benutzerevents und Feiertage für das aktuelle Jahr.
  Future<void> _loadInitialData() async {
    _userEvents = await _storageService.loadEvents();
    await _loadHolidaysForYear(_currentYear);
  }

  /// Lädt die Feiertage für das angegebene Jahr basierend auf dem ausgewählten Bundesland.
  Future<void> _loadHolidaysForYear(int year) async {
    final stateCode = await _storageService.getSelectedState();
    _holidays = await _holidayService.getHolidays(year, stateCode);
    _rebuildEventListAndRefreshDataSource();
  }

  /// Baut die Liste der anzuzeigenden Events neu auf und aktualisiert die Datenquelle.
  void _rebuildEventListAndRefreshDataSource() {
    setState(() {
      final List<Event> displayEvents = [];
      displayEvents.addAll(_userEvents.where((event) => !event.isBirthday));

      // Geburtstage für das aktuelle, vorherige und nächste Jahr hinzufügen
      final birthdayEvents = _userEvents.where((event) => event.isBirthday);
      for (final birthday in birthdayEvents) {
        for (int yearOffset = -1; yearOffset <= 1; yearOffset++) {
          final targetYear = _currentYear + yearOffset;
          final birthdayInYear = DateTime(
            targetYear,
            birthday.date.month,
            birthday.date.day,
          );
          // Nur hinzufügen, wenn der Geburtstag im aktuellen Jahr oder in der Zukunft liegt
          displayEvents.add(birthday.copyWith(date: birthdayInYear));
        }
      }

      _allEvents = [...displayEvents, ..._holidays];
      _dataSource = EventDataSource(_allEvents);
      _dataSource.notifyListeners(CalendarDataSourceAction.reset, _allEvents);
    });
  }

  /// Handler für das Tippen auf ein Kalenderelement.
  void _onCalendarTapped(CalendarTapDetails details) {
    setState(() {
      _selectedDay = details.date;
    });
  }

  /// Fügt einen neuen Termin hinzu und lädt die Daten neu.
  void _addEvent(Event event) {
    _storageService.addEvent(event).then((_) {
      if (!mounted) return;
      _loadInitialData();
    });
  }

  /// Löscht einen Termin und lädt die Daten neu.
  void _deleteEvent(Event event) {
    if (event.isHoliday) return;
    final int notificationId = event.id.hashCode;
    NotificationService().cancelReminders(notificationId);

    // Entfernt auch alle Erinnerungen, die mit diesem Termin verbunden sind.
    _storageService.deleteEvent(event.id).then((_) {
      if (!mounted) return;
      _loadInitialData();
    });
  }

  /// Aktualisiert einen bestehenden Termin und lädt die Daten neu.
  void _updateEvent(Event oldEvent, Event newEvent) {
    final int oldNotificationId = oldEvent.id.hashCode;
    NotificationService().cancelReminders(oldNotificationId);

    // Entfernt auch alle alten Erinnerungen, die mit dem alten Termin verbunden sind.
    _storageService.updateEvent(newEvent).then((_) {
      if (!mounted) return;
      _loadInitialData();
    });
  }

  /// Importiert Termine aus einer .ics-Datei und lädt die Daten neu.
  void _importEvents() async {
    final List<Event> importedEvents = await _calendarService.importEvents();

    // "Insert or Replace" Logik für importierte Termine
    if (importedEvents.isNotEmpty) {
      for (final event in importedEvents) {
        await _storageService.addEvent(event);
      }
      await _loadInitialData();
    }

    if (!mounted) return;

    // Bestätigung anzeigen, wie viele Termine importiert/aktualisiert wurden.
    if (importedEvents.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${importedEvents.length} Termin(e) erfolgreich importiert/aktualisiert.',
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Import abgebrochen oder keine Termine gefunden.'),
        ),
      );
    }
  }

  /// Exportiert die aktuellen Termine in eine .ics-Datei.
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

  /// Erstellt ein internes Backup der aktuellen Termine im JSON-Format.
  void _performBackup() async {
    if (_userEvents.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Es sind keine Termine für ein Backup vorhanden.'),
        ),
      );
      return;
    }
    await _calendarService.createInternalBackup(_userEvents);
  }

  /// Stellt Termine aus einem internen JSON-Backup wieder her.
  void _performRestore() async {
    final List<Event> restoredEvents = await _calendarService
        .restoreFromInternalBackup();

    if (!mounted) return;

    // Wenn keine Termine wiederhergestellt wurden, Abbruch.
    if (restoredEvents.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Wiederherstellung abgebrochen oder Datei ungültig.'),
        ),
      );
      return;
    }

    // Dialog zur Auswahl der Wiederherstellungsoption anzeigen.
    final choice = await showDialog<String>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Backup wiederherstellen'),
        content: const Text(
          'Wie möchten Sie das Backup einspielen?\n\n'
          'Achtung: "Alles Ersetzen" löscht alle Termine, die Sie seit diesem Backup erstellt haben!',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop('merge'),
            child: const Text('Zusammenführen'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () => Navigator.of(context).pop('replace'),
            child: const Text('Alles Ersetzen'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(), // Returns null
            child: const Text('Abbrechen'),
          ),
        ],
      ),
    );

    // Abbruch, wenn der Dialog geschlossen oder abgebrochen wurde.
    if (choice == null || !mounted) return;

    // Wenn "Alles Ersetzen" gewählt wurde, alle bestehenden Termine löschen.
    if (choice == 'replace') {
      await _storageService.clearAllEvents();
    }

    // Wiederhergestellte Termine hinzufügen.
    for (final event in restoredEvents) {
      await _storageService.addEvent(event);
    }

    // Daten neu laden, um die Änderungen anzuzeigen.
    await _loadInitialData();

    // Bestätigung anzeigen.
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${restoredEvents.length} Termin(e) wiederhergestellt.'),
      ),
    );
  }

  /// Baut die Zelle für einen Monatstag in der Kalenderansicht.
  Widget _monthCellBuilder(BuildContext context, MonthCellDetails details) {
    final DateTime now = DateTime.now();
    // Bestimmt, ob der Tag der heutige Tag ist.
    final bool isToday =
        details.date.year == now.year &&
        details.date.month == now.month &&
        details.date.day == now.day;
    // Bestimmt, ob der Tag ein Feiertag ist.
    final bool isHoliday = details.appointments.any(
      (appointment) => (appointment as Event).isHoliday,
    );
    // Bestimmt, ob der Tag ein Wochenende ist (Samstag oder Sonntag).
    final bool isWeekend =
        details.date.weekday == DateTime.saturday ||
        details.date.weekday == DateTime.sunday;
    // Bestimmt, ob der Tag im aktuell angezeigten Monat liegt.
    final bool isCurrentMonth = details.date.month == _focusedDay.month;
    // Bestimmt, ob der Tag der aktuell ausgewählte Tag ist.
    final bool isSelected =
        _selectedDay != null &&
        _selectedDay!.year == details.date.year &&
        _selectedDay!.month == details.date.month &&
        _selectedDay!.day == details.date.day;

    Color dayNumberColor;

    // Bestimmt die Textfarbe für die Tagesnummer basierend auf verschiedenen Zuständen.
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    // Logik zur Bestimmung der Textfarbe
    if (isSelected) {
      dayNumberColor = Colors.white;
    } else if (!isCurrentMonth) {
      dayNumberColor = isDark ? Colors.white24 : Colors.black26;
    } else if (isWeekend && !isHoliday) {
      dayNumberColor = AppColors.weekendDay; // <-- ÄNDERUNG: Zentrale Farbe
    } else {
      dayNumberColor = isDark ? Colors.white70 : Colors.black87;
    }
    // Baut die Zelle mit entsprechender Dekoration und Terminen.
    return Container(
      decoration: BoxDecoration(
        color: isHoliday ? AppColors.holidayBackground : Colors.transparent,
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
                          color: AppColors
                              .holidayText, // <-- ÄNDERUNG: Zentrale Farbe
                          fontSize: 10.0,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );
                  }

                  // Bestimmt die Farbe des Termins basierend auf seiner Kategorie.
                  final Color eventColor = CalendarColorLogic.getEventColor(
                    event,
                  );

                  return GestureDetector(
                    onTap: () async {
                      final Event originalEvent = _userEvents.firstWhere(
                        (e) => e.id == event.id,
                        orElse: () => event,
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
                        _updateEvent(originalEvent, result);
                      } else if (result is bool && result == true) {
                        _deleteEvent(originalEvent);
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

  /// Öffnet den Einstellungsbildschirm und lädt die Feiertage neu, wenn Änderungen vorgenommen wurden.
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
  // Baut die Benutzeroberfläche des Kalenders.
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final Color startColor = Color.lerp(
      colorScheme.surface,
      colorScheme.primaryContainer,
      0.3,
    )!;

    // Farbverlaufshintergrund für den Kalenderbildschirm.
    final Color endColor = colorScheme.surfaceContainerLow;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Termine im Monat:',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: isDarkMode
              ? Brightness.light
              : Brightness.dark,
          statusBarBrightness: isDarkMode ? Brightness.dark : Brightness.light,
        ),

        // Menü- und Einstellungsaktionen in der App-Leiste.
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.import_export),
            tooltip: 'Daten importieren/exportieren',
            onSelected: (value) {
              switch (value) {
                case 'export_ics':
                  _exportEvents();
                  break;
                case 'import_ics':
                  _importEvents();
                  break;
                case 'backup_json':
                  _performBackup();
                  break;
                case 'restore_json':
                  _performRestore();
                  break;
              }
            },
            // Menüeinträge für Import/Export und Backup/Wiederherstellung.
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'export_ics',
                enabled: false,
                child: ListTile(
                  leading: Icon(Icons.arrow_upward),
                  title: Text('Exportieren (.ics)'),
                ),
              ),
              const PopupMenuItem<String>(
                value: 'import_ics',
                child: ListTile(
                  leading: Icon(Icons.arrow_downward),
                  title: Text('Importieren (.ics)'),
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem<String>(
                value: 'backup_json',
                child: ListTile(
                  leading: Icon(Icons.backup_outlined),
                  title: Text('Backup erstellen...'),
                ),
              ),
              const PopupMenuItem<String>(
                value: 'restore_json',
                child: ListTile(
                  leading: Icon(Icons.restore_page_outlined),
                  title: Text('Backup wiederherstellen...'),
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Einstellungen',
            onPressed: _openSettings,
          ),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [startColor, endColor],
          ),
        ),
        padding: EdgeInsets.only(
          top: kToolbarHeight + MediaQuery.of(context).padding.top,
        ),
        // Kalenderansicht mit Syncfusion Flutter Calendar.
        child: SfCalendar(
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
              setState(() {
                _currentYear = newYear;
                _loadHolidaysForYear(newYear);
              });
            }
          },
        ),
      ),

      // Schaltfläche zum Hinzufügen neuer Termine.
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.floatingActionButton,
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
        // Icon für die Schaltfläche.
        child: const Icon(Icons.add),
      ),
    );
  }
}
