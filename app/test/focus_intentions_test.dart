import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studentos/core/db/app_database.dart';
import 'package:studentos/core/router/app_router.dart';
import 'package:studentos/core/theme/app_theme.dart';
import 'package:studentos/core/widgets/ponpon_talk.dart';
import 'package:studentos/features/calendar/calendar_repository.dart';
import 'package:studentos/features/calendar/calendar_screen.dart';
import 'package:studentos/features/calendar/event.dart';
import 'package:studentos/features/focus/clock_panels.dart';
import 'package:studentos/features/focus/focus_controller.dart';
import 'package:studentos/features/focus/focus_plan.dart';
import 'package:studentos/features/focus/focus_platform.dart';
import 'package:studentos/features/focus/focus_repository.dart';
import 'package:studentos/features/insights/calendar_insights.dart';
import 'package:studentos/features/insights/insights_providers.dart';
import 'package:studentos/features/insights/ponpon_insight.dart';
import 'package:studentos/features/insights/ponpon_talk_slot.dart';
import 'package:studentos/features/notes/note.dart';
import 'package:studentos/features/notes/notes_repository.dart';
import 'package:studentos/features/tasks/task_item.dart';
import 'package:studentos/features/tasks/tasks_repository.dart';
import 'package:studentos/main.dart';

class _FakeFocusPlatform implements FocusPlatform {
  Map<String, Object?>? focus;
  final List<bool> pins = <bool>[];
  PhoneReadiness ready = const PhoneReadiness(accessibility: true);

  @override
  Future<void> syncAlarms(List<Map<String, Object?>> alarms) async {}

  @override
  Future<List<int>> takeFiredOnce() async => <int>[];

  @override
  Future<Map<int, DateTime>> snoozes() async => <int, DateTime>{};

  @override
  Future<void> testAlarm(Map<String, Object?> alarm) async {}

  @override
  Future<({String uri, String name})?> pickSound(String? current) async => null;

  @override
  Future<PhoneReadiness> readiness() async => ready;

  @override
  Future<void> openSetting(String which) async {}

  @override
  Future<void> startFocus(Map<String, Object?> session) async =>
      focus = session;

  @override
  Future<void> stopFocus() async => focus = null;

  @override
  Future<void> setPinned(bool pinned) async => pins.add(pinned);

  @override
  Future<List<InstalledApp>> launchableApps() async => const <InstalledApp>[];

  @override
  Future<String?> takeRoute() async => null;

  @override
  void onRouteWaiting(void Function() onRoute) {}

