import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

part 'app_database.g.dart';

/// Generic offline cache: one JSON payload per key.
///
/// SQL: `cache_entries(key TEXT PRIMARY KEY, payload TEXT, saved_at INTEGER)`
/// where `saved_at` is milliseconds since the Unix epoch (UTC).
class CacheEntries extends Table {
  TextColumn get key => text()();

  TextColumn get payload => text()();

  IntColumn get savedAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{key};
}

@DriftDatabase(tables: <Type>[CacheEntries])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
    : super(executor ?? driftDatabase(name: 'studentos_cache'));

  @override
  int get schemaVersion => 1;
}

final Provider<AppDatabase> appDatabaseProvider = Provider<AppDatabase>((ref) {
  final AppDatabase database = AppDatabase();
  ref.onDispose(database.close);
  return database;
});
