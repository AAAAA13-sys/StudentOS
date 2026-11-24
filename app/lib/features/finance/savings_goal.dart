import 'dart:math' as math;

import 'package:intl/intl.dart';

/// A personal savings pocket / goal pot inside Finance.
///
/// Goals are personal allocation buckets and stay completely isolated from
/// cashflow [Transaction]s and monthly spending totals.
class SavingsGoal {
  const SavingsGoal({
    required this.id,
    required this.title,
    required this.targetCents,
    this.savedCents = 0,
    this.targetDate,
    required this.createdAt,
  });

  final int id;
  final String title;

  /// Target amount in centavos.
  final int targetCents;

  /// Stashed amount in centavos.
  final int savedCents;

  /// Optional target date as `YYYY-MM-DD`.
  final String? targetDate;

  final DateTime createdAt;

  double get targetAmount => targetCents / 100;

  double get savedAmount => savedCents / 100;

  int get remainingCents => math.max(0, targetCents - savedCents);

  bool get isReached => targetCents > 0 && savedCents >= targetCents;

  double get progress =>
      targetCents <= 0 ? 0.0 : (savedCents / targetCents).clamp(0.0, 1.0);

  String get percentLabel => '${(progress * 100).round()}%';

  DateTime? get targetDateTime => parseGoalDateKey(targetDate);

  /// Calendar-day delta from [today] to [targetDateTime], or null when unset.
  /// Returns 0 when due today, positive when ahead, negative when past.
  int? daysLeft(DateTime today) {
    final DateTime? due = targetDateTime;
    if (due == null) return null;
    return goalDaysBetween(today, due);
  }

  SavingsGoal copyWith({
    int? id,
    String? title,
    int? targetCents,
    int? savedCents,
    String? targetDate,
    bool clearTargetDate = false,
    DateTime? createdAt,
  }) {
    return SavingsGoal(
      id: id ?? this.id,
      title: title ?? this.title,
      targetCents: targetCents ?? this.targetCents,
      savedCents: savedCents ?? this.savedCents,
      targetDate: clearTargetDate ? null : (targetDate ?? this.targetDate),
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

DateTime goalDateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// Formats [day] as `YYYY-MM-DD`.
String formatGoalDateKey(DateTime day) {
  return '${day.year.toString().padLeft(4, '0')}-'
      '${day.month.toString().padLeft(2, '0')}-'
      '${day.day.toString().padLeft(2, '0')}';
}

/// Parses `YYYY-MM-DD` strictly to a local midnight [DateTime], or null.
DateTime? parseGoalDateKey(String? text) {
  if (text == null) return null;
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

/// Calendar days from [from] to [to], using UTC midnight to avoid DST skew.
int goalDaysBetween(DateTime from, DateTime to) => DateTime.utc(
  to.year,
  to.month,
  to.day,
).difference(DateTime.utc(from.year, from.month, from.day)).inDays;

/// Human-readable target date label (`Today`, `Tomorrow`, `MMM d`, or
/// `Overdue · MMM d`), or empty string when [goal.targetDateTime] is null.
String goalTargetDateLabel(SavingsGoal goal, DateTime now) {
  final DateTime? due = goal.targetDateTime;
  if (due == null) return '';
  final int days = goalDaysBetween(now, due);
  final String dateText = DateFormat('MMM d').format(due);
  if (!goal.isReached && days < 0) return 'Overdue · $dateText';
  if (days == 0) return 'Today';
  if (days == 1) return 'Tomorrow';
  return dateText;
}
