import 'dart:math' as math;

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/db/app_database.dart';
import 'iou_item.dart';

/// Persists IOUs and bill splits in the on-device `ious` table.
///
/// IOUs stay isolated from `transactions`, monthly balance, and
/// `MoneyWidgetSync` unless explicitly settled with Cashflow logging.
class IousRepository {
  const IousRepository(this._db);

  final AppDatabase _db;

  /// All IOUs: open (`settled = false`) first ordered by newest `occurredOn`
  /// then `id` descending, followed by settled IOUs ordered by newest
  /// `settledAt` then `id` descending.
  Future<List<IouItem>> getIous() async {
    final List<IouRow> rows = await _db.select(_db.iouRows).get();
    final List<IouItem> items = rows.map(_fromRow).toList();
    items.sort(_compareIous);
    return items;
  }

  Future<IouItem?> getIou(int id) async {
    final IouRow? row = await (_db.select(
      _db.iouRows,
    )..where((IouRows t) => t.id.equals(id))).getSingleOrNull();
    return row == null ? null : _fromRow(row);
  }

  Future<int> createIou(IouItem item) {
    final String? cleanNote = _cleanNote(item.note);
    return _db
        .into(_db.iouRows)
        .insert(
          IouRowsCompanion.insert(
            person: item.person.trim(),
            direction: item.direction.code,
            amountCents: math.max(0, item.amountCents),
            note: Value(cleanNote),
            occurredOn: item.occurredOn.trim(),
            settled: Value(item.settled),
            settledAt: Value(item.settled ? item.settledAt : null),
            createdAt: item.createdAt,
          ),
        );
  }

  Future<void> updateIou(IouItem item) {
    final String? cleanNote = _cleanNote(item.note);
    return (_db.update(
      _db.iouRows,
    )..where((IouRows t) => t.id.equals(item.id))).write(
      IouRowsCompanion(
        person: Value(item.person.trim()),
        direction: Value(item.direction.code),
        amountCents: Value(math.max(0, item.amountCents)),
        note: Value(cleanNote),
        occurredOn: Value(item.occurredOn.trim()),
        settled: Value(item.settled),
        settledAt: Value(item.settled ? item.settledAt : null),
      ),
    );
  }

  Future<void> deleteIou(int id) {
    return (_db.delete(
      _db.iouRows,
    )..where((IouRows t) => t.id.equals(id))).go();
  }

  Future<void> setSettled(
    int id, {
    required bool settled,
    DateTime? at,
  }) {
    return (_db.update(
      _db.iouRows,
    )..where((IouRows t) => t.id.equals(id))).write(
      IouRowsCompanion(
        settled: Value(settled),
        settledAt: Value(settled ? (at ?? DateTime.now()) : null),
      ),
    );
  }

  static String? _cleanNote(String? raw) {
    if (raw == null) return null;
    final String trimmed = raw.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  static int _compareIous(IouItem a, IouItem b) {
    if (a.settled != b.settled) return a.settled ? 1 : -1;
    if (!a.settled) {
      final int dateCmp = b.occurredOn.compareTo(a.occurredOn);
      if (dateCmp != 0) return dateCmp;
      return b.id.compareTo(a.id);
    }
    final DateTime aSettled = a.settledAt ?? a.createdAt;
    final DateTime bSettled = b.settledAt ?? b.createdAt;
    final int settledCmp = bSettled.compareTo(aSettled);
    return settledCmp != 0 ? settledCmp : b.id.compareTo(a.id);
  }

  static IouItem _fromRow(IouRow row) => IouItem(
    id: row.id,
    person: row.person,
    direction: IouDirection.parse(row.direction),
    amountCents: row.amountCents,
    note: row.note,
    occurredOn: row.occurredOn,
    settled: row.settled,
    settledAt: row.settledAt,
    createdAt: row.createdAt,
  );
}

final Provider<IousRepository> iousRepositoryProvider =
    Provider<IousRepository>(
      (Ref ref) => IousRepository(ref.watch(appDatabaseProvider)),
    );
