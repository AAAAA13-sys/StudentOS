import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';

import 'calendar_repository.dart';
import 'event.dart';
import 'reminder_platform.dart';
import 'reminder_schedule.dart';

class CalendarController extends AsyncNotifier<List<CalendarEvent>> {
  CalendarRepository get _repo => ref.read(calendarRepositoryProvider);

  @override
  FutureOr<List<CalendarEvent>> build() async {
    return _fetchEvents();
  }

  Future<List<CalendarEvent>> _fetchEvents() async {
    final List<CalendarEvent> events = await _repo.getEvents();
    unawaited(syncWidget());
    unawaited(syncReminders());
    return events;
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetchEvents);
  }

  Future<void> addEvent(CalendarEvent event) async {
    final CalendarEvent created = await _repo.createEvent(event);
    state = AsyncData(<CalendarEvent>[
      ...state.value ?? <CalendarEvent>[],
      created,
    ]);
    unawaited(syncWidget());
    unawaited(syncReminders());
  }

  Future<void> addEvents(List<CalendarEvent> events) async {
    final List<CalendarEvent> created = <CalendarEvent>[
      for (final CalendarEvent event in events) await _repo.createEvent(event),
    ];
    state = AsyncData(<CalendarEvent>[
      ...state.value ?? <CalendarEvent>[],
      ...created,
    ]);
    unawaited(syncWidget());
    unawaited(syncReminders());
  }

  Future<void> updateEvent(CalendarEvent event) async {
    final CalendarEvent updated = await _repo.updateEvent(event);
    state = AsyncData(
      (state.value ?? <CalendarEvent>[])
          .map((e) => e.id == updated.id ? updated : e)
          .toList(),
    );
    unawaited(syncWidget());
    unawaited(syncReminders());
  }

  Future<void> deleteEvent(int id) async {
    await _repo.deleteEvent(id);
    state = AsyncData(
      (state.value ?? <CalendarEvent>[]).where((e) => e.id != id).toList(),
    );
    unawaited(syncWidget());
    unawaited(syncReminders());
  }

  /// Gives Android the reminders due in the next two weeks.
  Future<void> syncReminders() async {
    try {
      final List<ReminderFire> fires = upcomingReminders(
        await _repo.getEvents(),
        DateTime.now(),
      );
      await ref.read(reminderPlatformProvider).sync(<Map<String, Object?>>[
        for (final ReminderFire f in fires) f.toNative(),
      ]);
    } catch (_) {
      // Best-effort, like the widget sync.
    }
  }

  /// Writes the next few occurrences across all events as epoch millis, so
  /// the native widget can drop passed events and say "Today"/"Tomorrow"
  /// itself without the app running.
  Future<void> syncWidget() async {
    try {
      final DateTime now = DateTime.now();
      final List<({String t, int s})> upcoming = <({String t, int s})>[];
      for (final CalendarEvent event in await _repo.getEvents()) {
        final String prefix = event.isExam
            ? 'Exam: '
            : (event.isAssignment ? 'Due: ' : '');
        DateTime from = now;
        for (int i = 0; i < 6; i++) {
          final DateTime? next = event.nextOccurrence(from);
          if (next == null) break;
          upcoming.add((
            t: '$prefix${event.title}',
            s: next.millisecondsSinceEpoch,
          ));
          from = next.add(const Duration(minutes: 1));
        }
      }
      upcoming.sort((a, b) => a.s.compareTo(b.s));
      await HomeWidget.saveWidgetData<String>(
        'upcoming_events',
        jsonEncode(<Map<String, Object>>[
          for (final ({String t, int s}) e in upcoming.take(20))
            <String, Object>{'t': e.t, 's': e.s},
        ]),
      );
      await HomeWidget.saveWidgetData<String>('event_title', null);
      await HomeWidget.saveWidgetData<String>('event_time', null);
      await HomeWidget.updateWidget(
        name: 'CalendarWidgetProvider',
        androidName: 'CalendarWidgetProvider',
      );
    } catch (_) {
      // Best-effort for widget sync
    }
  }
}

final AsyncNotifierProvider<CalendarController, List<CalendarEvent>>
calendarControllerProvider =
    AsyncNotifierProvider<CalendarController, List<CalendarEvent>>(
      CalendarController.new,
    );
