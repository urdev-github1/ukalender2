// lib/services/notification_service.dart

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'storage_service.dart';

class NotificationService {
  static final NotificationService _notificationService =
      NotificationService._internal();

  factory NotificationService() {
    return _notificationService;
  }

  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  final StorageService _storageService = StorageService();

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

  Future<void> scheduleReminders(
    int baseId,
    String title,
    DateTime eventTime,
  ) async {
    // Prüfen, welcher Benachrichtigungsmodus (Standard oder Test) aktiv ist.
    final isTestMode = await _storageService.getIsTestNotification();
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);

    int reminder1Minutes;
    int reminder2Minutes;

    if (isTestMode) {
      final reminderSettings = await _storageService.getReminderMinutes();
      reminder1Minutes = reminderSettings['reminder1']!;
      reminder2Minutes = reminderSettings['reminder2']!;
    } else {
      // Im Standardmodus werden die festen Werte (24h / 1h) verwendet.
      reminder1Minutes = 1440; // 24 * 60
      reminder2Minutes = 60;
    }

    // Planen der 1. Benachrichtigung
    if (reminder1Minutes > 0) {
      final reminder1Time = eventTime.subtract(
        Duration(minutes: reminder1Minutes),
      );
      if (reminder1Time.isAfter(now)) {
        await scheduleNotification(
          baseId,
          'Erinnerung: $title',
          'Ihr Termin beginnt in $reminder1Minutes Minuten.',
          reminder1Time,
        );
      } else {}
    }

    // Planen der 2. Benachrichtigung
    if (reminder2Minutes > 0) {
      final reminder2Time = eventTime.subtract(
        Duration(minutes: reminder2Minutes),
      );
      if (reminder2Time.isAfter(now)) {
        await scheduleNotification(
          baseId + 1,
          'Erinnerung: $title',
          'Ihr Termin beginnt in $reminder2Minutes Minuten.',
          reminder2Time,
        );
      } else {}
    }
  }

  Future<void> cancelReminders(int baseId) async {
    await flutterLocalNotificationsPlugin.cancel(baseId);
    await flutterLocalNotificationsPlugin.cancel(baseId + 1);
  }
}
