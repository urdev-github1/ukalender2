// lib/widgets/calendar_app_bar.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

/// Funktionen der AppBar
class CalendarAppBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback onListPressed;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;
  final Function(String) onActionSelected;
  final VoidCallback onSettingsPressed;
  final CalendarController
  // Der Controller wird hier übergeben
  calendarController;

  const CalendarAppBar({
    super.key,
    required this.onListPressed,
    required this.onPreviousMonth,
    required this.onNextMonth,
    required this.onActionSelected,
    required this.onSettingsPressed,
    required this.calendarController,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.list, size: 28.0),
        tooltip: 'Terminliste anzeigen',
        onPressed: onListPressed,
      ),
      backgroundColor: Colors.transparent,
      systemOverlayStyle: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios, size: 23.0),
            tooltip: 'Vorheriger Monat',
            onPressed: () => calendarController.backward!(),
          ),
          const SizedBox(width: 35),
          IconButton(
            icon: const Icon(Icons.arrow_forward_ios, size: 23.0),
            tooltip: 'Nächster Monat',
            onPressed: () => calendarController.forward!(),
          ),
        ],
      ),
      centerTitle: true,
      actions: [
        PopupMenuButton<String>(
          icon: const Icon(Icons.import_export, size: 30.0),
          tooltip: 'Daten importieren/exportieren',
          onSelected: onActionSelected,
          itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
            const PopupMenuItem<String>(
              value: 'export_ics',
              child: ListTile(
                leading: Icon(Icons.arrow_upward),
                title: Text(
                  'Exportieren (.ics)',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
              ),
            ),
            const PopupMenuItem<String>(
              value: 'import_ics',
              child: ListTile(
                leading: Icon(Icons.arrow_downward),
                title: Text(
                  'Importieren (.ics)',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
              ),
            ),
            const PopupMenuDivider(),
            const PopupMenuItem<String>(
              value: 'backup_json',
              child: ListTile(
                leading: Icon(Icons.backup_outlined),
                title: Text(
                  'Backup erstellen...',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
              ),
            ),
            const PopupMenuItem<String>(
              value: 'restore_json',
              child: ListTile(
                leading: Icon(Icons.restore_page_outlined),
                title: Text(
                  'Backup wiederherstellen...',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
              ),
            ),
          ],
        ),
        IconButton(
          icon: const Icon(Icons.settings, size: 26.0),
          tooltip: 'Einstellungen',
          onPressed: onSettingsPressed,
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
