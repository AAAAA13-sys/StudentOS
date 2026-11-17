import '../work/shift.dart';
import 'event.dart';

/// One line of the Week list: a class/event occurrence or a work shift.
class AgendaItem {
  const AgendaItem({
    required this.start,
    required this.end,
    required this.title,
    this.event,
    this.shift,
    this.overlapsWith,
  }) : assert((event == null) != (shift == null));

  /// The occurrence being shown (events repeat, so this is not `startsAt`).
  final DateTime start;
  final DateTime end;

  /// The event title, or `Shift · <workplace>` for a shift.
  final String title;
  final CalendarEvent? event;
  final Shift? shift;

  /// Title of the first other open item this one runs into, or null.
  final String? overlapsWith;

  bool get isShift => shift != null;

  bool get isAllDay => event?.isAllDay ?? false;

  /// Done events no longer count toward overlaps; shifts are never done.
  bool get done => event?.done ?? false;

  /// Centavos still expected for a shift: nothing once paid or without a rate.
  int get expectedPayCents {
    final Shift? s = shift;
    return s == null || s.paid ? 0 : s.payCents;
  }

  AgendaItem _withOverlap(String? other) => AgendaItem(
    start: start,
    end: end,
    title: title,
    event: event,
    shift: shift,
    overlapsWith: other,
  );
}

/// One calendar day of the week, items in time order (all-day first).
class AgendaDay {
  const AgendaDay({required this.day, required this.items});

  final DateTime day;
  final List<AgendaItem> items;

  bool get isFree => items.isEmpty;
}

/// Seven consecutive days from [start], with the totals for the footer.
class WeekAgenda {
  const WeekAgenda({required this.start, required this.days});

  final DateTime start;
  final List<AgendaDay> days;

  DateTime get end => days.last.day;

  Iterable<AgendaItem> get items => days.expand((AgendaDay d) => d.items);

  int get eventCount => items.where((AgendaItem i) => !i.isShift).length;

  int get shiftCount => items.where((AgendaItem i) => i.isShift).length;

  /// Pay still to receive for this week's unpaid shifts.
  int get expectedPayCents =>
      items.fold(0, (int sum, AgendaItem i) => sum + i.expectedPayCents);

  /// Open items that run into another one.
  int get overlapCount =>
      items.where((AgendaItem i) => i.overlapsWith != null).length;

  bool get isEmpty => days.every((AgendaDay d) => d.isFree);
}

DateTime _dayOf(DateTime d) => DateTime(d.year, d.month, d.day);

/// Builds the seven days from [start]. Repeating events expand per
/// occurrence (respecting their end date); an event that runs past midnight
/// is listed under the day it starts. When [now] is given, items that have
/// already ended are ignored for overlaps, so only something still ahead is
/// flagged.
WeekAgenda buildWeekAgenda({
  required List<CalendarEvent> events,
  required List<Shift> shifts,
  required DateTime start,
  DateTime? now,
}) {
  final DateTime first = _dayOf(start);
  final List<List<AgendaItem>> perDay = <List<AgendaItem>>[];
  final List<AgendaItem> all = <AgendaItem>[];

  for (int i = 0; i < 7; i++) {
    final DateTime day = DateTime(first.year, first.month, first.day + i);
    final List<AgendaItem> items = <AgendaItem>[];
    for (final CalendarEvent e in events) {
      if (!e.occursOn(day)) continue;
      final DateTime s = e.startsAt.toLocal();
      final DateTime at = DateTime(
        day.year,
        day.month,
        day.day,
        s.hour,
        s.minute,
      );
      items.add(
        AgendaItem(
          start: at,
          end: at.add(Duration(minutes: e.durationMinutes)),
          title: e.title,
          event: e,
        ),
      );
    }
    for (final Shift s in shifts) {
      if (_dayOf(s.startsAt) != day) continue;
      items.add(
        AgendaItem(
          start: s.startsAt,
          end: s.endsAt,
          title: 'Shift · ${s.job}',
          shift: s,
        ),
      );
    }
    items.sort((AgendaItem a, AgendaItem b) {
      if (a.isAllDay != b.isAllDay) return a.isAllDay ? -1 : 1;
      final int byTime = a.start.compareTo(b.start);
      return byTime != 0 ? byTime : a.title.compareTo(b.title);
    });
    perDay.add(items);
    all.addAll(items);
  }

  // Overlaps are found across the whole week, in start order, so a late
  // night item running into the next morning is still caught.
  bool counts(AgendaItem i) =>
      !i.done && !i.isAllDay && (now == null || i.end.isAfter(now));
  final List<AgendaItem> open = all.where(counts).toList()
    ..sort((AgendaItem a, AgendaItem b) => a.start.compareTo(b.start));
  final Map<AgendaItem, String> clash = <AgendaItem, String>{};
  for (int a = 0; a < open.length; a++) {
    for (int b = a + 1; b < open.length; b++) {
      if (!open[b].start.isBefore(open[a].end)) break;
      clash.putIfAbsent(open[a], () => open[b].title);
      clash.putIfAbsent(open[b], () => open[a].title);
    }
  }

  return WeekAgenda(
    start: first,
    days: <AgendaDay>[
      for (int i = 0; i < 7; i++)
        AgendaDay(
          day: DateTime(first.year, first.month, first.day + i),
          items: <AgendaItem>[
            for (final AgendaItem item in perDay[i])
              clash.containsKey(item) ? item._withOverlap(clash[item]) : item,
          ],
        ),
    ],
  );
}

/// "Today", "Tomorrow", else [fmt] of the day (e.g. "Wed, Nov 18").
String dayHeading(DateTime day, DateTime today, String Function(DateTime) fmt) {
  final DateTime t = _dayOf(today);
  final int diff = _dayOf(day).difference(t).inDays;
  if (diff == 0) return 'Today';
  if (diff == 1) return 'Tomorrow';
  return fmt(day);
}

/// `This week: 2 events · 1 shift · ₱450.00 expected pay`, the pay left out
/// when zero. Starts "These 7 days:" when [today] falls outside the week.
String weekFooter(
  WeekAgenda week,
  String Function(int cents) money, {
  DateTime? today,
}) {
  String plural(int n, String one) => '$n $one${n == 1 ? '' : 's'}';
  final DateTime? t = today == null ? null : _dayOf(today);
  final bool current =
      t == null || (!t.isBefore(week.start) && !t.isAfter(week.end));
  final StringBuffer out = StringBuffer(
    '${current ? 'This week' : 'These 7 days'}: '
    '${plural(week.eventCount, 'event')} · '
    '${plural(week.shiftCount, 'shift')}',
  );
  if (week.expectedPayCents > 0) {
    out.write(' · ${money(week.expectedPayCents)} expected pay');
  }
  return out.toString();
}
