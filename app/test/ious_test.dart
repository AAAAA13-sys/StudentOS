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
import 'package:studentos/features/finance/iou_item.dart';
import 'package:studentos/features/finance/ious_controller.dart';
import 'package:studentos/features/finance/ious_repository.dart';
import 'package:studentos/features/finance/transaction.dart';
import 'package:studentos/features/insights/insights_providers.dart';
import 'package:studentos/features/insights/ponpon_insight.dart';
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

  group('Drift v11 -> v12 migration', () {
    test('upgrades a v11 schema database and creates the ious table', () async {
      final AppDatabase db = AppDatabase(
        NativeDatabase.memory(
          setup: (rawDb) {
            rawDb.execute('PRAGMA user_version = 11;');
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

      expect(db.schemaVersion, greaterThanOrEqualTo(12));
      final IousRepository repo = IousRepository(db);
      final int id = await repo.createIou(
        IouItem(
          id: 0,
          person: 'Sam',
          direction: IouDirection.owed,
          amountCents: 25000,
          note: 'Lunch',
          occurredOn: '2026-11-24',
          createdAt: DateTime(2026, 11, 24),
        ),
      );
      final IouItem? loaded = await repo.getIou(id);
      expect(loaded, isNotNull);
      expect(loaded!.person, 'Sam');
      expect(loaded.direction, IouDirection.owed);
      expect(loaded.amountCents, 25000);
      expect(loaded.note, 'Lunch');
      expect(loaded.occurredOn, '2026-11-24');
      expect(loaded.settled, isFalse);
      expect(loaded.settledAt, isNull);
    });
  });

  group('IouItem & splitShareCents math', () {
    test('computes amount, occurredOnDate, ageDays, and splitShareCents', () {
      final IouItem item = IouItem(
        id: 1,
        person: 'Alex',
        direction: IouDirection.owing,
        amountCents: 18550,
        occurredOn: '2026-11-20',
        createdAt: DateTime(2026, 11, 20, 14),
      );
      expect(item.amount, 185.5);
      expect(item.occurredOnDate, DateTime(2026, 11, 20));
      expect(item.ageDays(DateTime(2026, 11, 24, 22)), 4);

      expect(splitShareCents(10000, 1), 10000);
      expect(splitShareCents(10000, 0), 10000);
      expect(splitShareCents(10000, 2), 5000);
      expect(splitShareCents(10000, 3), 3333);
      expect(splitShareCents(50000, 4), 12500);
    });
  });

  group('IousRepository CRUD & Cashflow isolation', () {
    test('orders open newest occurredOn first, then settled, and keeps Transactions isolated', () async {
      final AppDatabase db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final IousRepository iousRepo = IousRepository(db);
      final FinanceRepository financeRepo = FinanceRepository(db);

      await financeRepo.createTransaction(
        Transaction(
          id: 0,
          type: 'income',
          amount: 2000,
          category: 'Allowance',
          occurredOn: DateTime(2026, 11, 24),
        ),
      );

      final int idSettled = await iousRepo.createIou(
        IouItem(
          id: 0,
          person: 'Settled early',
          direction: IouDirection.owed,
          amountCents: 15000,
          occurredOn: '2026-11-24',
          settled: true,
          settledAt: DateTime(2026, 11, 24, 9),
          createdAt: DateTime(2026, 11, 20),
        ),
      );
      final int idOlderOpen = await iousRepo.createIou(
        IouItem(
          id: 0,
          person: 'Older open',
          direction: IouDirection.owing,
          amountCents: 30000,
          occurredOn: '2026-11-19',
          createdAt: DateTime(2026, 11, 19),
        ),
      );
      final int idNewerOpen = await iousRepo.createIou(
        IouItem(
          id: 0,
          person: 'Newer open',
          direction: IouDirection.owed,
          amountCents: 45000,
          occurredOn: '2026-11-23',
          createdAt: DateTime(2026, 11, 23),
        ),
      );

      final List<IouItem> ordered = await iousRepo.getIous();
      expect(
        ordered.map((IouItem i) => i.id).toList(),
        <int>[idNewerOpen, idOlderOpen, idSettled],
      );

      final IouItem updated = (await iousRepo.getIou(idOlderOpen))!
          .copyWith(person: 'Updated person', amountCents: 35000);
      await iousRepo.updateIou(updated);
      expect((await iousRepo.getIou(idOlderOpen))!.person, 'Updated person');
      expect((await iousRepo.getIou(idOlderOpen))!.amountCents, 35000);

      await iousRepo.setSettled(
        idOlderOpen,
        settled: true,
        at: DateTime(2026, 11, 24, 15),
      );
      expect((await iousRepo.getIou(idOlderOpen))!.settled, isTrue);

      await iousRepo.deleteIou(idSettled);
      expect(await iousRepo.getIou(idSettled), isNull);

      // Transactions & monthly summary are untouched by IOU CRUD.
      final List<Transaction> txs = await financeRepo.getTransactions();
      expect(txs, hasLength(1));
      final FinanceSummary summary = await financeRepo.getSummary(
        month: '2026-11',
      );
      expect(summary.totalIncome, 2000.0);
      expect(summary.totalExpenses, 0.0);
      expect(summary.balance, 2000.0);
    });
  });

  group('IousController settlement & Cashflow logging', () {
    test('settleIou(logInCashflow: false) leaves Transactions unchanged, true logs income or expense', () async {
      final AppDatabase db = AppDatabase(NativeDatabase.memory());
      final ProviderContainer container = ProviderContainer(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
      );
      addTearDown(() async {
        container.dispose();
        await db.close();
      });

      final IousController controller = container.read(
        iousControllerProvider.notifier,
      );
      await container.read(iousControllerProvider.future);
      await container.read(financeControllerProvider.future);

      await controller.addIou(
        IouItem(
          id: 0,
          person: 'Bea',
          direction: IouDirection.owed,
          amountCents: 12000,
          note: 'Coffee',
          occurredOn: '2026-11-22',
          createdAt: DateTime(2026, 11, 22),
        ),
      );
      await controller.addIou(
        IouItem(
          id: 0,
          person: 'Carl',
          direction: IouDirection.owing,
          amountCents: 8000,
          occurredOn: '2026-11-23',
          createdAt: DateTime(2026, 11, 23),
        ),
      );
      await controller.addIou(
        IouItem(
          id: 0,
          person: 'Dana',
          direction: IouDirection.owed,
          amountCents: 5000,
          occurredOn: '2026-11-24',
          createdAt: DateTime(2026, 11, 24),
        ),
      );

      final List<IouItem> items = container
          .read(iousControllerProvider)
          .requireValue;
      final IouItem bea = items.firstWhere((IouItem i) => i.person == 'Bea');
      final IouItem carl = items.firstWhere((IouItem i) => i.person == 'Carl');
      final IouItem dana = items.firstWhere((IouItem i) => i.person == 'Dana');

      final DateTime settleNow = DateTime(2026, 11, 24, 10);

      // 1. Settle Dana without Cashflow logging.
      await controller.settleIou(dana, logInCashflow: false, now: settleNow);
      expect(await FinanceRepository(db).getTransactions(), isEmpty);

      // 2. Settle Bea (owed) WITH Cashflow logging -> income transaction.
      await controller.settleIou(bea, logInCashflow: true, now: settleNow);
      // 3. Settle Carl (owing) WITH Cashflow logging -> expense transaction.
      await controller.settleIou(carl, logInCashflow: true, now: settleNow);

      final List<Transaction> txs = await FinanceRepository(
        db,
      ).getTransactions();
      expect(txs, hasLength(2));

      final Transaction incomeTx = txs.firstWhere(
        (Transaction t) => t.type == 'income',
      );
      expect(incomeTx.amount, 120.0);
      expect(incomeTx.category, 'Other');
      expect(incomeTx.note, 'Settled IOU from Bea · Coffee');

      final Transaction expenseTx = txs.firstWhere(
        (Transaction t) => t.type == 'expense',
      );
      expect(expenseTx.amount, 80.0);
      expect(expenseTx.category, 'Other');
      expect(expenseTx.note, 'Paid IOU to Carl');

      // Reopen restores settled = false.
      await controller.reopenIou(dana);
      final IouItem reopenedDana = container
          .read(iousControllerProvider)
          .requireValue
          .firstWhere((IouItem i) => i.person == 'Dana');
      expect(reopenedDana.settled, isFalse);
      expect(reopenedDana.settledAt, isNull);
    });
  });

  group('Finance | IOUs UI, Split Calculator, routing & Back pop', () {
    testWidgets('Cashflow | Goals | IOUs toggle, /ious route, 3 bottom tabs, and Back returns to Cashflow', (
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

      // Navigate via /ious redirect -> opens Finance > IOUs.
      container.read(routerProvider).go('/ious');
      await settle(tester);

      expect(container.read(financeViewProvider), FinanceView.ious);
      expect(find.byType(SegmentedButton<FinanceView>), findsOneWidget);
      expect(find.byTooltip('New IOU'), findsOneWidget);
      // Empty state shows only the 88dp Ponpon and suppresses PonponTalk.
      expect(find.byType(Ponpon), findsOneWidget);
      expect(find.byType(PonponTalk), findsNothing);
      expect(find.text('No open IOUs'), findsOneWidget);

      // Pressing system Back on Finance > IOUs returns to Finance > Cashflow.
      final NavigatorState nav = tester.state(find.byType(Navigator).first);
      await nav.maybePop();
      await settle(tester);
      expect(container.read(financeViewProvider), FinanceView.cashflow);
      expect(find.byTooltip('Quick expense'), findsOneWidget);

      // Switch back to IOUs via SegmentedButton.
      await tester.tap(find.text('IOUs'));
      await settle(tester);
      expect(container.read(financeViewProvider), FinanceView.ious);
    });

    testWidgets('IousPanel creates split IOU, settles, and reopens without touching Cashflow', (
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

      // Switch to IOUs.
      await tester.tap(find.text('IOUs'));
      await settle(tester);
      expect(find.text('No open IOUs'), findsOneWidget);

      // Create IOU using "Split a total" calculator.
      await tester.tap(find.byTooltip('New IOU'));
      await settle(tester);
      expect(find.text('New IOU'), findsOneWidget);

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Person'),
        'Mika',
      );
      await tester.tap(find.text('Split a total'));
      await settle(tester);

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Total bill (₱)'),
        '600',
      );
      await settle(tester);
      // Default Split ways is 2 -> Amount (₱) becomes 300.
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Split ways'),
        '3',
      );
      await settle(tester);

      final TextFormField amountField = tester.widget<TextFormField>(
        find.widgetWithText(TextFormField, 'Amount (₱)'),
      );
      expect(amountField.controller!.text, '200');

      await tester.ensureVisible(find.text('Save IOU'));
      await settle(tester);
      await tester.tap(find.text('Save IOU'));
      await settle(tester);

      expect(find.text('Mika'), findsOneWidget);
      expect(find.text('₱200.00'), findsWidgets);
      expect(find.text('+₱200.00'), findsOneWidget);

      // Settle without Cashflow logging (switch defaults to false).
      await tester.tap(find.widgetWithText(FilledButton, 'Settle'));
      await settle(tester);
      expect(find.text('Settle with Mika?'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Settle').last);
      await settle(tester);

      // Open filter is now empty; Settled chip shows Mika with Reopen.
      expect(find.text('No open IOUs'), findsOneWidget);
      await tester.tap(find.text('Settled'));
      await settle(tester);
      expect(find.text('Mika'), findsOneWidget);
      expect(find.text('Reopen'), findsOneWidget);

      // Reopen moves Mika back to Open.
      await tester.tap(find.text('Reopen'));
      await settle(tester);
      expect(find.text('No settled IOUs yet'), findsOneWidget);

      await tester.tap(find.text('Open'));
      await settle(tester);
      expect(find.text('Mika'), findsOneWidget);

      // Cashflow remains untouched at ₱0.00.
      await tester.tap(find.text('Cashflow'));
      await settle(tester);
      expect(find.text('No transactions this month'), findsOneWidget);
    });

    testWidgets('Ponpon seeIous tip navigates from Cashflow to IOUs', (
      WidgetTester tester,
    ) async {
      final AppDatabase db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final DateTime now = DateTime.now();

      await tester.runAsync(() async {
        await IousRepository(db).createIou(
          IouItem(
            id: 0,
            person: 'Sam',
            direction: IouDirection.owing,
            amountCents: 15000,
            occurredOn: formatIouDateKey(now),
            createdAt: now,
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
                  text: 'You owe ₱150 across 1 open IOU.',
                  priority: 3,
                  action: PonponAction.seeIous,
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

      expect(find.text('You owe ₱150 across 1 open IOU.'), findsOneWidget);
      await tester.tap(find.text('See IOUs'));
      await settle(tester);

      expect(container.read(financeViewProvider), FinanceView.ious);
      expect(find.text('Sam'), findsOneWidget);
    });

    test('AppDrawer.formatRestoreSummary includes non-zero ious', () {
      expect(
        AppDrawer.formatRestoreSummary(
          events: 1,
          transactions: 2,
          notes: 3,
          ious: 2,
        ),
        'Restored 1 event, 2 transactions, 3 notes and 2 IOUs',
      );
      expect(
        AppDrawer.formatRestoreSummary(
          events: 1,
          transactions: 1,
          notes: 1,
          goals: 1,
          ious: 1,
        ),
        'Restored 1 event, 1 transaction, 1 note, 1 goal and 1 IOU',
      );
    });
  });
}
