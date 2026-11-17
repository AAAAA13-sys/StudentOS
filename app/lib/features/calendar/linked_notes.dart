import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../notes/note.dart';
import '../notes/notes_controller.dart';
import '../notes/notes_repository.dart';

/// Every stored note by id, so an event card can tell whether the note it
/// links to still exists. Reloads whenever the notes list changes.
final FutureProvider<Map<int, Note>> linkedNotesProvider =
    FutureProvider<Map<int, Note>>((Ref ref) async {
      ref.watch(notesControllerProvider);
      final List<Note> notes = await ref
          .read(notesRepositoryProvider)
          .getNotes();
      return <int, Note>{for (final Note n in notes) n.id: n};
    });
