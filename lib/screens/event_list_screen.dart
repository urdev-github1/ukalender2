// lib/screens/event_list_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import '../models/event.dart';
import '../utils/app_colors.dart';
import '../utils/calendar_color_logic.dart';

/// Ein Screen, der eine chronologische Liste aller Kalenderereignisse anzeigt.
class EventListScreen extends StatefulWidget {
  final List<Event> allEvents;
  final DateTime? initialSelectedDate;

  const EventListScreen({
    super.key,
    required this.allEvents,
    this.initialSelectedDate,
  });

  @override
  State<EventListScreen> createState() => _EventListScreenState();
}

class _EventListScreenState extends State<EventListScreen> {
  final ItemScrollController _itemScrollController = ItemScrollController();
  final ItemPositionsListener _itemPositionsListener =
      ItemPositionsListener.create();

  late Map<DateTime, List<Event>> _groupedEvents;
  late List<MapEntry<DateTime, List<Event>>> _sortedGroupedEntries;

  @override
  void initState() {
    super.initState();
    // Events gruppieren und sortieren
    _groupedEvents = _groupEventsByDate(widget.allEvents);
    _groupedEvents.forEach((date, events) {
      events.sort(
        (a, b) => a.date.compareTo(b.date),
      ); // Sortiere Events innerhalb eines Tages nach Uhrzeit
    });
    _sortedGroupedEntries = _groupedEvents.entries.toList();

    // Scrollen, sobald die Liste gerendert ist
    _itemPositionsListener.itemPositions.addListener(_handleScroll);
  }

  void _handleScroll() {
    if (_itemScrollController.isAttached) {
      _itemPositionsListener.itemPositions.removeListener(
        _handleScroll,
      ); // Listener entfernen, um Mehrfachausführung zu verhindern
      _scrollToFirstUpcomingEvent();
    }
  }

  @override
  void dispose() {
    _itemPositionsListener.itemPositions.removeListener(
      _handleScroll,
    ); // Sicherstellen, dass der Listener entfernt wird
    super.dispose();
  }

  /// Gruppiert eine Liste von Events nach ihrem Datum (ohne Zeitkomponente).
  Map<DateTime, List<Event>> _groupEventsByDate(List<Event> events) {
    Map<DateTime, List<Event>> groupedEvents = {};
    for (var event in events) {
      // Datum normalisieren, um Zeitkomponente für die Gruppierung zu entfernen
      DateTime dateOnly = DateTime(
        event.date.year,
        event.date.month,
        event.date.day,
      );
      if (!groupedEvents.containsKey(dateOnly)) {
        groupedEvents[dateOnly] = [];
      }
      groupedEvents[dateOnly]!.add(event);
    }
    // Schlüssel (Daten) chronologisch sortieren
    final sortedKeys = groupedEvents.keys.toList()
      ..sort((a, b) => a.compareTo(b));
    return {for (var k in sortedKeys) k: groupedEvents[k]!};
  }

  /// Scrollt die Liste zum ersten Eintrag, der am oder nach dem aktuellen Tag liegt.
  void _scrollToFirstUpcomingEvent() {
    if (_sortedGroupedEntries.isEmpty) {
      debugPrint('EventListScreen: Liste leer, kein Scrollen möglich.');
      return;
    }

    final now = DateTime.now();
    // Bestimme den aktuellen Tag ohne Zeitkomponente.
    DateTime today = DateTime(now.year, now.month, now.day);

    debugPrint('EventListScreen: Aktuelles Datum (ohne Zeit): $today');
    debugPrint(
      'EventListScreen: Anzahl der gruppierten Termine: ${_sortedGroupedEntries.length}',
    );

    int targetScrollIndex = 0; // Standardmäßig am Anfang der Liste bleiben
    bool foundTarget = false;

    // Finde den Index des ersten Datumseintrags, der am oder nach 'today' liegt.
    for (int i = 0; i < _sortedGroupedEntries.length; i++) {
      final DateTime groupDate = _sortedGroupedEntries[i].key;
      // Wir suchen das erste Event, das am oder nach dem heutigen Tag liegt.
      if (groupDate.isAtSameMomentAs(today) || groupDate.isAfter(today)) {
        targetScrollIndex = i;
        foundTarget = true;
        // debugPrint(
        //   'EventListScreen: Ziel gefunden bei Index $i für Datum $groupDate',
        // );
        break;
      }
    }

    if (foundTarget) {
      debugPrint(
        'EventListScreen: final targetScrollIndex: $targetScrollIndex',
      );

      if (_itemScrollController.isAttached) {
        _itemScrollController.scrollTo(
          index: targetScrollIndex,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOut,
          // Bringt das Element an den oberen Rand des Viewports
          alignment: 0.0,
        );
        debugPrint(
          'EventListScreen: Scrollen mit ItemScrollController eingeleitet.',
        );
      } else {
        debugPrint(
          'EventListScreen: ItemScrollController nicht bereit, kann nicht scrollen.',
        );
      }
    } else {
      debugPrint(
        'EventListScreen: Kein Termin am heutigen Tag oder später gefunden. Liste bleibt am Anfang.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Terminliste'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
        ),
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.surfaceContainer,
              Theme.of(context).colorScheme.surfaceContainerLow,
            ],
          ),
        ),
        padding: EdgeInsets.only(
          top: kToolbarHeight + MediaQuery.of(context).padding.top,
        ),
        child: _sortedGroupedEntries.isEmpty
            ? const Center(
                child: Text(
                  'Keine Termine vorhanden.',
                  style: TextStyle(fontSize: 18, color: AppColors.textPrimary),
                ),
              )
            : ScrollablePositionedList.builder(
                itemScrollController: _itemScrollController,
                itemPositionsListener: _itemPositionsListener,
                itemCount: _sortedGroupedEntries.length,
                itemBuilder: (context, index) {
                  final date = _sortedGroupedEntries[index].key;
                  final eventsForDate = _sortedGroupedEntries[index].value;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 8.0,
                        ),
                        child: Text(
                          '${DateFormat.EEEE('de_DE').format(date)}, ${DateFormat.yMMMMd('de_DE').format(date)}',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                        ),
                      ),
                      ...eventsForDate.map((event) {
                        final displayColor = CalendarColorLogic.getEventColor(
                          event,
                        );
                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16.0,
                            vertical: 4.0,
                          ),
                          elevation: 1,
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Row(
                              children: [
                                Container(
                                  width: 5.0,
                                  height:
                                      event.description != null &&
                                          event.description!.isNotEmpty
                                      ? 70.0
                                      : 50.0,
                                  decoration: BoxDecoration(
                                    color: displayColor,
                                    borderRadius: BorderRadius.circular(2.5),
                                  ),
                                  margin: const EdgeInsets.only(right: 12.0),
                                ),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        event.isHoliday
                                            ? 'Ganztägig (Feiertag)'
                                            : (event.isBirthday
                                                  ? 'Ganztägig (Geburtstag)'
                                                  : DateFormat.Hm(
                                                      'de_DE',
                                                    ).format(event.date)),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        event.title,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.textPrimary,
                                            ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      if (event.description != null &&
                                          event.description!.isNotEmpty)
                                        Text(
                                          event.description!,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium
                                              ?.copyWith(color: AppColors.grey),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ],
                  );
                },
              ),
      ),
    );
  }
}
