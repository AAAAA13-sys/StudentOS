import 'event.dart';

/// One reminder notification to fire: computed here, stored and fired by
/// Android (see ReminderStore.kt).
class ReminderFire {
  const ReminderFire({
    required this.id,
    required this.fireAt,
    required this.startsAt,
    required this.title,
    required this.text,
    required this.route,
  });

  final int id;
  final DateTime fireAt;
  final DateTime startsAt;
  final String title;
  final String text;

  /// Where a tap goes: `day:yyyy-MM-dd`.
  final String route;

  Map<String, Object?> toNative() => <String, Object?>{
    'id': id,
    'fireAt': fireAt.millisecondsSinceEpoch,
    'startsAt': startsAt.millisecondsSinceEpoch,
    'title': title,
    'text': text,
    'route': route,
  };
}

String _two(int n) => n.toString().padLeft(2, '0');

String _clock(DateTime t) {
  final int h = t.hour % 12 == 0 ? 12 : t.hour % 12;
  return '$h:${_two(t.minute)} ${t.hour < 12 ? 'AM' : 'PM'}';
}

/// "Starting now", "In 15 min", "In 1 hour", "Tomorrow at 9:00 AM".
String reminderLeadText(int minutes, DateTime start, DateTime fireAt) {
  if (minutes <= 0) return 'Starting now';
  if (minutes >= 1440) {
    final DateTime fireDay = DateTime(fireAt.year, fireAt.month, fireAt.day);
    final DateTime startDay = DateTime(start.year, start.month, start.day);
    final int days = startDay.difference(fireDay).inDays;
    if (days == 1) return 'Tomorrow at ${_clock(start)}';
    return 'In ${minutes ~/ 1440} days';
  }
  if (minutes >= 60 && minutes % 60 == 0) {
    final int h = minutes ~/ 60;
    return 'In $h ${h == 1 ? 'hour' : 'hours'}';
  }
  return 'In $minutes min';
}

/// The reminders that will fire within [window] of [now], soonest first, at
/// most [max]. Recurring events contribute each occurrence in the window.
List<ReminderFire> upcomingReminders(
  List<CalendarEvent> events,
  DateTime now, {
  Duration window = const Duration(days: 14),
  int max = 64,
}) {
  final DateTime horizon = now.add(window);
  final List<ReminderFire> fires = <ReminderFire>[];
  for (final CalendarEvent event in events) {
    final int? minutes = event.reminderMinutes;
    if (event.done || minutes == null || minutes < 0) continue;
    final Duration lead = Duration(minutes: minutes);
    final String prefix = event.isExam
        ? 'Exam: '
        : (event.isAssignment ? 'Due: ' : '');
    DateTime from = now.add(lead);
    // A daily event yields at most ~15 occurrences in the window.
    for (int i = 0; i < 400; i++) {
      final DateTime? occ = event.nextOccurrence(from);
      if (occ == null) break;
      final DateTime fireAt = occ.subtract(lead);
      if (fireAt.isAfter(horizon)) break;
      if (fireAt.isAfter(now)) {
        final DateTime end = occ.add(Duration(minutes: event.durationMinutes));
        final String where = (event.location ?? '').trim();
        final String span = event.durationMinutes > 0
            ? '${_clock(occ)}–${_clock(end)}'
            : _clock(occ);
        fires.add(
          ReminderFire(
            id:
                (event.id * 1000003 + occ.millisecondsSinceEpoch ~/ 60000) &
                0x7fffffff,
            fireAt: fireAt,
            startsAt: occ,
            title: '$prefix${event.title}',
            text: <String>[
              reminderLeadText(minutes, occ, fireAt),
              span,
              if (where.isNotEmpty) where,
            ].join(' · '),
            route: 'day:${occ.year}-${_two(occ.month)}-${_two(occ.day)}',
          ),
        );
      }
      from = occ.add(const Duration(minutes: 1));
    }
  }
  fires.sort((a, b) => a.fireAt.compareTo(b.fireAt));
  return fires.take(max).toList();
}
