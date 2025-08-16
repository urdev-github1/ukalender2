// lib/screens/settings_screen.dart

import 'package:flutter/material.dart';
import '../services/storage_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final StorageService _storageService = StorageService();
  String _selectedStateCode = 'NW';

  // Map mit allen Bundesländern und deren Kürzeln
  final Map<String, String> _germanStates = {
    'NATIONAL': 'Bundesweit',
    'BW': 'Baden-Württemberg',
    'BY': 'Bayern',
    'BE': 'Berlin',
    'BB': 'Brandenburg',
    'HB': 'Bremen',
    'HH': 'Hamburg',
    'HE': 'Hessen',
    'MV': 'Mecklenburg-Vorpommern',
    'NI': 'Niedersachsen',
    'NW': 'Nordrhein-Westfalen',
    'RP': 'Rheinland-Pfalz',
    'SL': 'Saarland',
    'SN': 'Sachsen',
    'ST': 'Sachsen-Anhalt',
    'SH': 'Schleswig-Holstein',
    'TH': 'Thüringen',
  };

  @override
  void initState() {
    super.initState();
    _loadCurrentState();
  }

  void _loadCurrentState() async {
    final savedState = await _storageService.getSelectedState();
    setState(() {
      _selectedStateCode = savedState;
    });
  }

  void _onStateSelected(String? newCode) {
    if (newCode != null) {
      setState(() {
        _selectedStateCode = newCode;
      });
      _storageService.saveSelectedState(newCode);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Einstellungen'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          // Beim Zurückgehen wird der Kalender-Screen informiert, neu zu laden.
          onPressed: () => Navigator.of(context).pop(true), 
        ),
      ),
      body: ListView(
        children: _germanStates.entries.map((entry) {
          final code = entry.key;
          final name = entry.value;
          return RadioListTile<String>(
            title: Text(name),
            value: code,
            groupValue: _selectedStateCode,
            onChanged: _onStateSelected,
          );
        }).toList(),
      ),
    );
  }
}