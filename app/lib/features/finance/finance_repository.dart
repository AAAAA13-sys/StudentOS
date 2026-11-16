import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/db/app_database.dart';
import 'safe_to_spend.dart';
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
            occurredOn: _dateKey(day),
            note: Value(transaction.note),
          ),
        );
  }

  /// Replaces the stored transaction that has [transaction]'s id.
  Future<void> updateTransaction(Transaction transaction) {
    return (_db.update(
      _db.transactionRows,
    )..where((t) => t.id.equals(transaction.id))).write(
      TransactionRowsCompanion(
        type: Value(transaction.type),
        amountCents: Value((transaction.amount * 100).round()),
        category: Value(transaction.category),
        occurredOn: Value(_dateKey(transaction.occurredOn)),
        note: Value(transaction.note),
      ),
    );
  }

  Future<void> deleteTransaction(int id) {
    return (_db.delete(
      _db.transactionRows,
    )..where((t) => t.id.equals(id))).go();
  }

  /// Today's spending room, from every transaction dated up to [today].
  Future<SafeToSpend> getSafeToSpend(DateTime today) async {
    final String key = _dateKey(today);
    final List<TransactionRow> rows = await (_db.select(
      _db.transactionRows,
    )..where((t) => t.occurredOn.isSmallerOrEqualValue(key))).get();

    int balance = 0;
    int spentToday = 0;
    for (final TransactionRow row in rows) {
      if (row.type == 'income') {
        balance += row.amountCents;
      } else {
        balance -= row.amountCents;
        if (row.occurredOn == key) {
          spentToday += row.amountCents;
        }
      }
    }

    final DateTime day = DateTime(today.year, today.month, today.day);
    final DateTime? allowance = await getNextAllowance();
    final bool untilAllowance = allowance != null && allowance.isAfter(day);
    final int lastDay = DateTime(today.year, today.month + 1, 0).day;
    return SafeToSpend.calculate(
      balanceCents: balance,
      spentTodayCents: spentToday,
      // Rounded because a day is 23 or 25 hours long when clocks change.
      daysLeft: untilAllowance
          ? (allowance.difference(day).inHours / 24).round()
          : lastDay - today.day + 1,
      untilAllowance: untilAllowance,
      reservedCents: await getReservedCents(),
    );
  }

  static const String _reservedKey = 'fixed_commitments_cents';

  /// Centavos set aside for fixed bills; zero when none is set.
  Future<int> getReservedCents() async {
    final SettingRow? row = await (_db.select(
      _db.settingRows,
    )..where((t) => t.key.equals(_reservedKey))).getSingleOrNull();
    final int cents = row == null ? 0 : int.tryParse(row.value) ?? 0;
    return cents < 0 ? 0 : cents;
  }

  Future<void> setReservedCents(int cents) {
    return _db
        .into(_db.settingRows)
        .insertOnConflictUpdate(
          SettingRowsCompanion.insert(
            key: _reservedKey,
            value: (cents < 0 ? 0 : cents).toString(),
          ),
        );
  }

  static const String _nextAllowanceKey = 'next_allowance';

  /// The day the next allowance arrives, if the user has set one.
  Future<DateTime?> getNextAllowance() async {
    final SettingRow? row = await (_db.select(
      _db.settingRows,
    )..where((t) => t.key.equals(_nextAllowanceKey))).getSingleOrNull();
    return row == null ? null : DateTime.tryParse(row.value);
  }

  Future<void> setNextAllowance(DateTime day) {
    return _db
        .into(_db.settingRows)
        .insertOnConflictUpdate(
          SettingRowsCompanion.insert(
            key: _nextAllowanceKey,
            value: _dateKey(day),
          ),
        );
  }

  static String _dateKey(DateTime day) {
    return '${day.year.toString().padLeft(4, '0')}-'
        '${day.month.toString().padLeft(2, '0')}-'
        '${day.day.toString().padLeft(2, '0')}';
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
