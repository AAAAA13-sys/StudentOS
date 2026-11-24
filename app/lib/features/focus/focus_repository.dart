import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/db/app_database.dart';
import 'alarm.dart';
import 'focus_plan.dart';

/// Alarms, focus settings, the running session and finished sessions.
class FocusRepository {
  const FocusRepository(this._db);

  final AppDatabase _db;

  static const String _settingsKey = 'focus_settings';
  static const String _sessionKey = 'focus_session';
  static const String _intentionKey = 'active_focus_intention';

  // Alarms.

  static Alarm _fromRow(AlarmRow r) => Alarm(
    id: r.id,
    hour: r.hour,
    minute: r.minute,
    days: r.days,
    label: r.label,
    enabled: r.enabled,
    soundUri: r.soundUri,
    soundName: r.soundName,
    volume: r.volume,
    rampSeconds: r.rampSeconds,
    volumeLock: r.volumeLock,
    vibrate: r.vibrate,
    challenge: AlarmChallenge.fromKey(r.challenge),
    challengeCount: r.challengeCount,
    difficulty: MathDifficulty.fromKey(r.difficulty),
    phrase: r.phrase,
    snoozeLimit: r.snoozeLimit,
    snoozeMinutes: r.snoozeMinutes,
    wakeCheck: r.wakeCheck,
    wakeCheckMinutes: r.wakeCheckMinutes,
  );

  static AlarmRowsCompanion _toCompanion(Alarm a) => AlarmRowsCompanion(
    hour: Value(a.hour),
    minute: Value(a.minute),
    days: Value(a.days),
    label: Value(a.label),
    enabled: Value(a.enabled),
    soundUri: Value(a.soundUri),
    soundName: Value(a.soundName),
    volume: Value(a.volume),
    rampSeconds: Value(a.rampSeconds),
    volumeLock: Value(a.volumeLock),
    vibrate: Value(a.vibrate),
    challenge: Value(a.challenge.key),
    challengeCount: Value(a.challengeCount),
    difficulty: Value(a.difficulty.key),
    phrase: Value(a.phrase),
    snoozeLimit: Value(a.snoozeLimit),
    snoozeMinutes: Value(a.snoozeMinutes),
    wakeCheck: Value(a.wakeCheck),
    wakeCheckMinutes: Value(a.wakeCheckMinutes),
  );

  /// Every alarm, earliest time of day first.
  Future<List<Alarm>> getAlarms() async {
    final List<AlarmRow> rows =
        await (_db.select(_db.alarmRows)..orderBy([
              (t) => OrderingTerm.asc(t.hour),
              (t) => OrderingTerm.asc(t.minute),
              (t) => OrderingTerm.asc(t.id),
            ]))
            .get();
    return rows.map(_fromRow).toList();
  }

  Future<Alarm> createAlarm(Alarm alarm) async {
    final int id = await _db.into(_db.alarmRows).insert(_toCompanion(alarm));
    return alarm.copyWith(id: id);
  }

  Future<void> updateAlarm(Alarm alarm) => (_db.update(
    _db.alarmRows,
  )..where((t) => t.id.equals(alarm.id))).write(_toCompanion(alarm));

  Future<void> deleteAlarm(int id) =>
      (_db.delete(_db.alarmRows)..where((t) => t.id.equals(id))).go();

  /// Turns off one-time alarms that have already rung.
  Future<void> disableAlarms(Iterable<int> ids) async {
    if (ids.isEmpty) return;
    await (_db.update(_db.alarmRows)
          ..where((t) => t.id.isIn(ids) & t.days.equals(0)))
        .write(const AlarmRowsCompanion(enabled: Value(false)));
  }

  // Focus.

  Future<String?> _setting(String key) async => (await (_db.select(
    _db.settingRows,
  )..where((t) => t.key.equals(key))).getSingleOrNull())?.value;

  Future<void> _put(String key, String value) => _db
      .into(_db.settingRows)
      .insertOnConflictUpdate(
        SettingRowsCompanion.insert(key: key, value: value),
      );

  Future<FocusSettings> getSettings() async {
    final String? raw = await _setting(_settingsKey);
    if (raw == null) return const FocusSettings();
    try {
      return FocusSettings.fromJson(
        (jsonDecode(raw) as Map<Object?, Object?>).cast(),
      );
    } catch (_) {
      return const FocusSettings();
    }
  }

  Future<void> saveSettings(FocusSettings settings) =>
      _put(_settingsKey, jsonEncode(settings.toJson()));

  Future<FocusSession?> getSession() async =>
      FocusSession.decode(await _setting(_sessionKey));

