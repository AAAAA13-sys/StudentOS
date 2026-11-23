import 'package:intl/intl.dart';

/// Where an open task sits relative to today's calendar date.
enum TaskDueStatus { overdue, today, upcoming, anytime }

/// Valid repeat values stored in `tasks.repeat`.
abstract final class TaskRepeat {
  static const String none = 'none';
  static const String daily = 'daily';
  static const String weekly = 'weekly';
  static const String monthly = 'monthly';

  static const List<String> values = <String>[none, daily, weekly, monthly];

  static String label(String repeat) => switch (repeat) {
    daily => 'Daily',
    weekly => 'Weekly',
    monthly => 'Monthly',
    _ => 'None',
  };
}

/// One student task or to-do item.
class TaskItem {
  const TaskItem({
    required this.id,
    required this.title,
    this.notes,
    this.dueOn,
    this.repeat = TaskRepeat.none,
    this.done = false,
    this.doneAt,
    this.createdAt,
  });

  final int id;
  final String title;
  final String? notes;

  /// `YYYY-MM-DD`, or null for anytime tasks.
  final String? dueOn;

  /// `none`, `daily`, `weekly`, or `monthly`.
  final String repeat;

  final bool done;
  final DateTime? doneAt;
  final DateTime? createdAt;

  DateTime? get dueDate => parseTaskDateKey(dueOn);

  bool get isRepeating =>
      repeat == TaskRepeat.daily ||
      repeat == TaskRepeat.weekly ||
      repeat == TaskRepeat.monthly;

  /// Due status relative to [now]'s calendar date.
  TaskDueStatus dueStatus(DateTime now) {
    final DateTime? due = dueDate;
    if (due == null) return TaskDueStatus.anytime;
    final DateTime today = taskDateOnly(now);
    if (due.isBefore(today)) return TaskDueStatus.overdue;
    if (due == today) return TaskDueStatus.today;
    return TaskDueStatus.upcoming;
  }

  /// Advances [date] by one repeat cycle, clamping `'monthly'` to the last
  /// day of the next month (same semantics as `PaydaySchedule`). Returns null
  /// when [repeat] is `'none'` or unrecognized.
  DateTime? nextDueAfter(DateTime date) {
    final DateTime d = taskDateOnly(date);
    return switch (repeat) {
      TaskRepeat.daily => DateTime(d.year, d.month, d.day + 1),
      TaskRepeat.weekly => DateTime(d.year, d.month, d.day + 7),
      TaskRepeat.monthly => _clampMonthly(d.year, d.month + 1, d.day),
      _ => null,
    };
  }

  /// Next occurrence strictly after [today]'s calendar date, stepping whole
  /// cycles from the task's current [dueDate] (or [today] if unset).
  DateTime? nextDuePast(DateTime today) {
    if (!isRepeating) return null;
    final DateTime cutoff = taskDateOnly(today);
    final DateTime anchor = dueDate ?? cutoff;
    if (repeat == TaskRepeat.monthly) {
      int step = 1;
      while (true) {
        final DateTime candidate = _clampMonthly(
          anchor.year,
          anchor.month + step,
          anchor.day,
        );
        if (candidate.isAfter(cutoff)) return candidate;
        step++;
      }
    }
    DateTime candidate = nextDueAfter(anchor)!;
    while (!candidate.isAfter(cutoff)) {
      candidate = nextDueAfter(candidate)!;
    }
    return candidate;
  }

  TaskItem copyWith({
    int? id,
    String? title,
    String? notes,
    bool clearNotes = false,
    String? dueOn,
    bool clearDueOn = false,
    String? repeat,
    bool? done,
    DateTime? doneAt,
    bool clearDoneAt = false,
    DateTime? createdAt,
  }) {
    return TaskItem(
      id: id ?? this.id,
      title: title ?? this.title,
      notes: clearNotes ? null : (notes ?? this.notes),
      dueOn: clearDueOn ? null : (dueOn ?? this.dueOn),
      repeat: repeat ?? this.repeat,
      done: done ?? this.done,
      doneAt: clearDoneAt ? null : (doneAt ?? this.doneAt),
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

DateTime _clampMonthly(int year, int month, int desiredDay) {
  final int last = DateTime(year, month + 1, 0).day;
  return DateTime(year, month, desiredDay < last ? desiredDay : last);
}

DateTime taskDateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// Formats [day] as `YYYY-MM-DD`.
String formatTaskDateKey(DateTime day) {
  return '${day.year.toString().padLeft(4, '0')}-'
      '${day.month.toString().padLeft(2, '0')}-'
      '${day.day.toString().padLeft(2, '0')}';
}

/// Parses `YYYY-MM-DD` strictly to a local midnight [DateTime], or null.
DateTime? parseTaskDateKey(String? text) {
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
int taskDaysBetween(DateTime from, DateTime to) => DateTime.utc(
  to.year,
  to.month,
  to.day,
).difference(DateTime.utc(from.year, from.month, from.day)).inDays;

/// Human-readable due date label (e.g. `Overdue · Nov 18`, `Today`,
/// `Tomorrow`, `Nov 28`), or empty string if [task.dueDate] is null.
String taskDueLabel(TaskItem task, DateTime now) {
  final DateTime? due = task.dueDate;
  if (due == null) return '';
  final int days = taskDaysBetween(now, due);
  final String dateText = DateFormat('MMM d').format(due);
  if (!task.done && days < 0) return 'Overdue · $dateText';
  if (days == 0) return 'Today';
  if (days == 1) return 'Tomorrow';
  if (days == -1) return 'Yesterday';
  return dateText;
}
