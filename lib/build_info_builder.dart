// lib/build_info_builder.dart

import 'dart:async';
import 'package:build/build.dart';
import 'package:intl/intl.dart';

// Diese Funktion wird von der build_info_builder.yaml aufgerufen, um den Builder zu starten.
Builder buildInfoBuilder(BuilderOptions options) => BuildInfoBuilder();

class BuildInfoBuilder implements Builder {
  @override
  FutureOr<void> build(BuildStep buildStep) async {
    // Definieren, welche Datei wir am Ende erstellen wollen.
    final outputId = AssetId(
      buildStep.inputId.package,
      'lib/generated/build_info.dart',
    );

    // Die bekannte Logik zum Erstellen des Zeitstempels.
    final now = DateTime.now();
    final formattedDate = DateFormat('yyyy-MM-dd HH:mm:ss').format(now);

    final content =
        '''
// Diese Datei wird automatisch generiert. NICHT manuell bearbeiten.
class BuildInfo {
  static const String buildTimestamp = '$formattedDate';
}
''';

    // Den Inhalt in die Zieldatei schreiben.
    await buildStep.writeAsString(outputId, content);
  }

  @override
  Map<String, List<String>> get buildExtensions => {
    // Diese Regel sagt dem Build-System:
    // "Wenn du die Datei 'lib/main.dart' siehst, erstelle als Ausgabe
    // die Datei 'lib/generated/build_info.dart'".
    // 'main.dart' dient hier nur als existierender Ankerpunkt.
    'lib/main.dart': const ['lib/generated/build_info.dart'],
  };
}
