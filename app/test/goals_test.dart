import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studentos/core/db/app_database.dart';
import 'package:studentos/core/router/app_router.dart';
import 'package:studentos/core/theme/app_theme.dart';
import 'package:studentos/core/widgets/app_drawer.dart';
import 'package:studentos/core/widgets/ponpon.dart';
import 'package:studentos/core/widgets/ponpon_talk.dart';
import 'package:studentos/features/finance/finance_controller.dart';
import 'package:studentos/features/finance/finance_repository.dart';
import 'package:studentos/features/finance/finance_screen.dart';
import 'package:studentos/features/finance/goals_controller.dart';
import 'package:studentos/features/finance/goals_repository.dart';
import 'package:studentos/features/finance/savings_goal.dart';
import 'package:studentos/features/finance/transaction.dart';
import 'package:studentos/features/insights/insights_providers.dart';
import 'package:studentos/features/insights/ponpon_insight.dart';
import 'package:studentos/features/work/shift.dart';
import 'package:studentos/features/work/work_repository.dart';
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

  group('Drift v10 -> v11 migration', () {
    test('upgrades a v10 schema database and creates the goals table', () async {
      final AppDatabase db = AppDatabase(
        NativeDatabase.memory(
          setup: (rawDb) {
            rawDb.execute('PRAGMA user_version = 10;');
            rawDb.execute(
              'CREATE TABLE transactions ('
              'id INTEGER PRIMARY KEY AUTOINCREMENT, '
              'type TEXT NOT NULL, '
              'amount_cents INTEGER NOT NULL, '
              'category TEXT NOT NULL, '
              'occurred_on TEXT NOT NULL, '
              'note TEXT);',
            );
          },
        ),
      );
      addTearDown(db.close);

      expect(db.schemaVersion, greaterThanOrEqualTo(11));
      final GoalsRepository repo = GoalsRepository(db);
      final int id = await repo.createGoal(
        SavingsGoal(
          id: 0,
          title: 'Tuition',
          targetCents: 1000000,
          savedCents: 250000,
          targetDate: '2026-12-15',
          createdAt: DateTime(2026, 11, 24),
        ),
      );
      final SavingsGoal? loaded = await repo.getGoal(id);
      expect(loaded, isNotNull);
      expect(loaded!.title, 'Tuition');
      expect(loaded.targetCents, 1000000);
      expect(loaded.savedCents, 250000);
      expect(loaded.targetDate, '2026-12-15');
    });
  });

  group('SavingsGoal math', () {
    test('computes amounts, remaining, progress, percentLabel, isReached, daysLeft', () {
      final SavingsGoal active = SavingsGoal(
        id: 1,
        title: 'Laptop',
        targetCents: 200000,
        savedCents: 150000,
        targetDate: '2026-11-30',
        createdAt: DateTime(2026, 11, 1),
      );
      expect(active.targetAmount, 2000.0);
      expect(active.savedAmount, 1500.0);
      expect(active.remainingCents, 50000);
      expect(active.isReached, isFalse);
      expect(active.progress, closeTo(0.75, 0.0001));
      expect(active.percentLabel, '75%');
      expect(active.targetDateTime, DateTime(2026, 11, 30));
      expect(active.daysLeft(DateTime(2026, 11, 24, 22, 15)), 6);

      final SavingsGoal overfunded = SavingsGoal(
        id: 2,
        title: 'Emergency',
        targetCents: 50000,
        savedCents: 60000,
        createdAt: DateTime(2026, 11, 1),
      );
      expect(overfunded.remainingCents, 0);
      expect(overfunded.isReached, isTrue);
      expect(overfunded.progress, 1.0);
      expect(overfunded.percentLabel, '100%');
      expect(overfunded.daysLeft(DateTime(2026, 11, 24)), isNull);

      final SavingsGoal zeroTarget = SavingsGoal(
        id: 3,
        title: 'Zero',
        targetCents: 0,
        savedCents: 0,
        createdAt: DateTime(2026, 11, 1),
      );
      expect(zeroTarget.isReached, isFalse);
      expect(zeroTarget.progress, 0.0);
    });
  });

  group('GoalsRepository CRUD & isolation', () {
    test('orders unreached earliest targetDate first, clamps adjustSaved >= 0, and stays isolated from Transactions', () async {
      final AppDatabase db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final GoalsRepository goalsRepo = GoalsRepository(db);
      final FinanceRepository financeRepo = FinanceRepository(db);

      await financeRepo.createTransaction(
        Transaction(
          id: 0,
          type: 'income',
          amount: 5000,
          category: 'Allowance',
          occurredOn: DateTime(2026, 11, 24),
        ),
      );

      final int idReached = await goalsRepo.createGoal(
        SavingsGoal(
          id: 0,
          title: 'Reached early',
          targetCents: 10000,
          savedCents: 10000,
          targetDate: '2026-11-25',
          createdAt: DateTime(2026, 11, 20),
        ),
      );
      final int idNoDate = await goalsRepo.createGoal(
        SavingsGoal(
          id: 0,
          title: 'Open no date',
          targetCents: 50000,
          savedCents: 5000,
          createdAt: DateTime(2026, 11, 21),
        ),
      );
      final int idDueSoon = await goalsRepo.createGoal(
        SavingsGoal(
          id: 0,
          title: 'Open due soon',
          targetCents: 80000,
          savedCents: 10000,
          targetDate: '2026-11-28',
          createdAt: DateTime(2026, 11, 22),
        ),
      );

      final List<SavingsGoal> ordered = await goalsRepo.getGoals();
      expect(
        ordered.map((SavingsGoal g) => g.id).toList(),
        <int>[idDueSoon, idNoDate, idReached],
      );

      // Deposit & withdraw clamp >= 0.
      await goalsRepo.adjustSaved(idNoDate, 15000);
      expect((await goalsRepo.getGoal(idNoDate))!.savedCents, 20000);
      await goalsRepo.adjustSaved(idNoDate, -999999);
      expect((await goalsRepo.getGoal(idNoDate))!.savedCents, 0);

      // No-op when goal missing.
      await goalsRepo.adjustSaved(9999, 5000);

      // Update & delete.
      final SavingsGoal updated = (await goalsRepo.getGoal(idDueSoon))!
          .copyWith(title: 'Updated due soon');
      await goalsRepo.updateGoal(updated);
      expect((await goalsRepo.getGoal(idDueSoon))!.title, 'Updated due soon');
      await goalsRepo.deleteGoal(idReached);
      expect(await goalsRepo.getGoal(idReached), isNull);

      // Transactions & monthly summary are untouched by any goal operations.
      final List<Transaction> txs = await financeRepo.getTransactions();
      expect(txs, hasLength(1));
      final FinanceSummary summary = await financeRepo.getSummary(
        month: '2026-11',
      );
      expect(summary.totalIncome, 5000.0);
      expect(summary.totalExpenses, 0.0);
      expect(summary.balance, 5000.0);
    });
  });

  group('Finance | Goals UI, routing, Back pop & Work payout stash', () {
    testWidgets('Cashflow | Goals switch, /goals route, 3 bottom tabs, and Back returns to Cashflow', (
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

      // Strictly 3 bottom NavigationDestinations.
      final NavigationBar navBar = tester.widget<NavigationBar>(
        find.byType(NavigationBar),
      );
      expect(navBar.destinations, hasLength(3));

      final ProviderContainer container = ProviderScope.containerOf(
        tester.element(find.byType(NavigationBar)),
      );

      // Navigate via /goals redirect -> opens Finance > Goals.
      container.read(routerProvider).go('/goals');
      await settle(tester);

      expect(container.read(financeViewProvider), FinanceView.goals);
      expect(find.byType(SegmentedButton<FinanceView>), findsOneWidget);
      expect(find.byTooltip('New goal'), findsOneWidget);
      // Empty state shows only the 88dp Ponpon and suppresses PonponTalk.
      expect(find.byType(Ponpon), findsOneWidget);
      expect(find.byType(PonponTalk), findsNothing);
      expect(find.text('No savings goals yet'), findsOneWidget);

      // Pressing system Back on Finance > Goals returns to Finance > Cashflow.
      final NavigatorState nav = tester.state(find.byType(Navigator).first);
      await nav.maybePop();
      await settle(tester);
      expect(container.read(financeViewProvider), FinanceView.cashflow);
      expect(find.byTooltip('Quick expense'), findsOneWidget);

      // Switch back to Goals via SegmentedButton.
      await tester.tap(find.text('Goals'));
      await settle(tester);
      expect(container.read(financeViewProvider), FinanceView.goals);
    });

    testWidgets('GoalsPanel CRUD via showGoalEditor and + Add / - Take updates UI without affecting Cashflow', (
      WidgetTester tester,
    ) async {
      final AppDatabase db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [appDatabaseProvider.overrideWithValue(db)],
          child: MaterialApp(
            theme: AppTheme.light,
            home: const FinanceScreen(),
          ),
        ),
      );
      await settle(tester);

      // Switch to Goals.
      await tester.tap(find.text('Goals'));
      await settle(tester);

      // Create goal via FAB -> showGoalEditor.
      await tester.tap(find.byTooltip('New goal'));
      await settle(tester);
      expect(find.text('New goal'), findsOneWidget);

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Title'),
        'New Laptop',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Target amount (₱)'),
        '1000',
      );
      await tester.tap(find.text('Save goal'));
      await settle(tester);

      expect(find.text('New Laptop'), findsOneWidget);
      expect(find.text('0%'), findsOneWidget);

      // - Take is disabled at ₱0 saved.
      final OutlinedButton takeDisabled = tester.widget<OutlinedButton>(
        find.widgetWithText(OutlinedButton, '- Take'),
      );
      expect(takeDisabled.onPressed, isNull);

      // + Add ₱500 -> updates to 50% and enables - Take.
      await tester.tap(find.text('+ Add'));
      await settle(tester);
      expect(find.text('Deposit to New Laptop'), findsOneWidget);
      await tester.tap(find.widgetWithText(ActionChip, '₱500'));
      await settle(tester);
      await tester.tap(find.widgetWithText(FilledButton, 'Add'));
      await settle(tester);

      expect(find.text('50%'), findsOneWidget);
      expect(find.text('₱500.00 / ₱1,000.00'), findsOneWidget);

      // - Take prevents withdrawing more than saved balance.
      await tester.tap(find.text('- Take'));
      await settle(tester);
      expect(find.text('Withdraw from New Laptop'), findsOneWidget);
      await tester.enterText(
        find.widgetWithText(TextField, 'Amount (₱)'),
        '900',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Take'));
      await settle(tester);
      expect(find.text('Exceeds saved balance'), findsOneWidget);

      // Withdraw ₱100 -> updates to 40% (₱400).
      await tester.tap(find.widgetWithText(ActionChip, '₱100'));
      await settle(tester);
      await tester.tap(find.widgetWithText(FilledButton, 'Take'));
      await settle(tester);

      expect(find.text('40%'), findsOneWidget);
      expect(find.text('₱400.00 / ₱1,000.00'), findsOneWidget);

      // Cashflow balance remains ₱0.00 (goal adjustments do not create transactions).
      await tester.tap(find.text('Cashflow'));
      await settle(tester);
      expect(find.text('No transactions this month'), findsOneWidget);
      expect(find.text('₱0.00'), findsWidgets);
    });

    testWidgets('GotPaidDialog optional Stash part of pay credits selected goal', (
      WidgetTester tester,
    ) async {
      final AppDatabase db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);

      final DateTime now = DateTime.now();
      final DateTime workedStart = now.subtract(const Duration(hours: 3));

      await tester.runAsync(() async {
        await WorkRepository(db).createShifts(<Shift>[
          Shift(
            id: 0,
            job: 'Cafe',
            startsAt: workedStart,
            durationMinutes: 120,
            hourlyRateCents: 10000, // ₱200 total
          ),
        ]);
        await GoalsRepository(db).createGoal(
          SavingsGoal(
            id: 0,
            title: 'Camera Gear',
            targetCents: 100000,
            savedCents: 10000,
            createdAt: now,
          ),
        );
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [appDatabaseProvider.overrideWithValue(db)],
          child: MaterialApp(
            theme: AppTheme.light,
            home: const FinanceScreen(),
          ),
        ),
      );
      await settle(tester);

      expect(find.text('I got paid'), findsOneWidget);
      await tester.tap(find.text('I got paid'));
      await settle(tester);

      expect(find.text('Stash part of pay (optional)'), findsOneWidget);
      await tester.tap(find.byType(DropdownButtonFormField<int?>));
      await settle(tester);
      await tester.tap(find.text('Camera Gear').last);
      await settle(tester);

      await tester.enterText(
        find.widgetWithText(TextField, 'Stash amount'),
        '50',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await settle(tester);

      final ProviderContainer container = ProviderScope.containerOf(
        tester.element(find.byType(FinanceScreen)),
      );
      final FinanceState finance = container
          .read(financeControllerProvider)
          .requireValue;
      expect(finance.summary.totalIncome, 200.0);

      final SavingsGoal goal = container
          .read(goalsControllerProvider)
          .requireValue
          .single;
      expect(goal.savedCents, 15000);
      expect(find.textContaining('Stashed ₱50.00 to Camera Gear'), findsOneWidget);
    });

    testWidgets('Ponpon seeGoals tip navigates from Cashflow to Goals', (
      WidgetTester tester,
    ) async {
      final AppDatabase db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final DateTime now = DateTime.now();

      await tester.runAsync(() async {
        await GoalsRepository(db).createGoal(
          SavingsGoal(
            id: 0,
            title: 'Headphones',
            targetCents: 100000,
            savedCents: 90000,
            createdAt: now,
          ),
        );
        await FinanceRepository(db).createTransaction(
          Transaction(
            id: 0,
            type: 'income',
            amount: 500,
            category: 'Allowance',
            occurredOn: DateTime(now.year, now.month, now.day),
          ),
        );
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWithValue(db),
            financeInsightsProvider.overrideWithValue(
              const AsyncData<List<PonponInsight>>(<PonponInsight>[
                PonponInsight(
                  text: 'Almost there: Headphones is ₱100 away.',
                  priority: 2,
                  action: PonponAction.seeGoals,
                ),
              ]),
            ),
          ],
          child: const StudentOSApp(),
        ),
      );
      await settle(tester);

      final ProviderContainer container = ProviderScope.containerOf(
        tester.element(find.byType(NavigationBar)),
      );
      container.read(routerProvider).go('/finance');
      await settle(tester);

      expect(find.text('Almost there: Headphones is ₱100 away.'), findsOneWidget);
      await tester.tap(find.text('See goals'));
      await settle(tester);

      expect(container.read(financeViewProvider), FinanceView.goals);
      expect(find.text('Headphones'), findsOneWidget);
    });

    test('AppDrawer.formatRestoreSummary includes non-zero goals', () {
      expect(
        AppDrawer.formatRestoreSummary(
          events: 1,
          transactions: 2,
          notes: 3,
          goals: 2,
        ),
        'Restored 1 event, 2 transactions, 3 notes and 2 goals',
      );
      expect(
        AppDrawer.formatRestoreSummary(
          events: 1,
          transactions: 1,
          notes: 1,
          tasks: 1,
          goals: 1,
        ),
        'Restored 1 event, 1 transaction, 1 note, 1 task and 1 goal',
      );
    });
  });
}
