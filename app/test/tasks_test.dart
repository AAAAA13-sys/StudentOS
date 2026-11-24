import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studentos/core/db/app_database.dart';
import 'package:studentos/core/router/app_router.dart';
import 'package:studentos/core/theme/app_theme.dart';
import 'package:studentos/core/widgets/app_drawer.dart';
import 'package:studentos/core/widgets/ponpon.dart';
import 'package:studentos/core/widgets/ponpon_talk.dart';
import 'package:studentos/features/calendar/calendar_repository.dart';
import 'package:studentos/features/calendar/calendar_screen.dart';
import 'package:studentos/features/calendar/event.dart';
import 'package:studentos/features/insights/insights_providers.dart';
import 'package:studentos/features/insights/ponpon_insight.dart';
import 'package:studentos/features/notes/notes_screen.dart';
import 'package:studentos/features/tasks/day_tasks.dart';
import 'package:studentos/features/tasks/task_item.dart';
import 'package:studentos/features/tasks/tasks_controller.dart';
import 'package:studentos/features/tasks/tasks_repository.dart';
import 'package:studentos/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> settle(WidgetTester tester) async {
    await tester.pump();
    await tester.pump();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 60)),
    );
    await tester.pumpAndSettle();
  }

  group('Drift v9 -> v10 migration', () {
    test('upgrades a v9 schema database and creates the tasks table', () async {
      final AppDatabase db = AppDatabase(
        NativeDatabase.memory(
          setup: (rawDb) {
            rawDb.execute('PRAGMA user_version = 9;');
            rawDb.execute(
              'CREATE TABLE notes ('
              'id INTEGER PRIMARY KEY AUTOINCREMENT, '
              'title TEXT NOT NULL, '
              'body TEXT NOT NULL, '
              'tags TEXT NOT NULL, '
              'created_at INTEGER NOT NULL, '
              'updated_at INTEGER NOT NULL, '
              'pinned INTEGER NOT NULL DEFAULT 0);',
            );
          },
        ),
      );
      addTearDown(db.close);

      expect(db.schemaVersion, greaterThanOrEqualTo(10));
      final TaskRepository repo = TaskRepository(db);
      final int id = await repo.createTask(
        TaskItem(
          id: 0,
          title: 'Migrated task',
          dueOn: '2026-11-24',
          repeat: TaskRepeat.daily,
          createdAt: DateTime(2026, 11, 24),
        ),
      );
      final TaskItem? loaded = await repo.getTask(id);
      expect(loaded, isNotNull);
      expect(loaded!.title, 'Migrated task');
      expect(loaded.repeat, TaskRepeat.daily);
    });
  });

  group('TaskItem & TaskRepository', () {
    test('dueStatus classifies overdue, today, upcoming, and anytime', () {
      final DateTime now = DateTime(2026, 11, 23, 15, 30);
      expect(
        const TaskItem(id: 1, title: 'A', dueOn: '2026-11-22').dueStatus(now),
        TaskDueStatus.overdue,
      );
      expect(
        const TaskItem(id: 2, title: 'B', dueOn: '2026-11-23').dueStatus(now),
        TaskDueStatus.today,
      );
      expect(
        const TaskItem(id: 3, title: 'C', dueOn: '2026-11-24').dueStatus(now),
        TaskDueStatus.upcoming,
      );
      expect(
        const TaskItem(id: 4, title: 'D').dueStatus(now),
        TaskDueStatus.anytime,
      );
    });

    test('nextDueAfter handles daily, weekly, and monthly clamping', () {
      expect(
        const TaskItem(
          id: 1,
          title: 'D',
          repeat: TaskRepeat.daily,
        ).nextDueAfter(DateTime(2026, 11, 30)),
        DateTime(2026, 12, 1),
      );
      expect(
        const TaskItem(
          id: 2,
          title: 'W',
          repeat: TaskRepeat.weekly,
        ).nextDueAfter(DateTime(2026, 11, 23)),
        DateTime(2026, 11, 30),
      );
      // Jan 31 -> Feb 28 (non-leap) and Feb 29 (leap).
      expect(
        const TaskItem(
          id: 3,
          title: 'M',
          repeat: TaskRepeat.monthly,
        ).nextDueAfter(DateTime(2027, 1, 31)),
        DateTime(2027, 2, 28),
      );
      expect(
        const TaskItem(
          id: 4,
          title: 'M',
          repeat: TaskRepeat.monthly,
        ).nextDueAfter(DateTime(2028, 1, 31)),
        DateTime(2028, 2, 29),
      );
      // Dec -> Jan rollover.
      expect(
        const TaskItem(
          id: 5,
          title: 'M',
          repeat: TaskRepeat.monthly,
        ).nextDueAfter(DateTime(2026, 12, 31)),
        DateTime(2027, 1, 31),
      );
      expect(
        const TaskItem(
          id: 6,
          title: 'N',
          repeat: TaskRepeat.none,
        ).nextDueAfter(DateTime(2026, 11, 23)),
        isNull,
      );
    });

    test('toggleDone advances repeating tasks past today and toggles one-off tasks', () async {
      final AppDatabase db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final TaskRepository repo = TaskRepository(db);

      final DateTime now = DateTime(2026, 11, 23, 9, 0);
      final int oneOffId = await repo.createTask(
        TaskItem(
          id: 0,
          title: 'Print syllabus',
          dueOn: '2026-11-23',
          createdAt: now,
        ),
      );
      final TaskItem oneOff = (await repo.getTask(oneOffId))!;
      final TaskItem doneOneOff = await repo.toggleDone(oneOff, now: now);
      expect(doneOneOff.done, isTrue);
      expect(doneOneOff.doneAt, now);

      final TaskItem undoneOneOff = await repo.toggleDone(doneOneOff, now: now);
      expect(undoneOneOff.done, isFalse);
      expect(undoneOneOff.doneAt, isNull);

      // Overdue repeating task advances past `now` and stays open.
      final int repeatId = await repo.createTask(
        TaskItem(
          id: 0,
          title: 'Review flashcards',
          dueOn: '2026-11-10',
          repeat: TaskRepeat.weekly,
          createdAt: DateTime(2026, 11, 10),
        ),
      );
      final TaskItem repeating = (await repo.getTask(repeatId))!;
      final TaskItem advanced = await repo.toggleDone(repeating, now: now);
      expect(advanced.done, isFalse);
      expect(advanced.doneAt, isNull);
      expect(advanced.dueOn, '2026-11-24');

      // Monthly repeating task due Jan 31 completed on Jan 31 clamps to Feb 28.
      final int monthEndId = await repo.createTask(
        TaskItem(
          id: 0,
          title: 'Pay dorm fee',
          dueOn: '2027-01-31',
          repeat: TaskRepeat.monthly,
          createdAt: DateTime(2027, 1, 1),
        ),
      );
      final TaskItem monthEnd = (await repo.getTask(monthEndId))!;
      final TaskItem nextMonth = await repo.toggleDone(
        monthEnd,
        now: DateTime(2027, 1, 31, 10),
      );
      expect(nextMonth.done, isFalse);
      expect(nextMonth.dueOn, '2027-02-28');
    });
  });

  group('Notes | Tasks segmented UI, routing & editor', () {
    testWidgets('Notes | Tasks switch updates FAB, filters, and Back returns to Notes', (
      WidgetTester tester,
    ) async {
      final AppDatabase db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [appDatabaseProvider.overrideWithValue(db)],
          child: const StudentOSApp(),
        ),
      );
      await settle(tester);

      final ProviderContainer container = ProviderScope.containerOf(
        tester.element(find.byType(NavigationBar)),
      );

      // Navigate via /tasks redirect -> opens Notes > Tasks.
      container.read(routerProvider).go('/tasks');
      await settle(tester);

      expect(container.read(notesViewProvider), NotesView.tasks);
      expect(find.byType(SegmentedButton<NotesView>), findsOneWidget);
      expect(find.byTooltip('New task'), findsOneWidget);
      // Empty state shows Ponpon and suppresses PonponTalk.
      expect(find.byType(Ponpon), findsOneWidget);
      expect(find.byType(PonponTalk), findsNothing);

      // Pressing system Back on Notes > Tasks returns to Notes > Notes first.
      final NavigatorState nav = tester.state(find.byType(Navigator).first);
      await nav.maybePop();
      await settle(tester);
      expect(container.read(notesViewProvider), NotesView.notes);
      expect(find.byTooltip('New note'), findsOneWidget);

      // Switch back to Tasks via SegmentedButton.
      await tester.tap(find.text('Tasks'));
      await settle(tester);
      expect(container.read(notesViewProvider), NotesView.tasks);
    });

    testWidgets('TasksPanel groups Open/Today/Done, >=48dp checkboxes, and CRUD via showTaskEditor', (
      WidgetTester tester,
    ) async {
      final AppDatabase db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);

      final DateTime now = DateTime.now();
      final DateTime today = taskDateOnly(now);
      final DateTime yesterday = DateTime(
        today.year,
        today.month,
        today.day - 1,
      );
      final DateTime nextWeek = DateTime(
        today.year,
        today.month,
        today.day + 5,
      );

      await tester.runAsync(() async {
        final TaskRepository repo = TaskRepository(db);
        await repo.createTask(
          TaskItem(
            id: 0,
            title: 'Overdue essay',
            dueOn: formatTaskDateKey(yesterday),
            createdAt: yesterday,
          ),
        );
        await repo.createTask(
          TaskItem(
            id: 0,
            title: 'Today quiz prep',
            dueOn: formatTaskDateKey(today),
            createdAt: today,
          ),
        );
        await repo.createTask(
          TaskItem(
            id: 0,
            title: 'Future reading',
            dueOn: formatTaskDateKey(nextWeek),
            createdAt: today,
          ),
        );
        await repo.createTask(
          TaskItem(id: 0, title: 'Anytime cleanup', createdAt: today),
        );
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [appDatabaseProvider.overrideWithValue(db)],
          child: MaterialApp(
            theme: AppTheme.light,
            home: const NotesScreen(),
          ),
        ),
      );
      await settle(tester);

      // Switch to Tasks.
      await tester.tap(find.text('Tasks'));
      await settle(tester);

      expect(find.text('Overdue'), findsOneWidget);
      expect(find.text('Today'), findsWidgets);
      expect(find.text('Upcoming'), findsOneWidget);
      expect(find.text('Anytime'), findsOneWidget);
      expect(find.text('Overdue essay'), findsOneWidget);
      expect(find.text('Today quiz prep'), findsOneWidget);
      expect(find.text('Future reading'), findsOneWidget);
      expect(find.text('Anytime cleanup'), findsOneWidget);

      // Verify checkbox tap target is >= 48dp and has checkbox semantics.
      final SemanticsHandle handle = tester.ensureSemantics();
      final Finder checkboxFinder = find.bySemanticsLabel('Today quiz prep');
      expect(checkboxFinder, findsOneWidget);
      final Size boxSize = tester.getSize(checkboxFinder);
      expect(boxSize.width, greaterThanOrEqualTo(48));
      expect(boxSize.height, greaterThanOrEqualTo(48));
      final SemanticsData sem = tester
          .getSemantics(checkboxFinder)
          .getSemanticsData();
      expect(sem.flagsCollection.isChecked, isNotNull);
      handle.dispose();

      // Today filter hides Upcoming & Anytime.
      await tester.tap(find.widgetWithText(FilterChip, 'Today'));
      await settle(tester);
      expect(find.text('Today quiz prep'), findsOneWidget);
      expect(find.text('Future reading'), findsNothing);
      expect(find.text('Anytime cleanup'), findsNothing);

      // Tick Today quiz prep -> moves out of Today/Open and into Done.
      await tester.tap(find.bySemanticsLabel('Today quiz prep'));
      await settle(tester);
      expect(find.text('Today quiz prep'), findsNothing);

      await tester.tap(find.widgetWithText(FilterChip, 'Done'));
      await settle(tester);
      expect(find.text('Today quiz prep'), findsOneWidget);

      // Add a new task via FAB -> showTaskEditor.
      await tester.tap(find.widgetWithText(FilterChip, 'Open'));
      await settle(tester);
      await tester.tap(find.byTooltip('New task'));
      await settle(tester);
      expect(find.text('New task'), findsOneWidget);

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Title'),
        'Buy index cards',
      );
      await tester.tap(find.text('Save task'));
      await settle(tester);
      expect(find.text('Buy index cards'), findsOneWidget);

      // Edit and delete via showTaskEditor + confirmDestructive.
      await tester.tap(find.text('Buy index cards'));
      await settle(tester);
      expect(find.text('Edit task'), findsOneWidget);

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Title'),
        'Buy flashcards',
      );
      await tester.tap(find.text('Save changes'));
      await settle(tester);
      expect(find.text('Buy flashcards'), findsOneWidget);

      await tester.tap(find.text('Buy flashcards'));
      await settle(tester);
      await tester.tap(find.text('Delete task'));
      await settle(tester);
      expect(find.text('Delete task?'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
      await settle(tester);
      expect(find.text('Buy flashcards'), findsNothing);
    });
  });

  group('Calendar DayTasks & Ponpon seeTasks', () {
    testWidgets('DayTasks displays today + overdue tasks on Calendar and toggles inline', (
      WidgetTester tester,
    ) async {
      final AppDatabase db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final DateTime today = taskDateOnly(DateTime.now());
      final DateTime yesterday = DateTime(
        today.year,
        today.month,
        today.day - 1,
      );

      await tester.runAsync(() async {
        final TaskRepository repo = TaskRepository(db);
        await repo.createTask(
          TaskItem(
            id: 0,
            title: 'Carryover task',
            dueOn: formatTaskDateKey(yesterday),
            createdAt: yesterday,
          ),
        );
        await repo.createTask(
          TaskItem(
            id: 0,
            title: 'Due today task',
            dueOn: formatTaskDateKey(today),
            createdAt: today,
          ),
        );
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [appDatabaseProvider.overrideWithValue(db)],
          child: MaterialApp(
            theme: AppTheme.light,
            home: const CalendarScreen(),
          ),
        ),
      );
      await settle(tester);

      expect(find.byType(DayTasks), findsOneWidget);
      expect(find.text('Carryover task'), findsOneWidget);
      expect(find.text('Due today task'), findsOneWidget);

      await tester.tap(find.bySemanticsLabel('Due today task'));
      await settle(tester);
      expect(find.text('Due today task'), findsNothing);
      expect(find.text('Carryover task'), findsOneWidget);
    });

    testWidgets('Ponpon seeTasks switches from Calendar to Notes > Tasks', (
      WidgetTester tester,
    ) async {
      final AppDatabase db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final DateTime now = DateTime.now();
      final DateTime today = taskDateOnly(now);

      await tester.runAsync(() async {
        // Add an event today so Calendar does not show its empty-state Ponpon
        // and suppress PonponTalkSlot.
        await CalendarRepository(db).createEvent(
          CalendarEvent(
            id: 0,
            title: 'Biology Lab',
            startsAt: DateTime(today.year, today.month, today.day, 10),
          ),
        );
        await TaskRepository(db).createTask(
          TaskItem(
            id: 0,
            title: 'Study biology',
            dueOn: formatTaskDateKey(today),
            createdAt: today,
          ),
        );
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWithValue(db),
            calendarInsightsProvider.overrideWithValue(const <PonponInsight>[
              PonponInsight(
                text: 'Task due today: Study biology.',
                mood: PonponMood.focused,
                priority: 2,
                action: PonponAction.seeTasks,
              ),
            ]),
          ],
          child: const StudentOSApp(),
        ),
      );
      await settle(tester);

      final ProviderContainer container = ProviderScope.containerOf(
        tester.element(find.byType(NavigationBar)),
      );

      expect(find.text('Task due today: Study biology.'), findsOneWidget);
      await tester.tap(find.text('See tasks'));
      await settle(tester);

      expect(container.read(notesViewProvider), NotesView.tasks);
      expect(find.text('Study biology'), findsOneWidget);
    });

    test('AppDrawer.formatRestoreSummary includes non-zero tasks', () {
      expect(
        AppDrawer.formatRestoreSummary(
          events: 1,
          transactions: 2,
          notes: 3,
          tasks: 4,
        ),
        'Restored 1 event, 2 transactions, 3 notes and 4 tasks',
      );
    });
  });
}
