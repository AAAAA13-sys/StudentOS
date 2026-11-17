import '../calendar/event.dart';
import 'alarm.dart';

/// How far before a first event an alarm still counts as "for it".
const Duration wakeWindow = Duration(hours: 3);

/// How long before the event the suggested alarm rings.
const Duration suggestedLead = Duration(minutes: 60);

/// A first event of the day that no alarm wakes the owner up for.
typedef AlarmGap = ({CalendarEvent event, DateTime start, bool isToday});

/// The first event the owner could oversleep and the alarm that is missing,
/// or null when there is no such event or an enabled alarm rings between
/// [wakeWindow] before it and its start.
///
/// Today counts while its first event is still more than [suggestedLead]
/// away, otherwise tomorrow's first event is checked. Done events, all-day
/// events and plain assignments (deadlines, not places to be) are ignored.
AlarmGap? alarmGapFor({
  required List<CalendarEvent> events,
  required List<Alarm> alarms,
  required DateTime now,
}) {
  final DateTime today = DateTime(now.year, now.month, now.day);
  final DateTime tomorrow = DateTime(now.year, now.month, now.day + 1);

  ({CalendarEvent event, DateTime start})? firstOn(DateTime day) {
    ({CalendarEvent event, DateTime start})? first;
    for (final CalendarEvent e in events) {
      if (e.done || e.isAllDay || (e.isAssignment && !e.isExam)) continue;
      if (!e.occursOn(day)) continue;
      final DateTime s = e.startsAt.toLocal();
      final DateTime start = DateTime(
        day.year,
        day.month,
        day.day,
        s.hour,
        s.minute,
      );
      if (first == null || start.isBefore(first.start)) {
        first = (event: e, start: start);
      }
    }
    return first;
  }

  var target = firstOn(today);
  bool isToday = true;
  if (target == null || !target.start.subtract(suggestedLead).isAfter(now)) {
    target = firstOn(tomorrow);
    isToday = false;
  }
  if (target == null) return null;

  final DateTime start = target.start;
  final DateTime windowStart = start.subtract(wakeWindow);
  for (final Alarm a in alarms) {
    if (!a.enabled) continue;
    final DateTime ring = DateTime(
      start.year,
      start.month,
      start.day,
      a.hour,
      a.minute,
    );
    if (ring.isBefore(windowStart) || ring.isAfter(start)) continue;
    if (!ring.isAfter(now)) continue;
    final bool rings = a.repeats
        ? a.ringsOn(ring.weekday)
        : a.nextRing(now) == ring;
    if (rings) return null;
  }
  return (event: target.event, start: start, isToday: isToday);
}

/// An unsaved one-time alarm [suggestedLead] before [gap]'s event, ready for
/// the alarm editor, which can still add repeat days.
Alarm suggestedAlarm(AlarmGap gap) {
  final DateTime ring = gap.start.subtract(suggestedLead);
  return Alarm(
    id: 0,
    hour: ring.hour,
    minute: ring.minute,
    label: gap.event.title,
  );
}
