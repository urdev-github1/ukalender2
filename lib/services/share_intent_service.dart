// lib/services/share_intent_service.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import '../models/event.dart';
import 'calendar_service.dart';
import 'storage_service.dart';

/// Ein Typedef für einen Callback, der eine SnackBar anzeigt.
/// Ersetzt den direkten Zugriff auf ScaffoldMessenger.of(context)
/// und ermöglicht es dem Service, Nachrichten anzuzeigen, ohne den Context direkt zu halten.
typedef ShowSnackBarCallback = void Function(SnackBar snackBar);

/// Service zur Verarbeitung von geteilten Inhalten (insbesondere ICS-Dateien).
class ShareIntentService {
  final CalendarService _calendarService;
  final StorageService _storageService;
  StreamSubscription? _intentDataStreamSubscription;
  final ShowSnackBarCallback _showSnackBar;
  final VoidCallback
  _onEventsImported; // Callback, um den Kalender zu aktualisieren

  ShareIntentService({
    required CalendarService calendarService,
    required StorageService storageService,
    required ShowSnackBarCallback showSnackBar,
    required VoidCallback onEventsImported,
  }) : _calendarService = calendarService,
       _storageService = storageService,
       _showSnackBar = showSnackBar,
       _onEventsImported = onEventsImported;

  /// Initialisiert den Listener für geteilte Inhalte mit receive_sharing_intent.
  void initReceiveSharing() {
    _intentDataStreamSubscription = ReceiveSharingIntent.instance
        .getMediaStream()
        .listen(
          (List<SharedMediaFile> value) {
            if (value.isNotEmpty) {
              _handleSharedIcsFile(value.first);
            }
          },
          onError: (err) {
            // Optional: Fehlerprotokollierung
            debugPrint(
              "ReceiveSharingIntent [ERROR]: Fehler im Media-Stream: $err",
            );
          },
        );

    ReceiveSharingIntent.instance.getInitialMedia().then((
      List<SharedMediaFile> value,
    ) {
      if (value.isNotEmpty) {
        _handleSharedIcsFile(value.first);
      }
    });
  }

  /// Verarbeitet eine geteilte ICS-Datei von receive_sharing_intent.
  Future<void> _handleSharedIcsFile(SharedMediaFile file) async {
    if (file.path.toLowerCase().endsWith('.ics')) {
      final String path = file.path;

      _showSnackBar(
        const SnackBar(content: Text('Importiere geteilte Termine...')),
      );

      final List<Event> importedEvents = await _calendarService.parseIcsFile(
        path,
      );

      if (importedEvents.isNotEmpty) {
        for (final event in importedEvents) {
          await _storageService.addEvent(event);
        }
        _onEventsImported(); // Benachrichtigt den CalendarScreen, die Daten neu zu laden

        _showSnackBar(
          SnackBar(
            content: Text(
              '${importedEvents.length} Termin(e) erfolgreich importiert.',
            ),
          ),
        );
      } else {
        _showSnackBar(
          const SnackBar(
            content: Text(
              'Import fehlgeschlagen oder keine Termine in der Datei gefunden.',
            ),
          ),
        );
      }
    } else {
      debugPrint(
        "ReceiveSharingIntent: Geteilte Datei ist keine .ics-Datei: ${file.path}",
      );
    }
  }

  /// Beendet das Stream-Abonnement.
  void dispose() {
    _intentDataStreamSubscription?.cancel();
  }
}
