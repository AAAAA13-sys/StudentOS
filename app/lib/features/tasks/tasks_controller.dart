import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/db/app_database.dart';
import '../calendar/widget_sync.dart';
import 'task_item.dart';
import 'tasks_repository.dart';

/// The three views of the Notes tab: Notes, Tasks, and Recall.
enum NotesView { notes, tasks, recall }

/// Which view of the Notes tab is showing (`Notes` by default).
final NotifierProvider<NotesViewController, NotesView> notesViewProvider =
    NotifierProvider<NotesViewController, NotesView>(NotesViewController.new);

class NotesViewController extends Notifier<NotesView> {
  @override
  NotesView build() => NotesView.notes;

  void show(NotesView view) => state = view;
}

/// Filter chips on the Tasks panel.
enum TaskFilter { open, today, done }

class TasksController extends AsyncNotifier<List<TaskItem>> {
  TaskRepository get _repo => ref.read(tasksRepositoryProvider);
  AppDatabase get _db => ref.read(appDatabaseProvider);

  Future<bool>? _reconcileInFlight;

  @override
  FutureOr<List<TaskItem>> build() async {
    final AppDatabase db = _db;
    final TaskRepository repo = _repo;
    await reconcileWidgetCheckoffs();
    if (!ref.mounted) return const <TaskItem>[];
    final List<TaskItem> tasks = await repo.getTasks();
    if (ref.mounted) unawaited(syncTodayWidget(db));
    return tasks;
  }

  /// Applies task check-offs queued from the Today home-screen widget. Guarded
  /// so concurrent `build()` and `onResume` calls share a single run.
  Future<bool> reconcileWidgetCheckoffs({bool reloadIfChanged = false}) {
    final Future<bool>? active = _reconcileInFlight;
    if (active != null) return active;
    final AppDatabase db = _db;
    final Future<bool> run = _runReconcile(db, reloadIfChanged: reloadIfChanged);
    _reconcileInFlight = run;
    return run.whenComplete(() {
      if (identical(_reconcileInFlight, run)) {
        _reconcileInFlight = null;
      }
    });
  }

  Future<bool> _runReconcile(
    AppDatabase db, {
    required bool reloadIfChanged,
  }) async {
    final bool changed = await reconcileWidgetCompletedTasks(db);
    if (changed && ref.mounted && reloadIfChanged) {
      await _reload();
    }
    return changed;
  }

  Future<void> _reload() async {
    final AppDatabase db = _db;
    state = await AsyncValue.guard(_repo.getTasks);
    if (ref.mounted) unawaited(syncTodayWidget(db));
  }

  Future<void> addTask(TaskItem task) async {
    await _repo.createTask(task);
    if (!ref.mounted) return;
    await _reload();
  }

  Future<void> updateTask(TaskItem task) async {
    await _repo.updateTask(task);
    if (!ref.mounted) return;
    await _reload();
  }

  Future<void> deleteTask(int id) async {
    await _repo.deleteTask(id);
    if (!ref.mounted) return;
    await _reload();
  }

  Future<void> toggleDone(TaskItem task, {DateTime? now}) async {
    await _repo.toggleDone(task, now: now);
    if (!ref.mounted) return;
    await _reload();
  }

  Future<void> refresh() async {
    final AppDatabase db = _db;
    state = const AsyncLoading();
    await reconcileWidgetCheckoffs();
    if (!ref.mounted) return;
    state = await AsyncValue.guard(_repo.getTasks);
    if (ref.mounted) unawaited(syncTodayWidget(db));
  }
}

final AsyncNotifierProvider<TasksController, List<TaskItem>>
tasksControllerProvider =
    AsyncNotifierProvider<TasksController, List<TaskItem>>(TasksController.new);
