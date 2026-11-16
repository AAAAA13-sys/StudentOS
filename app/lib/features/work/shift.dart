import '../calendar/event.dart';

/// One work shift on one day.
class Shift {
  const Shift({
    required this.id,
    required this.job,
    required this.startsAt,
    required this.durationMinutes,
    this.breakMinutes = 0,
    this.hourlyRateCents = 0,
    this.paid = false,
    this.seriesId,
  });

  final int id;
  final String job;
  final DateTime startsAt;
  final int durationMinutes;

  /// Unpaid break time inside the shift.
  final int breakMinutes;

  /// Centavos per hour.
  final int hourlyRateCents;

  /// True once the pay for this shift has been received.
  final bool paid;

  /// Shared by shifts that were added together as one weekly repeat.
  final int? seriesId;

  DateTime get endsAt => startsAt.add(Duration(minutes: durationMinutes));

  /// Minutes that are paid for; never negative.
  int get paidMinutes {
    final int minutes = durationMinutes - breakMinutes;
    return minutes < 0 ? 0 : minutes;
  }

  /// Pay before any deductions, rounded to the nearest centavo.
  int get payCents => (paidMinutes * hourlyRateCents + 30) ~/ 60;

  /// Whether the shift is over at [now].
  bool isWorked(DateTime now) => !endsAt.isAfter(now);
}

/// Hours and pay not yet received, split into what is already worked and
/// what is still ahead. The two are never added together: only worked hours
/// have been earned.
class WorkSummary {
  const WorkSummary({
    required this.workedMinutes,
    required this.workedPayCents,
    required this.upcomingMinutes,
    required this.upcomingPayCents,
  });

  factory WorkSummary.of(Iterable<Shift> shifts, DateTime now) {
    int workedMinutes = 0;
    int workedPay = 0;
    int upcomingMinutes = 0;
    int upcomingPay = 0;
    for (final Shift shift in shifts) {
      if (shift.paid) continue;
      if (shift.isWorked(now)) {
        workedMinutes += shift.paidMinutes;
        workedPay += shift.payCents;
      } else {
        upcomingMinutes += shift.paidMinutes;
        upcomingPay += shift.payCents;
      }
    }
    return WorkSummary(
      workedMinutes: workedMinutes,
      workedPayCents: workedPay,
      upcomingMinutes: upcomingMinutes,
      upcomingPayCents: upcomingPay,
    );
  }

  final int workedMinutes;
  final int workedPayCents;
  final int upcomingMinutes;
  final int upcomingPayCents;

  bool get isEmpty => workedMinutes == 0 && upcomingMinutes == 0;
}

/// Hours as text with at most two decimals: `4`, `4.5`, `4.25`.
String formatHours(int minutes) {
  final String text = (minutes / 60).toStringAsFixed(2);
  return text.replaceFirst(RegExp(r'\.?0+$'), '');
}

/// Minutes from [startMinute] to [endMinute] of the day. An end at or before
/// the start means the shift finishes the next day.
int shiftDurationMinutes(int startMinute, int endMinute) {
  final int minutes = endMinute - startMinute;
  return minutes > 0 ? minutes : minutes + 24 * 60;
}

/// One shift for every day in [weekdays] (`DateTime.monday` ..
/// `DateTime.sunday`) from [from] through [until], both included.
List<Shift> buildShiftSeries({
  required String job,
  required Set<int> weekdays,
  required int startMinute,
  required int durationMinutes,
  required int breakMinutes,
  required int hourlyRateCents,
  required DateTime from,
  required DateTime until,
}) {
  final DateTime last = DateTime(until.year, until.month, until.day);
  final List<Shift> shifts = <Shift>[];
  for (int offset = 0; ; offset++) {
    final DateTime day = DateTime(from.year, from.month, from.day + offset);
    if (day.isAfter(last)) break;
    if (!weekdays.contains(day.weekday)) continue;
    shifts.add(
      Shift(
        id: 0,
        job: job,
        startsAt: DateTime(
          day.year,
          day.month,
          day.day,
          startMinute ~/ 60,
          startMinute % 60,
        ),
        durationMinutes: durationMinutes,
        breakMinutes: breakMinutes,
        hourlyRateCents: hourlyRateCents,
      ),
    );
  }
  return shifts;
}

/// The events in [events] with an occurrence that runs into the time from
/// [start] for [durationMinutes]. Ending exactly when the other begins is
/// not an overlap. Exams come first.
List<CalendarEvent> eventsOverlapping({
  required DateTime start,
  required int durationMinutes,
  required Iterable<CalendarEvent> events,
}) {
  final DateTime end = start.add(Duration(minutes: durationMinutes));
  final DateTime firstDay = DateTime(start.year, start.month, start.day - 1);
  final DateTime lastDay = DateTime(end.year, end.month, end.day);
  final List<CalendarEvent> found = <CalendarEvent>[];
  for (final CalendarEvent event in events) {
    final DateTime eventStart = event.startsAt.toLocal();
    // An event is listed on the day it starts, so one that began the day
    // before and runs past midnight is checked too.
    for (
      DateTime day = firstDay;
      !day.isAfter(lastDay);
      day = DateTime(day.year, day.month, day.day + 1)
    ) {
      if (!event.occursOn(day)) continue;
      final DateTime occurrence = DateTime(
        day.year,
        day.month,
        day.day,
        eventStart.hour,
        eventStart.minute,
      );
      final DateTime occurrenceEnd = occurrence.add(
        Duration(minutes: event.durationMinutes),
      );
      if (occurrence.isBefore(end) && start.isBefore(occurrenceEnd)) {
        found.add(event);
        break;
      }
    }
  }
  found.sort(
    (CalendarEvent a, CalendarEvent b) =>
        (a.isExam ? 0 : 1).compareTo(b.isExam ? 0 : 1),
  );
  return found;
}
