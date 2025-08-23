// lib/screens/calendar_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  bool isAllDay(int index) {
    final Event event = appointments![index] as Event;
    return event.isHoliday || event.isBirthday;
  }
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
      final List<Event> displayEvents = [];
      displayEvents.addAll(_userEvents.where((event) => !event.isBirthday));

      final birthdayEvents = _userEvents.where((event) => event.isBirthday);
      for (final birthday in birthdayEvents) {
        for (int yearOffset = -1; yearOffset <= 1; yearOffset++) {
          final targetYear = _currentYear + yearOffset;
          final birthdayInYear = DateTime(
            targetYear,
            birthday.date.month,
            birthday.date.day,
          );
          displayEvents.add(birthday.copyWith(date: birthdayInYear));
        }
      }

      _allEvents = [...displayEvents, ..._holidays];
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
      _loadInitialData();
    });
  }

  void _deleteEvent(Event event) {
    if (event.isHoliday) return;
    final int notificationId = event.id.hashCode;
    NotificationService().cancelReminders(notificationId);

    _storageService.deleteEvent(event.id).then((_) {
      if (!mounted) return;
      _loadInitialData();
    });
  }

  void _updateEvent(Event oldEvent, Event newEvent) {
    final int oldNotificationId = oldEvent.id.hashCode;
    NotificationService().cancelReminders(oldNotificationId);

    _storageService.updateEvent(newEvent).then((_) {
      if (!mounted) return;
      _loadInitialData();
    });
  }

  // --- Logic for Import/Export & Backup/Restore ---

  /// **REVISED**: This function now completes all async work first,
  /// then checks if the widget is still mounted before showing a SnackBar.
  void _importEvents() async {
    final List<Event> importedEvents = await _calendarService.importEvents();

    if (importedEvents.isNotEmpty) {
      for (final event in importedEvents) {
        // "Insert or Replace" logic
        await _storageService.addEvent(event);
      }
      await _loadInitialData();
    }

    // After all async operations, check if the widget is still in the tree.
    if (!mounted) return;

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

  /// **REVISED**: This function now includes 'mounted' checks after each
  /// async operation (await) before using the BuildContext.
  void _performRestore() async {
    // 1. Read events from the backup file.
    final List<Event> restoredEvents = await _calendarService
        .restoreFromInternalBackup();

    // 2. After the await, check if the widget is still mounted.
    if (!mounted) return;

    if (restoredEvents.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Wiederherstellung abgebrochen oder Datei ungültig.'),
        ),
      );
      return;
    }

    // 3. Show the dialog to let the user choose the strategy.
    // The context is safe to use here because of the 'mounted' check above.
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

    // 4. After the dialog is closed, the widget might have been unmounted.
    // Check again before proceeding.
    if (choice == null || !mounted) return;

    // 5. Handle the user's decision and perform storage operations.
    if (choice == 'replace') {
      await _storageService.clearAllEvents();
    }

    for (final event in restoredEvents) {
      await _storageService.addEvent(event);
    }

    // 6. Reload the UI and show a success message.
    await _loadInitialData();

    // 7. Check if mounted one last time before the final SnackBar.
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${restoredEvents.length} Termin(e) wiederhergestellt.'),
      ),
    );
  }

  Widget _monthCellBuilder(BuildContext context, MonthCellDetails details) {
    // This method is unchanged and correct
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
                      final Event originalEvent = _userEvents.firstWhere(
                        (e) => e.id == event.id,
                        orElse: () => event,
                      );
                      // Using context before the 'await' is safe.
                      final result = await Navigator.push<dynamic>(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AddEventScreen(
                            selectedDate: originalEvent.date,
                            eventToEdit: originalEvent,
                          ),
                        ),
                      );
                      // No context is used after the 'await', so no 'mounted' check is needed here.
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

  void _openSettings() async {
    // Using context before the 'await' is safe.
    final shouldReload = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const SettingsScreen()),
    );
    // No context is used after the 'await'.
    if (shouldReload == true) {
      _loadHolidaysForYear(_currentYear);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final Color startColor = Color.lerp(
      colorScheme.surface,
      colorScheme.primaryContainer,
      0.3,
    )!;
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
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color.fromARGB(255, 131, 185, 201),
        onPressed: () async {
          // Using context before the 'await' is safe.
          final result = await Navigator.push<Event>(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  AddEventScreen(selectedDate: _selectedDay ?? DateTime.now()),
            ),
          );
          // No context is used after the 'await'.
          if (result != null) {
            _addEvent(result);
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
