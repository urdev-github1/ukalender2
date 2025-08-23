// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'screens/calendar_screen.dart';
import 'services/notification_service.dart';
import 'package:firebase_core/firebase_core.dart';

// =======================================================================
// ==================== NEUER IMPORT HINZUFÜGEN ==========================
import 'package:firebase_messaging/firebase_messaging.dart';
// =======================================================================

import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // =======================================================================
  // ==================== HIER IST DIE ENTSCHEIDENDE ERGÄNZUNG ===============
  // Dies ist der "Weckruf" für den Firebase Messaging Dienst.
  // Wir fordern das FCM-Token an. Dieser Prozess startet den persistenten
  // Hintergrunddienst, der die App vor dem Beenden durch das OS schützt.
  try {
    final fcmToken = await FirebaseMessaging.instance.getToken();
    print('--- FCM Token (Bodyguard is active): $fcmToken ---');
  } catch (e) {
    print('--- Failed to get FCM token: $e ---');
  }
  // =======================================================================

  await initializeDateFormatting('de_DE', null);
  await NotificationService().init();
  await NotificationService().requestPermissions();
  runApp(const MyApp());
}

// Der Rest Ihrer main.dart Datei bleibt unverändert
class MyApp extends StatelessWidget {
  // ... Ihr bestehender Code
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Terminkalender',

      // Helles Thema (Light Mode)
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF006C4E), // Ein tiefes Waldgrün
          brightness: Brightness.light,
        ),

        // Der Scaffold-Hintergrund wird nicht mehr global definiert,
        // da wir ihn pro Screen mit einem Gradienten versehen.
        cardTheme: CardThemeData(
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          // --- HIER IST DIE ANPASSUNG ---
          // Die Karten bekommen eine etwas dunklere Tönung als der Hintergrund,
          // damit sie sich klarer abheben.
          color: ColorScheme.fromSeed(
            seedColor: const Color(0xFF006C4E),
            brightness: Brightness.light,
          ).surfaceContainerHigh, // Von 'surfaceContainer' zu 'surfaceContainerHigh' geändert
        ),
      ),

      // // Dunkles Thema (Dark Mode)
      // darkTheme: ThemeData(
      //   useMaterial3: true,
      //   colorScheme: ColorScheme.fromSeed(
      //     //seedColor: const Color(0xFF006C4E), // Dieselbe Samenfarbe
      //     seedColor: const Color(0xFF006C4E), // Dieselbe Samenfarbe
      //     brightness: Brightness.dark,
      //   ),

      //   cardTheme: CardThemeData(
      //     elevation: 1,
      //     shape: RoundedRectangleBorder(
      //       borderRadius: BorderRadius.circular(12),
      //     ),
      //     // --- HIER IST DIE ANPASSUNG ---
      //     // Auch im Dark Mode wird die nächstdunklere Stufe verwendet.
      //     color: ColorScheme.fromSeed(
      //       seedColor: const Color(0xFF006C4E),
      //       brightness: Brightness.dark,
      //     ).surfaceContainerHigh, // Von 'surfaceContainer' zu 'surfaceContainerHigh' geändert
      //   ),
      // ),

      //themeMode: ThemeMode.system,
      themeMode: ThemeMode.light,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('de', 'DE'), Locale('en', 'US')],
      locale: const Locale('de', 'DE'),
      home: const CalendarScreen(),
    );
  }
}
