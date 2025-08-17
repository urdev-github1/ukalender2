// lib/scripts/generate_build_info.dart

import 'dart:io';
import 'package:intl/intl.dart';

void main() {
  // Aktuelles Datum und Uhrzeit holen
  final now = DateTime.now();
  // Formatieren (z.B. 2025-08-16 21:55:10)
  final formattedDate = DateFormat('yyyy-MM-dd HH:mm:ss').format(now);

  // Den Inhalt für die Zieldatei erstellen
  final content =
      '''
// Diese Datei wird automatisch generiert. NICHT manuell bearbeiten.
class BuildInfo {
  static const String buildTimestamp = '$formattedDate';
}
''';

  // Die Zieldatei schreiben
  final file = File('lib/generated/build_info.dart');
  // Sicherstellen, dass das Verzeichnis existiert
  file.parent.createSync(recursive: true);
  file.writeAsStringSync(content);

  print(
    'Build-Informationen erfolgreich generiert in lib/generated/build_info.dart',
  );
}
