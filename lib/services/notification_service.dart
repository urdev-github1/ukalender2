// lib/services/notification_service.dart

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

// Dieser Service kümmert sich um die Initialisierung und das Planen von lokalen Benachrichtigungen.
class NotificationService {
  static final NotificationService _notificationService = NotificationService._internal();

  factory NotificationService() {
    return _notificationService;
  }

  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS-Einstellungen hinzufügen
    const DarwinInitializationSettings initializationSettingsIOS = DarwinInitializationSettings();

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    tz.initializeTimeZones();
    
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

Future<void> scheduleNotification(int id, String title, String body, DateTime scheduledTime) async {
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
      // iOS-Einstellungen könnten hier ebenfalls hinzugefügt werden
      iOS: DarwinNotificationDetails(),
    ),
    androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    // Fügen Sie diesen Parameter wieder hinzu, da er in dieser Version erforderlich ist
    uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
  );
}

  // Erinnerungen planen (z.B. 24h und 1h vorher)
  Future<void> scheduleReminders(int baseId, String title, DateTime eventTime) async {
    // 1 Stunde vorher
    if (eventTime.isAfter(DateTime.now().add(const Duration(hours: 1)))) {
      await scheduleNotification(
        baseId, 
        'Erinnerung: $title', 
        'Ihr Termin beginnt in einer Stunde.', 
        eventTime.subtract(const Duration(hours: 1)),
      );
    }

    // 24 Stunden vorher
    if (eventTime.isAfter(DateTime.now().add(const Duration(days: 1)))) {
      await scheduleNotification(
        baseId + 1, 
        'Erinnerung: $title', 
        'Ihr Termin beginnt morgen.', 
        eventTime.subtract(const Duration(days: 1)),
      );
    }
  }
}