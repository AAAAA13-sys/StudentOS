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

  /// 2 added work shifts, 3 phone use, 4 alarms and focus sessions. Older
  /// files restore with none of what they lack.
  static const int formatVersion = 4;

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
    final List<SettingRow> settings;
    final List<ShiftRow> shifts;
    final List<PhoneDayRow> phoneDays;
    final List<PhoneAppDayRow> phoneApps;
    final List<AlarmRow> alarms;
    final List<FocusLogRow> focusLogs;
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
