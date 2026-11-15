import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_database.dart';

/// Thrown when a file is not a StudentOS backup this version can read.
class BackupFormatException implements Exception {
  const BackupFormatException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Copies everything in the database to and from one JSON document, so the
/// data can be kept outside the phone.
class BackupService {
  const BackupService(this._db);

  final AppDatabase _db;

  static const int formatVersion = 1;

  Future<String> exportJson() async {
    final List<EventRow> events = await _db.select(_db.eventRows).get();
    final List<TransactionRow> transactions = await _db
        .select(_db.transactionRows)
        .get();
    final List<NoteRow> notes = await _db.select(_db.noteRows).get();

    return const JsonEncoder.withIndent('  ').convert(<String, Object?>{
      'app': 'studentos',
      'format': formatVersion,
      'exported_at': DateTime.now().toUtc().toIso8601String(),
      'events': <Object?>[for (final EventRow row in events) row.toJson()],
      'transactions': <Object?>[
        for (final TransactionRow row in transactions) row.toJson(),
      ],
      'notes': <Object?>[for (final NoteRow row in notes) row.toJson()],
    });
  }

  /// Replaces everything in the database with the contents of [json].
  /// Nothing is changed when the file cannot be read.
  Future<({int events, int transactions, int notes})> restoreJson(
    String json,
  ) async {
    final List<EventRow> events;
    final List<TransactionRow> transactions;
    final List<NoteRow> notes;
    try {
      final Object? decoded = jsonDecode(json);
      if (decoded is! Map<String, dynamic> || decoded['app'] != 'studentos') {
        throw const BackupFormatException('This is not a StudentOS backup.');
      }
      final Object? format = decoded['format'];
      if (format is! int || format > formatVersion) {
        throw const BackupFormatException(
          'This backup was made by a newer version of the app.',
        );
      }
      List<Map<String, dynamic>> rows(String key) =>
          (decoded[key] as List<dynamic>).cast<Map<String, dynamic>>();
      events = rows('events').map(EventRow.fromJson).toList();
      transactions = rows('transactions').map(TransactionRow.fromJson).toList();
      notes = rows('notes').map(NoteRow.fromJson).toList();
    } on BackupFormatException {
      rethrow;
    } catch (_) {
      throw const BackupFormatException('The backup file is damaged.');
    }

    await _db.transaction(() async {
      await _db.delete(_db.eventRows).go();
      await _db.delete(_db.transactionRows).go();
      await _db.delete(_db.noteRows).go();
      await _db.batch((batch) {
        batch.insertAll(_db.eventRows, events);
        batch.insertAll(_db.transactionRows, transactions);
        batch.insertAll(_db.noteRows, notes);
      });
    });
    return (
      events: events.length,
      transactions: transactions.length,
      notes: notes.length,
    );
  }
}

final Provider<BackupService> backupServiceProvider = Provider<BackupService>(
  (ref) => BackupService(ref.watch(appDatabaseProvider)),
);
