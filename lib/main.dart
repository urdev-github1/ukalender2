// lib/main.dart

import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'screens/calendar_screen.dart';
import 'services/notification_service.dart';

void main() async {
  // Sicherstellen, dass die Widgets initialisiert sind, bevor Services aufgerufen werden
  WidgetsFlutterBinding.ensureInitialized();
  
  // Lokalisierungsdaten für intl (z.B. für deutsche Monatsnamen) laden
  await initializeDateFormatting('de_DE', null);
  
  // Benachrichtigungs-Service initialisieren
  await NotificationService().init();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Terminkalender',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      // Setzt die Locale auf Deutsch
      locale: const Locale('de', 'DE'),
      home: const CalendarScreen(),
    );
  }
}