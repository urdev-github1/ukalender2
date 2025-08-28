// lib/screens/calendar_screen.dart

import 'dart:async'; // Notwendig für StreamSubscription
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:ukalender2/calendar/event_data_source.dart';
import '../models/event.dart';
import '../services/holiday_service.dart';
import '../screens/add_event_screen.dart';
import '../services/storage_service.dart';
import '../services/calendar_service.dart';
import '../screens/settings_screen.dart';
import '../services/notification_service.dart';
import '../utils/app_colors.dart';
import '../widgets/calendar_month_cell.dart';
import '../services/share_intent_service.dart';
import '../features/event_import_export/event_importer.dart';
import '../features/event_import_export/event_exporter.dart';
import '../features/event_import_export/event_backup_restorer.dart';

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

  // Kapselt die gesamte Logik für receive_sharing_intent.
  late ShareIntentService _shareIntentService;

  // NEUE INSTANZEN DER MANAGER-KLASSEN
  late EventImporter _eventImporter;
  late EventExporter _eventExporter;
  // Verwaltet Backup und Restore
  late EventBackupRestorer _eventBackupRestorer;

  final CalendarController _calendarController = CalendarController();

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _currentYear = _focusedDay.year;
    _dataSource = EventDataSource([]);
    _loadInitialData();

    // ShareIntentService initialisieren
    _shareIntentService = ShareIntentService(
      calendarService: _calendarService,
      storageService: _storageService,
      showSnackBar: (snackBar) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(snackBar);
        }
      },
      // Callback, um Daten neu zu laden
      onEventsImported: _loadInitialData,
    );
    _shareIntentService
        // Initialisierungsmethode des Services aufrufen
        .initReceiveSharing();

    // Manager-Klassen initialisieren
    _eventImporter = EventImporter(
      calendarService: _calendarService,
      storageService: _storageService,
      onEventsImported: _loadInitialData,
      showSnackBar: (snackBar) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(snackBar);
      },
    );

    _eventExporter = EventExporter(
      calendarService: _calendarService,
      showSnackBar: (snackBar) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(snackBar);
      },
    );

    _eventBackupRestorer = EventBackupRestorer(
      calendarService: _calendarService,
      storageService: _storageService,
      onEventsRestored: _loadInitialData,
      showSnackBar: (snackBar) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(snackBar);
      },
      // Übergabe der Dialog-Logik an den Manager
      showConfirmationDialog: (contentWidget) => showDialog<String>(
        context: context,
        builder: (BuildContext context) => AlertDialog(
          title: const Text('Backup wiederherstellen'),
          content: contentWidget,
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
      ),
    );
  }

  @override
  void dispose() {
    // Dispose-Methode des Services aufrufen
    _shareIntentService.dispose();
    super.dispose();
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
    await _eventImporter.importEvents();
  }

  /// Exportiert die aktuellen Termine in eine .ics-Datei.
  void _exportEvents() async {
    await _eventExporter.exportEvents(_userEvents);
  }

  /// Erstellt ein internes Backup der aktuellen Termine im JSON-Format.
  void _performBackup() async {
    await _eventBackupRestorer.createBackup(_userEvents);
  }

  /// Stellt Termine aus einem internen JSON-Backup wieder her.
  void _performRestore() async {
    await _eventBackupRestorer.restoreBackup();
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
        backgroundColor: Colors.transparent,
        // Statusleiste (Akku, Uhrzeit, WLAN, usw.)
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
        ),
        // Die Navigations-Buttons in der Title-Eigenschaft.
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(width: 100),
            IconButton(
              // Button für vorherigen Monat
              icon: const Icon(Icons.arrow_back_ios, size: 23.0),
              tooltip: 'Vorheriger Monat',
              onPressed: () {
                // Navigiert zur vorherigen Ansicht
                _calendarController.backward!();
              },
            ),
            const SizedBox(width: 35),
            IconButton(
              // Button für nächsten Monat
              icon: const Icon(Icons.arrow_forward_ios, size: 23.0),
              tooltip: 'Nächster Monat',
              onPressed: () {
                // Navigiert zur nächsten Ansicht
                _calendarController.forward!();
              },
            ),
          ],
        ),

        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.import_export, size: 30.0),
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
                child: ListTile(
                  leading: Icon(Icons.arrow_upward),
                  title: Text(
                    'Exportieren (.ics)',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                ),
              ),
              const PopupMenuItem<String>(
                value: 'import_ics',
                child: ListTile(
                  leading: Icon(Icons.arrow_downward),
                  title: Text(
                    'Importieren (.ics)',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem<String>(
                value: 'backup_json',
                child: ListTile(
                  leading: Icon(Icons.backup_outlined),
                  title: Text(
                    'Backup erstellen...',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                ),
              ),
              const PopupMenuItem<String>(
                value: 'restore_json',
                child: ListTile(
                  leading: Icon(Icons.restore_page_outlined),
                  title: Text(
                    'Backup wiederherstellen...',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.settings, size: 26.0),
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
          controller: _calendarController,
          view: _calendarView,
          dataSource: _dataSource,
          initialDisplayDate: _focusedDay,
          initialSelectedDate: _selectedDay,
          onTap: _onCalendarTapped,
          firstDayOfWeek: 1,
          //headerHeight: 0,
          headerStyle: CalendarHeaderStyle(
            textAlign: TextAlign.center,
            backgroundColor: Colors.transparent,
            textStyle: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          //
          monthCellBuilder: (context, details) {
            return CalendarMonthCell(
              details: details,
              focusedDay: _focusedDay,
              selectedDay: _selectedDay,
              // Die Liste der User-Events übergeben
              userEvents: _userEvents,
              onUpdateEvent: _updateEvent,
              onDeleteEvent: _deleteEvent,
            );
          },
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
