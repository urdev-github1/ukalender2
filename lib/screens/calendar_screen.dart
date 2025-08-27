// lib/screens/calendar_screen.dart

import 'dart:async'; // Notwendig für StreamSubscription
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ERSETZT: Der alte Import wurde entfernt.
// import 'package:share_handler/share_handler.dart';
// NEU: Import für die korrekte und funktionierende Bibliothek.
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

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
    return CalendarColorLogic.getEventColor(event);
  }

  @override
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

  // ANGEPASST: Stream-Abonnement für die neue Bibliothek.
  StreamSubscription? _intentDataStreamSubscription;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _currentYear = _focusedDay.year;
    _dataSource = EventDataSource([]);
    _loadInitialData();

    // ANGEPASST: Neue Initialisierungsmethode für receive_sharing_intent aufrufen.
    _initReceiveSharing();
  }

  @override
  void dispose() {
    // ANGEPASST: Das korrekte Abonnement beenden, um Speicherlecks zu vermeiden.
    _intentDataStreamSubscription?.cancel();
    super.dispose();
  }

  // ERSETZT: Die alte _initShareHandler Methode wurde durch diese ersetzt.
  /// Initialisiert den Listener für geteilte Inhalte mit receive_sharing_intent.
  // Ersetzen Sie die fehlerhaften Zeilen in der _initReceiveSharing() Methode:

  void _initReceiveSharing() {
    // Korrekte statische Methoden für receive_sharing_intent ^1.8.1
    _intentDataStreamSubscription = ReceiveSharingIntent.instance
        .getMediaStream()
        .listen(
          (List<SharedMediaFile> value) {
            if (value.isNotEmpty) {
              print(
                "ReceiveSharingIntent: Geteilte Datei empfangen (App aktiv): ${value.first.path}",
              );
              _handleSharedIcsFile(value.first);
            }
          },
          onError: (err) {
            print("ReceiveSharingIntent [ERROR]: Fehler im Media-Stream: $err");
          },
        );

    // Korrekte statische Methode
    ReceiveSharingIntent.instance.getInitialMedia().then((
      List<SharedMediaFile> value,
    ) {
      if (value.isNotEmpty) {
        print(
          "ReceiveSharingIntent: Geteilte Datei empfangen (beim App-Start): ${value.first.path}",
        );
        _handleSharedIcsFile(value.first);
      }
    });
  }

  // ERSETZT: Die alte _handleSharedFile Methode wurde durch diese ersetzt.
  /// Verarbeitet eine geteilte ICS-Datei von receive_sharing_intent.
  Future<void> _handleSharedIcsFile(SharedMediaFile file) async {
    // Der Pfad von dieser Bibliothek ist in der Regel bereits in einem für die App zugänglichen Cache-Ordner.
    if (file.path.toLowerCase().endsWith('.ics')) {
      final String path = file.path;

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Importiere geteilte Termine...')),
      );

      // Wir rufen die wiederverwendbare parseIcsFile-Methode im CalendarService auf.
      final List<Event> importedEvents = await _calendarService.parseIcsFile(
        path,
      );

      if (!mounted) return;

      if (importedEvents.isNotEmpty) {
        for (final event in importedEvents) {
          await _storageService.addEvent(event);
        }
        await _loadInitialData();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${importedEvents.length} Termin(e) erfolgreich importiert.',
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Import fehlgeschlagen oder keine Termine in der Datei gefunden.',
            ),
          ),
        );
      }
    } else {
      print(
        "ReceiveSharingIntent: Geteilte Datei ist keine .ics-Datei: ${file.path}",
      );
    }
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
    _storageService.deleteEvent(event.id).then((_) {
      if (!mounted) return;
      _loadInitialData();
    });
  }

  /// Aktualisiert einen bestehenden Termin und lädt die Daten neu.
  void _updateEvent(Event oldEvent, Event newEvent) {
    final int oldNotificationId = oldEvent.id.hashCode;
    NotificationService().cancelReminders(oldNotificationId);
    _storageService.updateEvent(newEvent).then((_) {
      if (!mounted) return;
      _loadInitialData();
    });
  }

  /// Importiert Termine aus einer .ics-Datei und lädt die Daten neu.
  void _importEvents() async {
    // ANGEPASST: Ruft die umbenannte Methode im Service auf, um Klarheit zu schaffen.
    final List<Event> importedEvents = await _calendarService
        .importEventsFromPicker();

    if (importedEvents.isNotEmpty) {
      for (final event in importedEvents) {
        await _storageService.addEvent(event);
      }
      await _loadInitialData();
    }
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
    if (restoredEvents.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Wiederherstellung abgebrochen oder Datei ungültig.'),
        ),
      );
      return;
    }
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
            style: TextButton.styleFrom(
              foregroundColor: AppColors.destructiveActionColor,
            ),
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

    if (choice == null || !mounted) return;
    if (choice == 'replace') {
      await _storageService.clearAllEvents();
    }
    for (final event in restoredEvents) {
      await _storageService.addEvent(event);
    }
    await _loadInitialData();
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

  /// Öffnet den Einstellungsbildschirm.
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
    final colorScheme = Theme.of(context).colorScheme;
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
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
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
        child: const Icon(Icons.add),
      ),
    );
  }
}
