// lib/screens/settings_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../generated/build_info.dart';
import '../services/notification_service.dart'; // NEUER Import für den Test-Button
import '../services/storage_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final StorageService _storageService = StorageService();
  String _selectedStateCode = 'NW';
  PackageInfo _packageInfo = PackageInfo(
    appName: 'Unknown',
    packageName: 'Unknown',
    version: 'Unknown',
    buildNumber: 'Unknown',
  );

  late TextEditingController _reminder1Controller;
  late TextEditingController _reminder2Controller;

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

  Future<void> _loadAllSettings() async {
    final savedState = await _storageService.getSelectedState();
    final reminderMinutes = await _storageService.getReminderMinutes();
    // Sicherstellen, dass der State noch gemounted ist, bevor setState aufgerufen wird
    if (mounted) {
      setState(() {
        _selectedStateCode = savedState;
        _reminder1Controller.text = reminderMinutes['reminder1']!.toString();
        _reminder2Controller.text = reminderMinutes['reminder2']!.toString();
      });
    }
  }

  Future<void> _loadPackageInfo() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() {
        _packageInfo = info;
      });
    }
  }

  void _onStateSelected(String? newCode) {
    if (newCode != null) {
      setState(() {
        _selectedStateCode = newCode;
      });
      _storageService.saveSelectedState(newCode);
    }
  }

  void _saveReminderSettings() {
    // Schließt die Tastatur, bevor gespeichert wird
    FocusScope.of(context).unfocus();

    final reminder1 = int.tryParse(_reminder1Controller.text) ?? 0;
    final reminder2 = int.tryParse(_reminder2Controller.text) ?? 0;
    _storageService.saveReminderMinutes(reminder1, reminder2);

    // Feedback für den Benutzer
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Erinnerungszeiten gespeichert.'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 20.0, 16.0, 8.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
          fontSize: 19,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: isDarkMode
              ? Brightness.light
              : Brightness.dark,
          statusBarBrightness: isDarkMode ? Brightness.dark : Brightness.light,
        ),
      ),
      extendBodyBehindAppBar: true,
      body: PopScope(
        canPop: false,
        // UPDATED: 'onPopInvoked' is replaced with 'onPopInvokedWithResult'
        // and the callback signature is updated.
        onPopInvokedWithResult: (bool didPop, Object? result) {
          if (didPop) return;
          Navigator.of(context).pop(true);
        },
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
            child: ListView(
              padding: EdgeInsets.only(
                top: kToolbarHeight + MediaQuery.of(context).padding.top,
              ),
              children: [
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
                      // =======================================================================
                      // ==================== HIER IST DER TEST-BUTTON =========================
                      // =======================================================================
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: TextButton(
                          onPressed: () {
                            NotificationService().showTestNotification();
                          },
                          child: const Text('SOFORT-BENACHRICHTIGUNG TESTEN'),
                        ),
                      ),
                      // =======================================================================
                      // =======================================================================
                    ],
                  ),
                ),
                _buildSectionTitle(context, 'Benachrichtigungen'),
                Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Erinnerungen vor einem Termin (in Minuten).',
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _reminder1Controller,
                                decoration: const InputDecoration(
                                  labelText: '1. Erinnerung',
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
                                controller: _reminder2Controller,
                                decoration: const InputDecoration(
                                  labelText: '2. Erinnerung',
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
                        Align(
                          alignment: Alignment.centerRight,
                          child: ElevatedButton(
                            onPressed: _saveReminderSettings,
                            child: const Text('Speichern'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                _buildSectionTitle(context, 'Feiertage'),
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