  @override
  Future<bool> pinWidget(String which) async => true;
}

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

  group('Drift v13 -> v14 migration & FocusIntention domain', () {
    test('upgrades v13 focus_logs and preserves pre-existing rows', () async {
      final AppDatabase db = AppDatabase(
        NativeDatabase.memory(
          setup: (rawDb) {
            rawDb.execute('PRAGMA user_version = 13;');
            rawDb.execute(
              'CREATE TABLE focus_logs ('
              'id INTEGER PRIMARY KEY AUTOINCREMENT, '
              'started_at INTEGER NOT NULL, '
              'ended_at INTEGER NOT NULL, '
              'focus_ms INTEGER NOT NULL, '
              'rounds INTEGER NOT NULL, '
              'ended_early INTEGER NOT NULL DEFAULT 0);',
            );
            rawDb.execute(
              'CREATE TABLE settings ('
              'key TEXT PRIMARY KEY NOT NULL, '
              'value TEXT NOT NULL);',
            );
            rawDb.execute(
              'INSERT INTO focus_logs (started_at, ended_at, focus_ms, rounds, ended_early) '
              'VALUES (1000, 2000, 600000, 1, 0);',
            );
          },
        ),
      );
      addTearDown(db.close);

      expect(db.schemaVersion, 14);
      final FocusRepository repo = FocusRepository(db);
      final FocusLog? legacy = await repo.latestLog();
      expect(legacy, isNotNull);
      expect(legacy!.focusMs, 600000);
      expect(legacy.intention, isNull);

      await repo.logSession(
        startedAt: DateTime(2026, 11, 24, 10),
        endedAt: DateTime(2026, 11, 24, 10, 25),
        focusMs: 1500000,
        rounds: 1,
        endedEarly: false,
        intention: const FocusIntention(
          type: FocusTargetType.event,
          id: 9,
          label: 'Bio 101',
        ),
      );
      final FocusLog? latest = await repo.latestLog();
      expect(latest, isNotNull);
      expect(
        latest!.intention,
        const FocusIntention(
          type: FocusTargetType.event,
          id: 9,
          label: 'Bio 101',
        ),
      );
    });

    test('FocusIntention JSON round-trip and SettingRows persistence', () async {
      const FocusIntention taskIntention = FocusIntention(
        type: FocusTargetType.task,
        id: 7,
        label: 'Finish lab',
      );
      final FocusIntention? parsed = FocusIntention.tryParse(
        taskIntention.toJsonString(),
      );
      expect(parsed, taskIntention);
      expect(FocusIntention.tryParse('not json'), isNull);
      expect(FocusIntention.tryParse('{"type":"unknown","label":"x"}'), isNull);
      expect(FocusIntention.tryParse('{"type":"task","label":"  "}'), isNull);

      final AppDatabase db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final FocusRepository repo = FocusRepository(db);
      expect(await repo.getIntention(), isNull);
      await repo.saveIntention(taskIntention);
      expect(await repo.getIntention(), taskIntention);
      await repo.saveIntention(null);
      expect(await repo.getIntention(), isNull);
    });

    test('logSession and todayByTarget aggregate by intention label', () async {
      final AppDatabase db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final FocusRepository repo = FocusRepository(db);
      final DateTime dayStart = DateTime(2026, 11, 24);

      await repo.logSession(
        startedAt: DateTime(2026, 11, 23, 22),
        endedAt: DateTime(2026, 11, 23, 22, 25),
        focusMs: 1500000,
        rounds: 1,
        endedEarly: false,
        intention: const FocusIntention(
          type: FocusTargetType.event,
          id: 1,
          label: 'Yesterday',
        ),
      );
      await repo.logSession(
        startedAt: DateTime(2026, 11, 24, 9),
        endedAt: DateTime(2026, 11, 24, 9, 25),
        focusMs: 1500000,
        rounds: 1,
        endedEarly: false,
        intention: const FocusIntention(
          type: FocusTargetType.event,
          id: 2,
          label: 'Bio 101',
        ),
      );
      await repo.logSession(
        startedAt: DateTime(2026, 11, 24, 10),
        endedAt: DateTime(2026, 11, 24, 10, 20),
        focusMs: 1200000,
        rounds: 1,
        endedEarly: true,
        intention: const FocusIntention(
          type: FocusTargetType.event,
          id: 2,
          label: 'Bio 101',
        ),
      );
      await repo.logSession(
        startedAt: DateTime(2026, 11, 24, 11),
        endedAt: DateTime(2026, 11, 24, 11, 15),
        focusMs: 900000,
        rounds: 1,
        endedEarly: false,
        intention: const FocusIntention(
          type: FocusTargetType.recall,
          label: 'Recall deck (2 due)',
        ),
      );

      final List<({String label, int focusMs})> byTarget = await repo
          .todayByTarget(dayStart);
      expect(byTarget, <({String label, int focusMs})>[
        (label: 'Bio 101', focusMs: 2700000),
        (label: 'Recall deck (2 due)', focusMs: 900000),
      ]);
    });
  });

  group('FocusController intentions & adaptive micro-sprints', () {
    test('start(overrideSettings:) leaves saved FocusSettings intact', () async {
      final AppDatabase db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final _FakeFocusPlatform platform = _FakeFocusPlatform();
      final ProviderContainer c = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          focusPlatformProvider.overrideWithValue(platform),
        ],
      );
      addTearDown(c.dispose);

      await c.read(focusControllerProvider.future);
      final FocusController controller = c.read(
        focusControllerProvider.notifier,
      );
      DateTime now = DateTime(2026, 11, 24, 9);
      controller.clockNow = () => now;

      await controller.saveSettings(
        const FocusSettings(focusMinutes: 30, rounds: 3, shortBreakMinutes: 5),
      );
      await controller.setIntention(
        const FocusIntention(
          type: FocusTargetType.task,
          id: 1,
          label: 'Problem set',
        ),
      );

      await controller.start(
        overrideSettings: const FocusSettings(
          focusMinutes: 10,
          shortBreakMinutes: 0,
          longBreakMinutes: 0,
          rounds: 1,
        ),
      );

      final FocusState running = c.read(focusControllerProvider).requireValue;
      expect(running.settings.focusMinutes, 30);
      expect(running.settings.rounds, 3);
      expect(running.session, isNotNull);
      expect(running.session!.settings.focusMinutes, 10);
      expect(running.session!.totalRounds, 1);
      expect((await FocusRepository(db).getSettings()).focusMinutes, 30);

      now = now.add(const Duration(minutes: 10));
      await controller.tick();

      final FocusState done = c.read(focusControllerProvider).requireValue;
      expect(done.session, isNull);
      expect(done.intention, isNull);
      expect(done.completionPrompt, isNotNull);
      expect(done.completionPrompt!.intention.label, 'Problem set');
      expect(done.completionPrompt!.focusedMs, 600000);
      expect(done.todayTargets.single.label, 'Problem set');
      expect(done.todayTargets.single.focusMs, 600000);
    });

    test('showMicroSprint triggers on >20m, endedEarly, and rest < 5.5h', () async {
      // 1. Default 25m -> true
      final AppDatabase db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final _FakeFocusPlatform platform = _FakeFocusPlatform();
      final ProviderContainer c = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          focusPlatformProvider.overrideWithValue(platform),
        ],
      );
      addTearDown(c.dispose);
      final FocusController controller = c.read(
        focusControllerProvider.notifier,
      );
      DateTime now = DateTime(2026, 11, 24, 9);
      controller.clockNow = () => now;
      expect((await c.read(focusControllerProvider.future)).showMicroSprint, isTrue);

      // 2. <=20m, no early stop, no low rest -> false
      await controller.saveSettings(const FocusSettings(focusMinutes: 15));
      expect(c.read(focusControllerProvider).requireValue.showMicroSprint, isFalse);

      // 3. <=20m with endedEarly == true -> true
      await FocusRepository(db).logSession(
        startedAt: now.subtract(const Duration(minutes: 10)),
        endedAt: now.subtract(const Duration(minutes: 5)),
        focusMs: 300000,
        rounds: 0,
        endedEarly: true,
      );
      await controller.saveSettings(const FocusSettings(focusMinutes: 15));
      expect(c.read(focusControllerProvider).requireValue.showMicroSprint, isTrue);

      // 4. Fresh DB with <=20m and PhoneDay rest < 5.5h -> true
      final AppDatabase lowRestDb = AppDatabase(NativeDatabase.memory());
      addTearDown(lowRestDb.close);
      await FocusRepository(
        lowRestDb,
      ).saveSettings(const FocusSettings(focusMinutes: 15));
      await lowRestDb
          .into(lowRestDb.phoneDayRows)
          .insert(
            PhoneDayRowsCompanion.insert(
              date: '2026-11-24',
              screenOnMs: 3600000,
              unlocks: 12,
              restStart: Value(DateTime(2026, 11, 24, 1)),
              restEnd: Value(DateTime(2026, 11, 24, 5, 30)), // 4h 30m < 5.5h
            ),
          );
      final ProviderContainer c2 = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(lowRestDb),
          focusPlatformProvider.overrideWithValue(platform),
        ],
      );
      addTearDown(c2.dispose);
      c2.read(focusControllerProvider.notifier).clockNow = () => now;
      expect(
        (await c2.read(focusControllerProvider.future)).showMicroSprint,
        isTrue,
      );
    });
  });

  group('UI: picker, micro-sprint, completion closure, entry points & Ponpon', () {
    testWidgets(
      'FocusPanel picker, micro-sprint, running badge, today target, and Mark done closure',
      (WidgetTester tester) async {
        final AppDatabase db = AppDatabase(NativeDatabase.memory());
        addTearDown(db.close);
        final _FakeFocusPlatform platform = _FakeFocusPlatform();
        final DateTime now = DateTime.now();
        final String todayKey = formatTaskDateKey(now);

        await tester.runAsync(() async {
          await TaskRepository(db).createTask(
            TaskItem(
              id: 0,
              title: 'Finish essay',
              dueOn: todayKey,
              createdAt: now,
            ),
          );
          await CalendarRepository(db).createEvent(
            CalendarEvent(
              id: 0,
              title: 'Bio Midterm',
              startsAt: now.add(const Duration(days: 2)),
            ),
          );
          await NotesRepository(db).createNote(
            const Note(
              id: 0,
              title: 'Bio Notes',
              body: 'Q: ATP?\nA: Energy',
              tags: <String>[],
            ),
          );
        });

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              appDatabaseProvider.overrideWithValue(db),
              focusPlatformProvider.overrideWithValue(platform),
              ponponClockProvider.overrideWithValue(() => now),
            ],
            child: MaterialApp(
              theme: AppTheme.light,
              builder: (BuildContext context, Widget? child) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: const TextScaler.linear(1.3)),
                child: child!,
              ),
              home: const CalendarScreen(),
            ),
          ),
        );
        await settle(tester);

        final ProviderContainer container = ProviderScope.containerOf(
          tester.element(find.byType(CalendarScreen)),
        );
        final FocusController focusController = container.read(
          focusControllerProvider.notifier,
        );
        DateTime fakeNow = now;
        focusController.clockNow = () => fakeNow;

        await tester.tap(find.text('Focus'));
        await settle(tester);

        expect(find.text('Focus on: Anything (optional)'), findsOneWidget);
        expect(find.text('10m starter'), findsOneWidget);
        expect(find.text('15m sprint'), findsOneWidget);

        // Open intention picker -> shows Tasks, Upcoming Events, Recall Deck.
        await tester.tap(find.text('Focus on: Anything (optional)'));
        await settle(tester);

        expect(find.text('Tasks'), findsOneWidget);
        expect(find.text('Finish essay'), findsOneWidget);
        expect(find.text('Upcoming Events'), findsOneWidget);
        expect(find.text('Bio Midterm'), findsOneWidget);
        expect(find.text('Recall deck (1 due)'), findsOneWidget);

        await tester.tap(find.text('Finish essay'));
        await settle(tester);
        expect(find.text('Focus on: Finish essay'), findsOneWidget);

        // Tap 10m starter -> starts 10m session with running badge.
        await tester.tap(find.text('10m starter'));
        await settle(tester);
        expect(find.text('Working on: Finish essay'), findsOneWidget);
        expect(
          container.read(focusControllerProvider).requireValue.settings.focusMinutes,
          25,
        );

        // Advance 2 minutes and stop -> completion banner offers Mark done.
        fakeNow = fakeNow.add(const Duration(minutes: 2));
        await tester.scrollUntilVisible(
          find.text('Stop session'),
          200,
          scrollable: find.byType(Scrollable).last,
        );
        await tester.tap(find.text('Stop session'));
        await settle(tester);

        expect(find.text('Logged 2m on Finish essay'), findsOneWidget);
        expect(find.text('2m on Finish essay'), findsOneWidget);
        expect(find.text('Mark done'), findsOneWidget);

        await tester.tap(find.text('Mark done'));
        await settle(tester);

        expect(find.text('Logged 2m on Finish essay'), findsNothing);
        final List<TaskItem> savedTasks =
            await tester.runAsync(() => TaskRepository(db).getTasks()) ??
            <TaskItem>[];
        expect(savedTasks.single.done, isTrue);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('Tasks and Recall Focus buttons arm intention and navigate to Focus', (
      WidgetTester tester,
    ) async {
      final AppDatabase db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final _FakeFocusPlatform platform = _FakeFocusPlatform();
      final DateTime now = DateTime(2026, 11, 24, 9);

      await tester.runAsync(() async {
        await TaskRepository(db).createTask(
          TaskItem(
            id: 0,
            title: 'Solve calculus',
            dueOn: '2026-11-24',
            createdAt: now,
          ),
        );
        await NotesRepository(db).createNote(
          const Note(
            id: 0,
            title: 'Chem',
            body: 'Q: Au?\nA: Gold',
            tags: <String>[],
          ),
        );
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWithValue(db),
            focusPlatformProvider.overrideWithValue(platform),
            ponponClockProvider.overrideWithValue(() => now),
          ],
          child: const StudentOSApp(),
        ),
      );
      await settle(tester);

      final ProviderContainer container = ProviderScope.containerOf(
        tester.element(find.byType(NavigationBar)),
      );

      // Task -> Focus
      container.read(routerProvider).go('/notes?view=tasks');
      await settle(tester);
      await tester.tap(find.byTooltip('Focus on task'));
      await settle(tester);

      expect(container.read(calendarViewProvider), CalendarView.focus);
      expect(find.text('Focus on: Solve calculus'), findsOneWidget);

      // Recall -> Focus
      container.read(routerProvider).go('/notes?view=recall');
      await settle(tester);
      await tester.tap(find.text('Focus'));
      await settle(tester);

      expect(container.read(calendarViewProvider), CalendarView.focus);
      expect(find.text('Focus on: Recall deck (1 due)'), findsOneWidget);
    });

    testWidgets('Ponpon startFocus forwards focusTarget to FocusController', (
      WidgetTester tester,
    ) async {
      final AppDatabase db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final _FakeFocusPlatform platform = _FakeFocusPlatform();
      final DateTime now = DateTime(2026, 11, 24, 9);
      final List<PonponInsight> tips = calendarInsights(
        events: <CalendarEvent>[
          CalendarEvent(
            id: 55,
            title: 'Organic Chem Exam',
            startsAt: DateTime(2026, 11, 26, 10),
          ),
        ],
        now: now,
      );
      final PonponInsight examTip = tips.firstWhere(
        (PonponInsight i) => i.action == PonponAction.startFocus,
      );
      expect(
        examTip.focusTarget,
        const FocusIntention(
          type: FocusTargetType.event,
          id: 55,
          label: 'Organic Chem Exam',
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWithValue(db),
            focusPlatformProvider.overrideWithValue(platform),
            calendarInsightsProvider.overrideWithValue(<PonponInsight>[examTip]),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            home: const Scaffold(
              body: Column(
                children: <Widget>[
                  PonponTalkSlot(surface: PonponSurface.calendar),
                  Expanded(child: FocusPanel()),
                ],
              ),
            ),
          ),
        ),
      );
      await settle(tester);

      await tester.tap(find.text('Focus'));
      await settle(tester);

      final ProviderContainer container = ProviderScope.containerOf(
        tester.element(find.byType(PonponTalk)),
      );
      expect(container.read(calendarViewProvider), CalendarView.focus);
      expect(
        container.read(focusControllerProvider).requireValue.intention,
        const FocusIntention(
          type: FocusTargetType.event,
          id: 55,
          label: 'Organic Chem Exam',
        ),
      );
      expect(find.text('Focus on: Organic Chem Exam'), findsOneWidget);
    });
  });
}
