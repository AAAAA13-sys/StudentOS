import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:studentos/core/db/app_database.dart';
import 'package:studentos/core/router/app_router.dart';
import 'package:studentos/core/theme/app_theme.dart';
import 'package:studentos/core/widgets/scaffold_with_nav_bar.dart';
import 'package:studentos/features/finance/iou_item.dart';
import 'package:studentos/features/finance/savings_goal.dart';
import 'package:studentos/features/finance/transaction.dart';
import 'package:studentos/features/focus/focus_plan.dart';
import 'package:studentos/features/focus/focus_repository.dart';
import 'package:studentos/features/insights/finance_insights.dart';
import 'package:studentos/features/insights/month_review.dart';
import 'package:studentos/features/insights/month_review_screen.dart';
import 'package:studentos/features/insights/ponpon_insight.dart';
import 'package:studentos/features/notes/recall_item.dart';
import 'package:studentos/features/phone/phone_day.dart';
import 'package:studentos/features/phone/phone_repository.dart';
import 'package:studentos/features/phone/phone_usage.dart';
import 'package:studentos/features/tasks/task_item.dart';
import 'package:studentos/features/work/shift.dart';
import 'package:studentos/main.dart';

class _FakePhoneUsage implements PhoneUsageSource {
  _FakePhoneUsage({this.access = false});

  bool access;
  bool throwOnAccess = false;
  List<(DateTime, DateTime)> spans = const <(DateTime, DateTime)>[];
  int hasAccessCalls = 0;
  int queryCalls = 0;

  @override
  Future<bool> hasAccess() async {
    hasAccessCalls++;
    if (throwOnAccess) {
      throw PlatformException(code: 'unavailable', message: 'No plugin');
    }
    return access;
  }

  @override
  Future<bool> openAccessSettings() async => true;

