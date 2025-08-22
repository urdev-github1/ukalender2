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

  Future<void> requestPermissions() async {
    // ... (keine Änderungen hier)
  }

  /// Zeigt eine sofortige Test-Benachrichtigung an.
  Future<void> showTestNotification() async {
    //print('--- [NotificationService] Showing IMMEDIATE Test Notification ---');
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
    //print('--- [NotificationService] Scheduling Notification ---');
    //print('ID: $id, Title: $title, Scheduled: $scheduledTime');

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
          //iOS: DarwinInitializationDetails(),
        ),
        // =======================================================================
        // ==================== HIER IST DIE ENTSCHEIDENDE ÄNDERUNG ================
        // =======================================================================
        // Wir deklarieren den Alarm als "alarmClock". Dies signalisiert dem OS
        // eine extrem hohe Priorität, die selbst von Huawei respektiert wird.
        androidScheduleMode: AndroidScheduleMode.alarmClock,
        // =======================================================================
        // =======================================================================
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
      // print('--- [NotificationService] SUCCESSFULLY scheduled notification with ID $id.',
      // );
    } catch (e) {
      // print(
      //   '--- [NotificationService] FAILED to schedule notification with ID $id. Error: $e',
      // );
    }
  }

  Future<void> scheduleReminders(
    int baseId,
    String title,
    DateTime eventTime,
  ) async {
    // print(
    //   '--- [NotificationService] scheduleReminders called for "$title" at $eventTime',
    // );

    final reminderSettings = await _storageService.getReminderMinutes();
    final reminder1Minutes = reminderSettings['reminder1']!;
    final reminder2Minutes = reminderSettings['reminder2']!;
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);

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
      } else {
        // print(
        //   '--- [NotificationService] Reminder 1 was not scheduled (in past).',
        // );
      }
    }

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
      } else {
        // print(
        //   '--- [NotificationService] Reminder 2 was not scheduled (in past).',
        // );
      }
    }
  }

  Future<void> cancelReminders(int baseId) async {
    await flutterLocalNotificationsPlugin.cancel(baseId);
    await flutterLocalNotificationsPlugin.cancel(baseId + 1);
    //print('--- [NotificationService] Canceled reminders for base ID $baseId.');
  }
}
