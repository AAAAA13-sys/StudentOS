import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

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

  @override
  FutureOr<List<TaskItem>> build() => _repo.getTasks();

  Future<void> _reload() async {
    state = await AsyncValue.guard(_repo.getTasks);
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
    state = const AsyncLoading();
    state = await AsyncValue.guard(_repo.getTasks);
  }
}

final AsyncNotifierProvider<TasksController, List<TaskItem>>
tasksControllerProvider =
    AsyncNotifierProvider<TasksController, List<TaskItem>>(TasksController.new);
