// lib/features/event_import_export/backup_restore_dialogs.dart

import 'package:flutter/material.dart';
import 'package:ukalender2/utils/app_colors.dart';

Future<String?> showBackupRestoreConfirmationDialog({
  required BuildContext context,
  required Widget contentWidget,
}) {
  String? selectedOption; // 'merge', 'replace'

  return showDialog<String>(
    context: context,
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Backup wiederherstellen'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                contentWidget,
                const SizedBox(height: 20),
                RadioListTile<String>(
                  title: const Text('Termine zusammenführen'),
                  value: 'merge',
                  groupValue: selectedOption,
                  onChanged: (value) {
                    setState(() {
                      selectedOption = value;
                    });
                  },
                ),
                RadioListTile<String>(
                  title: const Text('Alle Termine ersetzen'),
                  value: 'replace',
                  groupValue: selectedOption,
                  onChanged: (value) {
                    setState(() {
                      selectedOption = value;
                    });
                  },
                ),
              ],
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Abbrechen'),
              ),
              ElevatedButton(
                onPressed: selectedOption == null
                    ? null
                    : () => Navigator.of(context).pop(selectedOption),
                style: ElevatedButton.styleFrom(
                  backgroundColor: selectedOption == 'replace'
                      ? AppColors.destructiveActionColor
                      : Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Bestätigen'),
              ),
            ],
          );
        },
      );
    },
  );
}
