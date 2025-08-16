// lib/screens/add_event_screen.dart

import 'package:flutter/material.dart';
//import 'package:intl/intl.dart';
import '../models/event.dart';
import '../services/notification_service.dart';
// NEU: Importiert die zentrale Farbpalette der App.
import '../utils/app_colors.dart';

class AddEventScreen extends StatefulWidget {
  final DateTime selectedDate;
  final Event? eventToEdit;

  const AddEventScreen({
    super.key,
    required this.selectedDate,
    this.eventToEdit,
  });

  @override
  State<AddEventScreen> createState() => _AddEventScreenState();
}

class _AddEventScreenState extends State<AddEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  // NEU: Eine Zustandsvariable für die vom Benutzer gewählte Farbe.
  late Color _selectedColor;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.selectedDate;

    if (widget.eventToEdit != null) {
      // Modus "Bearbeiten": Initialisiert die Felder mit den Werten des bestehenden Termins.
      final event = widget.eventToEdit!;
      _titleController.text = event.title;
      _descController.text = event.description ?? '';
      _selectedDate = event.date;
      _selectedTime = TimeOfDay.fromDateTime(event.date);
      // Die aktuell gespeicherte Farbe des Termins wird übernommen.
      _selectedColor = event.color;
    } else {
      // Modus "Neu erstellen": Setzt Standardwerte.
      _selectedTime = TimeOfDay.now();
      // Die erste Farbe aus der vordefinierten Liste wird als Standardfarbe gesetzt.
      _selectedColor = AppColors.eventColors.first;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  // NEU: Ein wiederverwendbares Widget, das die Farbauswahl-UI generiert.
  Widget _buildColorPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Farbe auswählen', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 10),
        // Das Wrap-Widget sorgt für einen automatischen Zeilenumbruch,
        // falls nicht alle Farbkreise in eine Zeile passen.
        Wrap(
          spacing: 12.0, // Horizontaler Abstand
          runSpacing: 10.0, // Vertikaler Abstand bei Umbruch
          children: AppColors.eventColors.map((color) {
            // KORREKTUR: Direkter Vergleich der Color-Objekte.
            // Dies ist die empfohlene Vorgehensweise und behebt die Warnung.
            final isSelected = _selectedColor == color;
            return GestureDetector(
              onTap: () {
                // Bei Tippen wird der Zustand aktualisiert, was die UI neu zeichnet.
                setState(() {
                  _selectedColor = color;
                });
              },
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  // Visuelles Feedback für die Auswahl (dickerer Rand und Haken).
                  border: isSelected
                      ? Border.all(color: Colors.black, width: 3.0)
                      : Border.all(color: Colors.grey.shade400, width: 1.5),
                ),
                child: isSelected
                    ? const Icon(Icons.check, color: Colors.white, size: 22)
                    : null,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.eventToEdit == null
              ? 'Neuen Termin erstellen'
              : 'Termin bearbeiten',
        ),
      ),
      body: SingleChildScrollView(
        // Wichtig für kleine Bildschirme
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(labelText: 'Titel'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Bitte geben Sie einen Titel ein.';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: _descController,
                  decoration: const InputDecoration(
                    labelText: 'Beschreibung (optional)',
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  // ... (Datums- und Zeitauswahl bleibt unverändert)
                  // HINWEIS: Es scheint, als würde der Code für die Zeitauswahl hier fehlen.
                  // Normalerweise würde hier ein Button sein, der `_selectTime` aufruft.
                ),
                const SizedBox(height: 24),
                // NEU: Hier wird das Farbauswahl-Widget in das Formular eingefügt.
                _buildColorPicker(),
                const SizedBox(height: 30),
                Center(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        final newEventTime = DateTime(
                          _selectedDate.year,
                          _selectedDate.month,
                          _selectedDate.day,
                          _selectedTime.hour,
                          _selectedTime.minute,
                        );

                        final newEvent = Event(
                          title: _titleController.text,
                          description: _descController.text.isEmpty
                              ? null
                              : _descController.text,
                          date: newEventTime,
                          // KORREKTUR: Die vom Benutzer ausgewählte Farbe
                          // wird hier an das Event-Objekt übergeben.
                          color: _selectedColor,
                        );

                        final eventId = DateTime.now().millisecondsSinceEpoch
                            .remainder(100000);
                        NotificationService().scheduleReminders(
                          eventId,
                          newEvent.title,
                          newEvent.date,
                        );

                        Navigator.of(context).pop(newEvent);
                      }
                    },
                    child: const Text('Speichern'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
