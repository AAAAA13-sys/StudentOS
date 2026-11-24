import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studentos/core/db/app_database.dart';
import 'package:studentos/core/theme/app_theme.dart';
import 'package:studentos/core/widgets/ponpon.dart';
import 'package:studentos/features/finance/finance_controller.dart';
import 'package:studentos/features/finance/finance_repository.dart';
import 'package:studentos/features/finance/finance_screen.dart';
import 'package:studentos/features/finance/transaction.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> settle(WidgetTester tester) async {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pumpAndSettle();
  }

  group('filterCashflowTransactions', () {
    final List<Transaction> sample = <Transaction>[
      Transaction(
        id: 1,
        type: 'income',
        amount: 3000,
        category: 'Allowance',
        occurredOn: DateTime(2026, 11, 1),
        note: 'Monthly stipend',
      ),
      Transaction(
        id: 2,
        type: 'expense',
        amount: 120,
        category: 'Food',
        occurredOn: DateTime(2026, 11, 2),
        note: 'Ramen near campus',
      ),
      Transaction(
        id: 3,
        type: 'expense',
        amount: 50,
        category: 'Transport',
        occurredOn: DateTime(2026, 11, 3),
        note: 'Jeepney',
      ),
    ];

    test('filters by query, type, and category', () {
      expect(
        filterCashflowTransactions(sample, const FinanceCashflowFilter()),
        hasLength(3),
      );
      expect(
        filterCashflowTransactions(
          sample,
          const FinanceCashflowFilter(query: 'ramen'),
        ).map((Transaction t) => t.id),
        <int>[2],
      );
      expect(
        filterCashflowTransactions(
          sample,
          const FinanceCashflowFilter(query: 'transport'),
        ).map((Transaction t) => t.id),
        <int>[3],
      );
      expect(
        filterCashflowTransactions(
          sample,
          const FinanceCashflowFilter(type: 'income'),
        ).map((Transaction t) => t.id),
        <int>[1],
      );
      expect(
        filterCashflowTransactions(
          sample,
          const FinanceCashflowFilter(type: 'expense', category: 'Food'),
        ).map((Transaction t) => t.id),
        <int>[2],
      );
    });
  });

  group('FinanceScreen drill-down & search', () {
    testWidgets('hides filter bar when month has no transactions', (
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

      expect(find.text('No transactions this month'), findsOneWidget);
      expect(find.text('Search note or category'), findsNothing);
    });

    testWidgets(
      'searches notes, switches type chips, shows smug Ponpon on empty match, and clears filters',
      (WidgetTester tester) async {
        final AppDatabase db = AppDatabase(NativeDatabase.memory());
        addTearDown(db.close);
        final DateTime now = DateTime.now();

        await tester.runAsync(() async {
          final FinanceRepository repo = FinanceRepository(db);
          await repo.createTransaction(
            Transaction(
              id: 0,
              type: 'income',
              amount: 2500,
              category: 'Allowance',
              occurredOn: now,
              note: 'Weekly allowance',
            ),
          );
          await repo.createTransaction(
            Transaction(
              id: 0,
              type: 'expense',
              amount: 140,
              category: 'Food',
              occurredOn: now,
              note: 'Siomai rice',
            ),
          );
          await repo.createTransaction(
            Transaction(
              id: 0,
              type: 'expense',
              amount: 60,
              category: 'Transport',
              occurredOn: now,
              note: 'Tricycle',
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

        expect(find.text('Search note or category'), findsOneWidget);
        expect(find.text('Siomai rice'), findsOneWidget);
        expect(find.text('Tricycle'), findsOneWidget);
        expect(find.text('Weekly allowance'), findsOneWidget);

        // Filter by Income chip.
        await tester.tap(find.widgetWithText(ChoiceChip, 'Income'));
        await settle(tester);
        expect(find.text('Weekly allowance'), findsOneWidget);
        expect(find.text('Siomai rice'), findsNothing);

        // Back to All, then search for 'siomai'.
        await tester.tap(find.widgetWithText(ChoiceChip, 'All'));
        await settle(tester);
        await tester.enterText(find.byType(TextField), 'siomai');
        await settle(tester);
        expect(find.text('Siomai rice'), findsOneWidget);
        expect(find.text('Tricycle'), findsNothing);

        // Search something non-existent -> smug Ponpon + Clear filters.
        await tester.enterText(find.byType(TextField), 'helicopter');
        await settle(tester);
        expect(find.text('No matching transactions'), findsOneWidget);
        expect(find.text('Clear filters'), findsOneWidget);
        final Ponpon smug = tester.widget<Ponpon>(find.byType(Ponpon));
        expect(smug.mood, PonponMood.smug);

        await tester.ensureVisible(find.text('Clear filters'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Clear filters'));
        await settle(tester);
        expect(find.text('Siomai rice'), findsOneWidget);
        expect(find.text('Tricycle'), findsOneWidget);
        expect(find.text('Weekly allowance'), findsOneWidget);
      },
    );

    testWidgets(
      'tapping _MonthCard categories opens CategoryBreakdownSheet and filters Cashflow',
      (WidgetTester tester) async {
        final AppDatabase db = AppDatabase(NativeDatabase.memory());
        addTearDown(db.close);
        final DateTime now = DateTime.now();

        await tester.runAsync(() async {
          final FinanceRepository repo = FinanceRepository(db);
          await repo.createTransaction(
            Transaction(
              id: 0,
              type: 'income',
              amount: 1000,
              category: 'Allowance',
              occurredOn: now,
              note: 'Stipend',
            ),
          );
          await repo.createTransaction(
            Transaction(
              id: 0,
              type: 'expense',
              amount: 300,
              category: 'Food',
              occurredOn: now,
              note: 'Bento',
            ),
          );
          await repo.createTransaction(
            Transaction(
              id: 0,
              type: 'expense',
              amount: 100,
              category: 'Transport',
              occurredOn: now,
              note: 'Bus fare',
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

        // Tap the category summary row on _MonthCard.
        await tester.tap(find.text('All').first);
        await settle(tester);

        expect(find.text('Category breakdown'), findsOneWidget);
        expect(find.text('Expenses'), findsOneWidget);
        expect(find.text('Food (1)'), findsOneWidget);
        expect(find.text('Transport (1)'), findsOneWidget);
        expect(find.text('₱300.00 · 75%'), findsOneWidget);

        // Tap Transport -> closes sheet and filters Cashflow to Transport.
        await tester.tap(find.text('Transport (1)'));
        await settle(tester);

        expect(find.text('Category breakdown'), findsNothing);
        expect(find.text('Bus fare'), findsOneWidget);
        expect(find.text('Bento'), findsNothing);
        expect(find.byType(InputChip), findsOneWidget);
      },
    );
  });
}
