import 'dart:convert';

import 'package:home_widget/home_widget.dart';

import '../../core/db/app_database.dart';
import '../notes/note.dart';
import '../notes/notes_repository.dart';
import '../notes/recall_item.dart';
import '../notes/recall_repository.dart';
import '../tasks/task_item.dart';
import '../tasks/tasks_repository.dart';
import '../work/shift.dart';
import '../work/work_repository.dart';
import 'calendar_repository.dart';
import 'event.dart';

/// Writes the Today home-screen widget payload (`upcoming_events`,
/// `widget_tasks`, `widget_tasks_open_due_count`, `widget_recall_due`) from
/// the local database and requests an Android widget redraw. Best-effort.
Future<void> syncTodayWidget(AppDatabase db, {DateTime? now}) async {
  try {
    final DateTime at = now ?? DateTime.now();
    final List<CalendarEvent> events = await CalendarRepository(db).getEvents();
    final List<Shift> shifts = await WorkRepository(db).getShifts();
    final List<TaskItem> tasks = await TaskRepository(db).getTasks();
    final List<Note> notes = await NotesRepository(db).getNotes();
    final List<RecallReview> reviews = await RecallRepository(db).getReviews();

    final List<({String t, int s, String l, bool isShift})> upcoming =
        <({String t, int s, String l, bool isShift})>[];
    for (final CalendarEvent event in events) {
      if (event.done) continue;
      final String prefix = event.isExam
          ? 'Exam: '
          : (event.isAssignment ? 'Due: ' : '');
      DateTime from = at;
      for (int i = 0; i < 6; i++) {
        final DateTime? next = event.nextOccurrence(from);
        if (next == null) break;
        upcoming.add((
          t: '$prefix${event.title}',
          s: next.millisecondsSinceEpoch,
          l: event.location?.trim() ?? '',
          isShift: false,
        ));
        from = next.add(const Duration(minutes: 1));
      }
    }

    for (final Shift shift in shifts) {
      if (shift.paid || shift.isWorked(at)) continue;
      final DateTime start = shift.startsAt.toLocal();
      if (start.isBefore(at)) continue;
      upcoming.add((
        t: 'Shift: ${shift.job}',
        s: start.millisecondsSinceEpoch,
        l: '',
        isShift: true,
      ));
    }

    upcoming.sort((a, b) => a.s.compareTo(b.s));
    await HomeWidget.saveWidgetData<String>(
      'upcoming_events',
      jsonEncode(<Map<String, Object>>[
        for (final ({String t, int s, String l, bool isShift}) e
            in upcoming.take(20))
          <String, Object>{
            't': e.t,
            's': e.s,
            'location': e.l,
            'isShift': e.isShift,
          },
      ]),
    );

    final List<TaskItem> dueTasks = <TaskItem>[
      for (final TaskItem t in tasks)
        if (!t.done &&
            (t.dueStatus(at) == TaskDueStatus.overdue ||
                t.dueStatus(at) == TaskDueStatus.today))
          t,
    ];
    await HomeWidget.saveWidgetData<int>(
      'widget_tasks_open_due_count',
      dueTasks.length,
    );
    await HomeWidget.saveWidgetData<String>(
      'widget_tasks',
      jsonEncode(<Map<String, Object?>>[
        for (final TaskItem t in dueTasks.take(2))
          <String, Object?>{
            'id': t.id,
            'title': t.title,
            'overdue': t.dueStatus(at) == TaskDueStatus.overdue,
            'dueOn': t.dueOn,
          },
      ]),
    );

    final deck = buildRecallDeck(
      notes: notes,
      reviews: reviews,
      events: events,
      now: at,
    );
    await HomeWidget.saveWidgetData<int>(
      'widget_recall_due',
      deck.dueCards.length,
    );

    await HomeWidget.saveWidgetData<String>('event_title', null);
    await HomeWidget.saveWidgetData<String>('event_time', null);
    await HomeWidget.updateWidget(
      name: 'CalendarWidgetProvider',
      androidName: 'CalendarWidgetProvider',
    );
  } catch (_) {
    // Best-effort for widget sync.
  }
}

/// Applies task check-offs queued by the Android Today widget
/// (`widget_completed_task_ids`), clearing the queue immediately so repeats
/// never double-advance. Returns true if at least one task was updated.
Future<bool> reconcileWidgetCompletedTasks(AppDatabase db) async {
  try {
    final String? raw = await HomeWidget.getWidgetData<String>(
      'widget_completed_task_ids',
    );
    if (raw == null || raw.trim().isEmpty) return false;
    await HomeWidget.saveWidgetData<String>('widget_completed_task_ids', null);
    final Object? decoded = jsonDecode(raw);
    if (decoded is! List<dynamic> || decoded.isEmpty) return false;

    final TaskRepository repo = TaskRepository(db);
    bool changed = false;
    final Set<int> seenIds = <int>{};
    for (final Object? entry in decoded) {
      if (entry is! Map<dynamic, dynamic>) continue;
      final int? id = (entry['id'] as num?)?.toInt();
      final int? atMs = (entry['at'] as num?)?.toInt();
      if (id == null || !seenIds.add(id)) continue;
      final TaskItem? task = await repo.getTask(id);
      if (task == null || task.done) continue;
      final DateTime at = atMs != null
          ? DateTime.fromMillisecondsSinceEpoch(atMs)
          : DateTime.now();
      await repo.toggleDone(task, now: at);
      changed = true;
    }
    return changed;
  } catch (_) {
    return false;
  }
}
