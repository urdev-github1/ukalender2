// lib/services/notification_service.dart

// Importiert die notwendigen Pakete.
// 'flutter_local_notifications' ist die Hauptbibliothek zur Verwaltung von lokalen Benachrichtigungen.
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// 'timezone' wird benötigt, um Benachrichtigungen zuverlässig zu planen, 
// unabhängig von der Zeitzone des Geräts.
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

// Definiert die Klasse NotificationService.
// Dieser Service kapselt die gesamte Logik für das Senden von lokalen Benachrichtigungen.
class NotificationService {
  // Dies implementiert das Singleton-Pattern. 
  // _notificationService ist die einzige Instanz dieser Klasse.
  static final NotificationService _notificationService = NotificationService._internal();

  // Der Factory-Konstruktor stellt sicher, dass bei jedem Aufruf von NotificationService()
  // immer dieselbe Instanz (_notificationService) zurückgegeben wird.
  factory NotificationService() {
    return _notificationService;
  }

  // Der private Konstruktor verhindert, dass von außerhalb dieser Klasse neue Instanzen 
  // erstellt werden können.
  NotificationService._internal();

  // Eine Instanz des Haupt-Plugins für lokale Benachrichtigungen.
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  // Die init-Methode initialisiert den Benachrichtigungsdienst.
  // Sie sollte einmal beim Start der App aufgerufen werden (z. B. in der main()-Funktion).
  Future<void> init() async {
    // Definiert die Initialisierungseinstellungen für Android.
    // '@mipmap/ic_launcher' ist das Standard-App-Icon, das für die Benachrichtigung verwendet wird.
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // Definiert die Initialisierungseinstellungen für iOS.
    const DarwinInitializationSettings initializationSettingsIOS = DarwinInitializationSettings();

    // Fasst die plattformspezifischen Einstellungen in einem Objekt zusammen.
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    // Initialisiert die Zeitzonen-Datenbank. Dies ist eine Voraussetzung für die Verwendung
    // von `zonedSchedule`, um zeitlich geplante Benachrichtigungen zu versenden.
    tz.initializeTimeZones();
    
    // Initialisiert das Plugin mit den zuvor definierten Einstellungen.
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

// Plant eine einzelne Benachrichtigung zu einem bestimmten Zeitpunkt.
Future<void> scheduleNotification(int id, String title, String body, DateTime scheduledTime) async {
  // Verwendet `zonedSchedule`, um die Benachrichtigung präzise zu planen.
  await flutterLocalNotificationsPlugin.zonedSchedule(
    id,    // Eindeutige ID für die Benachrichtigung. Eine neue Benachrichtigung mit derselben ID überschreibt die alte.
    title, // Der Titel der Benachrichtigung.
    body,  // Der Haupttext der Benachrichtigung.
    // Konvertiert die Dart `DateTime` in eine `TZDateTime`, die die lokale Zeitzone des Geräts berücksichtigt.
    tz.TZDateTime.from(scheduledTime, tz.local),
    // Definiert die Details für das Aussehen und Verhalten der Benachrichtigung.
    const NotificationDetails(
      // Android-spezifische Einstellungen.
      android: AndroidNotificationDetails(
        'main_channel', // ID des Benachrichtigungskanals.
        'Main Channel', // Name des Kanals, der in den App-Einstellungen des Geräts sichtbar ist.
        channelDescription: 'Main channel for notifications', // Beschreibung des Kanals.
        importance: Importance.max, // Setzt die Wichtigkeit auf maximal, damit die Benachrichtigung als Pop-up erscheint.
        priority: Priority.high,    // Setzt die Priorität hoch, um die Zustellung zu gewährleisten.
      ),
      // Hier könnten auch iOS-spezifische Einstellungen (`DarwinNotificationDetails`) vorgenommen werden.
      iOS: DarwinNotificationDetails(),
    ),
    // Stellt sicher, dass die Benachrichtigung auch dann zur exakten Zeit ausgelöst wird,
    // wenn sich das Android-Gerät im Energiesparmodus befindet.
    androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    // Legt fest, wie das Datum interpretiert wird, falls die Benachrichtigung erscheint, während die App im Vordergrund ist.
    // 'absoluteTime' bedeutet, es wird der exakte, geplante Zeitpunkt verwendet.
    uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
  );
}

  // Eine Hilfsfunktion, um automatisch Erinnerungen für ein Ereignis zu planen.
  Future<void> scheduleReminders(int baseId, String title, DateTime eventTime) async {
    // --- Erinnerung 1 Stunde vor dem Termin ---
    // Prüft, ob der Termin mehr als eine Stunde in der Zukunft liegt.
    if (eventTime.isAfter(DateTime.now().add(const Duration(hours: 1)))) {
      // Plant eine Benachrichtigung eine Stunde vor dem `eventTime`.
      await scheduleNotification(
        baseId, // Verwendet die Basis-ID für die erste Erinnerung.
        'Erinnerung: $title', 
        'Ihr Termin beginnt in einer Stunde.', 
        eventTime.subtract(const Duration(hours: 1)),
      );
    }

    // --- Erinnerung 24 Stunden vor dem Termin ---
    // Prüft, ob der Termin mehr als 24 Stunden in der Zukunft liegt.
    if (eventTime.isAfter(DateTime.now().add(const Duration(days: 1)))) {
      // Plant eine Benachrichtigung einen Tag vor dem `eventTime`.
      await scheduleNotification(
        baseId + 1, // Verwendet eine andere ID, um die 1-Stunden-Erinnerung nicht zu überschreiben.
        'Erinnerung: $title', 
        'Ihr Termin beginnt morgen.', 
        eventTime.subtract(const Duration(days: 1)),
      );
    }
  }
}