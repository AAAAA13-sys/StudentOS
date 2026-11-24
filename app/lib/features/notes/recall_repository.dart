import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/db/app_database.dart';
import 'recall_item.dart';

class RecallRepository {
  const RecallRepository(this._db);

  final AppDatabase _db;

  Future<List<RecallReview>> getReviews() async {
    final List<RecallReviewRow> rows = await _db
        .select(_db.recallReviewRows)
        .get();
    return <RecallReview>[for (final RecallReviewRow row in rows) _fromRow(row)];
  }

  Future<RecallReview?> getReview(int noteId, String cardKey) async {
    final RecallReviewRow? row =
        await (_db.select(_db.recallReviewRows)..where(
              (t) => t.noteId.equals(noteId) & t.cardKey.equals(cardKey),
            ))
            .getSingleOrNull();
    return row == null ? null : _fromRow(row);
  }

  Future<void> upsertReview(RecallReview review) {
    return _db
        .into(_db.recallReviewRows)
        .insertOnConflictUpdate(
          RecallReviewRowsCompanion.insert(
            noteId: review.noteId,
            cardKey: review.cardKey,
            box: Value(review.box),
            nextReviewOn: review.nextReviewOn,
            lastReviewedAt: Value(review.lastReviewedAt),
            timesReviewed: Value(review.timesReviewed),
          ),
        );
  }

  Future<void> deleteForNote(int noteId) {
    return (_db.delete(
      _db.recallReviewRows,
    )..where((t) => t.noteId.equals(noteId))).go();
  }

  RecallReview _fromRow(RecallReviewRow row) {
    return RecallReview(
      noteId: row.noteId,
      cardKey: row.cardKey,
      box: row.box,
      nextReviewOn: row.nextReviewOn,
      lastReviewedAt: row.lastReviewedAt,
      timesReviewed: row.timesReviewed,
    );
  }
}

final Provider<RecallRepository> recallRepositoryProvider =
    Provider<RecallRepository>(
      (Ref ref) => RecallRepository(ref.watch(appDatabaseProvider)),
    );
