import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/db/app_database.dart';
import 'calendar_repository.dart';
import 'event.dart';
import 'reminder_platform.dart';
import 'reminder_schedule.dart';
import 'widget_sync.dart';

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

  Future<void> toggleDone(CalendarEvent event) =>
      updateEvent(event.copyWith(done: !event.done));

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

  /// Writes the next few occurrences across events and shifts, due tasks, and
  /// recall count for the Today home-screen widget.
  Future<void> syncWidget() => syncTodayWidget(ref.read(appDatabaseProvider));
}

final AsyncNotifierProvider<CalendarController, List<CalendarEvent>>
calendarControllerProvider =
    AsyncNotifierProvider<CalendarController, List<CalendarEvent>>(
      CalendarController.new,
    );
