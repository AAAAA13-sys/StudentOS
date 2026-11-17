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

  /// An exam or assignment the owner has marked done. Applies to the whole
  /// series when the event repeats.
  BoolColumn get done => boolean().withDefault(const Constant(false))();
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

  BoolColumn get pinned => boolean().withDefault(const Constant(false))();
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

/// Phone use on one day, copied from Android's usage history, which the
/// system keeps for only a few days.
@DataClassName('PhoneDayRow')
class PhoneDayRows extends Table {
  @override
  String get tableName => 'phone_days';

  /// `YYYY-MM-DD`.
  TextColumn get date => text()();

  /// Time the screen was on.
  IntColumn get screenOnMs => integer()();

  IntColumn get unlocks => integer()();

  /// First unlock of the day.
  DateTimeColumn get firstPickup => dateTime().nullable()();

  /// The longest stretch with the screen off around the night before this
  /// day; the app cannot know whether that was sleep.
  DateTimeColumn get restStart => dateTime().nullable()();

  DateTimeColumn get restEnd => dateTime().nullable()();

  /// True once the day was read after it ended. A complete day is never read
  /// again, so the system forgetting it later cannot wipe it.
  BoolColumn get complete => boolean().withDefault(const Constant(false))();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{date};
}

/// Time in one app on one day.
@DataClassName('PhoneAppDayRow')
class PhoneAppDayRows extends Table {
  @override
  String get tableName => 'phone_app_days';

  TextColumn get date => text()();

  TextColumn get package => text()();

  /// Kept so the name survives the app being uninstalled.
  TextColumn get label => text()();

  IntColumn get foregroundMs => integer()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{date, package};
}

/// One wake-up alarm and everything that makes it hard to ignore. The
/// Android side keeps its own copy so it can ring with the app closed.
@DataClassName('AlarmRow')
class AlarmRows extends Table {
  @override
  String get tableName => 'alarms';

  IntColumn get id => integer().autoIncrement()();

  IntColumn get hour => integer()();

  IntColumn get minute => integer()();

  /// Weekdays it repeats on: bit 0 is Monday ... bit 6 is Sunday. Zero rings
  /// once and then turns itself off.
  IntColumn get days => integer().withDefault(const Constant(0))();

  TextColumn get label => text().withDefault(const Constant(''))();

  BoolColumn get enabled => boolean().withDefault(const Constant(true))();

  /// A content URI from Android's sound picker; null is the phone's alarm.
  TextColumn get soundUri => text().nullable()();

  TextColumn get soundName => text().nullable()();

  /// Alarm volume in percent of the phone's maximum.
  IntColumn get volume => integer().withDefault(const Constant(100))();

  /// Seconds to rise from quiet to [volume]; 0 starts at full volume.
  IntColumn get rampSeconds => integer().withDefault(const Constant(0))();

  /// Puts the alarm volume back up whenever it is turned down while ringing.
  BoolColumn get volumeLock => boolean().withDefault(const Constant(true))();

  BoolColumn get vibrate => boolean().withDefault(const Constant(true))();

  /// `none`, `math`, `type` or `shake`: what it takes to turn it off.
  TextColumn get challenge => text().withDefault(const Constant('math'))();

  /// Problems to solve, or shakes to make.
  IntColumn get challengeCount => integer().withDefault(const Constant(3))();

  /// `easy`, `medium` or `hard` for maths.
  TextColumn get difficulty => text().withDefault(const Constant('medium'))();

  /// The sentence to type for the `type` challenge.
  TextColumn get phrase => text().withDefault(const Constant(''))();

  /// How many snoozes are allowed; 0 hides the button.
  IntColumn get snoozeLimit => integer().withDefault(const Constant(1))();

  IntColumn get snoozeMinutes => integer().withDefault(const Constant(5))();

  /// Asks "still awake?" a while after it is turned off, and rings again
  /// when nobody answers.
  BoolColumn get wakeCheck => boolean().withDefault(const Constant(true))();

  IntColumn get wakeCheckMinutes => integer().withDefault(const Constant(5))();
}

/// One finished focus session (a run of Pomodoro rounds).
@DataClassName('FocusLogRow')
class FocusLogRows extends Table {
  @override
  String get tableName => 'focus_logs';

  IntColumn get id => integer().autoIncrement()();

  DateTimeColumn get startedAt => dateTime()();

  DateTimeColumn get endedAt => dateTime()();

  /// Time actually spent in focus phases, without breaks or pauses.
  IntColumn get focusMs => integer()();

  /// Focus rounds finished in full.
  IntColumn get rounds => integer()();

  /// True when it was stopped before the last round ended.
  BoolColumn get endedEarly => boolean().withDefault(const Constant(false))();
}

/// The app's only data store. Everything lives on this device.
@DriftDatabase(
  tables: <Type>[
    EventRows,
    TransactionRows,
    NoteRows,
    SettingRows,
    ShiftRows,
    PhoneDayRows,
    PhoneAppDayRows,
    AlarmRows,
    FocusLogRows,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
    : super(executor ?? driftDatabase(name: 'studentos'));

  @override
  int get schemaVersion => 8;

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
      if (from < 5) {
        await m.createTable(phoneDayRows);
        await m.createTable(phoneAppDayRows);
      }
      if (from < 6) {
        await m.createTable(alarmRows);
        await m.createTable(focusLogRows);
      }
      if (from < 7) {
        await m.addColumn(noteRows, noteRows.pinned);
      }
      if (from < 8) {
        await m.addColumn(eventRows, eventRows.done);
      }
    },
  );
}

final Provider<AppDatabase> appDatabaseProvider = Provider<AppDatabase>((ref) {
  final AppDatabase database = AppDatabase();
  ref.onDispose(database.close);
  return database;
});
