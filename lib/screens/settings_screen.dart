// lib/screens/settings_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../generated/build_info.dart';
import '../services/notification_service.dart';
import '../services/storage_service.dart';

/// Screen für die Einstellungen der App.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

/// State-Klasse für den SettingsScreen.
class _SettingsScreenState extends State<SettingsScreen> {
  final StorageService _storageService = StorageService();
  String _selectedStateCode = 'NW';
  PackageInfo _packageInfo = PackageInfo(
    appName: 'Unknown',
    packageName: 'Unknown',
    version: 'Unknown',
    buildNumber: 'Unknown',
  );

  // Controller für die Textfelder der Erinnerungszeiten
  late TextEditingController _reminder1Controller;
  late TextEditingController _reminder2Controller;

  bool _isTestNotificationMode = false;

  // Deutsche Bundesländer und deren Codes
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
    _reminder1Controller = TextEditingController();
    _reminder2Controller = TextEditingController();
    _loadAllSettings();
    _loadPackageInfo();
  }

  @override
  void dispose() {
    _reminder1Controller.dispose();
    _reminder2Controller.dispose();
    super.dispose();
  }

  /// Lädt alle gespeicherten Einstellungen und aktualisiert den State.
  Future<void> _loadAllSettings() async {
    final savedState = await _storageService.getSelectedState();
    final reminderMinutes = await _storageService.getReminderMinutes();
    final isTestMode = await _storageService.getIsTestNotification();

    if (mounted) {
      setState(() {
        _selectedStateCode = savedState;
        _isTestNotificationMode = isTestMode;

        if (_isTestNotificationMode) {
          _reminder1Controller.text = reminderMinutes['reminder1']!.toString();
          _reminder2Controller.text = reminderMinutes['reminder2']!.toString();
        } else {
          _reminder1Controller.text = '1440';
          _reminder2Controller.text = '60';
        }
      });
    }
  }

  /// Lädt die Paketinformationen der App.
  Future<void> _loadPackageInfo() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() {
        _packageInfo = info;
      });
    }
  }

  /// Handler für die Auswahl eines Bundeslandes.
  void _onStateSelected(String? newCode) {
    if (newCode != null) {
      setState(() {
        _selectedStateCode = newCode;
      });
      _storageService.saveSelectedState(newCode);
    }
  }

  /// Speichert die Erinnerungszeiten, wenn der Testmodus aktiv ist.
  void _saveReminderSettings() {
    FocusScope.of(context).unfocus();

    if (_isTestNotificationMode) {
      final reminder1 = int.tryParse(_reminder1Controller.text) ?? 0;
      final reminder2 = int.tryParse(_reminder2Controller.text) ?? 0;
      _storageService.saveReminderMinutes(reminder1, reminder2);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Test-Erinnerungszeiten gespeichert.'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  /// Baut den Titel für einen Abschnitt im Einstellungsbildschirm.
  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 20.0, 16.0, 8.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: Theme.of(
            context,
          ).colorScheme.primary, // dunkles grün (#006C4E)
          fontWeight: FontWeight.bold,
          fontSize: 19,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: PopScope(
        canPop: false,
        onPopInvokedWithResult: (bool didPop, Object? result) {
          if (didPop) return;
          Navigator.of(context).pop(true);
        },
        // Der Hintergrund mit Farbverlauf
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  colorScheme.surfaceContainer,
                  colorScheme.surfaceContainerLow,
                ],
              ),
            ),
            // Der eigentliche Inhalt des Bildschirms
            child: ListView(
              children: [
                _buildSectionTitle(context, 'Über die App'),
                // 1. Karte mit App-Informationen.
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
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: TextButton(
                          onPressed: () {
                            NotificationService().showTestNotification();
                          },
                          child: const Text('SOFORT-BENACHRICHTIGUNG TESTEN'),
                        ),
                      ),
                    ],
                  ),
                ),
                // Abschnitt für Benachrichtigungseinstellungen
                _buildSectionTitle(context, 'Benachrichtigungen'),
                // 2. Karte mit Benachrichtigungseinstellungen.
                Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          !_isTestNotificationMode
                              ? 'Standardmodus: Erinnerungen erfolgen 24h und 1h vor einem Termin.'
                              : 'Testmodus: Definieren Sie die Erinnerungszeiten in Minuten.',
                        ),
                        const SizedBox(height: 16),
                        // Zwei Textfelder für die Erinnerungszeiten
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                enabled: _isTestNotificationMode,
                                controller: _reminder1Controller,
                                decoration: const InputDecoration(
                                  labelText: '1. Erinnerung (Min.)',
                                  border: OutlineInputBorder(),
                                ),
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextField(
                                enabled: _isTestNotificationMode,
                                controller: _reminder2Controller,
                                decoration: const InputDecoration(
                                  labelText: '2. Erinnerung (Min.)',
                                  border: OutlineInputBorder(),
                                ),
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Umschalter für den Testmodus
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            const Text('Standard'),
                            // Der Umschalter
                            Switch(
                              value: _isTestNotificationMode,
                              onChanged: (value) {
                                setState(() {
                                  _isTestNotificationMode = value;
                                  if (value) {
                                    _storageService.getReminderMinutes().then((
                                      minutes,
                                    ) {
                                      _reminder1Controller.text =
                                          minutes['reminder1']!.toString();
                                      _reminder2Controller.text =
                                          minutes['reminder2']!.toString();
                                    });
                                  } else {
                                    _reminder1Controller.text = '1440';
                                    _reminder2Controller.text = '60';
                                  }
                                });
                                _storageService.saveIsTestNotification(value);
                              },
                            ),
                            const Text('Test'),
                            const Spacer(),
                            ElevatedButton(
                              onPressed: _isTestNotificationMode
                                  ? _saveReminderSettings
                                  : null,
                              child: const Text('Speichern'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                // Abschnitt für die Auswahl des Bundeslandes
                _buildSectionTitle(context, 'Feiertage'),
                // 3. Karte mit Auswahl der Bundesländer bezüglich der Feiertage.
                Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 4.0,
                    ),
                    child: DropdownButton<String>(
                      value: _selectedStateCode,
                      onChanged: _onStateSelected,
                      underline: const SizedBox(),
                      isExpanded: true,
                      items: _germanStates.entries.map((entry) {
                        return DropdownMenuItem<String>(
                          value: entry.key,
                          child: Text(entry.value),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 20), // Abstand am Ende
              ],
            ),
          ),
        ),
      ),
    );
  }
}
