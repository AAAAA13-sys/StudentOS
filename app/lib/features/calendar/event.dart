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
    );
  }

  bool get isExam {
    final String lower = title.toLowerCase();
    final String notesLower = notes?.toLowerCase() ?? '';
    return lower.contains('exam') ||
        lower.contains('quiz') ||
        lower.contains('midterm') ||
        lower.contains('final') ||
        lower.contains('test') ||
        notesLower.contains('#exam');
  }

  bool get isAssignment {
    final String lower = title.toLowerCase();
    final String notesLower = notes?.toLowerCase() ?? '';
    return lower.contains('assignment') ||
        lower.contains('due') ||
        lower.contains('deadline') ||
        lower.contains('project') ||
        lower.contains('paper') ||
        lower.contains('homework') ||
        notesLower.contains('#assignment');
  }

  /// Relative countdown string from [now] (e.g. 'Today', 'Tomorrow', 'in 3 days').
  /// Null if not an exam/assignment or more than 14 days away or in the past.
  String? countdownBadge(DateTime now) {
    if (!isExam && !isAssignment) return null;
    final DateTime today = DateTime(now.year, now.month, now.day);
    final DateTime start = startsAt.toLocal();
    final DateTime startDay = DateTime(start.year, start.month, start.day);
    final int diff = startDay.difference(today).inDays;
    if (diff < 0 || diff > 14) return null;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Tomorrow';
    return 'in $diff days';
  }

  /// Parses markdown task items from [notes] (e.g. `- [ ] Item` or `[ ] Item`).
  List<({String text, bool done})> get checklistItems {
    if (notes == null || notes!.isEmpty) return const <({String text, bool done})>[];
    final List<({String text, bool done})> items = <({String text, bool done})>[];
    for (final String rawLine in notes!.split('\n')) {
      final String trimmed = rawLine.trim();
      if (trimmed.startsWith('- [ ] ') || trimmed.startsWith('[ ] ')) {
        final String text = trimmed.startsWith('- [ ] ')
            ? trimmed.substring(6).trim()
            : trimmed.substring(4).trim();
        if (text.isNotEmpty) items.add((text: text, done: false));
      } else if (trimmed.startsWith('- [x] ') || trimmed.startsWith('[x] ') ||
                 trimmed.startsWith('- [X] ') || trimmed.startsWith('[X] ')) {
        final String text = (trimmed.startsWith('- [x] ') || trimmed.startsWith('- [X] '))
            ? trimmed.substring(6).trim()
            : trimmed.substring(4).trim();
        if (text.isNotEmpty) items.add((text: text, done: true));
      }
    }
    return items;
  }

  /// Toggles the checklist item at [targetIndex] between done and undone.
  CalendarEvent toggleChecklistItem(int targetIndex) {
    if (notes == null || notes!.isEmpty) return this;
    final List<String> lines = notes!.split('\n');
    int currentIndex = 0;
    for (int i = 0; i < lines.length; i++) {
      final String line = lines[i];
      final String trimmed = line.trim();
      final bool isUnchecked = trimmed.startsWith('- [ ] ') || trimmed.startsWith('[ ] ');
      final bool isChecked = trimmed.startsWith('- [x] ') || trimmed.startsWith('[x] ') ||
                             trimmed.startsWith('- [X] ') || trimmed.startsWith('[X] ');
      if (isUnchecked || isChecked) {
        if (currentIndex == targetIndex) {
          if (isUnchecked) {
            if (line.contains('- [ ]')) {
              lines[i] = line.replaceFirst('- [ ]', '- [x]');
            } else {
              lines[i] = line.replaceFirst('[ ]', '[x]');
            }
          } else {
            if (line.contains('- [x]')) {
              lines[i] = line.replaceFirst('- [x]', '- [ ]');
            } else if (line.contains('- [X]')) {
              lines[i] = line.replaceFirst('- [X]', '- [ ]');
            } else if (line.contains('[X]')) {
              lines[i] = line.replaceFirst('[X]', '[ ]');
            } else {
              lines[i] = line.replaceFirst('[x]', '[ ]');
            }
          }
          break;
        }
        currentIndex++;
      }
    }
    return copyWith(notes: lines.join('\n'));
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
