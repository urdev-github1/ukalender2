// lib/screens/add_event_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../models/event.dart';
import '../services/notification_service.dart';
import '../utils/app_colors.dart';

/// Screen zum Hinzufügen oder Bearbeiten eines Termins
class AddEventScreen extends StatefulWidget {
  final DateTime selectedDate;
  final Event? eventToEdit;

  // Konstruktor
  const AddEventScreen({
    super.key,
    required this.selectedDate,
    this.eventToEdit,
  });

  @override
  State<AddEventScreen> createState() => _AddEventScreenState();
}

/// State-Klasse für den AddEventScreen
class _AddEventScreenState extends State<AddEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  late Color _selectedColor;
  bool _isBirthday = false;

  // UUID-Generator für eindeutige IDs
  final Uuid _uuid = const Uuid();

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.selectedDate;

    // Wenn ein Termin bearbeitet wurde.
    if (widget.eventToEdit != null) {
      final event = widget.eventToEdit!;
      _titleController.text = event.title;
      _descController.text = event.description ?? '';
      _selectedDate = event.date;
      _selectedTime = TimeOfDay.fromDateTime(event.date);
      _selectedColor = event.color; // Hintergrundfarbe des Termins (lightBlue)
      _isBirthday = event.isBirthday;
    } else {
      _selectedTime = TimeOfDay.now();
      // Standardfarbe für neue Termine (hellblau)
      _selectedColor = AppColors.eventColors.last;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  // Datumsauswahl-Dialog anzeigen
  Future<void> _selectDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      locale: const Locale('de', 'DE'),
    );
    if (pickedDate != null && pickedDate != _selectedDate) {
      setState(() {
        _selectedDate = pickedDate;
      });
    }
  }

  // Uhrzeitauswahl-Dialog anzeigen
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

  // Farbauswahl-Widget
  Widget _buildColorPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Farbauswahl:', style: Theme.of(context).textTheme.titleMedium),
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
              // Farbauswahl-Kreis
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: isSelected
                      ? Border.all(
                          color: AppColors.selectColorChoise,
                          width: 3.0,
                        )
                      : Border.all(
                          color: AppColors.deselectColorChoise,
                          width: 1.5,
                        ),
                ),
                child: isSelected
                    ? const Icon(
                        Icons.check,
                        color: AppColors.checkIcon,
                        size: 22,
                      )
                    : null,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // Widget für ein Textfeld mit Titel
  Widget _buildTitledTextField({
    required BuildContext context,
    required String label,
    required TextEditingController controller,
    String? hintText,
    String? Function(String?)? validator,
  }) {
    // Styling für Titel + Beschreibung
    final labelStyle = Theme.of(
      context,
    ).textTheme.titleMedium?.copyWith(color: AppColors.lableTextfield);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: labelStyle),
        const SizedBox(height: 8.0),
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hintText,
            labelText: null,
            border: const UnderlineInputBorder(),
            contentPadding: const EdgeInsets.symmetric(vertical: 10.0),
          ),
          validator: validator,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.eventToEdit != null;

    return Scaffold(
      // AppBar mit Titel und Lösch-Button (wenn Bearbeitung)
      appBar: AppBar(
        title: Text(
          isEditing ? 'Termin bearbeiten' : 'Termin erstellen',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          if (isEditing)
            IconButton(
              icon: const Icon(
                Icons.delete_outline,
                size: 25,
                color: AppColors.destructiveActionColor,
              ),
              tooltip: 'Termin löschen',
              onPressed: () async {
                final navigator = Navigator.of(context);
                final confirmDelete = await showDialog<bool>(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: const Text(
                        'Löschen bestätigen',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      // content: const Text(
                      //   'Möchten Sie diesen Termin wirklich endgültig löschen?',
                      // ),
                      actions: <Widget>[
                        // Abbrechen-Button
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: const Text(
                            'Abbrechen',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                        // Löschen-Button
                        TextButton(
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.deleteButton,
                          ),
                          onPressed: () => Navigator.of(context).pop(true),
                          child: const Text(
                            'Löschen',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ],
                    );
                  },
                );

                if (!mounted) return;
                if (confirmDelete == true) {
                  navigator.pop(true);
                }
              },
            ),
        ],
      ),
      // Formular zum Eingeben der Termindaten
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTitledTextField(
                  context: context,
                  label: 'Titel',
                  controller: _titleController,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Bitte geben Sie einen Titel ein.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                _buildTitledTextField(
                  context: context,
                  label: 'Beschreibung (optional)',
                  controller: _descController,
                ),
                const SizedBox(height: 24),
                SwitchListTile(
                  title: const Text('Jährlicher Geburtstag'),
                  // subtitle: const Text(
                  //   'Der Termin wird jedes Jahr wiederholt.',
                  // ),
                  value: _isBirthday,
                  onChanged: (bool value) {
                    setState(() {
                      _isBirthday = value;
                      if (value) {
                        _selectedColor = AppColors.birthdayColor;
                      } else {
                        _selectedColor = AppColors.defaultEventColor;
                      }
                    });
                  },
                ),
                const SizedBox(height: 16),
                // Datum- und Uhrzeitauswahl
                Row(
                  children: [
                    Expanded(
                      child: TextButton.icon(
                        icon: const Icon(Icons.calendar_today, size: 24),
                        label: Text(
                          DateFormat.yMd('de_DE').format(_selectedDate),
                          style: const TextStyle(fontSize: 17),
                        ),
                        onPressed: _selectDate,
                      ),
                    ),
                    const SizedBox(width: 12),
                    if (!_isBirthday)
                      Expanded(
                        child: TextButton.icon(
                          icon: const Icon(Icons.access_time, size: 24),
                          label: Text(
                            _selectedTime.format(context),
                            style: const TextStyle(fontSize: 17),
                          ),
                          onPressed: _selectTime,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 24),
                // Farbauswahl
                _buildColorPicker(),
                const SizedBox(height: 30),
                Center(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        final eventTime = _isBirthday
                            ? const TimeOfDay(hour: 0, minute: 0)
                            : _selectedTime;

                        final eventDateTime = DateTime(
                          _selectedDate.year,
                          _selectedDate.month,
                          _selectedDate.day,
                          eventTime.hour,
                          eventTime.minute,
                        );

                        final String eventId =
                            widget.eventToEdit?.id ?? _uuid.v4();

                        final finalEvent = Event(
                          id: eventId,
                          title: _titleController.text,
                          description: _descController.text.isEmpty
                              ? null
                              : _descController.text,
                          date: eventDateTime,
                          color: _selectedColor,
                          isBirthday: _isBirthday,
                        );
                        // Benachrichtigung planen
                        DateTime notificationDate = finalEvent.date;
                        if (finalEvent.isBirthday) {
                          final now = DateTime.now();
                          DateTime nextBirthday = DateTime(
                            now.year,
                            finalEvent.date.month,
                            finalEvent.date.day,
                          );
                          if (nextBirthday.isBefore(now)) {
                            nextBirthday = DateTime(
                              now.year + 1,
                              finalEvent.date.month,
                              finalEvent.date.day,
                            );
                          }
                          notificationDate = nextBirthday;
                        }

                        final int notificationId = eventId.hashCode;

                        // Vorherige Benachrichtigung löschen (falls vorhanden)
                        NotificationService().scheduleReminders(
                          notificationId,
                          finalEvent.title,
                          notificationDate,
                        );

                        if (!mounted) return;
                        // Zurück zur vorherigen Seite mit dem neuen/aktualisierten Termin
                        Navigator.of(context).pop(finalEvent);
                      }
                    },
                    child: const Text(
                      'Speichern',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
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
