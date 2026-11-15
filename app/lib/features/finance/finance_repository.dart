import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/db/app_database.dart';
import 'transaction.dart';

class FinanceRepository {
  const FinanceRepository(this._db);

  final AppDatabase _db;

  static const List<String> categories = <String>[
    'Food',
    'Transport',
    'School',
    'Entertainment',
    'Allowance',
    'Part-time Job',
    'Other',
  ];

  /// [month] is `YYYY-MM`. Newest first.
  Future<List<Transaction>> getTransactions({
    String? month,
    String? category,
  }) async {
    final query = _db.select(_db.transactionRows);
    if (month != null) {
      query.where((t) => t.occurredOn.like('$month-%'));
    }
    if (category != null) {
      query.where((t) => t.category.equals(category));
    }
    query.orderBy([
      (t) => OrderingTerm.desc(t.occurredOn),
      (t) => OrderingTerm.desc(t.id),
    ]);
    final List<TransactionRow> rows = await query.get();
    return rows
        .map(
          (TransactionRow row) => Transaction(
            id: row.id,
            type: row.type,
            amount: row.amountCents / 100,
            category: row.category,
            occurredOn: DateTime.parse(row.occurredOn),
            note: row.note,
          ),
        )
        .toList();
  }

  Future<void> createTransaction(Transaction transaction) {
    final DateTime day = transaction.occurredOn;
    return _db
        .into(_db.transactionRows)
        .insert(
          TransactionRowsCompanion.insert(
            type: transaction.type,
            amountCents: (transaction.amount * 100).round(),
            category: transaction.category,
            occurredOn:
                '${day.year.toString().padLeft(4, '0')}-'
                '${day.month.toString().padLeft(2, '0')}-'
                '${day.day.toString().padLeft(2, '0')}',
            note: Value(transaction.note),
          ),
        );
  }

  Future<void> deleteTransaction(int id) {
    return (_db.delete(
      _db.transactionRows,
    )..where((t) => t.id.equals(id))).go();
  }

  /// Totals for [month] (`YYYY-MM`), summed in centavos.
  Future<FinanceSummary> getSummary({required String month}) async {
    final List<TransactionRow> rows = await (_db.select(
      _db.transactionRows,
    )..where((t) => t.occurredOn.like('$month-%'))).get();

    int income = 0;
    int expenses = 0;
    final Map<(String, String), int> groups = <(String, String), int>{};
    for (final TransactionRow row in rows) {
      if (row.type == 'income') {
        income += row.amountCents;
      } else {
        expenses += row.amountCents;
      }
      groups.update(
        (row.category, row.type),
        (int total) => total + row.amountCents,
        ifAbsent: () => row.amountCents,
      );
    }

    final List<CategoryBreakdown> byCategory =
        groups.entries
            .map(
              (entry) => CategoryBreakdown(
                category: entry.key.$1,
                type: entry.key.$2,
                total: entry.value / 100,
              ),
            )
            .toList()
          ..sort((a, b) => b.total.compareTo(a.total));

    return FinanceSummary(
      month: month,
      totalIncome: income / 100,
      totalExpenses: expenses / 100,
      balance: (income - expenses) / 100,
      byCategory: byCategory,
    );
  }
}

final Provider<FinanceRepository> financeRepositoryProvider =
    Provider<FinanceRepository>(
      (ref) => FinanceRepository(ref.watch(appDatabaseProvider)),
    );
