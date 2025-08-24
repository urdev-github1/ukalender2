// lib/screens/color_scheme_preview_screen.dart

import 'package:flutter/material.dart';

class ColorSchemePreviewScreen extends StatelessWidget {
  const ColorSchemePreviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    // Eine umfassende Liste aller Farben im ColorScheme
    final List<MapEntry<String, Color>> colorEntries = [
      MapEntry('primary', scheme.primary),
      MapEntry('onPrimary', scheme.onPrimary),
      MapEntry('primaryContainer', scheme.primaryContainer),
      MapEntry('onPrimaryContainer', scheme.onPrimaryContainer),
      MapEntry('secondary', scheme.secondary),
      MapEntry('onSecondary', scheme.onSecondary),
      MapEntry('secondaryContainer', scheme.secondaryContainer),
      MapEntry('onSecondaryContainer', scheme.onSecondaryContainer),
      MapEntry('tertiary', scheme.tertiary),
      MapEntry('onTertiary', scheme.onTertiary),
      MapEntry('tertiaryContainer', scheme.tertiaryContainer),
      MapEntry('onTertiaryContainer', scheme.onTertiaryContainer),
      MapEntry('error', scheme.error),
      MapEntry('onError', scheme.onError),
      MapEntry('errorContainer', scheme.errorContainer),
      MapEntry('onErrorContainer', scheme.onErrorContainer),
      MapEntry('background', scheme.background),
      MapEntry('onBackground', scheme.onBackground),
      MapEntry('surface', scheme.surface),
      MapEntry('onSurface', scheme.onSurface),
      MapEntry('surfaceVariant', scheme.surfaceVariant),
      MapEntry('onSurfaceVariant', scheme.onSurfaceVariant),
      MapEntry('outline', scheme.outline),
      MapEntry('outlineVariant', scheme.outlineVariant),
      MapEntry('inverseSurface', scheme.inverseSurface),
      MapEntry('onInverseSurface', scheme.onInverseSurface),
      MapEntry('inversePrimary', scheme.inversePrimary),
      MapEntry('surfaceTint', scheme.surfaceTint),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text("Vorschau: ColorScheme")),
      body: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, // 2 Spalten
          childAspectRatio: 2, // Breiter als hoch
        ),
        itemCount: colorEntries.length,
        itemBuilder: (context, index) {
          final entry = colorEntries[index];
          final colorName = entry.key;
          final colorValue = entry.value;

          // Bestimmt, ob der Text hell oder dunkel sein sollte für beste Lesbarkeit
          final textColor =
              ThemeData.estimateBrightnessForColor(colorValue) ==
                  Brightness.dark
              ? Colors.white
              : Colors.black;

          return Container(
            color: colorValue,
            margin: const EdgeInsets.all(2),
            padding: const EdgeInsets.all(8),
            child: Center(
              child: Text(
                colorName,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      blurRadius: 2.0,
                      color: textColor == Colors.white
                          ? Colors.black
                          : Colors.white,
                      offset: const Offset(1.0, 1.0),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
