import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studentos/core/db/app_database.dart';
import 'package:studentos/core/db/backup.dart';
import 'package:studentos/features/calendar/calendar_repository.dart';
import 'package:studentos/features/calendar/event.dart';
import 'package:studentos/features/finance/finance_repository.dart';
import 'package:studentos/features/finance/transaction.dart';
import 'package:studentos/features/notes/note.dart';
import 'package:studentos/features/notes/notes_repository.dart';

void main() {
  test('A backup restores every record into an empty database', () async {
    final AppDatabase source = AppDatabase(NativeDatabase.memory());
    final AppDatabase target = AppDatabase(NativeDatabase.memory());
    addTearDown(source.close);
    addTearDown(target.close);

    final int noteId = await NotesRepository(source).createNote(
      const Note(
        id: 0,
        title: 'Formula sheet',
        body: 'F = ma',
        tags: <String>['physics'],
      ),
    );
    await CalendarRepository(source).createEvent(
      CalendarEvent(
        id: 0,
        title: 'Physics 201',
        startsAt: DateTime(2026, 11, 16, 9),
        location: 'Room 304',
        recurrence: 'weekly',
        recurrenceUntil: '2027-03-15',
        noteId: noteId,
      ),
    );
    await FinanceRepository(source).createTransaction(
      Transaction(
        id: 0,
        type: 'expense',
        amount: 120.5,
        category: 'Food',
        occurredOn: DateTime(2026, 11, 15),
        note: 'Lunch',
      ),
    );

    // Something already on the target must be replaced, not merged.
    await NotesRepository(
      target,
    ).createNote(const Note(id: 0, title: 'Old', body: '', tags: <String>[]));

    final String json = await BackupService(source).exportJson();
    final counts = await BackupService(target).restoreJson(json);
    expect(counts, (events: 1, transactions: 1, notes: 1));

    final CalendarEvent event = (await CalendarRepository(
      target,
    ).getEvents()).single;
    expect(event.title, 'Physics 201');
    expect(event.startsAt, DateTime(2026, 11, 16, 9));
    expect(event.recurrenceUntil, '2027-03-15');
    final Note? note = await NotesRepository(target).getNote(event.noteId!);
    expect(note!.title, 'Formula sheet');
    expect(note.tags, <String>['physics']);
    expect(await NotesRepository(target).getNotes(), hasLength(1));
    final Transaction tx = (await FinanceRepository(
      target,
    ).getTransactions()).single;
    expect(tx.amount, 120.5);
    expect(tx.note, 'Lunch');
  });

  test('A file that is not a backup changes nothing', () async {
    final AppDatabase db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    await NotesRepository(db).createNote(
      const Note(id: 0, title: 'Keep me', body: '', tags: <String>[]),
    );
    final BackupService backup = BackupService(db);

    for (final String bad in <String>[
      'not json',
      '{"app":"other"}',
      '{"app":"studentos","format":99}',
      '{"app":"studentos","format":1,"events":"x"}',
    ]) {
      await expectLater(
        backup.restoreJson(bad),
        throwsA(isA<BackupFormatException>()),
      );
    }
    expect((await NotesRepository(db).getNotes()).single.title, 'Keep me');
  });
}
