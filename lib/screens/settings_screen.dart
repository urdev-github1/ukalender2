// lib/screens/settings_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
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
  PackageInfo _packageInfo = PackageInfo(
    appName: 'Unknown',
    packageName: 'Unknown',
    version: 'Unknown',
    buildNumber: 'Unknown',
  );
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
    _loadPackageInfo();
  }

  void _loadCurrentState() async {
    final savedState = await _storageService.getSelectedState();
    setState(() {
      _selectedStateCode = savedState;
    });
  }

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

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 20.0, 16.0, 8.0),
      child: Text(
        title,
        // --- HIER IST DIE ANPASSUNG ---
        // Anstatt 'titleLarge' verwenden wir wieder 'titleMedium' als Basis
        // und fügen eine benutzerdefinierte Schriftgröße von 20.0 hinzu.
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
          fontSize: 19.0, // <-- INDIVIDUELLE SCHRIFTGRÖSSE
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
        title: const Text('Einstellungen'),
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
      body: WillPopScope(
        onWillPop: () async {
          Navigator.of(context).pop(true);
          return true;
        },
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
              _buildSectionTitle(context, 'Feiertage'),
              Card(
                margin: const EdgeInsets.symmetric(horizontal: 16.0),
                child: ListTile(
                  title: const Text('Bundesland'),
                  trailing: DropdownButton<String>(
                    value: _selectedStateCode,
                    onChanged: _onStateSelected,
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
      ),
    );
  }
}
