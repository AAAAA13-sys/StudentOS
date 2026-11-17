import '../../core/checklist.dart';

class CalendarEvent {
  const CalendarEvent({
    required this.id,
    required this.title,
    required this.startsAt,
    this.durationMinutes = 60,
    this.location,
    this.notes,
    this.recurrence = 'none',
    this.recurrenceUntil,
    this.reminderMinutes,
    this.noteId,
    this.done = false,
  });

  final int id;
  final String title;
  final DateTime startsAt;
  final int durationMinutes;
  final String? location;
  final String? notes;
  final String recurrence;
  final String? recurrenceUntil;
  final int? reminderMinutes;

  /// Id of the attached note, if any.
  final int? noteId;

  /// An exam or assignment marked done; it stops counting down and drops off
  /// the home widget. For a repeating event this applies to the series.
  final bool done;

  CalendarEvent withIds({required int id, required int? noteId}) {
    return CalendarEvent(
      id: id,
      title: title,
      startsAt: startsAt,
      durationMinutes: durationMinutes,
      location: location,
      notes: notes,
      recurrence: recurrence,
      recurrenceUntil: recurrenceUntil,
      reminderMinutes: reminderMinutes,
      noteId: noteId,
      done: done,
    );
  }

  CalendarEvent copyWith({
    int? id,
    String? title,
    DateTime? startsAt,
    int? durationMinutes,
    String? location,
    String? notes,
    String? recurrence,
    String? recurrenceUntil,
    int? reminderMinutes,
    int? noteId,
    bool? done,
  }) {
    return CalendarEvent(
      id: id ?? this.id,
      title: title ?? this.title,
      startsAt: startsAt ?? this.startsAt,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      location: location ?? this.location,
      notes: notes ?? this.notes,
      recurrence: recurrence ?? this.recurrence,
      recurrenceUntil: recurrenceUntil ?? this.recurrenceUntil,
      reminderMinutes: reminderMinutes ?? this.reminderMinutes,
      noteId: noteId ?? this.noteId,
      done: done ?? this.done,
    );
  }

  // Whole words only, so "Latest" or "Finalize" is not taken for an exam.
  static final RegExp _examWords = RegExp(
    r'\b(exams?|quiz(zes)?|midterms?|finals?|tests?)\b',
    caseSensitive: false,
  );
  static final RegExp _assignmentWords = RegExp(
    r'\b(assignments?|due|deadlines?|projects?|papers?|homework)\b',
    caseSensitive: false,
  );

  /// The lines the editor adds to [notes] to record the chosen event type.
  static const String examTag = '#exam';
  static const String assignmentTag = '#assignment';

  bool get isExam =>
      _examWords.hasMatch(title) ||
      (notes?.toLowerCase().contains(examTag) ?? false);

  bool get isAssignment =>
      _assignmentWords.hasMatch(title) ||
      (notes?.toLowerCase().contains(assignmentTag) ?? false);

  /// [notes] with the type tag lines removed and the tag for [type] (`exam`,
  /// `assignment`, or anything else for none) added, so the type can be
  /// changed back. Null when nothing is left.
  static String? notesWithType(String? notes, String type) {
    final List<String> lines = <String>[
      for (final String line in (notes ?? '').split('\n'))
        if (line.trim().toLowerCase() != examTag &&
            line.trim().toLowerCase() != assignmentTag)
          line,
    ];
    final String body = lines.join('\n').trim();
    final String? tag = type == 'exam'
        ? examTag
        : (type == 'assignment' ? assignmentTag : null);
    if (tag == null) return body.isEmpty ? null : body;
    return body.isEmpty ? tag : '$body\n$tag';
  }

  /// Whether this lasts the whole day: starts at midnight and runs 24 hours
  /// or more (what an imported all-day event looks like).
  bool get isAllDay {
    final DateTime start = startsAt.toLocal();
    return durationMinutes >= 1440 && start.hour == 0 && start.minute == 0;
  }

