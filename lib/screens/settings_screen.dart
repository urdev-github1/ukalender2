// lib/screens/settings_screen.dart

import 'package:flutter/material.dart';
// Import für die automatisch generierte Build-Information
//import '../scripts/generate_build_info.dart';
import '../generated/build_info.dart';
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
      // MODIFIZIERT: Das Layout wird in eine Spalte geändert,
      // um den Text unter der Liste platzieren zu können.
      body: Column(
        children: [
          // Das 'Expanded'-Widget sorgt dafür, dass die ListView den
          // gesamten verfügbaren Platz in der Spalte einnimmt.
          Expanded(
            child: ListView(
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
          ),

          // NEU: Ein Bereich am unteren Rand für die Build-Information.
          // Eine Trennlinie für eine saubere visuelle Abgrenzung.
          const Divider(height: 1.0, thickness: 1.0),

          // Ein Padding für etwas Abstand.
          Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 16.0,
              horizontal: 8.0,
            ),
            child: Text(
              // Greift auf die statische Konstante aus der generierten Datei zu.
              'Build-Zeitpunkt: ${BuildInfo.buildTimestamp}',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12.0, color: Colors.grey.shade600),
            ),
          ),
        ],
      ),
    );
  }
}
