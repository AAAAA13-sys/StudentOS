import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studentos/core/db/app_database.dart';
import 'package:studentos/core/db/backup.dart';
import 'package:studentos/features/calendar/event.dart';
import 'package:studentos/features/finance/finance_repository.dart';
import 'package:studentos/features/finance/finance_screen.dart';
import 'package:studentos/features/finance/safe_to_spend.dart';
import 'package:studentos/features/finance/transaction.dart';
import 'package:studentos/features/work/shift.dart';
import 'package:studentos/features/work/work_controller.dart';
import 'package:studentos/features/work/work_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase database;

  setUp(() => database = AppDatabase(NativeDatabase.memory()));
  tearDown(() => database.close());

  Shift shift(
    DateTime start, {
    int minutes = 240,
    int breakMinutes = 0,
    int rate = 10000,
    bool paid = false,
  }) => Shift(
    id: 0,
    job: 'Cafe',
    startsAt: start,
    durationMinutes: minutes,
    breakMinutes: breakMinutes,
    hourlyRateCents: rate,
    paid: paid,
  );

  test('Pay is paid minutes times the rate, rounded to the centavo', () {
    // 4 hours at 100.00 per hour.
    expect(shift(DateTime(2026, 11, 7, 17)).payCents, 40000);
    // 50 minutes at 76.25 per hour = 63.5416... -> 63.54.
    expect(
      shift(DateTime(2026, 11, 7), minutes: 50, rate: 7625).payCents,
      6354,
    );
    // An unpaid break comes off; a break longer than the shift pays nothing.
    expect(
      shift(DateTime(2026, 11, 7), minutes: 270, breakMinutes: 30).payCents,
      40000,
    );
    expect(
      shift(DateTime(2026, 11, 7), minutes: 30, breakMinutes: 60).payCents,
      0,
    );
    expect(formatHours(270), '4.5');
    expect(formatHours(240), '4');
    expect(formatHours(255), '4.25');
  });

  test('An end time before the start means the shift ends the next day', () {
    expect(shiftDurationMinutes(17 * 60, 21 * 60 + 30), 270);
    expect(shiftDurationMinutes(22 * 60, 2 * 60), 240);
  });

  test('Worked and still-to-work are kept apart; paid shifts drop out', () {
    final DateTime now = DateTime(2026, 11, 16, 12);
    final WorkSummary summary = WorkSummary.of(<Shift>[
      shift(DateTime(2026, 11, 14, 17)), // worked
      shift(DateTime(2026, 11, 15, 22)), // overnight, ended 02:00 on the 16th
      shift(DateTime(2026, 11, 16, 10)), // in progress: not worked yet
      shift(DateTime(2026, 11, 20, 17)), // ahead
      shift(DateTime(2026, 11, 10, 17), paid: true), // already paid
    ], now);
    expect(summary.workedMinutes, 480);
    expect(summary.workedPayCents, 80000);
    expect(summary.upcomingMinutes, 480);
    expect(summary.upcomingPayCents, 80000);
  });

  test('A weekly shift is one shift per chosen day through the end date', () {
    // Nov 16 2026 is a Monday.
    final List<Shift> shifts = buildShiftSeries(
      job: 'Cafe',
      weekdays: <int>{DateTime.tuesday, DateTime.saturday},
      startMinute: 17 * 60 + 30,
      durationMinutes: 270,
      breakMinutes: 0,
      hourlyRateCents: 9500,
      from: DateTime(2026, 11, 16),
      until: DateTime(2026, 11, 28),
    );
    expect(shifts.map((Shift s) => s.startsAt).toList(), <DateTime>[
      DateTime(2026, 11, 17, 17, 30),
      DateTime(2026, 11, 21, 17, 30),
      DateTime(2026, 11, 24, 17, 30),
      DateTime(2026, 11, 28, 17, 30),
    ]);
  });

  test('Overlaps find classes and exams but not touching times', () {
    final CalendarEvent math = CalendarEvent(
      id: 1,
      title: 'Math 101',
      startsAt: DateTime(2026, 11, 2, 13), // Mondays 1:00-2:00 PM
      recurrence: 'weekly',
      recurrenceUntil: '2026-12-31',
    );
    final CalendarEvent exam = CalendarEvent(
      id: 2,
      title: 'Physics Midterm',
      startsAt: DateTime(2026, 11, 16, 13, 30),
    );
    final CalendarEvent lateParty = CalendarEvent(
      id: 3,
      title: 'Org night',
      startsAt: DateTime(2026, 11, 15, 23), // Sunday 11 PM to 1 AM
      durationMinutes: 120,
    );
    final List<CalendarEvent> events = <CalendarEvent>[math, exam, lateParty];

    List<String> hits(DateTime start, int minutes) => eventsOverlapping(
      start: start,
      durationMinutes: minutes,
      events: events,
    ).map((CalendarEvent e) => e.title).toList();

    // Monday Nov 16, 12:30-2:30 PM: the exam is listed first.
    expect(hits(DateTime(2026, 11, 16, 12, 30), 120), <String>[
      'Physics Midterm',
      'Math 101',
    ]);
    // Ends exactly when the class starts: no overlap.
    expect(hits(DateTime(2026, 11, 23, 9), 240), isEmpty);
    // After the class stops repeating: no overlap.
    expect(hits(DateTime(2027, 1, 4, 12, 30), 120), isEmpty);
    // An event that started the day before and runs past midnight.
    expect(hits(DateTime(2026, 11, 16, 0, 30), 60), <String>['Org night']);
  });

  test(
    'Shifts are kept in a backup; older backups restore with none',
    () async {
      final AppDatabase target = AppDatabase(NativeDatabase.memory());
      addTearDown(target.close);
      await WorkRepository(database).createShifts(<Shift>[
        shift(DateTime(2026, 11, 17, 17)),
        shift(DateTime(2026, 11, 24, 17)),
      ]);

      final String json = await BackupService(database).exportJson();
      expect(json, contains('"shifts"'));
      await BackupService(target).restoreJson(json);
      final List<Shift> restored = await WorkRepository(target).getShifts();
      expect(restored.length, 2);
      expect(restored.first.seriesId, isNotNull);
      expect(restored.first.seriesId, restored.last.seriesId);

      // A file from before shifts existed replaces them with nothing.
      await BackupService(target).restoreJson(
        '{"app":"studentos","format":1,"events":[],"transactions":[],'
        '"notes":[],"settings":[]}',
      );
      expect(await WorkRepository(target).getShifts(), isEmpty);
    },
  );

  test('Removing a shift and later ones keeps earlier and paid days', () async {
    final WorkRepository repo = WorkRepository(database);
    await repo.createShifts(<Shift>[
      shift(DateTime(2026, 11, 3, 17)),
      shift(DateTime(2026, 11, 10, 17)),
      shift(DateTime(2026, 11, 17, 17)),
      shift(DateTime(2026, 11, 24, 17)),
    ]);
    List<Shift> all = await repo.getShifts();
    await repo.markPaid(<int>[all[3].id]); // odd, but must survive
    await repo.deleteShiftAndLater(all[1]);
    all = await repo.getShifts();
    expect(all.map((Shift s) => s.startsAt.day).toList(), <int>[3, 24]);
  });

  test('I got paid adds income, marks worked shifts paid, and only then '
      'changes what is safe to spend', () async {
    final ProviderContainer container = ProviderContainer(
      overrides: [appDatabaseProvider.overrideWithValue(database)],
    );
    addTearDown(container.dispose);
    final DateTime now = DateTime(2026, 11, 21, 9);
    final FinanceRepository finance = FinanceRepository(database);
    await finance.createTransaction(
      Transaction(
        id: 0,
        type: 'income',
        amount: 3000,
        category: 'Allowance',
        occurredOn: DateTime(2026, 11, 1),
      ),
    );
    await WorkRepository(database).createShifts(<Shift>[
      shift(DateTime(2026, 11, 18, 17)), // worked, 400.00
      shift(DateTime(2026, 11, 25, 17)), // ahead
    ]);

    // Logged but unpaid work does not change the figure.
    expect((await finance.getSafeToSpend(now)).leftToday, 300);

    await container.read(workControllerProvider.future);
    await container
        .read(workControllerProvider.notifier)
        .gotPaid(380, now: now);

    final List<Shift> shifts = await WorkRepository(database).getShifts();
    expect(shifts.map((Shift s) => s.paid).toList(), <bool>[true, false]);
    final Transaction pay = (await finance.getTransactions()).first;
    expect(pay.category, 'Part-time Job');
    expect(pay.amount, 380);
    expect(pay.note, '4 hrs at Cafe');
    // 3,380 over 10 days.
    final SafeToSpend after = await finance.getSafeToSpend(now);
    expect(after.leftToday, 338);
  });

  testWidgets('A shift added from Finance shows on the Work pay card', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(database)],
        child: const MaterialApp(home: FinanceScreen()),
      ),
    );
    Future<void> settle() async {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pumpAndSettle();
    }

    await settle();
    expect(find.text('Work pay'), findsOneWidget);
    await tester.tap(find.text('Add a shift'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Workplace'),
      'Jollibee',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Pay per hour (optional)'),
      '95',
    );
    await tester.tap(find.text('Save shift'));
    await settle();

    final List<Shift>? saved = await tester.runAsync(
      () => WorkRepository(database).getShifts(),
    );
    expect(saved!.single.job, 'Jollibee');
    expect(saved.single.hourlyRateCents, 9500);
    expect(saved.single.durationMinutes, 240);
    expect(find.text('Shifts'), findsOneWidget);
  });
}
