import 'package:intl/intl.dart';

import '../../core/widgets/ponpon.dart';
import '../calendar/event.dart';
import '../work/shift.dart';
import 'ponpon_insight.dart';

typedef _Occurrence = ({CalendarEvent event, DateTime at});

DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

DateTime _addDays(DateTime d, int n) => DateTime(d.year, d.month, d.day + n);

/// Every occurrence of [events] on the calendar day [day], earliest first.
List<_Occurrence> _occurrencesOn(List<CalendarEvent> events, DateTime day) {
  final List<_Occurrence> out = <_Occurrence>[
    for (final CalendarEvent e in events)
      if (e.occursOn(day))
        (
          event: e,
          at: DateTime(
            day.year,
            day.month,
            day.day,
            e.startsAt.toLocal().hour,
            e.startsAt.toLocal().minute,
          ),
        ),
  ];
  out.sort((a, b) => a.at.compareTo(b.at));
  return out;
}

/// What Ponpon says on the Schedule view. Pure: all time comes from [now].
List<PonponInsight> calendarInsights({
  required List<CalendarEvent> events,
  List<Shift> shifts = const <Shift>[],
  required DateTime now,
}) {
  final DateTime today = _day(now);
  final DateTime tomorrow = _addDays(today, 1);
  final List<_Occurrence> todayAll = _occurrencesOn(events, today);
  final List<_Occurrence> todayLeft = <_Occurrence>[
    for (final _Occurrence o in todayAll)
      if (!o.at.isBefore(now)) o,
  ];
  final List<_Occurrence> tomorrowAll = _occurrencesOn(events, tomorrow);
  final List<PonponInsight> out = <PonponInsight>[];

  // Next event within 2 hours (looks into tomorrow across midnight).
  final List<_Occurrence> soon = <_Occurrence>[
    ...todayLeft,
    ...tomorrowAll,
  ].where((o) => o.at.difference(now) <= const Duration(hours: 2)).toList();
  if (soon.isNotEmpty) {
    final _Occurrence next = soon.first;
    final String where = (next.event.location ?? '').trim();
    final Duration wait = next.at.difference(now);
    final String lead = wait.inSeconds <= 0
        ? 'Starting now'
        : 'In ${spanText(wait)}';
    out.add(
      PonponInsight(
        text: where.isEmpty
            ? '$lead: ${next.event.title}'
            : '$lead · $where: ${next.event.title}',
        mood: PonponMood.happy,
        priority: 0,
      ),
    );
  }

  // Nearest exam or assignment within 7 days.
  ({CalendarEvent event, int days})? due;
  for (int i = 0; i <= 7 && due == null; i++) {
    for (final _Occurrence o in _occurrencesOn(events, _addDays(today, i))) {
      if (!(o.event.isExam || o.event.isAssignment)) continue;
      if (i == 0 && o.at.isBefore(now)) continue;
      due = (event: o.event, days: i);
      break;
    }
  }
  if (due != null) {
    final String kind = due.event.isExam ? 'Exam' : 'Assignment';
    final String when = switch (due.days) {
      0 => 'today',
      1 => 'tomorrow',
      _ => 'in ${due.days} days',
    };
    out.add(
      PonponInsight(
        text: '$kind $when: ${due.event.title}. A focus session would help.',
        mood: PonponMood.focused,
        priority: 1,
        action: PonponAction.startFocus,
      ),
    );
  }

  // Late night with an early start tomorrow, else tomorrow's first event.
  if (tomorrowAll.isNotEmpty) {
    final _Occurrence first = tomorrowAll.first;
    if (now.hour >= 22 && first.at.hour < 10) {
      out.add(
        PonponInsight(
          text:
              'Still awake? ${clockText(first.at)} tomorrow: ${first.event.title}.',
          mood: PonponMood.smug,
          priority: 2,
        ),
      );
    } else {
      out.add(
        PonponInsight(
          text:
              'Tomorrow starts at ${clockText(first.at)} with ${first.event.title}.',
          priority: 3,
        ),
      );
    }
  }

  // A shift still ahead today.
  final List<Shift> shiftsLeft = <Shift>[
    for (final Shift s in shifts)
      if (_day(s.startsAt) == today && !s.startsAt.isBefore(now)) s,
  ]..sort((a, b) => a.startsAt.compareTo(b.startsAt));
  if (shiftsLeft.isNotEmpty) {
    final Shift s = shiftsLeft.first;
    out.add(
      PonponInsight(
        text: '${s.job} shift at ${clockText(s.startsAt)} today.',
        priority: 3,
      ),
    );
  }

  // Busiest day from today to Sunday, only when it holds 3 or more.
  final int daysToSunday = DateTime.sunday - now.weekday;
  String? busiestDay;
  int busiest = 0;
  for (int i = 0; i <= daysToSunday; i++) {
    final DateTime day = _addDays(today, i);
    final int count = i == 0
        ? todayLeft.length
        : _occurrencesOn(events, day).length;
    if (count > busiest) {
      busiest = count;
      busiestDay = i == 0 ? 'Today' : DateFormat('EEEE').format(day);
    }
  }
  if (busiestDay != null && busiest >= 3) {
    out.add(
      PonponInsight(
        text: '$busiestDay is your busiest day: $busiest things.',
        priority: 4,
      ),
    );
  }

  // The day's events are all behind us.
  if (todayAll.isNotEmpty && todayLeft.isEmpty && shiftsLeft.isEmpty) {
    out.add(
      const PonponInsight(
        text: 'Nothing else today. Rest up.',
        mood: PonponMood.sleepy,
        priority: 5,
      ),
    );
  }

  return rankInsights(out);
}
