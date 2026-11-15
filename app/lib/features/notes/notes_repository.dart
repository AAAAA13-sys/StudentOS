import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/db/app_database.dart';
import 'note.dart';

class NotesRepository {
  const NotesRepository(this._db);

  final AppDatabase _db;

  /// Most recently edited first. [q] matches title, body or any tag,
  /// ignoring case; [tag] must match a tag exactly.
  Future<List<Note>> getNotes({String? q, String? tag}) async {
    final List<NoteRow> rows = await (_db.select(
      _db.noteRows,
    )..orderBy([(t) => OrderingTerm.desc(t.updatedAt)])).get();

    final String needle = (q ?? '').trim().toLowerCase();
    return rows.map(_fromRow).where((Note note) {
      if (tag != null && tag.isNotEmpty && !note.tags.contains(tag)) {
        return false;
      }
      if (needle.isEmpty) {
        return true;
      }
      return note.title.toLowerCase().contains(needle) ||
          note.body.toLowerCase().contains(needle) ||
          note.tags.any((String t) => t.contains(needle));
    }).toList();
  }

  Future<Note?> getNote(int id) async {
    final NoteRow? row = await (_db.select(
      _db.noteRows,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    return row == null ? null : _fromRow(row);
  }

  /// Returns the new note's id.
  Future<int> createNote(Note note) {
    final DateTime now = DateTime.now();
    return _db
        .into(_db.noteRows)
        .insert(
          NoteRowsCompanion.insert(
            title: note.title,
            body: note.body,
            tags: jsonEncode(_normalizeTags(note.tags)),
            createdAt: now,
            updatedAt: now,
          ),
        );
  }

  Future<void> updateNote(
    int id, {
    required String title,
    required String body,
    required List<String> tags,
  }) {
    return (_db.update(_db.noteRows)..where((t) => t.id.equals(id))).write(
      NoteRowsCompanion(
        title: Value(title),
        body: Value(body),
        tags: Value(jsonEncode(_normalizeTags(tags))),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> deleteNote(int id) {
    return (_db.delete(_db.noteRows)..where((t) => t.id.equals(id))).go();
  }

  /// Every tag in use, sorted.
  Future<List<String>> getTags() async {
    final List<NoteRow> rows = await _db.select(_db.noteRows).get();
    final Set<String> tags = <String>{
      for (final NoteRow row in rows) ..._fromRow(row).tags,
    };
    return tags.toList()..sort();
  }

  List<String> _normalizeTags(List<String> tags) {
    return <String>{
      for (final String tag in tags)
        if (tag.trim().isNotEmpty) tag.trim().toLowerCase(),
    }.toList();
  }

  Note _fromRow(NoteRow row) {
    return Note(
      id: row.id,
      title: row.title,
      body: row.body,
      tags: (jsonDecode(row.tags) as List<dynamic>).cast<String>(),
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }
}

final Provider<NotesRepository> notesRepositoryProvider =
    Provider<NotesRepository>(
      (ref) => NotesRepository(ref.watch(appDatabaseProvider)),
    );
