// lib/services/notification_service.dart

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:intl/intl.dart'; // Import hinzufügen für DateFormat
import '../services/storage_service.dart';

/// Service zur Verwaltung von lokalen Benachrichtigungen.
class NotificationService {
  static final NotificationService _notificationService =
      NotificationService._internal();

  factory NotificationService() {
    return _notificationService;
  }

  // Interner Konstruktor
  NotificationService._internal();

  // Instanz des FlutterLocalNotificationsPlugin
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  // Instanz des StorageService
  final StorageService _storageService = StorageService();

  /// Initialisiert die Benachrichtigungsdienste.
  Future<void> init() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings();

    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsIOS,
        );

    // Initialisiere Zeitzonen
    tz.initializeTimeZones();
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  /// Fordert die notwendigen Berechtigungen für Benachrichtigungen an.
  Future<void> requestPermissions() async {}

  /// Zeigt eine sofortige Test-Benachrichtigung an.
  Future<void> showTestNotification() async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'main_channel',
          'Main Channel',
          channelDescription: 'Main channel for notifications',
          importance: Importance.max,
          priority: Priority.high,
        );
    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
    );

    await flutterLocalNotificationsPlugin.show(
      99,
      'Test Benachrichtigung',
      'Wenn Sie das sehen, funktioniert der Kanal.',
      platformDetails,
    );
  }

  /// Plant eine Benachrichtigung zu einem bestimmten Zeitpunkt.
  Future<void> scheduleNotification(
    int id,
    String title,
    String body,
    DateTime scheduledTime,
  ) async {
    try {
      await flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        tz.TZDateTime.from(scheduledTime, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'main_channel',
            'Main Channel',
            channelDescription: 'Main channel for notifications',
            importance: Importance.max,
            priority: Priority.high,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (e) {
      //print('Fehler beim Planen der Benachrichtigung: $e');
    }
  }

  /// Plant Erinnerungsbenachrichtigungen basierend auf den Einstellungen.
  ///
  /// Diese Methode ermittelt, ob der Testmodus für Benachrichtigungen aktiv ist
  /// und plant entsprechend zwei Erinnerungen für einen Event.
  ///
  /// [baseId] ist die Basis-ID für die Benachrichtigungen. Die erste Benachrichtigung
  /// erhält diese ID, die zweite [baseId + 1]. Dies ermöglicht das gezielte
  /// Löschen oder Aktualisieren von Erinnerungen zu einem Event.
  /// [title] ist der Titel des Events, der in der Benachrichtigung angezeigt wird.
  /// [eventTime] ist der Startzeitpunkt des Termins.
  Future<void> scheduleReminders(
    int baseId,
    String title,
    DateTime eventTime, // Startzeit des Termins
  ) async {
    // Prüfen, welcher Benachrichtigungsmodus (Standard oder Test) aktiv ist.
    final isTestMode = await _storageService.getIsTestNotification();
    // Aktuelle Zeit in der lokalen Zeitzone
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);

    int reminder1Minutes;
    int reminder2Minutes;
    String reminder1Body;
    String reminder2Body;

    // Im Testmodus werden die benutzerdefinierten Werte aus den Einstellungen verwendet.
    if (isTestMode) {
      final reminderSettings = await _storageService.getReminderMinutes();
      reminder1Minutes = reminderSettings['reminder1']!;
      reminder2Minutes = reminderSettings['reminder2']!;
      reminder1Body = 'Der Termin beginnt in $reminder1Minutes Minuten.';
      reminder2Body = 'Der Termin beginnt in $reminder2Minutes Minuten.';
    } else {
      // Im Standardmodus werden die festen Werte (24h / 2h) verwendet.
      reminder1Minutes = 1440; // 24 * 60
      reminder2Minutes = 120;

      // Initialisiert einen DateFormatter, um die Uhrzeit des Events im Format HH:mm zu erhalten.
      final timeFormat = DateFormat('HH:mm');
      // Setzt den Text für die erste Benachrichtigung (24 Stunden vorher).
      reminder1Body =
          'Der Termin beginnt morgen um ${timeFormat.format(eventTime)} Uhr.';
      // Setzt den Text für die zweite Benachrichtigung (2 Stunden vorher).
      reminder2Body =
          'Der Termin beginnt in 2 Std. um ${timeFormat.format(eventTime)} Uhr.';
    }

    // --- Planung der ersten Benachrichtigung ---
    // Überprüft, ob eine erste Erinnerung geplant werden soll.
    if (reminder1Minutes > 0) {
      // Berechnet den Zeitpunkt für die erste Erinnerung.
      final reminder1Time = eventTime.subtract(
        Duration(minutes: reminder1Minutes),
      );
      // Prüft, ob der berechnete Erinnerungszeitpunkt in der Zukunft liegt.
      if (reminder1Time.isAfter(now)) {
        // Plant die Benachrichtigung unter Verwendung der `scheduleNotification`-Methode.
        await scheduleNotification(
          // Die `baseId` dient als eindeutige ID für diese Benachrichtigung.
          baseId,
          title,
          reminder1Body, // Der zuvor definierte Textkörper der Benachrichtigung
          reminder1Time, // Der Zeitpunkt, wann die Benachrichtigung erscheinen soll
        );
      } else {
        // Optional: Log-Ausgabe oder andere Behandlung, wenn die Erinnerungszeit bereits vergangen ist.
      }
    }

    // --- Planung der zweiten Benachrichtigung ---
    // Überprüft, ob eine zweite Erinnerung geplant werden soll.
    if (reminder2Minutes > 0) {
      final reminder2Time = eventTime.subtract(
        Duration(minutes: reminder2Minutes),
      );
      if (reminder2Time.isAfter(now)) {
        await scheduleNotification(
          baseId + 1,
          title,
          reminder2Body,
          reminder2Time,
        );
      } else {
        // Optional: Log-Ausgabe oder andere Behandlung, wenn die Erinnerungszeit bereits vergangen ist.
      }
    }
  }

  /// Löscht alle geplanten Erinnerungsbenachrichtigungen für einen Termin.
  ///
  /// Diese Methode wird aufgerufen, um alle zuvor geplanten Benachrichtigungen
  /// für ein bestimmtes Event zu entfernen, z.B. wenn ein Event gelöscht oder aktualisiert wird.
  ///
  /// [baseId] ist die Basis-ID des Events. Es werden die Benachrichtigung mit [baseId]
  /// und [baseId + 1] gelöscht.
  Future<void> cancelReminders(int baseId) async {
    // Löscht die erste geplante Benachrichtigung mit der `baseId`.
    await flutterLocalNotificationsPlugin.cancel(baseId);
    // Löscht die zweite geplante Benachrichtigung mit der `baseId + 1`.
    await flutterLocalNotificationsPlugin.cancel(baseId + 1);
  }
}
