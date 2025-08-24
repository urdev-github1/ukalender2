// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import '../screens/calendar_screen.dart';
import '../services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase initialisieren.
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await initializeDateFormatting('de_DE', null);

  // Benachrichtigungsdienst initialisieren und Berechtigungen anfragen.
  await NotificationService().init();
  await NotificationService().requestPermissions();
  runApp(const MyApp());
}

/// Hauptanwendungsklasse.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Terminkalender',

      // Standardhelligkeit und -farben festlegen.
      theme: ThemeData(
        useMaterial3: true,
        // Hauptakzentfarbe der App definieren.
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF006C4E),
          brightness: Brightness.light,
        ),

        // Kartenstil anpassen.
        cardTheme: CardThemeData(
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          color: ColorScheme.fromSeed(
            seedColor: const Color(0xFF006C4E),
            brightness: Brightness.light,
          ).surfaceContainerHigh,
        ),
      ),

      // // Dunkelmodus-Thema definieren.
      // themeMode: ThemeMode.light,

      // Stellt sprachspezifische Texte und Layouts für die Flutter-Widgets bereit.
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      // Lokalisierungen und unterstützte Sprachen festlegen.
      supportedLocales: const [Locale('de', 'DE'), Locale('en', 'US')],
      locale: const Locale('de', 'DE'),

      // Startbildschirm der App festlegen.
      home: const CalendarScreen(),
    );
  }
}
