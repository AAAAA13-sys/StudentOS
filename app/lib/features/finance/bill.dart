import 'package:intl/intl.dart';

import '../work/payday.dart';

/// A recurring expense bill (rent, wifi, load, tuition, subscriptions).
class Bill {
  const Bill({
    required this.id,
    required this.title,
    required this.amountCents,
    required this.category,
    required this.cadence,
    required this.nextDueOn,
    this.active = true,
    this.autoLog = false,
  });

  final int id;
  final String title;

  /// Centavos, so amounts never accumulate floating-point error.
  final int amountCents;

  final String category;

  /// `weekly:N`, `semimonthly`, or `monthly:N` (reusing [PaydaySchedule]).
  final String cadence;

  /// Next due date as `YYYY-MM-DD`.
  final String nextDueOn;

  final bool active;
  final bool autoLog;

  double get amount => amountCents / 100;

  PaydaySchedule get schedule => PaydaySchedule.parse(cadence);

  DateTime? get nextDueDate => parseDateKey(nextDueOn);

  /// True when [active] and [nextDueOn] is on or before [now]'s calendar date.
  bool isDueOnOrBefore(DateTime now) {
    if (!active) return false;
    final DateTime? due = nextDueDate;
    if (due == null) return false;
    return !due.isAfter(dateOnly(now));
  }

  /// True when [active] and [nextDueOn] equals [now]'s calendar date.
  bool isDueToday(DateTime now) {
    if (!active) return false;
    final DateTime? due = nextDueDate;
    return due != null && due == dateOnly(now);
  }

  /// True when [active] and [nextDueOn] is strictly before [now]'s calendar date.
  bool isOverdue(DateTime now) {
    if (!active) return false;
    final DateTime? due = nextDueDate;
    return due != null && due.isBefore(dateOnly(now));
  }

  Bill copyWith({
    int? id,
    String? title,
    int? amountCents,
    String? category,
    String? cadence,
    String? nextDueOn,
    bool? active,
    bool? autoLog,
  }) {
    return Bill(
      id: id ?? this.id,
      title: title ?? this.title,
      amountCents: amountCents ?? this.amountCents,
      category: category ?? this.category,
      cadence: cadence ?? this.cadence,
      nextDueOn: nextDueOn ?? this.nextDueOn,
      active: active ?? this.active,
      autoLog: autoLog ?? this.autoLog,
    );
  }
}

DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// Formats [day] as `YYYY-MM-DD`.
String formatDateKey(DateTime day) {
  return '${day.year.toString().padLeft(4, '0')}-'
      '${day.month.toString().padLeft(2, '0')}-'
      '${day.day.toString().padLeft(2, '0')}';
}

/// Parses `YYYY-MM-DD` strictly to a local midnight [DateTime], or null.
DateTime? parseDateKey(String text) {
  final RegExpMatch? match = RegExp(
    r'^(\d{4})-(\d{2})-(\d{2})$',
  ).firstMatch(text.trim());
  if (match == null) return null;
  final int year = int.parse(match.group(1)!);
  final int month = int.parse(match.group(2)!);
  final int day = int.parse(match.group(3)!);
  if (month < 1 || month > 12 || day < 1 || day > 31) return null;
  final DateTime parsed = DateTime(year, month, day);
  if (parsed.year != year || parsed.month != month || parsed.day != day) {
    return null;
  }
  return parsed;
}

/// The next due date strictly after [afterDate]'s calendar day under [schedule].
/// Falls back to one month ahead if [schedule] is unset.
DateTime nextDueAfter(PaydaySchedule schedule, DateTime afterDate) {
  final DateTime nextDay = DateTime(
    afterDate.year,
    afterDate.month,
    afterDate.day + 1,
  );
  final DateTime? computed = nextPayday(schedule, nextDay);
  if (computed != null) return computed;
  final int last = DateTime(afterDate.year, afterDate.month + 2, 0).day;
  return DateTime(
    afterDate.year,
    afterDate.month + 1,
    afterDate.day < last ? afterDate.day : last,
  );
}

/// Human-readable cadence label, e.g. `Every month on the 15th`.
String describeBillCadence(String cadence) =>
    describePayday(PaydaySchedule.parse(cadence));

/// Days from [from] to [to] using UTC midnight so DST changes never shift by 1.
int daysBetweenDates(DateTime from, DateTime to) => DateTime.utc(
  to.year,
  to.month,
  to.day,
).difference(DateTime.utc(from.year, from.month, from.day)).inDays;

/// Short relative due label, e.g. `due today`, `overdue`, `due tomorrow`,
/// `in 3 days`, or `due Nov 30`.
String billDuePhrase(Bill bill, DateTime now) {
  final DateTime? due = bill.nextDueDate;
  if (due == null) return '';
  final int days = daysBetweenDates(now, due);
  if (days < 0) {
    final int late = -days;
    return late == 1 ? '1 day overdue' : '$late days overdue';
  }
  if (days == 0) return 'due today';
  if (days == 1) return 'due tomorrow';
  if (days <= 6) return 'in $days days';
  return 'due ${DateFormat('MMM d').format(due)}';
}
