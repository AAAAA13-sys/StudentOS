import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studentos/core/db/app_database.dart';
import 'package:studentos/features/calendar/calendar_repository.dart';
import 'package:studentos/features/calendar/calendar_screen.dart';
import 'package:studentos/features/calendar/class_schedule_sheet.dart';
import 'package:studentos/features/calendar/event.dart';
import 'package:studentos/features/finance/finance_repository.dart';
import 'package:studentos/features/finance/finance_screen.dart';
import 'package:studentos/features/finance/safe_to_spend.dart';
import 'package:studentos/features/finance/transaction.dart';
import 'package:studentos/features/notes/note.dart';
import 'package:studentos/features/notes/notes_repository.dart';
import 'package:studentos/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase database;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await database.close();
  });

  testWidgets('App opens straight on the calendar with no login', (
    WidgetTester tester,
  ) async {
    await tester.runAsync(() async {
      await CalendarRepository(database).createEvent(
        CalendarEvent(
          id: 0,
          title: 'Stored locally',
          startsAt: DateTime.now().add(const Duration(minutes: 5)),
        ),
      );
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(database)],
        child: const StudentOSApp(),
      ),
    );
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Sign In'), findsNothing);
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(NavigationDestination), findsNWidgets(3));
    expect(find.text('Stored locally'), findsWidgets);
  });

  group('Calendar', () {
    test('events survive a round trip and can be edited and deleted', () async {
      final CalendarRepository repo = CalendarRepository(database);
      final CalendarEvent created = await repo.createEvent(
        CalendarEvent(
          id: 0,
          title: 'Math 101',
          startsAt: DateTime(2026, 11, 20, 9, 30),
          durationMinutes: 90,
          location: 'Room 204',
          recurrence: 'weekly',
        ),
      );

      List<CalendarEvent> events = await repo.getEvents();
      expect(events.single.id, created.id);
      expect(events.single.startsAt, DateTime(2026, 11, 20, 9, 30));
      expect(events.single.location, 'Room 204');

      await repo.updateEvent(
        CalendarEvent(
          id: created.id,
          title: 'Math 102',
          startsAt: DateTime(2026, 11, 20, 10, 0),
        ),
      );
      events = await repo.getEvents();
      expect(events.single.title, 'Math 102');
      expect(events.single.location, isNull);
      expect(events.single.recurrence, 'none');

      await repo.deleteEvent(created.id);
      expect(await repo.getEvents(), isEmpty);
    });

    test('next event is the soonest upcoming occurrence', () async {
      final CalendarRepository repo = CalendarRepository(database);
      final DateTime now = DateTime.now();
      await repo.createEvent(
        CalendarEvent(
          id: 0,
          title: 'Finished',
          startsAt: now.subtract(const Duration(days: 3)),
        ),
      );
      await repo.createEvent(
        CalendarEvent(
          id: 0,
          title: 'Next week',
          startsAt: now.add(const Duration(days: 7)),
        ),
      );
      await repo.createEvent(
        CalendarEvent(
          id: 0,
          title: 'Daily class',
          startsAt: now.subtract(const Duration(days: 10, hours: 1)),
          recurrence: 'daily',
        ),
      );

      final next = await repo.getNextEvent();
      expect(next?.title, 'Daily class');
      expect(next!.startsAt.isAfter(now), isTrue);
      expect(next.startsAt.difference(now) < const Duration(days: 1), isTrue);
    });

    test('recurrence steps and end dates', () {
      final CalendarEvent weekly = CalendarEvent(
        id: 1,
        title: 'Weekly',
        startsAt: DateTime(2026, 11, 2, 9),
        recurrence: 'weekly',
      );
      expect(
        weekly.nextOccurrence(DateTime(2026, 11, 15, 12)),
        DateTime(2026, 11, 16, 9),
      );

      final CalendarEvent monthly = CalendarEvent(
        id: 2,
        title: 'Monthly',
        startsAt: DateTime(2026, 1, 31, 8),
        recurrence: 'monthly',
      );
      expect(
        monthly.nextOccurrence(DateTime(2026, 2, 1)),
        DateTime(2026, 2, 28, 8),
      );

      final CalendarEvent ended = CalendarEvent(
        id: 3,
        title: 'Ended',
        startsAt: DateTime(2026, 11, 1, 9),
        recurrence: 'daily',
        recurrenceUntil: '2026-11-10',
      );
      expect(
        ended.nextOccurrence(DateTime(2026, 11, 10, 8)),
        DateTime(2026, 11, 10, 9),
      );
      expect(ended.nextOccurrence(DateTime(2026, 11, 10, 10)), isNull);

      final CalendarEvent once = CalendarEvent(
        id: 4,
        title: 'Once',
        startsAt: DateTime(2026, 11, 1, 9),
      );
      expect(once.nextOccurrence(DateTime(2026, 11, 2)), isNull);
    });
  });

  test('Finance: monthly summary only counts that month', () async {
    final FinanceRepository repo = FinanceRepository(database);
    Future<void> add(String type, double amount, String category, DateTime on) {
      return repo.createTransaction(
        Transaction(
          id: 0,
          type: type,
          amount: amount,
          category: category,
          occurredOn: on,
        ),
      );
    }

    await add('income', 5000, 'Allowance', DateTime(2026, 11, 1));
    await add('expense', 120.10, 'Food', DateTime(2026, 11, 15));
    await add('expense', 80.20, 'Food', DateTime(2026, 11, 16));
    await add('expense', 35, 'Transport', DateTime(2026, 11, 16));
    await add('expense', 999, 'School', DateTime(2026, 10, 31));

    final FinanceSummary summary = await repo.getSummary(month: '2026-11');
    expect(summary.totalIncome, 5000);
    expect(summary.totalExpenses, 235.30);
    expect(summary.balance, 4764.70);
    expect(summary.byCategory.map((c) => c.category), <String>[
      'Allowance',
      'Food',
      'Transport',
    ]);
    expect(summary.byCategory[1].total, 200.30);

    final List<Transaction> november = await repo.getTransactions(
      month: '2026-11',
    );
    expect(november, hasLength(4));
    expect(november.first.occurredOn, DateTime(2026, 11, 16));

    await repo.deleteTransaction(november.first.id);
    expect((await repo.getSummary(month: '2026-11')).totalExpenses, 200.30);
  });

  test('Class schedule makes one weekly event per chosen day', () {
    // Sunday 15 Nov 2026.
    final List<CalendarEvent> events = buildClassSchedule(
      title: 'Math 101',
      location: 'Room 204',
      weekdays: <int>{DateTime.friday, DateTime.monday, DateTime.sunday},
      hour: 9,
      minute: 30,
      durationMinutes: 90,
      from: DateTime(2026, 11, 15, 20),
      until: DateTime(2026, 12, 18),
    );

    expect(events.map((e) => e.startsAt), <DateTime>[
      DateTime(2026, 11, 16, 9, 30), // Monday
      DateTime(2026, 11, 20, 9, 30), // Friday
      DateTime(2026, 11, 15, 9, 30), // Sunday: today
    ]);
    expect(events.every((e) => e.recurrence == 'weekly'), isTrue);
    expect(events.every((e) => e.recurrenceUntil == '2026-12-18'), isTrue);

    final CalendarEvent friday = events[1];
    expect(friday.occursOn(DateTime(2026, 11, 13)), isFalse); // before start
    expect(friday.occursOn(DateTime(2026, 11, 27)), isTrue);
    expect(friday.occursOn(DateTime(2026, 11, 28)), isFalse); // Saturday
    expect(friday.occursOn(DateTime(2026, 12, 18)), isTrue); // last day
    expect(friday.occursOn(DateTime(2026, 12, 25)), isFalse); // term over
  });

  testWidgets('Add a class saves the chosen days', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(database)],
        child: const MaterialApp(home: CalendarScreen()),
      ),
    );
    Future<void> settle() async {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 150)),
      );
      await tester.pumpAndSettle();
    }

    await settle();
    await tester.tap(find.byTooltip('More'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add a class'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Save class'));
    await tester.pumpAndSettle();
    expect(find.text('Subject required'), findsOneWidget);
    expect(find.text('Pick at least one day'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).first, 'Chem 101');
    await tester.tap(find.text('Tue'));
    await tester.tap(find.text('Thu'));
    await tester.pump();
    await tester.ensureVisible(find.text('Save class'));
    await tester.tap(find.text('Save class'));
    await settle();

    final List<CalendarEvent>? saved = await tester.runAsync(
      () => CalendarRepository(database).getEvents(),
    );
    expect(saved, hasLength(2));
    expect(saved!.map((e) => e.startsAt.weekday).toSet(), <int>{
      DateTime.tuesday,
      DateTime.thursday,
    });
    expect(saved.every((e) => e.title == 'Chem 101'), isTrue);
  });

  testWidgets('Add note on an event attaches a note once it is saved', (
    WidgetTester tester,
  ) async {
    await tester.runAsync(
      () => CalendarRepository(database).createEvent(
        CalendarEvent(
          id: 0,
          title: 'Physics 201',
          startsAt: DateTime.now().add(const Duration(minutes: 5)),
        ),
      ),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(database)],
        child: const MaterialApp(home: CalendarScreen()),
      ),
    );
    Future<void> settle() async {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 150)),
      );
      await tester.pumpAndSettle();
    }

    await settle();
    await tester.tap(find.text('Add note'));
    await settle();

    // Nothing is stored until the draft is saved.
    expect(find.text('New Note'), findsOneWidget);
    expect(
      await tester.runAsync(() => NotesRepository(database).getNotes()),
      isEmpty,
    );
    await tester.ensureVisible(find.text('Save Note'));
    await tester.tap(find.text('Save Note'));
    await settle();

    expect(find.text('Open note'), findsOneWidget);
    final CalendarEvent? event = await tester.runAsync(
      () async => (await CalendarRepository(database).getEvents()).single,
    );
    final Note? note = await tester.runAsync<Note?>(
      () => NotesRepository(database).getNote(event!.noteId!),
    );
    expect(note!.title, 'Physics 201');
  });

  test('Safe to spend spreads the balance over the days left', () {
    // 3,000 on hand, 10 days left, nothing spent yet today.
    SafeToSpend value = SafeToSpend.calculate(
      balanceCents: 300000,
      spentTodayCents: 0,
      daysLeft: 10,
    );
    expect(value.leftToday, 300);

    // 120 spent today: today's share of 300 has 180 left.
    value = SafeToSpend.calculate(
      balanceCents: 288000,
      spentTodayCents: 12000,
      daysLeft: 10,
    );
    expect(value.leftToday, 180);
    expect(value.spentToday, 120);

    // Overspent today: never negative.
    value = SafeToSpend.calculate(
      balanceCents: 250000,
      spentTodayCents: 50000,
      daysLeft: 10,
    );
    expect(value.leftToday, 0);
    expect(value.hasFunds, isTrue);

    // Nothing on hand.
    value = SafeToSpend.calculate(
      balanceCents: -5000,
      spentTodayCents: 5000,
      daysLeft: 3,
    );
    expect(value.leftToday, 0);
    expect(value.hasFunds, isFalse);
  });

  test('Safe to spend counts earlier months, not future entries', () async {
    final FinanceRepository repo = FinanceRepository(database);
    Future<void> add(String type, double amount, DateTime on) {
      return repo.createTransaction(
        Transaction(
          id: 0,
          type: type,
          amount: amount,
          category: 'Other',
          occurredOn: on,
        ),
      );
    }

    await add('income', 1000, DateTime(2026, 10, 20)); // carried over
    await add('income', 2100, DateTime(2026, 11, 1));
    await add('expense', 100, DateTime(2026, 11, 10));
    await add('expense', 60, DateTime(2026, 11, 21)); // today
    await add('income', 9999, DateTime(2026, 11, 25)); // not yet received

    final SafeToSpend value = await repo.getSafeToSpend(
      DateTime(2026, 11, 21, 14),
    );
    // 3,000 at the start of the day over 10 days = 300, minus 60 spent.
    expect(value.daysLeft, 10);
    expect(value.spentToday, 60);
    expect(value.leftToday, 240);
  });

  test('Safe to spend lasts until the allowance day when one is set', () async {
    final FinanceRepository repo = FinanceRepository(database);
    await repo.createTransaction(
      Transaction(
        id: 0,
        type: 'income',
        amount: 3000,
        category: 'Allowance',
        occurredOn: DateTime(2026, 11, 1),
      ),
    );
    final DateTime today = DateTime(2026, 11, 21, 9);

    await repo.setNextAllowance(DateTime(2026, 11, 26));
    SafeToSpend value = await repo.getSafeToSpend(today);
    expect(value.untilAllowance, isTrue);
    expect(value.daysLeft, 5);
    expect(value.leftToday, 600);

    // An allowance day that has passed falls back to the end of the month.
    await repo.setNextAllowance(DateTime(2026, 11, 21));
    value = await repo.getSafeToSpend(today);
    expect(value.untilAllowance, isFalse);
    expect(value.daysLeft, 10);
    expect(value.leftToday, 300);
  });

  test('Safe to spend leaves out money set aside for bills', () async {
    // 3,000 on hand, 800 set aside: 2,200 over 10 days, minus 20 spent.
    SafeToSpend value = SafeToSpend.calculate(
      balanceCents: 298000,
      spentTodayCents: 2000,
      daysLeft: 10,
      reservedCents: 80000,
    );
    expect(value.leftToday, 200);
    expect(value.reserved, 800);

    // More set aside than there is on hand: nothing is safe, never negative.
    value = SafeToSpend.calculate(
      balanceCents: 50000,
      spentTodayCents: 0,
      daysLeft: 5,
      reservedCents: 80000,
    );
    expect(value.leftToday, 0);
    expect(value.hasFunds, isTrue);

    final FinanceRepository repo = FinanceRepository(database);
    await repo.createTransaction(
      Transaction(
        id: 0,
        type: 'income',
        amount: 3000,
        category: 'Allowance',
        occurredOn: DateTime(2026, 11, 1),
      ),
    );
    final DateTime today = DateTime(2026, 11, 21, 9);
    await repo.setReservedCents(80000);
    expect((await repo.getSafeToSpend(today)).leftToday, 220);

    await repo.setReservedCents(0);
    value = await repo.getSafeToSpend(today);
    expect(value.leftToday, 300);
    expect(value.reserved, 0);
  });

  testWidgets('Money can be set aside for bills from the card', (
    WidgetTester tester,
  ) async {
    await tester.runAsync(
      () => FinanceRepository(database).createTransaction(
        Transaction(
          id: 0,
          type: 'income',
          amount: 3000,
          category: 'Allowance',
          occurredOn: DateTime.now(),
        ),
      ),
    );
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
    await tester.tap(find.text('Set aside for bills'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '800');
    await tester.tap(find.text('Save'));
    await settle();

    expect(find.text('₱800.00 set aside for bills'), findsOneWidget);
    expect(
      await tester.runAsync(
        () => FinanceRepository(database).getReservedCents(),
      ),
      80000,
    );

    // Emptying the field stops setting money aside.
    await tester.tap(find.text('₱800.00 set aside for bills'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '');
    await tester.tap(find.text('Save'));
    await settle();
    expect(find.text('Set aside for bills'), findsOneWidget);
  });

  testWidgets('Quick expense is logged in two taps', (
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
    expect(find.text('Safe to spend today'), findsOneWidget);

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text('₱50'));
    await tester.pump();
    await tester.tap(find.text('Transport'));
    await settle();

    final List<Transaction>? saved = await tester.runAsync(
      () => FinanceRepository(database).getTransactions(),
    );
    expect(saved!.single.amount, 50);
    expect(saved.single.category, 'Transport');
    expect(saved.single.type, 'expense');
    expect(find.text('Quick expense'), findsNothing);
  });

  testWidgets('Quick expense takes a typed amount', (
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
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Other').first);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '37.50');
    await tester.pump();
    await tester.tap(find.text('Food'));
    await settle();

    final List<Transaction>? saved = await tester.runAsync(
      () => FinanceRepository(database).getTransactions(),
    );
    expect(saved!.single.amount, 37.5);
    expect(saved.single.category, 'Food');
  });

  testWidgets('Tapping a transaction edits it', (WidgetTester tester) async {
    await tester.runAsync(
      () => FinanceRepository(database).createTransaction(
        Transaction(
          id: 0,
          type: 'expense',
          amount: 500,
          category: 'Food',
          occurredOn: DateTime.now(),
          note: 'Typo',
        ),
      ),
    );
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
    await tester.scrollUntilVisible(
      find.textContaining('Typo'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('Typo'));
    await tester.pumpAndSettle();
    expect(find.text('Edit Transaction'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).first, '50');
    await tester.ensureVisible(find.text('Update Transaction'));
    await tester.tap(find.text('Update Transaction'));
    await settle();

    final List<Transaction>? saved = await tester.runAsync(
      () => FinanceRepository(database).getTransactions(),
    );
    expect(saved, hasLength(1));
    expect(saved!.single.amount, 50);
    expect(saved.single.note, 'Typo');
  });

  test('A note without a title is named after its first line', () {
    expect(noteTitleFor('  Physics  ', 'body'), 'Physics');
    expect(noteTitleFor('', 'Quiz on Friday\nchapters 3-4'), 'Quiz on Friday');
    expect(noteTitleFor(' ', '  \n '), isNull);
    expect(noteTitleFor('', 'x' * 80)!.length, 61);
  });

  test('Notes: search matches title, body and tags', () async {
    final NotesRepository repo = NotesRepository(database);
    await repo.createNote(
      const Note(
        id: 0,
        title: 'Physics Formula Sheet',
        body: 'Newtonian mechanics',
        tags: <String>[' Exam ', 'physics', 'exam'],
      ),
    );
    await repo.createNote(
      const Note(
        id: 0,
        title: 'Groceries',
        body: 'Rice and eggs',
        tags: <String>[],
      ),
    );

    expect(await repo.getTags(), <String>['exam', 'physics']);
    expect(
      (await repo.getNotes(q: 'FORMULA')).single.title,
      'Physics Formula Sheet',
    );
    expect((await repo.getNotes(q: 'eggs')).single.title, 'Groceries');
    expect(
      (await repo.getNotes(q: 'exam')).single.title,
      'Physics Formula Sheet',
    );
    expect((await repo.getNotes(tag: 'physics')), hasLength(1));
    expect(await repo.getNotes(q: 'nothing'), isEmpty);

    final Note groceries = (await repo.getNotes(q: 'eggs')).single;
    await repo.updateNote(
      groceries.id,
      title: 'Shopping',
      body: 'Rice',
      tags: <String>['home'],
    );
    expect((await repo.getNotes(tag: 'home')).single.title, 'Shopping');

    await repo.deleteNote(groceries.id);
    expect(await repo.getNotes(), hasLength(1));
  });
}
