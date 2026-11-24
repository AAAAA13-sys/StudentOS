import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studentos/core/db/app_database.dart';
import 'package:studentos/core/db/backup.dart';
import 'package:studentos/features/calendar/calendar_repository.dart';
import 'package:studentos/features/calendar/event.dart';
import 'package:studentos/features/calendar/schedule_view.dart';
import 'package:studentos/features/finance/bill.dart';
import 'package:studentos/features/finance/bills_repository.dart';
import 'package:studentos/features/finance/finance_repository.dart';
import 'package:studentos/features/finance/goals_repository.dart';
import 'package:studentos/features/finance/savings_goal.dart';
import 'package:studentos/features/finance/transaction.dart';
import 'package:studentos/features/focus/alarm.dart';
import 'package:studentos/features/focus/focus_repository.dart';
import 'package:studentos/features/notes/note.dart';
import 'package:studentos/features/notes/notes_repository.dart';
import 'package:studentos/features/tasks/task_item.dart';
import 'package:studentos/features/tasks/tasks_repository.dart';
import 'package:studentos/features/work/payday.dart';
import 'package:studentos/features/work/shift.dart';
import 'package:studentos/features/work/work_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

  test('Restoring settings updates paydayProvider and scheduleViewProvider on invalidation', () async {
    final AppDatabase source = AppDatabase(NativeDatabase.memory());
    final AppDatabase target = AppDatabase(NativeDatabase.memory());
    addTearDown(source.close);
    addTearDown(target.close);

    await source
        .into(source.settingRows)
        .insertOnConflictUpdate(
          SettingRowsCompanion.insert(key: 'payday', value: 'weekly:5'),
        );
    await source
        .into(source.settingRows)
        .insertOnConflictUpdate(
          SettingRowsCompanion.insert(key: 'schedule_view', value: 'week'),
        );

    final ProviderContainer container = ProviderContainer(
      overrides: [appDatabaseProvider.overrideWithValue(target)],
    );
    addTearDown(container.dispose);

    expect(container.read(paydayProvider), PaydaySchedule.none);
    expect(container.read(scheduleViewProvider), ScheduleView.month);

    final String json = await BackupService(source).exportJson();
    await BackupService(target).restoreJson(json);

    container
      ..invalidate(paydayProvider)
      ..invalidate(scheduleViewProvider);
    container.read(paydayProvider);
    container.read(scheduleViewProvider);
    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(container.read(paydayProvider), PaydaySchedule.weekly(5));
    expect(container.read(scheduleViewProvider), ScheduleView.week);
  });

  test('hasData counts shifts and alarms too', () async {
    final AppDatabase shiftDb = AppDatabase(NativeDatabase.memory());
    final AppDatabase alarmDb = AppDatabase(NativeDatabase.memory());
    addTearDown(shiftDb.close);
    addTearDown(alarmDb.close);

    expect(await BackupService(shiftDb).hasData(), isFalse);
    await WorkRepository(shiftDb).createShifts(<Shift>[
      Shift(
        id: 0,
        job: 'Library',
        startsAt: DateTime(2026, 11, 20, 14),
        durationMinutes: 120,
      ),
    ]);
    expect(await BackupService(shiftDb).hasData(), isTrue);

    expect(await BackupService(alarmDb).hasData(), isFalse);
    await FocusRepository(alarmDb).createAlarm(
      const Alarm(id: 0, hour: 7, minute: 0),
    );
    expect(await BackupService(alarmDb).hasData(), isTrue);
  });

  test('restoreJsonWithCounts reports bills, shifts and alarms', () async {
    final AppDatabase source = AppDatabase(NativeDatabase.memory());
    final AppDatabase target = AppDatabase(NativeDatabase.memory());
    addTearDown(source.close);
    addTearDown(target.close);

    await BillsRepository(source).createBill(
      const Bill(
        id: 0,
        title: 'Internet',
        amountCents: 129900,
        category: 'Other',
        cadence: 'monthly:5',
        nextDueOn: '2026-12-05',
      ),
    );
    await WorkRepository(source).createShifts(<Shift>[
      Shift(
        id: 0,
        job: 'Cafe',
        startsAt: DateTime(2026, 11, 21, 9),
        durationMinutes: 240,
      ),
    ]);
    await FocusRepository(source).createAlarm(
      const Alarm(id: 0, hour: 6, minute: 30, label: 'Class'),
    );
    await TaskRepository(source).createTask(
      TaskItem(
        id: 0,
        title: 'Submit lab report',
        notes: 'Section 3',
        dueOn: '2026-11-24',
        repeat: TaskRepeat.weekly,
        createdAt: DateTime(2026, 11, 20),
      ),
    );

    final String json = await BackupService(source).exportJson();
    final counts = await BackupService(target).restoreJsonWithCounts(json);
    expect(counts, (
      events: 0,
      transactions: 0,
      notes: 0,
      bills: 1,
      shifts: 1,
      alarms: 1,
      tasks: 1,
      goals: 0,
    ));

    final TaskItem restoredTask = (await TaskRepository(target).getTasks()).single;
    expect(restoredTask.title, 'Submit lab report');
    expect(restoredTask.notes, 'Section 3');
    expect(restoredTask.dueOn, '2026-11-24');
    expect(restoredTask.repeat, TaskRepeat.weekly);
    expect(restoredTask.done, isFalse);
  });

  test('Restoring a v5 backup without tasks defaults tasks to empty', () async {
    final AppDatabase db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    await TaskRepository(db).createTask(
      TaskItem(
        id: 0,
        title: 'Old task',
        createdAt: DateTime(2026, 11, 20),
      ),
    );
    expect(await BackupService(db).hasData(), isTrue);

    final String v5Json = jsonEncode(<String, Object?>{
      'app': 'studentos',
      'format': 5,
      'exported_at': '2026-11-20T00:00:00.000Z',
      'events': <Object?>[],
      'transactions': <Object?>[],
      'notes': <Object?>[],
      'bills': <Object?>[],
    });
    final counts = await BackupService(db).restoreJsonWithCounts(v5Json);
    expect(counts.tasks, 0);
    expect(await TaskRepository(db).getTasks(), isEmpty);
  });

  test('hasData counts tasks too', () async {
    final AppDatabase db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    expect(await BackupService(db).hasData(), isFalse);
    await TaskRepository(db).createTask(
      TaskItem(id: 0, title: 'Buy pens', createdAt: DateTime(2026, 11, 20)),
    );
    expect(await BackupService(db).hasData(), isTrue);
  });

  test('backupStatusProvider reacts to local writes and backup markers', () async {
    final AppDatabase db = AppDatabase(NativeDatabase.memory());
    final ProviderContainer container = ProviderContainer(
      overrides: [appDatabaseProvider.overrideWithValue(db)],
    );
    addTearDown(() async {
      container.dispose();
      await db.close();
    });

    final List<BackupStatus> seen = <BackupStatus>[];
    final sub = container.listen<AsyncValue<BackupStatus>>(
      backupStatusProvider,
      (_, AsyncValue<BackupStatus> next) {
        if (next.hasValue) seen.add(next.requireValue);
      },
      fireImmediately: true,
    );
    addTearDown(sub.close);

    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(seen.last, (last: null, hasData: false));

    await WorkRepository(db).createShifts(<Shift>[
      Shift(
        id: 0,
        job: 'Tutor',
        startsAt: DateTime(2026, 11, 22, 10),
        durationMinutes: 90,
      ),
    ]);
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(seen.last.hasData, isTrue);
    expect(seen.last.last, isNull);

    final DateTime backedUpAt = DateTime(2026, 11, 22, 12);
    await BackupService(db).markBackedUp(backedUpAt);
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(seen.last.hasData, isTrue);
    expect(seen.last.last, backedUpAt);
  });

  test('v7 backup round-trips goals and counts them', () async {
    final AppDatabase source = AppDatabase(NativeDatabase.memory());
    final AppDatabase target = AppDatabase(NativeDatabase.memory());
    addTearDown(source.close);
    addTearDown(target.close);

    await GoalsRepository(source).createGoal(
      SavingsGoal(
        id: 0,
        title: 'Tuition',
        targetCents: 1500000,
        savedCents: 450000,
        targetDate: '2026-12-20',
        createdAt: DateTime(2026, 11, 20),
      ),
    );

    final String json = await BackupService(source).exportJson();
    final counts = await BackupService(target).restoreJsonWithCounts(json);
    expect(counts.goals, 1);

    final SavingsGoal restored =
        (await GoalsRepository(target).getGoals()).single;
    expect(restored.title, 'Tuition');
    expect(restored.targetCents, 1500000);
    expect(restored.savedCents, 450000);
    expect(restored.targetDate, '2026-12-20');
  });

  test('Restoring a v6 backup without goals defaults goals to empty', () async {
    final AppDatabase db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    await GoalsRepository(db).createGoal(
      SavingsGoal(
        id: 0,
        title: 'Old goal',
        targetCents: 50000,
        createdAt: DateTime(2026, 11, 20),
      ),
    );
    expect(await BackupService(db).hasData(), isTrue);

    final String v6Json = jsonEncode(<String, Object?>{
      'app': 'studentos',
      'format': 6,
      'exported_at': '2026-11-20T00:00:00.000Z',
      'events': <Object?>[],
      'transactions': <Object?>[],
      'notes': <Object?>[],
      'bills': <Object?>[],
      'tasks': <Object?>[],
    });
    final counts = await BackupService(db).restoreJsonWithCounts(v6Json);
    expect(counts.goals, 0);
    expect(await GoalsRepository(db).getGoals(), isEmpty);
  });

  test('hasData and backupStatusProvider react to goal writes', () async {
    final AppDatabase db = AppDatabase(NativeDatabase.memory());
    final ProviderContainer container = ProviderContainer(
      overrides: [appDatabaseProvider.overrideWithValue(db)],
    );
    addTearDown(() async {
      container.dispose();
      await db.close();
    });

    final List<BackupStatus> seen = <BackupStatus>[];
    final sub = container.listen<AsyncValue<BackupStatus>>(
      backupStatusProvider,
      (_, AsyncValue<BackupStatus> next) {
        if (next.hasValue) seen.add(next.requireValue);
      },
      fireImmediately: true,
    );
    addTearDown(sub.close);

    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(seen.last, (last: null, hasData: false));
    expect(await BackupService(db).hasData(), isFalse);

    await GoalsRepository(db).createGoal(
      SavingsGoal(
        id: 0,
        title: 'Laptop',
        targetCents: 3000000,
        createdAt: DateTime(2026, 11, 22),
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(await BackupService(db).hasData(), isTrue);
    expect(seen.last.hasData, isTrue);
  });
}
