// lib/screens/add_event_screen.dart

// Importiert die grundlegenden Material Design Widgets von Flutter.
import 'package:flutter/material.dart';
// Importiert das 'intl' Paket für die internationale Datums- und Zeitformatierung.
import 'package:intl/intl.dart';
// Importiert unser eigenes Event-Modell, das die Struktur eines Termins definiert.
import '../models/event.dart';
// Importiert den Service, der für das Planen von Benachrichtigungen zuständig ist.
import '../services/notification_service.dart';

// Ein StatefulWidget, das den Bildschirm zum Hinzufügen eines neuen Termins darstellt.
// "Stateful" bedeutet, dass sich die in diesem Widget angezeigten Daten ändern können.
class AddEventScreen extends StatefulWidget {
  // Das Datum, das vom vorherigen Bildschirm (z.B. dem Kalender) ausgewählt wurde.
  final DateTime selectedDate;

  // Der Konstruktor für das Widget. Er erfordert ein 'selectedDate'.
  const AddEventScreen({super.key, required this.selectedDate});

  // Erstellt den veränderlichen Zustand (State) für dieses Widget.
  @override
  State<AddEventScreen> createState() => _AddEventScreenState();
}

// Die State-Klasse für den AddEventScreen. Hier werden die veränderlichen Daten gespeichert.
class _AddEventScreenState extends State<AddEventScreen> {
  // Ein globaler Schlüssel, der das Formular eindeutig identifiziert.
  // Wird für die Validierung der Eingabefelder benötigt.
  final _formKey = GlobalKey<FormState>();
  
  // Controller für das Titel-Eingabefeld. Er liest und steuert den Text im Feld.
  final _titleController = TextEditingController();
  
  // Controller für das Beschreibungs-Eingabefeld.
  final _descController = TextEditingController();
  
  // Speichert das Datum des neuen Termins.
  late DateTime _selectedDate;
  
  // Speichert die Uhrzeit des neuen Termins, initialisiert mit der aktuellen Zeit.
  TimeOfDay _selectedTime = TimeOfDay.now();

  // Diese Methode wird einmalig aufgerufen, wenn das Widget initialisiert wird.
  @override
  void initState() {
    super.initState();
    // Übernimmt das ausgewählte Datum aus dem übergeordneten Widget in den lokalen State.
    _selectedDate = widget.selectedDate;
  }

  // Diese Methode wird aufgerufen, wenn das Widget endgültig aus dem Widget-Baum entfernt wird.
  @override
  void dispose() {
    // Gibt die Ressourcen der Controller frei, um Speicherlecks zu vermeiden.
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  // Eine asynchrone Methode, um einen Zeitauswahldialog anzuzeigen.
  Future<void> _selectTime(BuildContext context) async {
    // Zeigt den eingebauten TimePicker von Flutter an.
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime, // Startet mit der aktuell ausgewählten Zeit.
    );
    // Wenn der Benutzer eine Zeit ausgewählt hat (und nicht auf "Abbrechen" geklickt hat)...
    if (picked != null && picked != _selectedTime) {
      // ...aktualisiert den State mit der neuen Zeit. setState() sorgt dafür, dass das UI neu gezeichnet wird.
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  // Die build-Methode wird jedes Mal aufgerufen, wenn das UI neu gezeichnet werden muss.
  @override
  Widget build(BuildContext context) {
    // Scaffold ist eine grundlegende Layout-Struktur für Material Design Apps.
    return Scaffold(
      appBar: AppBar(
        // Die Titelzeile des Bildschirms.
        title: const Text('Neuen Termin erstellen'),
      ),
      // Der Hauptinhalt des Bildschirms.
      body: Padding(
        // Fügt einen Innenabstand von 16 Pixeln auf allen Seiten hinzu.
        padding: const EdgeInsets.all(16.0),
        // Das Form-Widget dient als Container für die Eingabefelder.
        child: Form(
          // Weist dem Formular den oben erstellten GlobalKey zu.
          key: _formKey,
          // Ordnet die Kinder (Eingabefelder, Buttons etc.) vertikal untereinander an.
          child: Column(
            children: [
              // Ein Texteingabefeld für den Titel des Termins.
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Titel'),
                // Die validator-Funktion prüft die Eingabe.
                validator: (value) {
                  // Wenn das Feld leer ist, wird eine Fehlermeldung zurückgegeben.
                  if (value == null || value.isEmpty) {
                    return 'Bitte geben Sie einen Titel ein.';
                  }
                  // Wenn alles in Ordnung ist, wird null zurückgegeben.
                  return null;
                },
              ),
              // Ein Texteingabefeld für die optionale Beschreibung.
              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(labelText: 'Beschreibung (optional)'),
              ),
              // Fügt einen vertikalen Abstand von 20 Pixeln hinzu.
              const SizedBox(height: 20),
              // Eine Zeile, um Datum und Uhrzeit nebeneinander anzuzeigen.
              Row(
                children: [
                  // Nimmt den verfügbaren Platz in der Zeile ein.
                  Expanded(
                    // Zeigt das formatierte Datum an (z.B. "8/15/2025").
                    child: Text(
                        'Datum: ${DateFormat.yMd().format(_selectedDate)}'
                    ),
                  ),
                  // Nimmt ebenfalls den verfügbaren Platz ein.
                  Expanded(
                    // Ein Button, der bei Klick den Zeitauswahldialog öffnet.
                    child: TextButton(
                      onPressed: () => _selectTime(context),
                      // Zeigt die formatierte, ausgewählte Uhrzeit an.
                      child: Text('Uhrzeit: ${_selectedTime.format(context)}'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Der Speicher-Button.
              ElevatedButton(
                onPressed: () {
                  // Prüft, ob alle Eingabefelder im Formular gültig sind (gemäß ihren validator-Funktionen).
                  if (_formKey.currentState!.validate()) {
                    // Kombiniert das ausgewählte Datum und die ausgewählte Zeit zu einem DateTime-Objekt.
                    final newEventTime = DateTime(
                      _selectedDate.year,
                      _selectedDate.month,
                      _selectedDate.day,
                      _selectedTime.hour,
                      _selectedTime.minute,
                    );

                    // Erstellt eine neue Instanz des Event-Modells mit den eingegebenen Daten.
                    final newEvent = Event(
                      title: _titleController.text,
                      description: _descController.text,
                      date: newEventTime,
                    );
                    
                    // --- Benachrichtigungen planen ---
                    // Erzeugt eine (relativ) eindeutige ID für die Benachrichtigung.
                    // In einer echten App würde man hier die ID aus einer Datenbank (z.B. nach dem Speichern) verwenden.
                    final eventId = DateTime.now().millisecondsSinceEpoch.remainder(100000);
                    // Ruft den NotificationService auf, um Erinnerungen für diesen Termin zu planen.
                    NotificationService().scheduleReminders(eventId, newEvent.title, newEvent.date);

                    // Schließt den aktuellen Bildschirm und gibt das neu erstellte Event
                    // an den vorherigen Bildschirm zurück.
                    Navigator.of(context).pop(newEvent);
                  }
                },
                child: const Text('Speichern'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}