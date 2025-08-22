// lib/screens/settings_screen.dart

import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import '../generated/build_info.dart';
import '../services/notification_service.dart';
import '../services/storage_service.dart';
import '../theme_provider.dart';

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
    FocusScope.of(context).unfocus();

    final reminder1 = int.tryParse(_reminder1Controller.text) ?? 0;
    final reminder2 = int.tryParse(_reminder2Controller.text) ?? 0;
    _storageService.saveReminderMinutes(reminder1, reminder2);

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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Einstellungen'),
        backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
        elevation: 1,
      ),
      body: PopScope(
        canPop: false,
        onPopInvoked: (bool didPop) {
          if (didPop) return;
          Navigator.of(context).pop(true);
        },
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: ListView(
            padding: const EdgeInsets.all(8.0),
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

              // =======================================================================
              // ==================== HIER BEGINNT DIE KORREKTUR =======================
              // =======================================================================
              _buildSectionTitle(context, 'Benachrichtigungen'),
              Card(
                margin: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Erinnerungen vor einem Termin (in Minuten).'),
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

              // =======================================================================
              // ===================== HIER ENDET DIE KORREKTUR ========================
              // =======================================================================
              _buildSectionTitle(context, 'Erscheinungsbild'),
              Card(
                margin: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 4.0,
                  ),
                  child: Consumer<ThemeProvider>(
                    builder: (context, themeProvider, child) {
                      return DropdownButton<ThemeMode>(
                        value: themeProvider.themeMode,
                        onChanged: (ThemeMode? newMode) {
                          if (newMode != null) {
                            themeProvider.setThemeMode(newMode);
                          }
                        },
                        underline: const SizedBox(),
                        isExpanded: true,
                        items: const [
                          DropdownMenuItem(
                            value: ThemeMode.system,
                            child: Text('Systemeinstellung'),
                          ),
                          DropdownMenuItem(
                            value: ThemeMode.light,
                            child: Text('Heller Modus'),
                          ),
                          DropdownMenuItem(
                            value: ThemeMode.dark,
                            child: Text('Dunkler Modus'),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