  Future<void> saveSession(FocusSession? session) => session == null
      ? (_db.delete(
          _db.settingRows,
        )..where((t) => t.key.equals(_sessionKey))).go()
      : _put(_sessionKey, session.encode());

  Future<FocusIntention?> getIntention() async =>
      FocusIntention.tryParse(await _setting(_intentionKey));

  Future<void> saveIntention(FocusIntention? intention) => intention == null
      ? (_db.delete(
          _db.settingRows,
        )..where((t) => t.key.equals(_intentionKey))).go()
      : _put(_intentionKey, intention.toJsonString());

  Future<void> logSession({
    required DateTime startedAt,
    required DateTime endedAt,
    required int focusMs,
    required int rounds,
    required bool endedEarly,
    FocusIntention? intention,
  }) => _db
      .into(_db.focusLogRows)
      .insert(
        FocusLogRowsCompanion.insert(
          startedAt: startedAt,
          endedAt: endedAt,
          focusMs: focusMs,
          rounds: rounds,
          endedEarly: Value(endedEarly),
          targetType: Value(intention?.type.key),
          targetId: Value(intention?.id),
          targetLabel: Value(intention?.label),
        ),
      );

  static FocusLog _logFromRow(FocusLogRow row) {
    final FocusTargetType? type = FocusTargetType.fromKey(row.targetType);
    final String? label = row.targetLabel?.trim();
    final FocusIntention? intention =
        type != null && label != null && label.isNotEmpty
        ? FocusIntention(type: type, id: row.targetId, label: label)
        : null;
    return FocusLog(
      id: row.id,
      startedAt: row.startedAt,
      endedAt: row.endedAt,
      focusMs: row.focusMs,
      rounds: row.rounds,
      endedEarly: row.endedEarly,
      intention: intention,
    );
  }

  Future<FocusLog?> latestLog() async {
    final FocusLogRow? row =
        await (_db.select(_db.focusLogRows)
              ..orderBy([
                (t) => OrderingTerm.desc(t.endedAt),
                (t) => OrderingTerm.desc(t.id),
              ])
              ..limit(1))
            .getSingleOrNull();
    return row == null ? null : _logFromRow(row);
  }

  /// Focus sessions whose `endedAt` falls in `[start, end)`, newest first.
  Future<List<FocusLog>> getLogsInRange(DateTime start, DateTime end) async {
    final List<FocusLogRow> rows =
        await (_db.select(_db.focusLogRows)
              ..where(
                (t) =>
                    t.endedAt.isBiggerOrEqualValue(start) &
                    t.endedAt.isSmallerThanValue(end),
              )
              ..orderBy([
                (t) => OrderingTerm.desc(t.endedAt),
                (t) => OrderingTerm.desc(t.id),
              ]))
            .get();
    return rows.map(_logFromRow).toList();
  }

  /// Focus time grouped by intention label for sessions ending on or after
  /// [since], longest duration first.
  Future<List<({String label, int focusMs})>> todayByTarget(
    DateTime since,
  ) async {
    final List<FocusLogRow> rows = await (_db.select(
      _db.focusLogRows,
    )..where((t) => t.endedAt.isBiggerOrEqualValue(since))).get();
    final Map<String, int> totals = <String, int>{};
    for (final FocusLogRow row in rows) {
      final String? label = row.targetLabel?.trim();
      if (label == null || label.isEmpty || row.focusMs <= 0) continue;
      totals[label] = (totals[label] ?? 0) + row.focusMs;
    }
    final List<({String label, int focusMs})> out =
        <({String label, int focusMs})>[
          for (final MapEntry<String, int> entry in totals.entries)
            (label: entry.key, focusMs: entry.value),
        ];
    out.sort((a, b) {
      final int byMs = b.focusMs.compareTo(a.focusMs);
      return byMs != 0 ? byMs : a.label.compareTo(b.label);
    });
    return out;
  }

  /// Focus time and finished rounds of sessions that ended on or after
  /// [from].
  Future<({int focusMs, int rounds, int sessions})> totalsSince(
    DateTime from,
  ) async {
    final List<FocusLogRow> rows = await (_db.select(
      _db.focusLogRows,
    )..where((t) => t.endedAt.isBiggerOrEqualValue(from))).get();
    return (
      focusMs: rows.fold(0, (int s, FocusLogRow r) => s + r.focusMs),
      rounds: rows.fold(0, (int s, FocusLogRow r) => s + r.rounds),
      sessions: rows.length,
    );
  }
}

final Provider<FocusRepository> focusRepositoryProvider =
    Provider<FocusRepository>(
      (ref) => FocusRepository(ref.watch(appDatabaseProvider)),
    );
