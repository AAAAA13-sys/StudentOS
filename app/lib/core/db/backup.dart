import 'dart:convert';

import 'package:drift/drift.dart';
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

  /// 2 added work shifts, 3 phone use, 4 alarms and focus sessions,
  /// 5 recurring bills. Older files restore with none of what they lack.
  static const int formatVersion = 5;

  /// Settings key holding when a backup was last saved (UTC ISO 8601).
  static const String lastBackupKey = 'last_backup_at';

  /// Records that a backup was just saved.
  Future<void> markBackedUp(DateTime at) {
    return _db
        .into(_db.settingRows)
        .insertOnConflictUpdate(
          SettingRowsCompanion.insert(
            key: lastBackupKey,
            value: at.toUtc().toIso8601String(),
          ),
        );
  }

  /// When a backup was last saved, or null when never.
  Future<DateTime?> lastBackupAt() async {
    final SettingRow? row = await (_db.select(
      _db.settingRows,
    )..where((t) => t.key.equals(lastBackupKey))).getSingleOrNull();
    return row == null ? null : DateTime.tryParse(row.value)?.toLocal();
  }

  /// True when there is anything worth backing up.
  Future<bool> hasData() async {
    return (await _db.select(_db.eventRows).get()).isNotEmpty ||
        (await _db.select(_db.transactionRows).get()).isNotEmpty ||
        (await _db.select(_db.noteRows).get()).isNotEmpty ||
        (await _db.select(_db.billRows).get()).isNotEmpty ||
        (await _db.select(_db.shiftRows).get()).isNotEmpty ||
        (await _db.select(_db.alarmRows).get()).isNotEmpty;
  }

  Future<String> exportJson() async {
    final List<EventRow> events = await _db.select(_db.eventRows).get();
    final List<TransactionRow> transactions = await _db
        .select(_db.transactionRows)
        .get();
    final List<NoteRow> notes = await _db.select(_db.noteRows).get();
    final List<SettingRow> settings = await _db.select(_db.settingRows).get();
    final List<ShiftRow> shifts = await _db.select(_db.shiftRows).get();
    final List<PhoneDayRow> phoneDays = await _db
        .select(_db.phoneDayRows)
        .get();
    final List<PhoneAppDayRow> phoneApps = await _db
        .select(_db.phoneAppDayRows)
        .get();
    final List<AlarmRow> alarms = await _db.select(_db.alarmRows).get();
    final List<FocusLogRow> focusLogs = await _db
        .select(_db.focusLogRows)
        .get();
    final List<BillRow> bills = await _db.select(_db.billRows).get();

    return const JsonEncoder.withIndent('  ').convert(<String, Object?>{
      'app': 'studentos',
      'format': formatVersion,
      'exported_at': DateTime.now().toUtc().toIso8601String(),
      'events': <Object?>[for (final EventRow row in events) row.toJson()],
      'transactions': <Object?>[
        for (final TransactionRow row in transactions) row.toJson(),
      ],
      'notes': <Object?>[for (final NoteRow row in notes) row.toJson()],
      'settings': <Object?>[
        for (final SettingRow row in settings) row.toJson(),
      ],
      'shifts': <Object?>[for (final ShiftRow row in shifts) row.toJson()],
      'phone_days': <Object?>[
        for (final PhoneDayRow row in phoneDays) row.toJson(),
      ],
      'phone_app_days': <Object?>[
        for (final PhoneAppDayRow row in phoneApps) row.toJson(),
      ],
      'alarms': <Object?>[for (final AlarmRow row in alarms) row.toJson()],
      'focus_logs': <Object?>[
        for (final FocusLogRow row in focusLogs) row.toJson(),
      ],
      'bills': <Object?>[for (final BillRow row in bills) row.toJson()],
    });
  }

  /// Replaces everything in the database with the contents of [json].
  /// Nothing is changed when the file cannot be read.
  Future<({int events, int transactions, int notes})> restoreJson(
    String json,
  ) async {
    final counts = await restoreJsonWithCounts(json);
    return (
      events: counts.events,
      transactions: counts.transactions,
      notes: counts.notes,
    );
  }

  /// Replaces everything in the database with the contents of [json] and
  /// returns counts for every user-facing record type.
  Future<
    ({
      int events,
      int transactions,
      int notes,
      int bills,
      int shifts,
      int alarms,
    })
  >
  restoreJsonWithCounts(String json) async {
    final List<EventRow> events;
    final List<TransactionRow> transactions;
    final List<NoteRow> notes;
    final List<SettingRow> settings;
    final List<ShiftRow> shifts;
    final List<PhoneDayRow> phoneDays;
    final List<PhoneAppDayRow> phoneApps;
    final List<AlarmRow> alarms;
    final List<FocusLogRow> focusLogs;
    final List<BillRow> bills;
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
      // Backups made before events could be ticked off have no `done` key.
      events = rows('events')
          .map(
            (Map<String, dynamic> m) =>
                EventRow.fromJson(<String, dynamic>{'done': false, ...m}),
          )
          .toList();
      transactions = rows('transactions').map(TransactionRow.fromJson).toList();
      // Backups made before pinning have no `pinned` key.
      notes = rows('notes')
          .map(
            (Map<String, dynamic> m) =>
                NoteRow.fromJson(<String, dynamic>{'pinned': false, ...m}),
          )
          .toList();
      // Backups made before settings existed have no such list.
      settings = decoded['settings'] == null
          ? <SettingRow>[]
          : rows('settings').map(SettingRow.fromJson).toList();
      shifts = decoded['shifts'] == null
          ? <ShiftRow>[]
          : rows('shifts').map(ShiftRow.fromJson).toList();
      phoneDays = decoded['phone_days'] == null
          ? <PhoneDayRow>[]
          : rows('phone_days').map(PhoneDayRow.fromJson).toList();
      phoneApps = decoded['phone_app_days'] == null
          ? <PhoneAppDayRow>[]
          : rows('phone_app_days').map(PhoneAppDayRow.fromJson).toList();
      alarms = decoded['alarms'] == null
          ? <AlarmRow>[]
          : rows('alarms').map(AlarmRow.fromJson).toList();
      focusLogs = decoded['focus_logs'] == null
          ? <FocusLogRow>[]
          : rows('focus_logs').map(FocusLogRow.fromJson).toList();
      bills = decoded['bills'] == null
          ? <BillRow>[]
          : rows('bills')
                .map(
                  (Map<String, dynamic> m) => BillRow.fromJson(
                    <String, dynamic>{
                      'active': true,
                      'autoLog': false,
                      ...m,
                    },
                  ),
                )
                .toList();
    } on BackupFormatException {
      rethrow;
    } catch (_) {
      throw const BackupFormatException('The backup file is damaged.');
    }

    await _db.transaction(() async {
      await _db.delete(_db.eventRows).go();
      await _db.delete(_db.transactionRows).go();
      await _db.delete(_db.noteRows).go();
      await _db.delete(_db.settingRows).go();
      await _db.delete(_db.shiftRows).go();
      await _db.delete(_db.phoneDayRows).go();
      await _db.delete(_db.phoneAppDayRows).go();
      await _db.delete(_db.alarmRows).go();
      await _db.delete(_db.focusLogRows).go();
      await _db.delete(_db.billRows).go();
      await _db.batch((batch) {
        batch.insertAll(_db.eventRows, events);
        batch.insertAll(_db.transactionRows, transactions);
        batch.insertAll(_db.noteRows, notes);
        batch.insertAll(_db.settingRows, settings);
        batch.insertAll(_db.shiftRows, shifts);
        batch.insertAll(_db.phoneDayRows, phoneDays);
        batch.insertAll(_db.phoneAppDayRows, phoneApps);
        batch.insertAll(_db.alarmRows, alarms);
        batch.insertAll(_db.focusLogRows, focusLogs);
        batch.insertAll(_db.billRows, bills);
      });
    });
    return (
      events: events.length,
      transactions: transactions.length,
      notes: notes.length,
      bills: bills.length,
      shifts: shifts.length,
      alarms: alarms.length,
    );
  }
}

