import 'dart:math' as math;

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/db/app_database.dart';
import 'savings_goal.dart';

/// Persists personal savings pockets in the on-device `goals` table.
///
/// Goals never touch `transactions`, monthly balance, or `MoneyWidgetSync`.
class GoalsRepository {
  const GoalsRepository(this._db);

  final AppDatabase _db;

  /// All goals: unreached first, then earliest `targetDate` (nulls last),
  /// then newest (`createdAt` desc, `id` desc).
  Future<List<SavingsGoal>> getGoals() async {
    final List<GoalRow> rows = await _db.select(_db.goalRows).get();
    final List<SavingsGoal> goals = rows.map(_fromRow).toList();
    goals.sort(_compareGoals);
    return goals;
  }

  Future<SavingsGoal?> getGoal(int id) async {
    final GoalRow? row = await (_db.select(
      _db.goalRows,
    )..where((GoalRows t) => t.id.equals(id))).getSingleOrNull();
    return row == null ? null : _fromRow(row);
  }

  Future<int> createGoal(SavingsGoal goal) {
    final String? cleanDate = _cleanDate(goal.targetDate);
    return _db
        .into(_db.goalRows)
        .insert(
          GoalRowsCompanion.insert(
            title: goal.title.trim(),
            targetCents: math.max(0, goal.targetCents),
            savedCents: Value(math.max(0, goal.savedCents)),
            targetDate: Value(cleanDate),
            createdAt: goal.createdAt,
          ),
        );
  }

  Future<void> updateGoal(SavingsGoal goal) {
    final String? cleanDate = _cleanDate(goal.targetDate);
    return (_db.update(
      _db.goalRows,
    )..where((GoalRows t) => t.id.equals(goal.id))).write(
      GoalRowsCompanion(
        title: Value(goal.title.trim()),
        targetCents: Value(math.max(0, goal.targetCents)),
        savedCents: Value(math.max(0, goal.savedCents)),
        targetDate: Value(cleanDate),
      ),
    );
  }

  Future<void> deleteGoal(int id) {
    return (_db.delete(
      _db.goalRows,
    )..where((GoalRows t) => t.id.equals(id))).go();
  }

  /// Adds [deltaCents] (or subtracts when negative) to the goal's `savedCents`,
  /// clamped at `>= 0`. No-op if the goal does not exist.
  Future<void> adjustSaved(int id, int deltaCents) {
    return _db.transaction(() async {
      final GoalRow? row = await (_db.select(
        _db.goalRows,
      )..where((GoalRows t) => t.id.equals(id))).getSingleOrNull();
      if (row == null) return;
      final int nextSaved = math.max(0, row.savedCents + deltaCents);
      await (_db.update(
        _db.goalRows,
      )..where((GoalRows t) => t.id.equals(id))).write(
        GoalRowsCompanion(savedCents: Value(nextSaved)),
      );
    });
  }

  static String? _cleanDate(String? raw) {
    if (raw == null) return null;
    final String trimmed = raw.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  static int _compareGoals(SavingsGoal a, SavingsGoal b) {
    if (a.isReached != b.isReached) return a.isReached ? 1 : -1;
    final DateTime? da = a.targetDateTime;
    final DateTime? db = b.targetDateTime;
    if (da != null && db != null) {
      final int dateCmp = da.compareTo(db);
      if (dateCmp != 0) return dateCmp;
    } else if (da != null || db != null) {
      return da != null ? -1 : 1;
    }
    final int createdCmp = b.createdAt.compareTo(a.createdAt);
    return createdCmp != 0 ? createdCmp : b.id.compareTo(a.id);
  }

  static SavingsGoal _fromRow(GoalRow row) => SavingsGoal(
    id: row.id,
    title: row.title,
    targetCents: row.targetCents,
    savedCents: row.savedCents,
    targetDate: row.targetDate,
    createdAt: row.createdAt,
  );
}

final Provider<GoalsRepository> goalsRepositoryProvider =
    Provider<GoalsRepository>(
      (Ref ref) => GoalsRepository(ref.watch(appDatabaseProvider)),
    );