  @override
  Future<UsageRange?> query(DateTime start, DateTime end) async {
    if (!access) return null;
    queryCalls++;
    final List<(DateTime, DateTime)> inside = <(DateTime, DateTime)>[
      for (final (DateTime s, DateTime e) in spans)
        if (e.isAfter(start) && s.isBefore(end)) (s, e),
    ];
    return UsageRange(
      apps: const <AppUsage>[],
      screenOn: inside,
      unlocks: const <DateTime>[],
      eventCount: inside.length * 2,
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> settle(WidgetTester tester) async {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pumpAndSettle();
  }

  group('buildMonthReview', () {
    test('aggregates money, work, focus, tasks, recall, and phone with centavo precision', () {
      final MonthReview review = buildMonthReview(
        month: '2026-11',
        transactions: <Transaction>[
          Transaction(
            id: 1,
            type: 'income',
            amount: 5000.00,
            category: 'Allowance',
            occurredOn: DateTime(2026, 11, 1),
          ),
          Transaction(
            id: 2,
            type: 'expense',
            amount: 19.99,
            category: 'Food',
            occurredOn: DateTime(2026, 11, 2),
          ),
          Transaction(
            id: 3,
            type: 'expense',
            amount: 0.01,
            category: 'Food',
            occurredOn: DateTime(2026, 11, 3),
          ),
          Transaction(
            id: 4,
            type: 'expense',
            amount: 150.00,
            category: 'Transport',
            occurredOn: DateTime(2026, 11, 4),
          ),
          // Outside month: ignored.
          Transaction(
            id: 5,
            type: 'expense',
            amount: 999.00,
            category: 'Other',
            occurredOn: DateTime(2026, 10, 31),
          ),
        ],
        goals: <SavingsGoal>[
          SavingsGoal(
            id: 1,
            title: 'Laptop',
            targetCents: 100000,
            savedCents: 60000,
            createdAt: DateTime(2026, 11, 1),
          ),
          SavingsGoal(
            id: 2,
            title: 'Books',
            targetCents: 20000,
            savedCents: 20000,
            createdAt: DateTime(2026, 11, 1),
          ),
        ],
        ious: <IouItem>[
          IouItem(
            id: 1,
            person: 'Sam',
            direction: IouDirection.owed,
            amountCents: 12000,
            occurredOn: '2026-11-05',
            createdAt: DateTime(2026, 11, 5),
          ),
          IouItem(
            id: 2,
            person: 'Alex',
            direction: IouDirection.owing,
            amountCents: 5000,
            occurredOn: '2026-11-06',
            createdAt: DateTime(2026, 11, 6),
          ),
          IouItem(
            id: 3,
            person: 'Kai',
            direction: IouDirection.owed,
            amountCents: 8000,
            occurredOn: '2026-11-02',
            settled: true,
            settledAt: DateTime(2026, 11, 10),
            createdAt: DateTime(2026, 11, 2),
          ),
          // Settled in October: not counted in November settled.
          IouItem(
            id: 4,
            person: 'Jo',
            direction: IouDirection.owing,
            amountCents: 3000,
            occurredOn: '2026-10-01',
            settled: true,
            settledAt: DateTime(2026, 10, 20),
            createdAt: DateTime(2026, 10, 1),
          ),
        ],
        shifts: <Shift>[
          Shift(
            id: 1,
            job: 'Cafe',
            startsAt: DateTime(2026, 11, 5, 9),
            durationMinutes: 270,
            breakMinutes: 30,
            hourlyRateCents: 10000,
            paid: true,
          ),
          Shift(
            id: 2,
            job: 'Tutor',
            startsAt: DateTime(2026, 11, 12, 14),
            durationMinutes: 120,
            hourlyRateCents: 15000,
            paid: false,
          ),
          // Outside month: ignored.
          Shift(
            id: 3,
            job: 'Old',
            startsAt: DateTime(2026, 10, 29, 9),
            durationMinutes: 120,
            hourlyRateCents: 10000,
            paid: true,
          ),
        ],
        focusLogs: <FocusLog>[
          FocusLog(
            id: 1,
            startedAt: DateTime(2026, 11, 8, 9),
            endedAt: DateTime(2026, 11, 8, 9, 50),
            focusMs: 3000000,
            rounds: 2,
            endedEarly: false,
            intention: const FocusIntention(
              type: FocusTargetType.task,
              id: 1,
              label: 'Physics Lab',
            ),
          ),
          FocusLog(
            id: 2,
            startedAt: DateTime(2026, 11, 9, 10),
            endedAt: DateTime(2026, 11, 9, 10, 15),
            focusMs: 900000,
            rounds: 0,
            endedEarly: true,
            intention: const FocusIntention(
              type: FocusTargetType.recall,
              label: 'Bio Deck',
            ),
          ),
        ],
        tasks: <TaskItem>[
          TaskItem(
            id: 1,
            title: 'Submit lab',
            done: true,
            doneAt: DateTime(2026, 11, 15, 18),
            createdAt: DateTime(2026, 11, 1),
          ),
          TaskItem(
            id: 2,
            title: 'Still open',
            done: false,
            createdAt: DateTime(2026, 11, 1),
          ),
          TaskItem(
            id: 3,
            title: 'Done in Oct',
            done: true,
            doneAt: DateTime(2026, 10, 28, 12),
            createdAt: DateTime(2026, 10, 20),
          ),
        ],
        recallReviews: <RecallReview>[
          RecallReview(
            noteId: 1,
            cardKey: 'a',
            box: 3,
            nextReviewOn: '2026-11-25',
            lastReviewedAt: DateTime(2026, 11, 18, 9),
            timesReviewed: 2,
          ),
          RecallReview(
            noteId: 1,
            cardKey: 'b',
            box: 2,
            nextReviewOn: '2026-11-20',
            lastReviewedAt: DateTime(2026, 10, 30, 9),
            timesReviewed: 1,
          ),
        ],
        phoneDays: <PhoneDay>[
          PhoneDay(
            date: DateTime(2026, 11, 1),
            screenOnMs: 7200000, // 2h
            unlocks: 20,
            restStart: DateTime(2026, 10, 31, 23),
            restEnd: DateTime(2026, 11, 1, 7), // 8h
          ),
          PhoneDay(
            date: DateTime(2026, 11, 2),
            screenOnMs: 14400000, // 4h
            unlocks: 30,
            restStart: DateTime(2026, 11, 2, 1),
            restEnd: DateTime(2026, 11, 2, 7), // 6h
          ),
        ],
        hasPhoneAccess: true,
      );

      expect(review.incomeCents, 500000);
      expect(review.expenseCents, 17000);
      expect(review.netCents, 483000);
      expect(review.transactionCount, 4);
      expect(review.topExpenseCategories.first.category, 'Transport');
      expect(review.topExpenseCategories.first.cents, 15000);
      expect(review.topExpenseCategories[1].category, 'Food');
      expect(review.topExpenseCategories[1].cents, 2000);
      expect(review.topExpenseCategories[1].count, 2);

      expect(review.goalsSavedCents, 80000);
      expect(review.goalsCount, 2);
      expect(review.goalsReachedCount, 1);

      expect(review.openIousCount, 2);
      expect(review.openOwedCents, 12000);
      expect(review.openOwingCents, 5000);
      expect(review.settledInMonthCount, 1);
      expect(review.settledInMonthCents, 8000);

      expect(review.shiftCount, 2);
      expect(review.paidShiftCount, 1);
      expect(review.paidShiftMinutes, 240);
      expect(review.paidShiftPayCents, 40000);
      expect(review.unpaidShiftCount, 1);
      expect(review.unpaidShiftMinutes, 120);
      expect(review.unpaidShiftPayCents, 30000);

      expect(review.focusMs, 3900000);
      expect(review.focusSessions, 2);
      expect(review.completedFocusSessions, 1);
      expect(review.focusRounds, 2);
      expect(review.topStudyTargets.first.label, 'Physics Lab');
      expect(review.topStudyTargets.first.focusMs, 3000000);
      expect(review.topStudyTargets[1].label, 'Bio Deck');

      expect(review.tasksCompletedCount, 1);
      expect(review.recallReviewedCount, 1);

      expect(review.hasPhoneAccess, isTrue);
      expect(review.daysWithPhone, 2);
      expect(review.avgScreenOnMs, 10800000); // 3h
      expect(review.avgRestDuration, const Duration(hours: 7));
    });
  });

  group('Repository range queries', () {
    test('FocusRepository.getLogsInRange filters [start, end) descending', () async {
      final AppDatabase db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final FocusRepository repo = FocusRepository(db);

      await repo.logSession(
        startedAt: DateTime(2026, 10, 31, 23),
        endedAt: DateTime(2026, 10, 31, 23, 59),
        focusMs: 1500000,
        rounds: 1,
        endedEarly: false,
      );
      await repo.logSession(
        startedAt: DateTime(2026, 11, 1, 0),
        endedAt: DateTime(2026, 11, 1, 0, 25),
        focusMs: 1500000,
        rounds: 1,
        endedEarly: false,
        intention: const FocusIntention(
          type: FocusTargetType.task,
          label: 'Early Nov',
        ),
      );
      await repo.logSession(
        startedAt: DateTime(2026, 11, 30, 23),
        endedAt: DateTime(2026, 11, 30, 23, 30),
        focusMs: 1800000,
        rounds: 1,
        endedEarly: false,
        intention: const FocusIntention(
          type: FocusTargetType.event,
          label: 'Late Nov',
        ),
      );
      await repo.logSession(
        startedAt: DateTime(2026, 12, 1, 0),
        endedAt: DateTime(2026, 12, 1, 0, 25),
        focusMs: 1500000,
        rounds: 1,
        endedEarly: false,
      );

      final List<FocusLog> nov = await repo.getLogsInRange(
        DateTime(2026, 11, 1),
        DateTime(2026, 12, 1),
      );
      expect(nov, hasLength(2));
      expect(nov.first.intention?.label, 'Late Nov');
      expect(nov.last.intention?.label, 'Early Nov');
    });

    test('PhoneRepository.getDaysInMonth returns matching month ascending', () async {
      final AppDatabase db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      await db.batch((batch) {
        batch.insertAll(db.phoneDayRows, <PhoneDayRowsCompanion>[
          PhoneDayRowsCompanion.insert(
            date: '2026-10-31',
            screenOnMs: 1000,
            unlocks: 1,
          ),
          PhoneDayRowsCompanion.insert(
            date: '2026-11-15',
            screenOnMs: 2000,
            unlocks: 2,
          ),
          PhoneDayRowsCompanion.insert(
            date: '2026-11-03',
            screenOnMs: 3000,
            unlocks: 3,
          ),
          PhoneDayRowsCompanion.insert(
            date: '2026-12-01',
            screenOnMs: 4000,
            unlocks: 4,
          ),
        ]);
      });

      final PhoneRepository repo = PhoneRepository(db, _FakePhoneUsage());
      final List<PhoneDay> nov = await repo.getDaysInMonth('2026-11');
      expect(nov.map((PhoneDay d) => d.date), <DateTime>[
        DateTime(2026, 11, 3),
        DateTime(2026, 11, 15),
      ]);
    });
  });

  group('financeInsights end-of-month review tip', () {
    test('emits seeMonthReview at priority 4 only in last 3 days when non-empty', () {
      final Transaction sample = Transaction(
        id: 1,
        type: 'expense',
        amount: 100,
        category: 'Food',
        occurredOn: DateTime(2026, 11, 20),
      );

      // Nov 27 (4th from end) -> not emitted.
      expect(
        financeInsights(
          thisMonth: <Transaction>[sample],
          lastMonth: const <Transaction>[],
          now: DateTime(2026, 11, 27, 12),
        ).any((PonponInsight i) => i.action == PonponAction.seeMonthReview),
        isFalse,
      );

      // Nov 28 (last 3 days) with empty month -> not emitted.
      expect(
        financeInsights(
          thisMonth: const <Transaction>[],
          lastMonth: const <Transaction>[],
          now: DateTime(2026, 11, 28, 12),
        ).any((PonponInsight i) => i.action == PonponAction.seeMonthReview),
        isFalse,
      );

      // Nov 28 with transactions -> emitted with priority 4.
      final List<PonponInsight> nov28 = financeInsights(
        thisMonth: <Transaction>[sample],
        lastMonth: const <Transaction>[],
        now: DateTime(2026, 11, 28, 12),
      );
      final PonponInsight tip = nov28.firstWhere(
        (PonponInsight i) => i.action == PonponAction.seeMonthReview,
      );
      expect(tip.priority, 4);
      expect(tip.action?.label, 'Month in review');
    });
  });

  group('MonthReviewScreen & /review route', () {
    testWidgets('shows Screen time access off when ungranted and no days stored', (
      WidgetTester tester,
    ) async {
      final AppDatabase db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWithValue(db),
            phoneUsageSourceProvider.overrideWithValue(
              _FakePhoneUsage(access: false),
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            home: const MonthReviewScreen(initialMonth: '2026-11'),
          ),
        ),
      );
      await settle(tester);

      expect(find.text('Month in Review'), findsOneWidget);
      expect(find.text('Money'), findsOneWidget);
      expect(find.text('Work & Study'), findsOneWidget);
      expect(find.text('Phone Rest & Screen Time'), findsOneWidget);
      expect(find.text('Screen time access off'), findsOneWidget);
      expect(find.text('0h'), findsNothing);
      expect(find.text('Export summary (.md)'), findsOneWidget);
    });

    testWidgets('shows No screen time recorded when granted but no days stored', (
      WidgetTester tester,
    ) async {
      final AppDatabase db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWithValue(db),
            phoneUsageSourceProvider.overrideWithValue(
              _FakePhoneUsage(access: true),
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.dark,
            home: const MonthReviewScreen(initialMonth: '2026-11'),
          ),
        ),
      );
      await settle(tester);

      expect(find.text('No screen time recorded'), findsOneWidget);
      expect(find.text('0h'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('pushing /review preserves 3 bottom tabs', (
      WidgetTester tester,
    ) async {
      final AppDatabase db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWithValue(db),
            phoneUsageSourceProvider.overrideWithValue(
              _FakePhoneUsage(access: false),
            ),
          ],
          child: const StudentOSApp(),
        ),
      );
      await settle(tester);

      expect(find.byType(NavigationDestination), findsNWidgets(3));
      final ProviderContainer container = ProviderScope.containerOf(
        tester.element(find.byType(NavigationBar)),
      );

      container.read(routerProvider).push('/review');
      await settle(tester);

      expect(find.text('Month in Review'), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);

      container.read(routerProvider).pop();
      await settle(tester);

      expect(find.byType(NavigationDestination), findsNWidgets(3));
    });
  });

  group('Silent phone sync on resume', () {
    testWidgets('performs zero DB writes when access is off and syncs silently when on', (
      WidgetTester tester,
    ) async {
      final AppDatabase db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final _FakePhoneUsage usage = _FakePhoneUsage(access: false);
      final GoRouter testRouter = GoRouter(
        initialLocation: '/calendar',
        routes: <RouteBase>[
          StatefulShellRoute.indexedStack(
            builder: (_, _, StatefulNavigationShell shell) =>
                ScaffoldWithNavBar(navigationShell: shell),
            branches: <StatefulShellBranch>[
              StatefulShellBranch(
                routes: <RouteBase>[
                  GoRoute(
                    path: '/calendar',
                    builder: (_, _) => const SizedBox.shrink(),
                  ),
                ],
              ),
              StatefulShellBranch(
                routes: <RouteBase>[
                  GoRoute(
                    path: '/finance',
                    builder: (_, _) => const SizedBox.shrink(),
                  ),
                ],
              ),
              StatefulShellBranch(
                routes: <RouteBase>[
                  GoRoute(
                    path: '/notes',
                    builder: (_, _) => const SizedBox.shrink(),
                  ),
                ],
              ),
            ],
          ),
        ],
      );
      addTearDown(testRouter.dispose);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWithValue(db),
            phoneUsageSourceProvider.overrideWithValue(usage),
          ],
          child: MaterialApp.router(
            theme: AppTheme.light,
            routerConfig: testRouter,
          ),
        ),
      );
      await settle(tester);

      // Simulate app resume without access -> zero DB writes.
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await settle(tester);
      expect(usage.hasAccessCalls, greaterThanOrEqualTo(1));
      expect(usage.queryCalls, 0);
      expect(await db.select(db.phoneDayRows).get(), isEmpty);

      // Simulate PlatformException on hasAccess -> silently ignored.
      usage.throwOnAccess = true;
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await settle(tester);
      expect(tester.takeException(), isNull);
      expect(await db.select(db.phoneDayRows).get(), isEmpty);

      // Grant access and resume -> syncs phone_days, and 1h cooldown blocks immediate re-sync.
      final DateTime now = DateTime.now();
      final DateTime today = DateTime(now.year, now.month, now.day);
      usage
        ..throwOnAccess = false
        ..access = true
        ..spans = <(DateTime, DateTime)>[
          (
            today.add(const Duration(minutes: 1)),
            today.add(const Duration(minutes: 31)),
          ),
        ];

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await settle(tester);
      final String monthKey = DateFormat('yyyy-MM').format(today);
      final List<PhoneDay> stored = await PhoneRepository(
        db,
        usage,
      ).getDaysInMonth(monthKey);
      expect(stored, isNotEmpty);

      final int queriesAfterFirstSync = usage.queryCalls;
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await settle(tester);
      expect(usage.queryCalls, queriesAfterFirstSync);
    });
  });
}
