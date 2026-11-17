import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/db/app_database.dart';
import 'shift.dart';

class WorkRepository {
  const WorkRepository(this._db);

  final AppDatabase _db;

  /// Every shift, earliest first.
  Future<List<Shift>> getShifts() async {
    final List<ShiftRow> rows = await (_db.select(
      _db.shiftRows,
    )..orderBy([(t) => OrderingTerm.asc(t.startsAt)])).get();
    return rows.map(_fromRow).toList();
  }

  /// Stores [shifts]. More than one are tied together as a series so they
  /// can later be removed together.
  Future<void> createShifts(List<Shift> shifts) {
    return _db.transaction(() async {
      int? seriesId;
      for (final Shift shift in shifts) {
        final int id = await _db
            .into(_db.shiftRows)
            .insert(
              ShiftRowsCompanion.insert(
                job: shift.job,
                startsAt: shift.startsAt,
                durationMinutes: shift.durationMinutes,
                breakMinutes: Value(shift.breakMinutes),
                hourlyRateCents: Value(shift.hourlyRateCents),
                seriesId: Value(seriesId),
              ),
            );
        if (shifts.length > 1 && seriesId == null) {
          seriesId = id;
          await (_db.update(_db.shiftRows)..where((t) => t.id.equals(id)))
              .write(ShiftRowsCompanion(seriesId: Value(id)));
        }
      }
    });
  }

  Future<void> deleteShift(int id) {
    return (_db.delete(_db.shiftRows)..where((t) => t.id.equals(id))).go();
  }

  /// Removes [shift] and the later shifts of its series that are not paid.
  Future<void> deleteShiftAndLater(Shift shift) {
    final int? seriesId = shift.seriesId;
    if (seriesId == null) return deleteShift(shift.id);
    return (_db.delete(_db.shiftRows)..where(
          (t) =>
              t.seriesId.equals(seriesId) &
              t.paid.equals(false) &
              t.startsAt.isBiggerOrEqualValue(shift.startsAt),
        ))
        .go();
  }

  /// Replaces the stored shift that has [shift]'s id; its series link and
  /// paid state are kept.
  Future<void> updateShift(Shift shift) {
    return (_db.update(
      _db.shiftRows,
    )..where((t) => t.id.equals(shift.id))).write(
      ShiftRowsCompanion(
        job: Value(shift.job),
        startsAt: Value(shift.startsAt),
        durationMinutes: Value(shift.durationMinutes),
        breakMinutes: Value(shift.breakMinutes),
        hourlyRateCents: Value(shift.hourlyRateCents),
      ),
    );
  }

  Future<void> markUnpaid(Iterable<int> ids) {
    return (_db.update(_db.shiftRows)..where((t) => t.id.isIn(ids))).write(
      const ShiftRowsCompanion(paid: Value(false)),
    );
  }

  Future<void> markPaid(Iterable<int> ids) {
    return (_db.update(_db.shiftRows)..where((t) => t.id.isIn(ids))).write(
      const ShiftRowsCompanion(paid: Value(true)),
    );
  }

  static Shift _fromRow(ShiftRow row) {
    return Shift(
      id: row.id,
      job: row.job,
      startsAt: row.startsAt,
      durationMinutes: row.durationMinutes,
      breakMinutes: row.breakMinutes,
      hourlyRateCents: row.hourlyRateCents,
      paid: row.paid,
      seriesId: row.seriesId,
    );
  }
}

final Provider<WorkRepository> workRepositoryProvider =
    Provider<WorkRepository>(
      (ref) => WorkRepository(ref.watch(appDatabaseProvider)),
    );
