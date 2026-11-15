import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/db/app_database.dart';
import 'event.dart';

class CalendarRepository {
  const CalendarRepository(this._db);

  final AppDatabase _db;

  Future<List<CalendarEvent>> getEvents() async {
    final List<EventRow> rows = await (_db.select(
      _db.eventRows,
    )..orderBy([(t) => OrderingTerm.asc(t.startsAt)])).get();
    return rows.map(_fromRow).toList();
  }

  Future<CalendarEvent> createEvent(CalendarEvent event) async {
    final int id = await _db.into(_db.eventRows).insert(_toCompanion(event));
    return event.withIds(id: id, noteId: event.noteId);
  }

  /// Replaces the stored event that has [event]'s id.
  Future<CalendarEvent> updateEvent(CalendarEvent event) async {
    await (_db.update(
      _db.eventRows,
    )..where((t) => t.id.equals(event.id))).write(_toCompanion(event));
    return event;
  }

  Future<void> deleteEvent(int id) {
    return (_db.delete(_db.eventRows)..where((t) => t.id.equals(id))).go();
  }

  /// The soonest upcoming occurrence across all events, for the home widget.
  Future<({String title, DateTime startsAt})?> getNextEvent() async {
    final DateTime now = DateTime.now();
    ({String title, DateTime startsAt})? best;
    for (final CalendarEvent event in await getEvents()) {
      final DateTime? next = event.nextOccurrence(now);
      if (next != null && (best == null || next.isBefore(best.startsAt))) {
        best = (title: event.title, startsAt: next);
      }
    }
    return best;
  }

  EventRowsCompanion _toCompanion(CalendarEvent event) {
    return EventRowsCompanion(
      title: Value(event.title),
      startsAt: Value(event.startsAt),
      durationMinutes: Value(event.durationMinutes),
      location: Value(event.location),
      notes: Value(event.notes),
      recurrence: Value(event.recurrence),
      recurrenceUntil: Value(event.recurrenceUntil),
      reminderMinutes: Value(event.reminderMinutes),
      noteId: Value(event.noteId),
    );
  }

  CalendarEvent _fromRow(EventRow row) {
    return CalendarEvent(
      id: row.id,
      title: row.title,
      startsAt: row.startsAt,
      durationMinutes: row.durationMinutes,
      location: row.location,
      notes: row.notes,
      recurrence: row.recurrence,
      recurrenceUntil: row.recurrenceUntil,
      reminderMinutes: row.reminderMinutes,
      noteId: row.noteId,
    );
  }
}

final Provider<CalendarRepository> calendarRepositoryProvider =
    Provider<CalendarRepository>(
      (ref) => CalendarRepository(ref.watch(appDatabaseProvider)),
    );
