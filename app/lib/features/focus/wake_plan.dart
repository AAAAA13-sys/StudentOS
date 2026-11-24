import '../calendar/event.dart';
import '../work/shift.dart';
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

/// A first class, event, or work shift of the day that no alarm wakes the
/// owner up for.
typedef CommitmentAlarmGap = ({
  String title,
  DateTime start,
  bool isToday,
  bool isShift,
});

/// Like [alarmGapFor], considering both open timed [CalendarEvent]s and
/// unpaid, unworked [Shift]s starting within the next 24 hours.
CommitmentAlarmGap? alarmGapForCommitments({
  required List<CalendarEvent> events,
  List<Shift> shifts = const <Shift>[],
  required List<Alarm> alarms,
  required DateTime now,
}) {
  final DateTime today = DateTime(now.year, now.month, now.day);
  final DateTime tomorrow = DateTime(now.year, now.month, now.day + 1);
  final DateTime horizon = now.add(const Duration(hours: 24));

  ({String title, DateTime start, bool isShift})? firstOn(DateTime day) {
    ({String title, DateTime start, bool isShift})? first;
    void consider(String title, DateTime start, bool isShift) {
      if (first == null || start.isBefore(first!.start)) {
        first = (title: title, start: start, isShift: isShift);
      }
    }

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
      consider(e.title, start, false);
    }

    for (final Shift s in shifts) {
      if (s.paid || s.isWorked(now)) continue;
      final DateTime start = s.startsAt.toLocal();
      if (start.isBefore(now) || start.isAfter(horizon)) continue;
      if (start.year == day.year &&
          start.month == day.month &&
          start.day == day.day) {
        consider('Shift at ${s.job}', start, true);
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
  return (
    title: target.title,
    start: start,
    isToday: isToday,
    isShift: target.isShift,
  );
}

/// An unsaved one-time alarm [suggestedLead] before [gap]'s commitment.
Alarm suggestedAlarmForCommitment(CommitmentAlarmGap gap) {
  final DateTime ring = gap.start.subtract(suggestedLead);
  return Alarm(
    id: 0,
    hour: ring.hour,
    minute: ring.minute,
    label: gap.title,
  );
}

/// A tight turnaround between an ending work shift and the next commitment.
typedef RestSqueeze = ({
  Shift shift,
  String nextTitle,
  DateTime nextAt,
  double gapHours,
});

/// Hours between [shiftEndsAt] and [nextStartAt] when strictly positive and
/// under [thresholdHours], otherwise null.
double? restSqueezeHours({
  required DateTime shiftEndsAt,
  required DateTime nextStartAt,
  double thresholdHours = 8.0,
}) {
  if (!nextStartAt.isAfter(shiftEndsAt)) return null;
  final double gapHours = nextStartAt.difference(shiftEndsAt).inMinutes / 60.0;
  if (gapHours >= thresholdHours) return null;
  return gapHours;
}

/// Finds the soonest upcoming unpaid/unworked shift within 48 hours whose gap
/// before the next open timed commitment is below [thresholdHours], or null.
RestSqueeze? restSqueezeFor({
  required List<CalendarEvent> events,
  required List<Shift> shifts,
  required DateTime now,
  double thresholdHours = 8.0,
}) {
  final DateTime horizon = now.add(const Duration(hours: 48));
  final List<Shift> upcomingShifts = <Shift>[
    for (final Shift s in shifts)
      if (!s.paid && !s.isWorked(now) && !s.startsAt.toLocal().isAfter(horizon))
        s,
  ]..sort((Shift a, Shift b) => a.endsAt.compareTo(b.endsAt));

  for (final Shift shift in upcomingShifts) {
    final DateTime shiftEnd = shift.endsAt.toLocal();
    ({String title, DateTime at})? earliestNext;
    void consider(String title, DateTime at) {
      if (!at.isAfter(shiftEnd)) return;
      if (earliestNext == null || at.isBefore(earliestNext!.at)) {
        earliestNext = (title: title, at: at);
      }
    }

    for (final CalendarEvent e in events) {
      if (e.done || e.isAllDay || (e.isAssignment && !e.isExam)) continue;
      DateTime? next = e.nextOccurrence(shiftEnd);
      if (next != null && !next.isAfter(shiftEnd)) {
        next = e.nextOccurrence(shiftEnd.add(const Duration(minutes: 1)));
      }
      if (next != null) {
        consider(e.title, next);
      }
    }

    for (final Shift other in shifts) {
      if (other.id == shift.id && other.startsAt == shift.startsAt) continue;
      if (other.paid) continue;
      final DateTime otherStart = other.startsAt.toLocal();
      if (otherStart.isAfter(shiftEnd)) {
        consider('Shift at ${other.job}', otherStart);
      }
    }

    final earliest = earliestNext;
    if (earliest == null) continue;
    final double? gap = restSqueezeHours(
      shiftEndsAt: shiftEnd,
      nextStartAt: earliest.at,
      thresholdHours: thresholdHours,
    );
    if (gap != null) {
      return (
        shift: shift,
        nextTitle: earliest.title,
        nextAt: earliest.at,
        gapHours: gap,
      );
    }
  }
  return null;
}
