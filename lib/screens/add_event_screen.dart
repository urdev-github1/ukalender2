// lib/screens/add_event_screen.dart

// Importiert die grundlegenden Material Design Widgets von Flutter.
import 'package:flutter/material.dart';
// Importiert das 'intl' Paket für die internationale Datums- und Zeitformatierung.
import 'package:intl/intl.dart';
// Importiert unser eigenes Event-Modell, das die Struktur eines Termins definiert.
import '../models/event.dart';
// Importiert den Service, der für das Planen von Benachrichtigungen zuständig ist.
import '../services/notification_service.dart';

class AddEventScreen extends StatefulWidget {
  final DateTime selectedDate;
  final Event? eventToEdit; // NEU: Optionales Event zum Bearbeiten

  const AddEventScreen({
    super.key, 
    required this.selectedDate, 
    this.eventToEdit, // NEU: Im Konstruktor hinzugefügt
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

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.selectedDate;

    // NEU: Wenn ein Event zum Bearbeiten übergeben wird, fülle die Felder aus
    if (widget.eventToEdit != null) {
      final event = widget.eventToEdit!;
      _titleController.text = event.title;
      _descController.text = event.description ?? '';
      _selectedDate = event.date;
      _selectedTime = TimeOfDay.fromDateTime(event.date);
    } else {
      // Standardverhalten, wenn ein neues Event erstellt wird
      _selectedTime = TimeOfDay.now();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // NEU: Titel dynamisch anpassen
        title: Text(widget.eventToEdit == null ? 'Neuen Termin erstellen' : 'Termin bearbeiten'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
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
                decoration: const InputDecoration(labelText: 'Beschreibung (optional)'),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: Text('Datum: ${DateFormat.yMd().format(_selectedDate)}'),
                  ),
                  Expanded(
                    child: TextButton(
                      onPressed: () => _selectTime(context),
                      child: Text('Uhrzeit: ${_selectedTime.format(context)}'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    final newEventTime = DateTime(
                      _selectedDate.year,
                      _selectedDate.month,
                      _selectedDate.day,
                      _selectedTime.hour,
                      _selectedTime.minute,
                    );

                    // Erstellt ein neues Event-Objekt (unabhängig davon, ob es neu ist oder bearbeitet wurde)
                    final newEvent = Event(
                      title: _titleController.text,
                      description: _descController.text.isEmpty ? null : _descController.text,
                      date: newEventTime,
                      // Wichtig: Behalte die Originalfarbe, falls vorhanden, sonst Standard
                      color: widget.eventToEdit?.color ?? Colors.blue, 
                    );
                    
                    final eventId = DateTime.now().millisecondsSinceEpoch.remainder(100000);
                    NotificationService().scheduleReminders(eventId, newEvent.title, newEvent.date);

                    // Gibt das Event zurück, damit die CalendarScreen es verarbeiten kann
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