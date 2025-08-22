// lib/theme_provider.dart

import 'package:flutter/material.dart';
import 'services/storage_service.dart';

class ThemeProvider with ChangeNotifier {
  final StorageService _storageService;
  late ThemeMode _themeMode;

  ThemeProvider(this._storageService);

  ThemeMode get themeMode => _themeMode;

  /// Lädt das gespeicherte Theme beim App-Start.
  Future<void> loadThemeMode() async {
    _themeMode = await _storageService.getThemeMode();
    // Kein notifyListeners() hier, da es vor dem App-Build geladen wird.
  }

  /// Ändert das Theme und speichert die Auswahl persistent.
  void setThemeMode(ThemeMode themeMode) {
    if (_themeMode == themeMode) return;

    _themeMode = themeMode;
    _storageService.saveThemeMode(themeMode);
    notifyListeners(); // Benachrichtigt die UI über die Änderung.
  }
}
