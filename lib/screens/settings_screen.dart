import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart'; // NEU
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

  // NEU: Variable zum Speichern der App-Informationen
  PackageInfo _packageInfo = PackageInfo(
    appName: 'Unknown',
    packageName: 'Unknown',
    version: 'Unknown',
    buildNumber: 'Unknown',
  );

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
    _loadPackageInfo(); // NEU
  }

  void _loadCurrentState() async {
    final savedState = await _storageService.getSelectedState();
    setState(() {
      _selectedStateCode = savedState;
    });
  }

  // NEU: Lädt die Informationen aus der pubspec.yaml
  Future<void> _loadPackageInfo() async {
    final info = await PackageInfo.fromPlatform();
    setState(() {
      _packageInfo = info;
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

  // NEU: Ein Hilfs-Widget für die Überschriften zur besseren Lesbarkeit
  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 20.0, 16.0, 8.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: Theme.of(context).primaryColor,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Einstellungen'),
        // WillPopScope ist hier eine saubere Alternative zum überschriebenen `leading`-Button,
        // da es sowohl den Zurück-Pfeil als auch die Android-Zurück-Geste abfängt.
      ),
      // Wir geben das `true` beim Verlassen des Screens an den Kalender zurück,
      // damit dieser weiß, dass er die Feiertage neu laden muss.
      body: WillPopScope(
        onWillPop: () async {
          Navigator.of(context).pop(true);
          return true;
        },
        child: ListView(
          children: [
            // --- ABSCHNITT 1: FEIERTAGS-EINSTELLUNGEN ---
            _buildSectionTitle(context, 'Feiertage'),
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16.0),
              child: ListTile(
                // Row und Padding wurden durch ListTile ersetzt
                //title: const Text('Bundesland'), // Der Text wird zum Titel
                trailing: DropdownButton<String>(
                  // Das Dropdown wird zum "trailing" Widget
                  value: _selectedStateCode,
                  onChanged: _onStateSelected,
                  // 'underline' wird hier oft entfernt, da das ListTile bereits eine Trennlinie hat
                  underline: const SizedBox(),
                  items: _germanStates.entries.map((entry) {
                    return DropdownMenuItem<String>(
                      value: entry.key,
                      child: Text(entry.value),
                    );
                  }).toList(),
                ),
              ),
            ),

            // --- ABSCHNITT 2: ÜBER DIE APP ---
            _buildSectionTitle(context, 'Über die App'),
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.info_outline),
                    title: const Text('App-Version'),
                    subtitle: Text(
                      '${_packageInfo.version}+${_packageInfo.buildNumber}',
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.build_circle_outlined),
                    title: const Text('Build-Zeitpunkt'),
                    subtitle: const Text(BuildInfo.buildTimestamp),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