  /// Relative countdown string from [now] (e.g. 'Today', 'Tomorrow', 'in 3
  /// days') to the occurrence on day [on], or to the next occurrence from
  /// today when [on] is null. Null if not an exam/assignment, done, more than
  /// 14 days away or in the past.
  String? countdownBadge(DateTime now, {DateTime? on}) {
    if (done || (!isExam && !isAssignment)) return null;
    final DateTime today = DateTime(now.year, now.month, now.day);
    final DateTime? occurrence = on ?? nextOccurrence(today);
    if (occurrence == null) return null;
    final DateTime day = DateTime(
      occurrence.year,
      occurrence.month,
      occurrence.day,
    );
    final int diff = day.difference(today).inDays;
    if (diff < 0 || diff > 14) return null;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Tomorrow';
    return 'in $diff days';
  }

  /// Parses markdown task items from [notes] (e.g. `- [ ] Item` or `[ ] Item`).
  List<({String text, bool done})> get checklistItems => parseChecklist(notes);

  /// Toggles the checklist item at [targetIndex] between done and undone.
  CalendarEvent toggleChecklistItem(int targetIndex) {
    final String? current = notes;
    if (current == null || current.isEmpty) return this;
    return copyWith(notes: toggleChecklistLine(current, targetIndex));
  }

  /// Whether an occurrence of this event falls on the calendar day [date].
  bool occursOn(DateTime date) {
    final DateTime start = startsAt.toLocal();
    final DateTime startDay = DateTime(start.year, start.month, start.day);
    final DateTime day = DateTime(date.year, date.month, date.day);

    if (day == startDay) return true;
    if (day.isBefore(startDay) || recurrence == 'none') return false;

    final DateTime? until = recurrenceUntil == null
        ? null
        : DateTime.tryParse(recurrenceUntil!);
    if (until != null &&
        day.isAfter(DateTime(until.year, until.month, until.day))) {
      return false;
    }

    return switch (recurrence) {
      'daily' => true,
      'weekly' => start.weekday == day.weekday,
      'monthly' => start.day == day.day,
      _ => false,
    };
  }

  /// The first time this event starts at or after [now], following its
  /// recurrence, or null when it is over.
  DateTime? nextOccurrence(DateTime now) {
    final DateTime start = startsAt.toLocal();
    if (!start.isBefore(now)) {
      return start;
    }
    if (recurrence == 'none') {
      return null;
    }

    DateTime at(int step) {
      switch (recurrence) {
        case 'daily':
          return DateTime(
            start.year,
            start.month,
            start.day + step,
            start.hour,
            start.minute,
          );
        case 'weekly':
          return DateTime(
            start.year,
            start.month,
            start.day + 7 * step,
            start.hour,
            start.minute,
          );
        default:
          // Monthly, clamped to the month's last day (Jan 31 -> Feb 28/29).
          final DateTime first = DateTime(start.year, start.month + step);
          final int lastDay = DateTime(first.year, first.month + 1, 0).day;
          return DateTime(
            first.year,
            first.month,
            start.day > lastDay ? lastDay : start.day,
            start.hour,
            start.minute,
          );
      }
    }

    final int elapsedDays = now.difference(start).inDays;
    int step = switch (recurrence) {
      'daily' => elapsedDays - 1,
      'weekly' => elapsedDays ~/ 7 - 1,
      _ => (now.year - start.year) * 12 + now.month - start.month - 1,
    };
    if (step < 1) {
      step = 1;
    }
    while (at(step).isBefore(now)) {
      step++;
    }
    final DateTime next = at(step);

    final DateTime? until = recurrenceUntil == null
        ? null
        : DateTime.tryParse(recurrenceUntil!);
    if (until != null &&
        !next.isBefore(DateTime(until.year, until.month, until.day + 1))) {
      return null;
    }
    return next;
  }
}

/// A length in minutes as people say it: `45 min`, `1 h 30 min`, `3 h`,
/// `All day` (a multiple of 24 h is shown as days).
String formatEventDuration(int minutes) {
  if (minutes >= 1440 && minutes % 1440 == 0) {
    final int days = minutes ~/ 1440;
    return days == 1 ? 'All day' : '$days days';
  }
  final int h = minutes ~/ 60;
  final int m = minutes % 60;
  if (h == 0) return '$m min';
  if (m == 0) return '$h h';
  return '$h h $m min';
}
