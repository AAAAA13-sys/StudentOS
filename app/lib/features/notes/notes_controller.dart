import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'note.dart';
import 'notes_repository.dart';

class NotesState {
  const NotesState({
    required this.notes,
    required this.tags,
    this.searchQuery = '',
    this.selectedTag,
  });

  final List<Note> notes;
  final List<String> tags;
  final String searchQuery;
  final String? selectedTag;

  NotesState copyWith({
    List<Note>? notes,
    List<String>? tags,
    String? searchQuery,
    String? selectedTag,
    bool clearTag = false,
  }) {
    return NotesState(
      notes: notes ?? this.notes,
      tags: tags ?? this.tags,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedTag: clearTag ? null : (selectedTag ?? this.selectedTag),
    );
  }
}

class NotesController extends AsyncNotifier<NotesState> {
  NotesRepository get _repo => ref.read(notesRepositoryProvider);

  @override
  FutureOr<NotesState> build() async {
    return _fetchState();
  }

  Future<NotesState> _fetchState({
    String? query,
    String? tag,
  }) async {
    final List<String> tags = await _repo.getTags();
    final List<Note> notes = await _repo.getNotes(q: query, tag: tag);

    return NotesState(
      notes: notes,
      tags: tags,
      searchQuery: query ?? '',
      selectedTag: tag,
    );
  }

  Future<void> search(String q) async {
    final String currentTag = state.value?.selectedTag ?? '';
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => _fetchState(
        query: q,
        tag: currentTag.isNotEmpty ? currentTag : null,
      ),
    );
  }

  Future<void> selectTag(String? tag) async {
    final String currentQuery = state.value?.searchQuery ?? '';
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => _fetchState(
        query: currentQuery.isNotEmpty ? currentQuery : null,
        tag: tag,
      ),
    );
  }

  Future<void> addNote(Note note) async {
    await _repo.createNote(note);
    final String q = state.value?.searchQuery ?? '';
    final String? tag = state.value?.selectedTag;
    state = await AsyncValue.guard(() => _fetchState(query: q, tag: tag));
  }

  Future<void> updateNote(
    int id, {
    required String title,
    required String body,
    required List<String> tags,
  }) async {
    await _repo.updateNote(id, title: title, body: body, tags: tags);
    final String q = state.value?.searchQuery ?? '';
    final String? tag = state.value?.selectedTag;
    state = await AsyncValue.guard(() => _fetchState(query: q, tag: tag));
  }

  Future<void> deleteNote(int id) async {
    await _repo.deleteNote(id);
    final String q = state.value?.searchQuery ?? '';
    final String? tag = state.value?.selectedTag;
    state = await AsyncValue.guard(() => _fetchState(query: q, tag: tag));
  }

  Future<void> refresh() async {
    final String q = state.value?.searchQuery ?? '';
    final String? tag = state.value?.selectedTag;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetchState(query: q, tag: tag));
  }
}

final AsyncNotifierProvider<NotesController, NotesState> notesControllerProvider =
    AsyncNotifierProvider<NotesController, NotesState>(
  NotesController.new,
);
