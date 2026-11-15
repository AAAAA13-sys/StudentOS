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
    state = AsyncData(<CalendarEvent>[...state.value ?? <CalendarEvent>[], created]);
    unawaited(syncWidget());
  }

  Future<void> updateEvent(int id, Map<String, dynamic> data) async {
    final CalendarEvent updated = await _repo.updateEvent(id, data);
    state = AsyncData(
      (state.value ?? <CalendarEvent>[]).map((e) => e.id == id ? updated : e).toList(),
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
      final Map<String, dynamic>? nextEvent = await _repo.getWidgetData();
      if (nextEvent != null) {
        final String title = nextEvent['title'] as String? ?? 'No upcoming events';
        final String? startsAtStr = nextEvent['starts_at'] as String?;
        String timeStr = '';
        if (startsAtStr != null) {
          final DateTime dt = DateTime.parse(startsAtStr).toLocal();
          timeStr = DateFormat('EEE, MMM d • h:mm a').format(dt);
        }
        await HomeWidget.saveWidgetData<String>('event_title', title);
        await HomeWidget.saveWidgetData<String>('event_time', timeStr);
      } else {
        await HomeWidget.saveWidgetData<String>('event_title', 'No upcoming events');
        await HomeWidget.saveWidgetData<String>('event_time', 'Enjoy your free time!');
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
