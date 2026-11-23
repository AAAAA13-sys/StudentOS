import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/db/app_database.dart';
import 'bill.dart';

/// Persists recurring bills in the on-device `bills` table.
class BillsRepository {
  const BillsRepository(this._db);

  final AppDatabase _db;

  /// All bills sorted by `nextDueOn` ascending, then `id` ascending.
  Future<List<Bill>> getBills() async {
    final List<BillRow> rows =
        await (_db.select(_db.billRows)..orderBy(<OrderingTerm Function(BillRows)>[
              (BillRows t) => OrderingTerm.asc(t.nextDueOn),
              (BillRows t) => OrderingTerm.asc(t.id),
            ]))
            .get();
    return rows.map(_fromRow).toList();
  }

  Future<int> createBill(Bill bill) {
    return _db
        .into(_db.billRows)
        .insert(
          BillRowsCompanion.insert(
            title: bill.title,
            amountCents: bill.amountCents,
            category: bill.category,
            cadence: bill.cadence,
            nextDueOn: bill.nextDueOn,
            active: Value(bill.active),
            autoLog: Value(bill.autoLog),
          ),
        );
  }

  Future<void> updateBill(Bill bill) {
    return (_db.update(
      _db.billRows,
    )..where((BillRows t) => t.id.equals(bill.id))).write(
      BillRowsCompanion(
        title: Value(bill.title),
        amountCents: Value(bill.amountCents),
        category: Value(bill.category),
        cadence: Value(bill.cadence),
        nextDueOn: Value(bill.nextDueOn),
        active: Value(bill.active),
        autoLog: Value(bill.autoLog),
      ),
    );
  }

  Future<void> deleteBill(int id) {
    return (_db.delete(
      _db.billRows,
    )..where((BillRows t) => t.id.equals(id))).go();
  }

  static Bill _fromRow(BillRow row) => Bill(
    id: row.id,
    title: row.title,
    amountCents: row.amountCents,
    category: row.category,
    cadence: row.cadence,
    nextDueOn: row.nextDueOn,
    active: row.active,
    autoLog: row.autoLog,
  );
}

final Provider<BillsRepository> billsRepositoryProvider =
    Provider<BillsRepository>(
      (Ref ref) => BillsRepository(ref.watch(appDatabaseProvider)),
    );
