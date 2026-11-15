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

    final DateTime? until =
        recurrenceUntil == null ? null : DateTime.tryParse(recurrenceUntil!);
    if (until != null &&
        !next.isBefore(DateTime(until.year, until.month, until.day + 1))) {
      return null;
    }
    return next;
  }
}
