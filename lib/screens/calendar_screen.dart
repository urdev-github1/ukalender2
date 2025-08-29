// lib/screens/calendar_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
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
import '../services/share_intent_service.dart';
import '../features/event_import_export/event_importer.dart';
import '../features/event_import_export/event_exporter.dart';
import '../features/event_import_export/event_backup_restorer.dart';
import 'package:ukalender2/screens/event_list_screen.dart';
import '../features/event_import_export/backup_restore_dialogs.dart';
import '../widgets/calendar_app_bar.dart';
import '../widgets/calendar_main_body.dart';

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
  final DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  late int _currentYear;
  final HolidayService _holidayService = HolidayService();
  final StorageService _storageService = StorageService();
  final CalendarService _calendarService = CalendarService();

  late ShareIntentService _shareIntentService;

  late EventImporter _eventImporter;
  late EventExporter _eventExporter;
  late EventBackupRestorer _eventBackupRestorer;

  // CalendarController kommt aus dem Syncfusion Flutter Calendar Paket.
  // _calendarController <- Instanz von CalendarController()
  final CalendarController _calendarController = CalendarController();

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _currentYear = _focusedDay.year;
    _dataSource = EventDataSource([]);
    _loadInitialData();

    _shareIntentService = ShareIntentService(
      calendarService: _calendarService,
      storageService: _storageService,
      showSnackBar: (snackBar) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(snackBar);
        }
      },
      onEventsImported: _loadInitialData,
    );
    _shareIntentService.initReceiveSharing();

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
      showConfirmationDialog: (contentWidget) =>
          showBackupRestoreConfirmationDialog(
            context: context,
            contentWidget: contentWidget,
          ),
    );
  }

  @override
  void dispose() {
    _shareIntentService.dispose();
    _calendarController.dispose();
    super.dispose();
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

  void _handleAppBarAction(String value) {
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
  }

  void _importEvents() async {
    await _eventImporter.importEvents();
  }

  void _exportEvents() async {
    await _eventExporter.exportEvents(_userEvents);
  }

  void _performBackup() async {
    await _eventBackupRestorer.createBackup(_userEvents);
  }

  void _performRestore() async {
    await _eventBackupRestorer.restoreBackup();
  }

  void _openSettings() async {
    final shouldReload = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const SettingsScreen()),
    );
    if (shouldReload == true) {
      _loadHolidaysForYear(_currentYear);
    }
  }

  void _onCalendarViewChanged(ViewChangedDetails details) {
    final newYear = details.visibleDates.first.year;
    if (newYear != _currentYear) {
      setState(() {
        _currentYear = newYear;
        _loadHolidaysForYear(newYear);
      });
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
    // Struktur des Kalender-Screens
    return Scaffold(
      // Benutzerdefinierte AppBar
      // CalendarAppBar Widget (lib/widgets/calendar_app_bar.dart)
      appBar: CalendarAppBar(
        calendarController: _calendarController,
        // Callback-Funktion (Bedienungen in der AppBar)
        onListPressed: () {
          // Terminliste aufrufen
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EventListScreen(
                // Liste mit den Events übergeben
                allEvents: _allEvents,
                // Events ab dem aktuellen Datum anzeigen
                initialSelectedDate: _selectedDay,
              ),
            ),
          );
        },
        // Callback-Funktionen
        onPreviousMonth: () => _calendarController.backward!(),
        onNextMonth: () => _calendarController.forward!(),
        onActionSelected: _handleAppBarAction,
        onSettingsPressed: _openSettings,
      ),

      extendBodyBehindAppBar: true,

      // Kalendergitter (lib/widgets/calendar_main_body.dart)
      body: CalendarMainBody(
        calendarController: _calendarController,
        dataSource: _dataSource,
        initialDisplayDate: _focusedDay,
        selectedDay: _selectedDay,
        // Callback-Funktion
        onCalendarTapped: _onCalendarTapped,
        userEvents: _userEvents,
        onUpdateEvent: _updateEvent,
        onDeleteEvent: _deleteEvent,
        onViewChanged: _onCalendarViewChanged,
        startColor: startColor,
        endColor: endColor,
        focusedDay: _focusedDay,
      ),

      // Termine erstellen
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
