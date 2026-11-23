import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/db/app_database.dart';
import 'task_item.dart';

/// Persists student tasks in the on-device `tasks` table.
class TaskRepository {
  const TaskRepository(this._db);

  final AppDatabase _db;

  /// All tasks: open first (due date ascending, nulls last, newest created
  /// first), then done (most recently completed first).
  Future<List<TaskItem>> getTasks() async {
    final List<TaskRow> rows =
        await (_db.select(_db.taskRows)..orderBy(<OrderingTerm Function(TaskRows)>[
              (TaskRows t) => OrderingTerm.asc(t.done),
              (TaskRows t) => OrderingTerm.asc(t.id),
            ]))
            .get();
    final List<TaskItem> items = rows.map(_fromRow).toList();
    items.sort(_compareTasks);
    return items;
  }

  Future<TaskItem?> getTask(int id) async {
    final TaskRow? row = await (_db.select(
      _db.taskRows,
    )..where((TaskRows t) => t.id.equals(id))).getSingleOrNull();
    return row == null ? null : _fromRow(row);
  }

  /// Inserts [task] and returns the created row's id.
  Future<int> createTask(TaskItem task) {
    final String? cleanNotes = _cleanNullable(task.notes);
    return _db
        .into(_db.taskRows)
        .insert(
          TaskRowsCompanion.insert(
            title: task.title.trim(),
            notes: Value(cleanNotes),
            dueOn: Value(task.dueOn),
            repeat: Value(task.repeat),
            done: Value(task.done),
            doneAt: Value(task.doneAt),
            createdAt: task.createdAt ?? DateTime.now(),
          ),
        );
  }

  Future<void> updateTask(TaskItem task) {
    final String? cleanNotes = _cleanNullable(task.notes);
    return (_db.update(
      _db.taskRows,
    )..where((TaskRows t) => t.id.equals(task.id))).write(
      TaskRowsCompanion(
        title: Value(task.title.trim()),
        notes: Value(cleanNotes),
        dueOn: Value(task.dueOn),
        repeat: Value(task.repeat),
        done: Value(task.done),
        doneAt: Value(task.doneAt),
      ),
    );
  }

  Future<void> deleteTask(int id) {
    return (_db.delete(
      _db.taskRows,
    )..where((TaskRows t) => t.id.equals(id))).go();
  }

  /// Toggles completion on [task]. Completing a repeating task advances `dueOn`
  /// past today's calendar date and keeps `done == false` so future
  /// occurrences stay scheduled; completing a one-off task sets `done = true`
  /// and `doneAt = now` (unticking clears both).
  Future<TaskItem> toggleDone(TaskItem task, {DateTime? now}) async {
    final DateTime current = now ?? DateTime.now();
    if (!task.done && task.isRepeating) {
      final DateTime nextDue = task.nextDuePast(current)!;
      final TaskItem advanced = task.copyWith(
        dueOn: formatTaskDateKey(nextDue),
        done: false,
        clearDoneAt: true,
      );
      await updateTask(advanced);
      return advanced;
    }
    final bool nextDone = !task.done;
    final TaskItem updated = task.copyWith(
      done: nextDone,
      doneAt: nextDone ? current : null,
      clearDoneAt: !nextDone,
    );
    await updateTask(updated);
    return updated;
  }

  static String? _cleanNullable(String? text) {
    if (text == null) return null;
    final String trimmed = text.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  static int _compareTasks(TaskItem a, TaskItem b) {
    if (a.done != b.done) return a.done ? 1 : -1;
    if (!a.done) {
      final DateTime? da = a.dueDate;
      final DateTime? db = b.dueDate;
      if (da != null && db != null) {
        final int cmp = da.compareTo(db);
        if (cmp != 0) return cmp;
      } else if (da != null || db != null) {
        return da != null ? -1 : 1;
      }
      final int createdCmp = (b.createdAt ?? DateTime(0)).compareTo(
        a.createdAt ?? DateTime(0),
      );
      return createdCmp != 0 ? createdCmp : b.id.compareTo(a.id);
    }
    final int doneCmp = (b.doneAt ?? DateTime(0)).compareTo(
      a.doneAt ?? DateTime(0),
    );
    return doneCmp != 0 ? doneCmp : b.id.compareTo(a.id);
  }

  static TaskItem _fromRow(TaskRow row) => TaskItem(
    id: row.id,
    title: row.title,
    notes: row.notes,
    dueOn: row.dueOn,
    repeat: row.repeat,
    done: row.done,
    doneAt: row.doneAt,
    createdAt: row.createdAt,
  );
}

final Provider<TaskRepository> tasksRepositoryProvider =
    Provider<TaskRepository>(
      (Ref ref) => TaskRepository(ref.watch(appDatabaseProvider)),
    );