final Provider<BackupService> backupServiceProvider = Provider<BackupService>(
  (ref) => BackupService(ref.watch(appDatabaseProvider)),
);

/// After this many days without a backup the menu icon shows a dot.
const int backupStaleDays = 14;

int _daysBetween(DateTime from, DateTime to) => DateTime(
  to.year,
  to.month,
  to.day,
).difference(DateTime(from.year, from.month, from.day)).inDays;

/// `today`, `yesterday`, `3 days ago` or `never`, by calendar day.
String backupAgeLabel(DateTime? last, DateTime now) {
  if (last == null) return 'never';
  final int days = _daysBetween(last, now);
  if (days <= 0) return 'today';
  if (days == 1) return 'yesterday';
  return '$days days ago';
}

/// A dot on the menu icon: never backed up (with data), or [backupStaleDays]
/// days or more ago.
bool backupNeedsAttention(
  DateTime? last,
  DateTime now, {
  required bool hasData,
}) {
  if (last == null) return hasData;
  return _daysBetween(last, now) >= backupStaleDays;
}

/// What the drawer and the menu icon need to know about backups.
typedef BackupStatus = ({DateTime? last, bool hasData});

final StreamProvider<BackupStatus> backupStatusProvider =
    StreamProvider.autoDispose<BackupStatus>((Ref ref) async* {
      final AppDatabase db = ref.watch(appDatabaseProvider);
      final BackupService service = ref.watch(backupServiceProvider);
      Future<BackupStatus> read() async => (
        last: await service.lastBackupAt(),
        hasData: await service.hasData(),
      );
      yield await read();
      await for (final Set<TableUpdate> _ in db.tableUpdates(
        TableUpdateQuery.onAllTables(<TableInfo<Table, Object?>>[
          db.eventRows,
          db.transactionRows,
          db.noteRows,
          db.billRows,
          db.shiftRows,
          db.alarmRows,
          db.settingRows,
        ]),
      )) {
        yield await read();
      }
    });
