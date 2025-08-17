// lib/build_info.dart

import 'dart:io';
import 'package:intl/intl.dart';

void main() {
  final now = DateTime.now();
  final formattedDate = DateFormat('yyyy-MM-dd HH:mm:ss').format(now);

  final content =
      '''
// Diese Datei wird automatisch generiert. NICHT manuell bearbeiten.
class BuildInfo {
  static const String buildTimestamp = '$formattedDate';
}
''';

  // Pfad zur Zieldatei definieren
  final file = File('lib/generated/build_info.dart');

  // Sicherstellen, dass das Verzeichnis existiert
  if (!file.parent.existsSync()) {
    file.parent.createSync(recursive: true);
  }

  // Inhalt in die Zieldatei schreiben
  file.writeAsStringSync(content);
  print('Build-Zeitstempel aktualisiert: $formattedDate');
}
