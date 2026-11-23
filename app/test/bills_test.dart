import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:studentos/core/db/app_database.dart';
import 'package:studentos/core/theme/app_theme.dart';
import 'package:studentos/features/finance/bill.dart';
import 'package:studentos/features/finance/bills_controller.dart';
import 'package:studentos/features/finance/bills_repository.dart';
import 'package:studentos/features/finance/finance_controller.dart';
import 'package:studentos/features/finance/finance_repository.dart';
import 'package:studentos/features/finance/finance_screen.dart';
import 'package:studentos/features/finance/transaction.dart';
import 'package:studentos/features/work/payday.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Bill schedule & due helpers', () {
    test('nextDueAfter advances strictly after today', () {
      // Weekly Friday: logging on Friday Nov 20 moves to next Friday Nov 27.
      expect(
        nextDueAfter(PaydaySchedule.weekly(DateTime.friday), DateTime(2026, 11, 20)),
        DateTime(2026, 11, 27),
      );
      // Semimonthly: on 15th -> last day of month; on 30th -> next 15th.
      expect(
        nextDueAfter(PaydaySchedule.semimonthly, DateTime(2026, 11, 15)),
        DateTime(2026, 11, 30),
      );
      expect(
        nextDueAfter(PaydaySchedule.semimonthly, DateTime(2026, 11, 30)),
        DateTime(2026, 12, 15),
      );
      // Monthly clamped to month-end (31st in Jan -> Feb 28 / Feb 29).
      expect(
        nextDueAfter(PaydaySchedule.monthly(31), DateTime(2027, 1, 31)),
        DateTime(2027, 2, 28),
      );
      expect(
        nextDueAfter(PaydaySchedule.monthly(31), DateTime(2028, 1, 31)),
        DateTime(2028, 2, 29),
      );
      // Year rollover on 25th.
      expect(
        nextDueAfter(PaydaySchedule.monthly(25), DateTime(2026, 12, 25)),
        DateTime(2027, 1, 25),
      );
    });

    test('due detection respects active flag and date', () {
      const Bill dueToday = Bill(
        id: 1,
        title: 'Rent',
        amountCents: 350000,
        category: 'Other',
        cadence: 'monthly:20',
        nextDueOn: '2026-11-20',
      );
      const Bill overdue = Bill(
        id: 2,
        title: 'Wifi',
        amountCents: 129900,
        category: 'Other',
        cadence: 'monthly:18',
        nextDueOn: '2026-11-18',
      );
      const Bill paused = Bill(
        id: 3,
        title: 'Gym',
        amountCents: 50000,
        category: 'Entertainment',
        cadence: 'monthly:1',
        nextDueOn: '2026-11-01',
        active: false,
      );
      final DateTime now = DateTime(2026, 11, 20, 14, 30);
      expect(dueToday.isDueOnOrBefore(now), isTrue);
      expect(dueToday.isDueToday(now), isTrue);
      expect(dueToday.isOverdue(now), isFalse);

      expect(overdue.isDueOnOrBefore(now), isTrue);
      expect(overdue.isOverdue(now), isTrue);
      expect(billDuePhrase(overdue, now), '2 days overdue');

      expect(paused.isDueOnOrBefore(now), isFalse);
      expect(paused.isOverdue(now), isFalse);
    });
  });

  group('BillsRepository & BillsController', () {
    test('repository orders by nextDueOn ascending and updates/deletes', () async {
      final AppDatabase db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final BillsRepository repo = BillsRepository(db);

      final int idLater = await repo.createBill(
        const Bill(
          id: 0,
          title: 'Wifi',
          amountCents: 129900,
          category: 'Other',
          cadence: 'monthly:25',
          nextDueOn: '2026-11-25',
        ),
      );
      final int idSooner = await repo.createBill(
        const Bill(
          id: 0,
          title: 'Rent',
          amountCents: 350000,
          category: 'Other',
          cadence: 'monthly:15',
          nextDueOn: '2026-11-15',
        ),
      );

      final List<Bill> list = await repo.getBills();
      expect(list.map((Bill b) => b.id), <int>[idSooner, idLater]);

      await repo.updateBill(list.first.copyWith(title: 'Dorm rent'));
      expect((await repo.getBills()).first.title, 'Dorm rent');

      await repo.deleteBill(idLater);
      expect((await repo.getBills()).single.id, idSooner);
    });

    test('logBill creates an expense and advances nextDueOn', () async {
      final AppDatabase db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final ProviderContainer container = ProviderContainer(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
      );
      addTearDown(container.dispose);

      final DateTime today = dateOnly(DateTime.now());
      final String todayKey = formatDateKey(today);

      await BillsRepository(db).createBill(
        Bill(
          id: 0,
          title: 'Rent',
          amountCents: 350000,
          category: 'Other',
          cadence: 'monthly:${today.day}',
          nextDueOn: todayKey,
        ),
      );

      final List<Bill> loaded = await container.read(billsControllerProvider.future);
      expect(loaded, hasLength(1));

      await container.read(billsControllerProvider.notifier).logBill(loaded.single, now: today);

      final List<Transaction> txs = await FinanceRepository(db).getTransactions();
      expect(txs, hasLength(1));
      expect(txs.single.type, 'expense');
      expect(txs.single.amount, 3500);
      expect(txs.single.category, 'Other');
      expect(txs.single.note, 'Rent');
      expect(dateOnly(txs.single.occurredOn), today);

      final Bill updated = (await container.read(billsControllerProvider.future)).single;
      expect(updated.nextDueDate!.isAfter(today), isTrue);
      expect(updated.isDueOnOrBefore(today), isFalse);
    });

    test('logBill still logs cleanly when FinanceController views another month', () async {
      final AppDatabase db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final ProviderContainer container = ProviderContainer(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
      );
      addTearDown(container.dispose);

      await container.read(financeControllerProvider.notifier).setMonth('2025-01');
      final DateTime today = dateOnly(DateTime.now());
      await BillsRepository(db).createBill(
        Bill(
          id: 0,
          title: 'Load',
          amountCents: 10000,
          category: 'Other',
          cadence: 'weekly:${today.weekday}',
          nextDueOn: formatDateKey(today),
        ),
      );

      final Bill bill = (await container.read(billsControllerProvider.future)).single;
      await container.read(billsControllerProvider.notifier).logBill(bill, now: today);

      final List<Transaction> thisMonthTxs = await FinanceRepository(db).getTransactions(
        month: DateFormat('yyyy-MM').format(today),
      );
      expect(thisMonthTxs, hasLength(1));
      expect(thisMonthTxs.single.note, 'Load');
    });

    test('autoLog bills log idempotently when BillsController loads', () async {
      final AppDatabase db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final ProviderContainer container = ProviderContainer(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
      );
      addTearDown(container.dispose);

      final DateTime today = dateOnly(DateTime.now());
      await BillsRepository(db).createBill(
        Bill(
          id: 0,
          title: 'Wifi',
          amountCents: 129900,
          category: 'Other',
          cadence: 'monthly:${today.day}',
          nextDueOn: formatDateKey(today),
          autoLog: true,
        ),
      );

      final List<Bill> afterFirstLoad =
          await container.read(billsControllerProvider.future);
      expect(afterFirstLoad.single.nextDueDate!.isAfter(today), isTrue);

      final List<Transaction> txsAfterFirst =
          await FinanceRepository(db).getTransactions();
      expect(txsAfterFirst, hasLength(1));
      expect(txsAfterFirst.single.amount, 1299);
      expect(txsAfterFirst.single.note, 'Wifi');

      // Reloading/invalidating again does not double-log.
      container.invalidate(billsControllerProvider);
      await container.read(billsControllerProvider.future);
      expect(await FinanceRepository(db).getTransactions(), hasLength(1));
    });

    test('refreshAutoLog logs bills across midnight idempotently', () async {
      final AppDatabase db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final ProviderContainer container = ProviderContainer(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
      );
      addTearDown(container.dispose);

      final DateTime today = dateOnly(DateTime.now());
      final DateTime tomorrow = DateTime(
        today.year,
        today.month,
        today.day + 1,
      );
      await BillsRepository(db).createBill(
        Bill(
          id: 0,
          title: 'Cloud',
          amountCents: 29900,
          category: 'Other',
          cadence: 'monthly:${tomorrow.day}',
          nextDueOn: formatDateKey(tomorrow),
          autoLog: true,
        ),
      );

      // Today: not due yet.
      await container.read(billsControllerProvider.future);
      expect(await FinanceRepository(db).getTransactions(), isEmpty);

      // Simulate resuming after midnight on tomorrow.
      await container
          .read(billsControllerProvider.notifier)
          .refreshAutoLog(now: tomorrow);
      await container
          .read(billsControllerProvider.notifier)
          .refreshAutoLog(now: tomorrow);

      final List<Transaction> txs = await FinanceRepository(
        db,
      ).getTransactions();
      expect(txs, hasLength(1));
      expect(txs.single.note, 'Cloud');
      expect(txs.single.amount, 299);
    });
  });

  group('FinanceScreen Bills UI', () {
    Future<void> settle(WidgetTester tester) async {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('empty state, add bill via sheet, 1-tap log, and dark mode', (
      WidgetTester tester,
    ) async {
      final AppDatabase db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [appDatabaseProvider.overrideWithValue(db)],
          child: MaterialApp(
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: ThemeMode.dark,
            home: const FinanceScreen(),
          ),
        ),
      );
      await settle(tester);

      expect(find.text('Recurring bills'), findsOneWidget);
      expect(find.text('No bills set'), findsOneWidget);

      // Open bills sheet and add a bill due today.
      await tester.tap(find.text('Recurring bills'));
      await settle(tester);
      expect(find.text('Add bill'), findsWidgets);

      await tester.tap(find.text('Add bill').first);
      await settle(tester);
      expect(find.text('New bill'), findsOneWidget);

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Title'),
        'Rent',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Amount (₱)'),
        '3500',
      );
      final Finder saveBillButton = find
          .widgetWithText(FilledButton, 'Add bill')
          .last;
      await tester.ensureVisible(saveBillButton);
      await tester.tap(saveBillButton);
      await settle(tester);

      // Close bills sheet back to FinanceScreen.
      Navigator.of(tester.element(find.text('Recurring bills').last)).pop();
      await settle(tester);

      expect(find.textContaining('Rent · ₱3,500.00 due today'), findsOneWidget);
      expect(find.text('Log'), findsOneWidget);
      // Ponpon talk bubble appears even on an empty month when a bill is due.
      expect(find.textContaining('Bill due today: Rent'), findsOneWidget);

      // 1-tap Log records expense and updates the row & balance.
      await tester.tap(find.widgetWithText(TextButton, 'Log'));
      await settle(tester);

      expect(find.text('Other'), findsWidgets);
      expect(find.text('Rent'), findsOneWidget);
      expect(find.textContaining('Next: Rent'), findsOneWidget);
    });

    testWidgets('multiple due bills show Log all and logs all due bills', (
      WidgetTester tester,
    ) async {
      final AppDatabase db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final DateTime today = dateOnly(DateTime.now());
      final String todayKey = formatDateKey(today);

      await tester.runAsync(() async {
        final BillsRepository repo = BillsRepository(db);
        await repo.createBill(
          Bill(
            id: 0,
            title: 'Rent',
            amountCents: 350000,
            category: 'Other',
            cadence: 'monthly:${today.day}',
            nextDueOn: todayKey,
          ),
        );
        await repo.createBill(
          Bill(
            id: 0,
            title: 'Load',
            amountCents: 70000,
            category: 'Other',
            cadence: 'weekly:${today.weekday}',
            nextDueOn: todayKey,
          ),
        );
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [appDatabaseProvider.overrideWithValue(db)],
          child: MaterialApp(theme: AppTheme.light, home: const FinanceScreen()),
        ),
      );
      await settle(tester);

      expect(find.text('2 bills due · ₱4,200.00'), findsOneWidget);
      expect(find.text('Log all'), findsOneWidget);

      await tester.tap(find.widgetWithText(TextButton, 'Log all'));
      await settle(tester);

      final List<Transaction>? txs = await tester.runAsync(
        () => FinanceRepository(db).getTransactions(),
      );
      expect(txs, hasLength(2));
      expect(find.text('Log all'), findsNothing);
    });

    testWidgets('delete bill with confirmation dialog', (
      WidgetTester tester,
    ) async {
      final AppDatabase db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final DateTime future = dateOnly(
        DateTime.now(),
      ).add(const Duration(days: 5));

      await tester.runAsync(() {
        return BillsRepository(db).createBill(
          Bill(
            id: 0,
            title: 'Spotify',
            amountCents: 14900,
            category: 'Entertainment',
            cadence: 'monthly:${future.day}',
            nextDueOn: formatDateKey(future),
          ),
        );
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [appDatabaseProvider.overrideWithValue(db)],
          child: MaterialApp(theme: AppTheme.light, home: const FinanceScreen()),
        ),
      );
      await settle(tester);

      await tester.tap(find.text('Recurring bills'));
      await settle(tester);
      expect(find.text('Spotify'), findsOneWidget);

      await tester.tap(find.byTooltip('Delete'));
      await settle(tester);
      expect(find.text('Delete bill?'), findsOneWidget);

      await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
      await settle(tester);

      expect(find.text('Spotify'), findsNothing);
      final List<Bill>? remaining = await tester.runAsync(
        () => BillsRepository(db).getBills(),
      );
      expect(remaining, isEmpty);
    });

    testWidgets('tapping Log inside _BillsSheet shows floating snackbar', (
      WidgetTester tester,
    ) async {
      final AppDatabase db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final DateTime today = dateOnly(DateTime.now());

      await tester.runAsync(() {
        return BillsRepository(db).createBill(
          Bill(
            id: 0,
            title: 'Rent',
            amountCents: 350000,
            category: 'Other',
            cadence: 'monthly:${today.day}',
            nextDueOn: formatDateKey(today),
          ),
        );
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [appDatabaseProvider.overrideWithValue(db)],
          child: MaterialApp(theme: AppTheme.light, home: const FinanceScreen()),
        ),
      );
      await settle(tester);

      await tester.tap(find.text('Recurring bills'));
      await settle(tester);

      // Tap the Log button inside the sheet (not the background row's Log).
      await tester.tap(find.widgetWithText(TextButton, 'Log').last);
      await settle(tester);

      expect(find.text('Logged Rent · ₱3,500.00'), findsOneWidget);
    });
  });
}
