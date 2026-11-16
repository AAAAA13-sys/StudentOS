import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';
import 'package:intl/intl.dart';

import 'calendar_repository.dart';
import 'event.dart';

class CalendarController extends AsyncNotifier<List<CalendarEvent>> {
  CalendarRepository get _repo => ref.read(calendarRepositoryProvider);

  @override
  FutureOr<List<CalendarEvent>> build() async {
    return _fetchEvents();
  }

  Future<List<CalendarEvent>> _fetchEvents() async {
    final List<CalendarEvent> events = await _repo.getEvents();
    unawaited(syncWidget());
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
  }

  Future<void> updateEvent(CalendarEvent event) async {
    final CalendarEvent updated = await _repo.updateEvent(event);
    state = AsyncData(
      (state.value ?? <CalendarEvent>[])
          .map((e) => e.id == updated.id ? updated : e)
          .toList(),
    );
    unawaited(syncWidget());
  }

  Future<void> deleteEvent(int id) async {
    await _repo.deleteEvent(id);
    state = AsyncData(
      (state.value ?? <CalendarEvent>[]).where((e) => e.id != id).toList(),
    );
    unawaited(syncWidget());
  }

  Future<void> syncWidget() async {
    try {
      final ({
        String title,
        DateTime startsAt,
        bool isExam,
        bool isAssignment,
      })? nextEvent = await _repo.getNextEvent();
      if (nextEvent != null) {
        final String prefix = nextEvent.isExam
            ? '🚨 '
            : (nextEvent.isAssignment ? '⚠️ ' : '');
        await HomeWidget.saveWidgetData<String>(
          'event_title',
          '$prefix${nextEvent.title}',
        );
        await HomeWidget.saveWidgetData<String>(
          'event_time',
          DateFormat('EEE, MMM d • h:mm a').format(nextEvent.startsAt),
        );
      } else {
        await HomeWidget.saveWidgetData<String>(
          'event_title',
          'No upcoming events',
        );
        await HomeWidget.saveWidgetData<String>(
          'event_time',
          'Enjoy your free time!',
        );
      }
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
