import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studentos/core/db/app_database.dart';
import 'package:studentos/core/db/backup.dart';
import 'package:studentos/features/calendar/calendar_repository.dart';
import 'package:studentos/features/calendar/event.dart';
import 'package:studentos/features/finance/bill.dart';
import 'package:studentos/features/finance/bills_repository.dart';
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

    await FinanceRepository(source).setNextAllowance(DateTime(2026, 11, 26));
    await BillsRepository(source).createBill(
      const Bill(
        id: 0,
        title: 'Rent',
        amountCents: 350000,
        category: 'Other',
        cadence: 'monthly:15',
        nextDueOn: '2026-12-15',
        active: true,
        autoLog: true,
      ),
    );

    // Something already on the target must be replaced, not merged.
    await NotesRepository(
      target,
    ).createNote(const Note(id: 0, title: 'Old', body: '', tags: <String>[]));

    final String json = await BackupService(source).exportJson();
    final counts = await BackupService(target).restoreJson(json);
    expect(counts, (events: 1, transactions: 1, notes: 1));

    final Bill restoredBill = (await BillsRepository(target).getBills()).single;
    expect(restoredBill.title, 'Rent');
    expect(restoredBill.amountCents, 350000);
    expect(restoredBill.cadence, 'monthly:15');
    expect(restoredBill.nextDueOn, '2026-12-15');
    expect(restoredBill.autoLog, isTrue);

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
    expect(
      await FinanceRepository(target).getNextAllowance(),
      DateTime(2026, 11, 26),
    );
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

  test('Restoring a v4 backup without bills defaults bills to empty', () async {
    final AppDatabase db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    await BillsRepository(db).createBill(
      const Bill(
        id: 0,
        title: 'Old bill',
        amountCents: 50000,
        category: 'Other',
        cadence: 'monthly:1',
        nextDueOn: '2026-12-01',
      ),
    );
    expect(await BackupService(db).hasData(), isTrue);

    final String v4Json = jsonEncode(<String, Object?>{
      'app': 'studentos',
      'format': 4,
      'exported_at': '2026-11-20T00:00:00.000Z',
      'events': <Object?>[],
      'transactions': <Object?>[],
      'notes': <Object?>[],
    });
    await BackupService(db).restoreJson(v4Json);
    expect(await BillsRepository(db).getBills(), isEmpty);
  });
}
