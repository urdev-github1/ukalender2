// lib/screens/add_event_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart'; // NEU: Import für eindeutige IDs
import '../models/event.dart';
import '../services/notification_service.dart';
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
  late Color _selectedColor;

  // NEU: Eine Instanz zur Generierung von UUIDs
  final Uuid _uuid = const Uuid();

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
      _selectedColor = event.color;
    } else {
      // Modus "Neu erstellen": Setzt Standardwerte.
      _selectedTime = TimeOfDay.now();
      _selectedColor = AppColors.eventColors.first;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  // --- HILFSMETHODEN FÜR DATUMS- UND ZEITAUSWAHL ---

  Future<void> _selectDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      locale: const Locale(
        'de',
        'DE',
      ), // Stellt sicher, dass der Kalender auf Deutsch ist
    );
    if (pickedDate != null && pickedDate != _selectedDate) {
      setState(() {
        _selectedDate = pickedDate;
      });
    }
  }

  Future<void> _selectTime() async {
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (pickedTime != null && pickedTime != _selectedTime) {
      setState(() {
        _selectedTime = pickedTime;
      });
    }
  }

  // Das Widget für die Farbauswahl bleibt unverändert.
  Widget _buildColorPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Farbe auswählen', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 10),
        Wrap(
          spacing: 12.0,
          runSpacing: 10.0,
          children: AppColors.eventColors.map((color) {
            final isSelected = _selectedColor == color;
            return GestureDetector(
              onTap: () {
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
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descController,
                  decoration: const InputDecoration(
                    labelText: 'Beschreibung (optional)',
                  ),
                ),
                const SizedBox(height: 24),

                // KORREKTUR: Implementierte Datums- und Zeitauswahl
                Row(
                  children: [
                    Expanded(
                      child: TextButton.icon(
                        icon: const Icon(Icons.calendar_today),
                        label: Text(
                          DateFormat.yMMMd('de_DE').format(_selectedDate),
                        ),
                        onPressed: _selectDate,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextButton.icon(
                        icon: const Icon(Icons.access_time),
                        label: Text(_selectedTime.format(context)),
                        onPressed: _selectTime,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildColorPicker(),
                const SizedBox(height: 30),
                Center(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        final eventDateTime = DateTime(
                          _selectedDate.year,
                          _selectedDate.month,
                          _selectedDate.day,
                          _selectedTime.hour,
                          _selectedTime.minute,
                        );

                        // KORREKTUR: Eindeutige ID-Generierung
                        // Beim Bearbeiten wird die alte ID beibehalten,
                        // nur bei neuen Terminen wird eine neue generiert.
                        final String eventId =
                            widget.eventToEdit?.id ?? _uuid.v4();

                        // Erstellt das finale Event-Objekt
                        final finalEvent = Event(
                          id: eventId, // Wichtig: Die ID dem Objekt mitgeben
                          title: _titleController.text,
                          description: _descController.text.isEmpty
                              ? null
                              : _descController.text,
                          date: eventDateTime,
                          color: _selectedColor,
                        );

                        // Die ID für Benachrichtigungen muss ein Integer sein.
                        // Der Hash-Code der UUID ist dafür eine sichere Wahl.
                        final int notificationId = eventId.hashCode;

                        // Planen der Benachrichtigungen
                        NotificationService().scheduleReminders(
                          notificationId,
                          finalEvent.title,
                          finalEvent.date,
                        );

                        // Gibt das erstellte/bearbeitete Event an den Kalender-Screen zurück
                        Navigator.of(context).pop(finalEvent);
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
