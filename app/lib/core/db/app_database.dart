import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

part 'app_database.g.dart';

@DataClassName('EventRow')
class EventRows extends Table {
  @override
  String get tableName => 'events';

  IntColumn get id => integer().autoIncrement()();

  TextColumn get title => text()();

  DateTimeColumn get startsAt => dateTime()();

  IntColumn get durationMinutes => integer().withDefault(const Constant(60))();

  TextColumn get location => text().nullable()();

  TextColumn get notes => text().nullable()();

  /// `none`, `daily`, `weekly` or `monthly`.
  TextColumn get recurrence => text().withDefault(const Constant('none'))();

  /// Last day the event repeats on, as `YYYY-MM-DD` (inclusive).
  TextColumn get recurrenceUntil => text().nullable()();

  IntColumn get reminderMinutes => integer().nullable()();

  /// The note attached to this event, if any. The note may have been
  /// deleted since; readers must cope with a missing note.
  IntColumn get noteId => integer().nullable()();
}

@DataClassName('TransactionRow')
class TransactionRows extends Table {
  @override
  String get tableName => 'transactions';

  IntColumn get id => integer().autoIncrement()();

  /// `income` or `expense`.
  TextColumn get type => text()();

  /// Centavos, so sums never accumulate floating-point error.
  IntColumn get amountCents => integer()();

  TextColumn get category => text()();

  /// `YYYY-MM-DD`; a month is the prefix `YYYY-MM`.
  TextColumn get occurredOn => text()();

  TextColumn get note => text().nullable()();
}

@DataClassName('NoteRow')
class NoteRows extends Table {
  @override
  String get tableName => 'notes';

  IntColumn get id => integer().autoIncrement()();

  TextColumn get title => text()();

  TextColumn get body => text()();

  /// JSON array of lower-case tag strings.
  TextColumn get tags => text()();

  DateTimeColumn get createdAt => dateTime()();

  DateTimeColumn get updatedAt => dateTime()();
}

/// Small named values, such as the next allowance day.
@DataClassName('SettingRow')
class SettingRows extends Table {
  @override
  String get tableName => 'settings';

  TextColumn get key => text()();

  TextColumn get value => text()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{key};
}

/// One work shift. A weekly repeat is stored as one row per day worked, so
/// a single day can be removed or changed without touching the others.
@DataClassName('ShiftRow')
class ShiftRows extends Table {
  @override
  String get tableName => 'shifts';

  IntColumn get id => integer().autoIncrement()();

  /// Where the shift is worked.
  TextColumn get job => text()();

  DateTimeColumn get startsAt => dateTime()();

  IntColumn get durationMinutes => integer()();

  /// Unpaid break time inside the shift.
  IntColumn get breakMinutes => integer().withDefault(const Constant(0))();

  /// Centavos per hour at the time the shift was logged.
  IntColumn get hourlyRateCents => integer().withDefault(const Constant(0))();

  /// True once the pay for this shift has been received.
  BoolColumn get paid => boolean().withDefault(const Constant(false))();

  /// Shared by the shifts that were added together as one weekly repeat.
  IntColumn get seriesId => integer().nullable()();
}

/// The app's only data store. Everything lives on this device.
@DriftDatabase(
  tables: <Type>[EventRows, TransactionRows, NoteRows, SettingRows, ShiftRows],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
    : super(executor ?? driftDatabase(name: 'studentos'));

  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (Migrator m, int from, int to) async {
      if (from < 2) {
        await m.addColumn(eventRows, eventRows.noteId);
      }
      if (from < 3) {
        await m.createTable(settingRows);
      }
      if (from < 4) {
        await m.createTable(shiftRows);
      }
    },
  );
}

final Provider<AppDatabase> appDatabaseProvider = Provider<AppDatabase>((ref) {
  final AppDatabase database = AppDatabase();
  ref.onDispose(database.close);
  return database;
});
