// lib/main.dart

// Importiert die grundlegenden Material Design Widgets von Flutter.
import 'package:flutter/material.dart';
// NEU: Importiert die Lokalisierungs-Delegates, die wir benötigen.
import 'package:flutter_localizations/flutter_localizations.dart';
// Importiert Funktionen zur Initialisierung der Datumsformatierung für verschiedene Sprachen.
import 'package:intl/date_symbol_data_local.dart';
// Importiert den Hauptbildschirm der Anwendung, die Kalenderansicht.
import 'screens/calendar_screen.dart';
// Importiert den Service, der für das Anzeigen von Benachrichtigungen zuständig ist.
import 'services/notification_service.dart';

// Die main-Funktion ist der Haupteinstiegspunkt für jede Flutter-Anwendung.
// 'async' wird verwendet, da wir auf das Ergebnis von asynchronen Operationen warten ('await').
void main() async {
  // Stellt sicher, dass die Flutter-Engine initialisiert ist, bevor auf Plugins
  // oder Services zugegriffen wird. Dies ist notwendig, wenn die main-Funktion asynchron ist.
  WidgetsFlutterBinding.ensureInitialized();

  // Lädt und initialisiert die Lokalisierungsdaten für die Datumsformatierung.
  // 'de_DE' sorgt dafür, dass Monatsnamen, Wochentage etc. auf Deutsch angezeigt werden.
  await initializeDateFormatting('de_DE', null);

  // Erstellt eine Instanz des NotificationService und ruft dessen init-Methode auf.
  // Dies initialisiert die Einstellungen für lokale Benachrichtigungen.
  await NotificationService().init();

  // Startet die Flutter-Anwendung mit dem MyApp-Widget als Wurzel-Widget.
  runApp(const MyApp());
}

// MyApp ist das Haupt-Widget (Wurzel-Widget) der gesamten Anwendung.
// Es ist ein StatelessWidget, da sich sein eigener Zustand nicht ändert.
class MyApp extends StatelessWidget {
  // Der Konstruktor für das MyApp-Widget.
  const MyApp({super.key});

  // Die build-Methode beschreibt, wie das Widget auf dem Bildschirm dargestellt wird.
  @override
  Widget build(BuildContext context) {
    // MaterialApp ist ein grundlegendes Widget, das viele für Material Design
    // typische Funktionen bereitstellt (z.B. Navigation, Theming).
    return MaterialApp(
      // Der Titel der App, der z.B. im Task-Manager des Betriebssystems angezeigt wird.
      title: 'Flutter Terminkalender',
      // Definiert das visuelle Thema der App.
      theme: ThemeData(
        // Setzt die primäre Farbpalette der App auf Blautöne.
        primarySwatch: Colors.blue,
      ),

      // --- HINZUGEFÜGTE KONFIGURATION FÜR LOKALISIERUNG ---

      // Dies sind die "Delegierten", die die eigentliche Übersetzungsarbeit leisten.
      localizationsDelegates: const [
        // Stellt die Übersetzungen für die Material-Widgets bereit (z.B. "OK" in Dialogen).
        GlobalMaterialLocalizations.delegate,
        // Stellt die grundlegende Textausrichtung (links-nach-rechts etc.) bereit.
        GlobalWidgetsLocalizations.delegate,
        // Stellt die Übersetzungen für die Cupertino-Widgets (iOS-Stil) bereit.
        GlobalCupertinoLocalizations.delegate,
      ],

      supportedLocales: const [
        Locale('de', 'DE'), // Deutsch
        Locale('en', 'US'), // Englisch (als Beispiel)
      ],

      // Stellt die Sprache und Region der App fest auf Deutsch (Deutschland) ein.
      locale: const Locale('de', 'DE'),

      // --- ENDE DER HINZUGEFÜGTEN KONFIGURATION ---

      // Das Widget, das als Startbildschirm der App angezeigt wird.
      home: const CalendarScreen(),
    );
  }
}
