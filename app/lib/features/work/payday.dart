import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/db/app_database.dart';

/// How often the pay arrives.
enum PaydayKind { none, weekly, semimonthly, monthly }

/// A payday schedule: nothing, a weekday, the 15th and the last day of the
/// month ("kinsenas/katapusan"), or one day of the month.
class PaydaySchedule {
  const PaydaySchedule._(this.kind, this.day);

  static const PaydaySchedule none = PaydaySchedule._(PaydayKind.none, 0);
  static const PaydaySchedule semimonthly = PaydaySchedule._(
    PaydayKind.semimonthly,
    0,
  );

  /// Every week on [weekday] (`DateTime.monday` to `DateTime.sunday`).
  /// Out-of-range input gives [none].
  factory PaydaySchedule.weekly(int weekday) => weekday >= 1 && weekday <= 7
      ? PaydaySchedule._(PaydayKind.weekly, weekday)
      : none;

  /// Every month on [day] (1-31); short months use their last day.
  /// Out-of-range input gives [none].
  factory PaydaySchedule.monthly(int day) =>
      day >= 1 && day <= 31 ? PaydaySchedule._(PaydayKind.monthly, day) : none;

  final PaydayKind kind;

  /// The weekday or day of month; 0 when the kind has none.
  final int day;

  bool get isSet => kind != PaydayKind.none;

  /// `none`, `weekly:5`, `semimonthly`, `monthly:25`.
  String serialize() => switch (kind) {
    PaydayKind.none => 'none',
    PaydayKind.weekly => 'weekly:$day',
    PaydayKind.semimonthly => 'semimonthly',
    PaydayKind.monthly => 'monthly:$day',
  };

  /// Reads [serialize]'s output; anything else is [none].
  static PaydaySchedule parse(String? text) {
    if (text == null) return none;
    final String value = text.trim();
    if (value == 'semimonthly') return semimonthly;
    final List<String> parts = value.split(':');
    if (parts.length != 2) return none;
    final int? n = int.tryParse(parts[1]);
    if (n == null) return none;
    if (parts[0] == 'weekly') return PaydaySchedule.weekly(n);
    if (parts[0] == 'monthly') return PaydaySchedule.monthly(n);
    return none;
  }

  @override
  bool operator ==(Object other) =>
      other is PaydaySchedule && other.kind == kind && other.day == day;

  @override
  int get hashCode => Object.hash(kind, day);
}

const List<String> _weekdayNames = <String>[
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
];

DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

int _lastDayOf(int year, int month) => DateTime(year, month + 1, 0).day;

DateTime _monthlyOn(int year, int month, int day) {
  final int last = _lastDayOf(year, month);
  return DateTime(year, month, day < last ? day : last);
}

/// The next payday on or after [now]'s date (today counts), as a date at
/// midnight. Null when no schedule is set.
DateTime? nextPayday(PaydaySchedule schedule, DateTime now) {
  final DateTime today = _dateOnly(now);
  switch (schedule.kind) {
    case PaydayKind.none:
      return null;
    case PaydayKind.weekly:
      final int ahead = (schedule.day - today.weekday + 7) % 7;
      return DateTime(today.year, today.month, today.day + ahead);
    case PaydayKind.semimonthly:
      if (today.day <= 15) return DateTime(today.year, today.month, 15);
      return DateTime(
        today.year,
        today.month,
        _lastDayOf(today.year, today.month),
      );
    case PaydayKind.monthly:
      final DateTime thisMonth = _monthlyOn(
        today.year,
        today.month,
        schedule.day,
      );
      if (!thisMonth.isBefore(today)) return thisMonth;
      return _monthlyOn(today.year, today.month + 1, schedule.day);
  }
}

/// Whether [now]'s date is a payday under [schedule].
bool isPaydayToday(PaydaySchedule schedule, DateTime now) {
  final DateTime? next = nextPayday(schedule, now);
  return next != null && next == _dateOnly(now);
}

/// `Payday today`, `Payday tomorrow`, `Payday Fri · in 3 days`,
/// `Payday Nov 30 · in 12 days`. Empty when no schedule is set.
String paydayLabel(PaydaySchedule schedule, DateTime now) {
  final DateTime? next = nextPayday(schedule, now);
  if (next == null) return '';
  final DateTime today = _dateOnly(now);
  final int days = DateTime.utc(
    next.year,
    next.month,
    next.day,
  ).difference(DateTime.utc(today.year, today.month, today.day)).inDays;
  if (days == 0) return 'Payday today';
  if (days == 1) return 'Payday tomorrow';
  final String when = days <= 6
      ? DateFormat('EEE').format(next)
      : DateFormat('MMM d').format(next);
  return 'Payday $when · in $days days';
}

/// `1st`, `2nd`, `23rd`, `11th`.
String ordinal(int n) {
  final int tens = n % 100;
  if (tens >= 11 && tens <= 13) return '${n}th';
  return switch (n % 10) {
    1 => '${n}st',
    2 => '${n}nd',
    3 => '${n}rd',
    _ => '${n}th',
  };
}

/// The schedule in words: `Every Friday`, `Not set`.
String describePayday(PaydaySchedule schedule) => switch (schedule.kind) {
  PaydayKind.none => 'Not set',
  PaydayKind.weekly => 'Every ${_weekdayNames[schedule.day - 1]}',
  PaydayKind.semimonthly => 'Every 15th and end of month',
  PaydayKind.monthly => 'Every month on the ${ordinal(schedule.day)}',
};

/// Full weekday name for `DateTime.weekday` 1-7.
String weekdayName(int weekday) => _weekdayNames[weekday - 1];

const String _key = 'payday';

/// The payday schedule, kept in the `settings` table. Starts as none and
/// switches once the stored value is read, unless the user already chose.
class PaydayController extends Notifier<PaydaySchedule> {
  bool _chosen = false;

  @override
  PaydaySchedule build() {
    unawaited(_load());
    return PaydaySchedule.none;
  }

  AppDatabase get _db => ref.read(appDatabaseProvider);

  Future<void> _load() async {
    try {
      final SettingRow? row = await (_db.select(
        _db.settingRows,
      )..where((t) => t.key.equals(_key))).getSingleOrNull();
      if (!ref.mounted || _chosen) return;
      state = PaydaySchedule.parse(row?.value);
    } catch (_) {
      // Keep the default when the setting cannot be read.
    }
  }

  Future<void> save(PaydaySchedule schedule) async {
    _chosen = true;
    state = schedule;
    try {
      await _db
          .into(_db.settingRows)
          .insertOnConflictUpdate(
            SettingRowsCompanion.insert(key: _key, value: schedule.serialize()),
          );
    } catch (_) {
      // The choice still applies for this session.
    }
  }
}

final NotifierProvider<PaydayController, PaydaySchedule> paydayProvider =
    NotifierProvider<PaydayController, PaydaySchedule>(PaydayController.new);
