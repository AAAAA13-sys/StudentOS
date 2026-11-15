import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_client.dart';
import '../../core/api/api_exception.dart';
import 'note.dart';

class NotesRepository {
  const NotesRepository(this._api);

  final ApiClient _api;

  Future<List<Note>> getNotes({String? q, String? tag}) async {
    final Map<String, dynamic> query = <String, dynamic>{};
    if (q != null && q.isNotEmpty) query['q'] = q;
    if (tag != null && tag.isNotEmpty) query['tag'] = tag;

    final Object? json = await _api.get(
      '/api/notes',
      query: query.isNotEmpty ? query : null,
    );

    if (json is Map<String, dynamic> && json['data'] is List) {
      return (json['data'] as List)
          .whereType<Map<String, dynamic>>()
          .map(Note.fromJson)
          .toList();
    }
    throw const UnexpectedApiException();
  }

  Future<Note> createNote(Note note) async {
    final Object? json = await _api.post(
      '/api/notes',
      body: note.toJson(),
    );

    if (json is Map<String, dynamic> && json['data'] is Map<String, dynamic>) {
      return Note.fromJson(json['data'] as Map<String, dynamic>);
    }
    throw const UnexpectedApiException();
  }

  Future<Note> updateNote(int id, Map<String, dynamic> data) async {
    final Object? json = await _api.put(
      '/api/notes/$id',
      body: data,
    );

    if (json is Map<String, dynamic> && json['data'] is Map<String, dynamic>) {
      return Note.fromJson(json['data'] as Map<String, dynamic>);
    }
    throw const UnexpectedApiException();
  }

  Future<void> deleteNote(int id) async {
    await _api.delete('/api/notes/$id');
  }

  Future<List<String>> getTags() async {
    final Object? json = await _api.get('/api/notes/tags');
    if (json is Map<String, dynamic> && json['data'] is List) {
      return (json['data'] as List).cast<String>();
    }
    return <String>[];
  }
}

final Provider<NotesRepository> notesRepositoryProvider =
    Provider<NotesRepository>(
  (ref) => NotesRepository(ref.watch(apiClientProvider)),
);
