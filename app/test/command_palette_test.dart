import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:studentos/core/db/app_database.dart';
import 'package:studentos/core/router/app_router.dart';
import 'package:studentos/core/widgets/app_drawer.dart';
import 'package:studentos/core/widgets/app_top_bar.dart';
import 'package:studentos/core/widgets/ponpon.dart';
import 'package:studentos/features/calendar/calendar_repository.dart';
import 'package:studentos/features/calendar/event.dart';
import 'package:studentos/features/finance/bill.dart';
import 'package:studentos/features/finance/bills_repository.dart';
import 'package:studentos/features/finance/finance_controller.dart';
import 'package:studentos/features/finance/finance_repository.dart';
import 'package:studentos/features/finance/goals_controller.dart';
import 'package:studentos/features/finance/goals_repository.dart';
import 'package:studentos/features/finance/iou_item.dart';
import 'package:studentos/features/finance/ious_repository.dart';
import 'package:studentos/features/finance/savings_goal.dart';
import 'package:studentos/features/finance/transaction.dart';
import 'package:studentos/features/focus/alarm.dart';
import 'package:studentos/features/focus/clock_panels.dart';
import 'package:studentos/features/focus/focus_repository.dart';
import 'package:studentos/features/notes/note.dart';
import 'package:studentos/features/notes/notes_repository.dart';
import 'package:studentos/features/search/global_search.dart';
import 'package:studentos/features/tasks/task_item.dart';
import 'package:studentos/features/tasks/tasks_controller.dart';
import 'package:studentos/features/tasks/tasks_repository.dart';
import 'package:studentos/features/work/shift.dart';
import 'package:studentos/features/work/work_repository.dart';
import 'package:studentos/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase database;

  setUp(() => database = AppDatabase(NativeDatabase.memory()));
  tearDown(() => database.close());

  Future<void> settle(WidgetTester tester) async {
    for (int i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 100));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
    }
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  Future<ProviderContainer> openApp(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 2.5;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(database)],
        child: const StudentOSApp(),
      ),
    );
    await settle(tester);
    return ProviderScope.containerOf(
      tester.element(find.byType(NavigationBar)),
    );
  }

  Future<void> seedAllNineEntities(DateTime now) async {
    final DateTime nextMonthDay = DateTime(now.year, now.month + 1, 12, 10, 30);
    final DateTime prevMonthDay = DateTime(now.year, now.month - 1, 8);
    final DateTime shiftDay = DateTime(now.year, now.month, now.day + 2, 14, 0);

    await CalendarRepository(database).createEvent(
      CalendarEvent(
        id: 0,
        title: 'Physics Midterm',
        startsAt: nextMonthDay,
        location: 'Room 304',
        notes: 'Bring calculator',
      ),
    );
    await WorkRepository(database).createShifts(<Shift>[
      Shift(
        id: 0,
        job: 'Campus Library Desk',
        startsAt: shiftDay,
        durationMinutes: 180,
        hourlyRateCents: 12000,
      ),
    ]);
    await TaskRepository(database).createTask(
      TaskItem(
        id: 0,
        title: 'Submit Bio Lab Report',
        notes: 'Include microscope diagrams',
        dueOn: DateFormat('yyyy-MM-dd').format(now),
        createdAt: now,
      ),
    );
    await NotesRepository(database).createNote(
      const Note(
        id: 0,
        title: 'Organic Chemistry Notes',
        body: 'Alkene addition reactions and mechanisms',
        tags: <String>['chem', 'midterm'],
      ),
    );
    await FinanceRepository(database).createTransaction(
      Transaction(
        id: 0,
        type: 'expense',
        amount: 145,
        category: 'Food',
        occurredOn: prevMonthDay,
        note: 'Ramen dinner',
      ),
    );
    await BillsRepository(database).createBill(
      Bill(
        id: 0,
        title: 'Dorm Wi-Fi',
        amountCents: 99900,
        category: 'Other',
        cadence: 'monthly:15',
        nextDueOn: DateFormat('yyyy-MM-dd').format(
          DateTime(now.year, now.month, now.day + 3),
        ),
      ),
    );
    await GoalsRepository(database).createGoal(
      SavingsGoal(
        id: 0,
        title: 'New Laptop Fund',
        targetCents: 3000000,
        savedCents: 1200000,
        createdAt: now,
      ),
    );
    await IousRepository(database).createIou(
      IouItem(
        id: 0,
        person: 'Mika',
        direction: IouDirection.owed,
        amountCents: 25000,
        note: 'Group pizza split',
        occurredOn: DateFormat('yyyy-MM-dd').format(now),
        createdAt: now,
      ),
    );
    await FocusRepository(database).createAlarm(
      const Alarm(
        id: 0,
        hour: 6,
        minute: 30,
        label: 'Morning Chem Lab',
      ),
    );
  }

  group('Global search snapshot and ranking', () {
    test('indexes all 9 entity types plus quick commands', () async {
      final DateTime now = DateTime(2026, 11, 24, 9, 0);
      await seedAllNineEntities(now);

      final ProviderContainer container = ProviderContainer(
        overrides: [appDatabaseProvider.overrideWithValue(database)],
      );
      addTearDown(container.dispose);

      final List<SearchHit> hits = await loadGlobalSearchSnapshotFromContainer(
        container,
        now: now,
      );

      final Set<SearchHitKind> kinds = hits.map((SearchHit h) => h.kind).toSet();
      expect(kinds, containsAll(SearchHitKind.values));

      expect(
        hits.any((SearchHit h) =>
            h.kind == SearchHitKind.event && h.title == 'Physics Midterm'),
        isTrue,
      );
      expect(
        hits.any((SearchHit h) =>
            h.kind == SearchHitKind.shift && h.title == 'Campus Library Desk'),
        isTrue,
      );
      expect(
        hits.any((SearchHit h) =>
            h.kind == SearchHitKind.task && h.title == 'Submit Bio Lab Report'),
        isTrue,
      );
      expect(
        hits.any((SearchHit h) =>
            h.kind == SearchHitKind.note &&
            h.title == 'Organic Chemistry Notes'),
        isTrue,
      );
      expect(
        hits.any((SearchHit h) =>
            h.kind == SearchHitKind.transaction &&
            h.title.contains('Ramen dinner')),
        isTrue,
      );
      expect(
        hits.any((SearchHit h) =>
            h.kind == SearchHitKind.bill && h.title == 'Dorm Wi-Fi'),
        isTrue,
      );
      expect(
        hits.any((SearchHit h) =>
            h.kind == SearchHitKind.goal && h.title == 'New Laptop Fund'),
        isTrue,
      );
      expect(
        hits.any((SearchHit h) =>
            h.kind == SearchHitKind.iou && h.title.contains('Mika')),
        isTrue,
      );
      expect(
        hits.any((SearchHit h) =>
            h.kind == SearchHitKind.alarm &&
            h.title.contains('Morning Chem Lab')),
        isTrue,
      );
      for (final String cmd in const <String>[
        'Quick expense',
        'New task',
        'New event',
        'New note',
        'Start focus',
        'Month in review',
        'Export CSV / summary',
        'Back up to a file',
        'Add Today widget',
        'Add Money widget',
      ]) {
        expect(
          hits.any(
            (SearchHit h) =>
                h.kind == SearchHitKind.command && h.title == cmd,
          ),
          isTrue,
          reason: 'Missing command $cmd',
        );
      }
    });

    test(
      'filterAndRankHits supports empty-query commands, tokens, groups, and ranking',
      () async {
        final DateTime now = DateTime(2026, 11, 24, 9, 0);
        await seedAllNineEntities(now);
        await NotesRepository(database).createNote(
          const Note(
            id: 0,
            title: 'Lab Logistics',
            body: 'Check physics equipment list',
            tags: <String>[],
          ),
        );

        final ProviderContainer container = ProviderContainer(
          overrides: [appDatabaseProvider.overrideWithValue(database)],
        );
        addTearDown(container.dispose);

        final List<SearchHit> all = await loadGlobalSearchSnapshotFromContainer(
          container,
          now: now,
        );

        // Empty query on All returns quick commands only.
        final List<SearchHit> emptyAll = filterAndRankHits(all, '');
        expect(emptyAll, isNotEmpty);
        expect(
          emptyAll.every((SearchHit h) => h.kind == SearchHitKind.command),
          isTrue,
        );

        // Empty query with a group returns that group's items.
        final List<SearchHit> financeOnly = filterAndRankHits(
          all,
          '',
          groupFilter: 'Finance',
        );
        expect(financeOnly.length, 4);
        expect(
          financeOnly.every(
            (SearchHit h) =>
                h.kind == SearchHitKind.transaction ||
                h.kind == SearchHitKind.bill ||
                h.kind == SearchHitKind.goal ||
                h.kind == SearchHitKind.iou,
          ),
          isTrue,
        );

        // Multi-token search across title + subtitle + searchText, ranked by title prefix.
        final List<SearchHit> physics = filterAndRankHits(all, 'physics');
        expect(physics.first.title, 'Physics Midterm');

        final List<SearchHit> tokenMatch = filterAndRankHits(all, 'physics 304');
        expect(tokenMatch.length, 1);
        expect(tokenMatch.first.title, 'Physics Midterm');

        // Group + filterKind scoping.
        final List<SearchHit> calendarPhysics = filterAndRankHits(
          all,
          'physics',
          groupFilter: 'Calendar',
        );
        expect(calendarPhysics.length, 1);
        expect(calendarPhysics.first.kind, SearchHitKind.event);

        final List<SearchHit> notesPhysics = filterAndRankHits(
          all,
          'physics',
          filterKind: SearchHitKind.note,
        );
        expect(notesPhysics.length, 1);
        expect(notesPhysics.first.title, 'Lab Logistics');
      },
    );
  });

  group('Command palette entry triggers & navigation', () {
    testWidgets(
      'opens from Finance, Notes, Calendar Schedule More, Alarms, Focus, and Drawer',
      (WidgetTester tester) async {
        final ProviderContainer container = await openApp(tester);

        // 1. Calendar > Schedule > More > Search & commands
        await tester.tap(find.byTooltip('More'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Search & commands'));
        await settle(tester);
        expect(
          find.text('Search events, notes, tasks, money or commands'),
          findsOneWidget,
        );

        // Empty state with Ponpon smug
        await tester.enterText(find.byType(TextField).last, 'zzzznonexistent');
        await tester.pumpAndSettle();
        expect(find.text('No matching items'), findsOneWidget);
        expect(find.byType(Ponpon), findsWidgets);

        // Close palette
        await tester.tapAt(const Offset(20, 20));
        await tester.pumpAndSettle();

        // 2. Calendar > Alarms & Focus (each keeps <= 2 AppTopBar actions)
        await tester.tap(find.text('Alarms'));
        await settle(tester);
        final AppTopBar alarmBar = tester.widget(find.byType(AppTopBar));
        expect(alarmBar.actions.length, lessThanOrEqualTo(2));
        await tester.tap(find.byTooltip('Search & commands'));
        await settle(tester);
        expect(find.text('Quick expense'), findsOneWidget);
        await tester.tapAt(const Offset(20, 20));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Focus'));
        await settle(tester);
        final AppTopBar focusBar = tester.widget(find.byType(AppTopBar));
        expect(focusBar.actions.length, lessThanOrEqualTo(2));
        await tester.tap(find.byTooltip('Search & commands'));
        await settle(tester);
        expect(find.text('Quick expense'), findsOneWidget);
        await tester.tapAt(const Offset(20, 20));
        await tester.pumpAndSettle();

        // 3. Finance AppTopBar search icon
        container.read(routerProvider).go('/finance');
        await settle(tester);
        final AppTopBar financeBar = tester.widget(find.byType(AppTopBar));
        expect(financeBar.actions.length, lessThanOrEqualTo(2));
        await tester.tap(find.byTooltip('Search & commands'));
        await settle(tester);
        expect(find.text('Quick expense'), findsOneWidget);
        await tester.tapAt(const Offset(20, 20));
        await tester.pumpAndSettle();

        // 4. Notes AppTopBar search icon
        container.read(routerProvider).go('/notes');
        await settle(tester);
        final AppTopBar notesBar = tester.widget(find.byType(AppTopBar));
        expect(notesBar.actions.length, lessThanOrEqualTo(2));
        await tester.tap(find.byTooltip('Search & commands'));
        await settle(tester);
        expect(find.text('Quick expense'), findsOneWidget);
        await tester.tapAt(const Offset(20, 20));
        await tester.pumpAndSettle();

        // 5. AppDrawer > Search & commands
        await tester.tap(find.byIcon(Icons.menu_rounded).first);
        await tester.pumpAndSettle();
        expect(find.byType(AppDrawer), findsOneWidget);
        await tester.tap(find.text('Search & commands'));
        await settle(tester);
        expect(find.byType(AppDrawer), findsNothing);
        expect(find.text('Quick expense'), findsOneWidget);
      },
    );

    testWidgets(
      'selecting entity hits routes cleanly to every target view',
      (WidgetTester tester) async {
        final DateTime now = DateTime.now();
        await seedAllNineEntities(now);
        final ProviderContainer container = await openApp(tester);

        // Pre-apply a Finance filter so we verify selecting a Transaction clears it
        // and switches Finance to that transaction's month.
        container.read(financeFilterProvider.notifier).setQuery('nonexistent');

        Future<void> openPaletteAndTap(String query, String hitText) async {
          // Open from current screen's menu drawer so it works from any tab/view.
          await tester.tap(find.byIcon(Icons.menu_rounded).first);
          await tester.pumpAndSettle();
          await tester.tap(find.text('Search & commands'));
          await settle(tester);
          await tester.enterText(find.byType(TextField).last, query);
          await tester.pumpAndSettle();
          await tester.tap(find.textContaining(hitText).last);
          await settle(tester);
        }

        // 1. Event -> Calendar day with _filterByDay == true
        await openPaletteAndTap('Physics Midterm', 'Physics Midterm');
        expect(container.read(calendarViewProvider), CalendarView.schedule);
        final FilterChip thisDayChip = tester.widget<FilterChip>(
          find.widgetWithText(FilterChip, 'This day'),
        );
        expect(thisDayChip.selected, isTrue);
        expect(find.text('Physics Midterm'), findsOneWidget);

        // 2. Task -> Notes > Tasks
        await openPaletteAndTap('Submit Bio Lab', 'Submit Bio Lab Report');
        expect(container.read(notesViewProvider), NotesView.tasks);
        expect(find.text('Submit Bio Lab Report'), findsOneWidget);

        // 3. Note -> Notes + opens note editor and saves cleanly
        await openPaletteAndTap('Organic Chemistry', 'Organic Chemistry Notes');
        expect(container.read(notesViewProvider), NotesView.notes);
        expect(find.text('Edit note'), findsOneWidget);
        await tester.tap(find.text('Save changes'));
        await settle(tester);
        expect(find.text('Edit note'), findsNothing);

        // 4. Transaction -> Finance Cashflow (switches month + clears filters)
        final String expectedPrevMonth = DateFormat(
          'yyyy-MM',
        ).format(DateTime(now.year, now.month - 1, 8));
        await openPaletteAndTap('Ramen dinner', 'Food · Ramen dinner');
        expect(container.read(financeViewProvider), FinanceView.cashflow);
        expect(container.read(financeFilterProvider).isActive, isFalse);
        expect(
          container.read(financeControllerProvider).value?.month,
          expectedPrevMonth,
        );
        expect(find.text('Ramen dinner'), findsOneWidget);

        // 5. Goal -> Finance > Goals
        await openPaletteAndTap('New Laptop Fund', 'New Laptop Fund');
        expect(container.read(financeViewProvider), FinanceView.goals);
        expect(find.text('New Laptop Fund'), findsOneWidget);

        // 6. IOU -> Finance > IOUs
        await openPaletteAndTap('Mika', 'Mika · Owes you');
        expect(container.read(financeViewProvider), FinanceView.ious);
        expect(find.text('Mika'), findsOneWidget);

        // 7. Alarm -> Calendar > Alarms
        await openPaletteAndTap('Morning Chem Lab', 'Morning Chem Lab');
        expect(container.read(calendarViewProvider), CalendarView.alarm);
        expect(find.text('Morning Chem Lab'), findsOneWidget);

        // 8. Shift -> Calendar day with _filterByDay == true
        await openPaletteAndTap('Campus Library Desk', 'Campus Library Desk');
        expect(container.read(calendarViewProvider), CalendarView.schedule);
        final FilterChip shiftDayChip = tester.widget<FilterChip>(
          find.widgetWithText(FilterChip, 'This day'),
        );
        expect(shiftDayChip.selected, isTrue);
        expect(find.text('Shift at Campus Library Desk'), findsOneWidget);

        // 9. Quick command -> Month in review
        await openPaletteAndTap('Month in review', 'Month in review');
        expect(find.text('Month in Review'), findsOneWidget);
      },
    );
  });
}
