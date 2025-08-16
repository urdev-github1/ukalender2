// lib/services/notification_service.dart

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService _notificationService =
      NotificationService._internal();

  factory NotificationService() {
    return _notificationService;
  }

  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

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

    tz.initializeTimeZones();

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  // NEU: Diese Methode hatten wir bereits im vorherigen Schritt hinzugefügt.
  // Sie ist wichtig, damit die App überhaupt Benachrichtigungen senden darf.
  Future<void> requestPermissions() async {
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
  }

  Future<void> scheduleNotification(
    int id,
    String title,
    String body,
    DateTime scheduledTime,
  ) async {
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
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> scheduleReminders(
    int baseId,
    String title,
    DateTime eventTime,
  ) async {
    if (eventTime.isAfter(DateTime.now().add(const Duration(hours: 1)))) {
      await scheduleNotification(
        baseId,
        'Erinnerung: $title',
        'Ihr Termin beginnt in einer Stunde.',
        eventTime.subtract(const Duration(hours: 1)),
      );
    }

    if (eventTime.isAfter(DateTime.now().add(const Duration(days: 1)))) {
      await scheduleNotification(
        baseId + 1,
        'Erinnerung: $title',
        'Ihr Termin beginnt morgen.',
        eventTime.subtract(const Duration(days: 1)),
      );
    }
  }

  // KORREKTUR: HIER IST DIE FEHLENDE METHODE
  Future<void> cancelReminders(int baseId) async {
    // Storniert die 1-Stunden-Erinnerung
    await flutterLocalNotificationsPlugin.cancel(baseId);
    // Storniert die 24-Stunden-Erinnerung
    await flutterLocalNotificationsPlugin.cancel(baseId + 1);
  }
}
