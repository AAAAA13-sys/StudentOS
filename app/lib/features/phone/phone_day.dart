import 'phone_usage.dart';

/// Phone use on one day, as stored.
class PhoneDay {
  const PhoneDay({
    required this.date,
    required this.screenOnMs,
    required this.unlocks,
    this.firstPickup,
    this.restStart,
    this.restEnd,
    this.complete = false,
  });

  /// Midnight at the start of the day.
  final DateTime date;
  final int screenOnMs;
  final int unlocks;
  final DateTime? firstPickup;
  final DateTime? restStart;
  final DateTime? restEnd;
  final bool complete;

  Duration? get rest => restStart == null || restEnd == null
      ? null
      : restEnd!.difference(restStart!);
}

/// The night before [day] is searched for phone rest from 6 PM the day
/// before until noon.
(DateTime, DateTime) restWindowFor(DateTime day) => (
  DateTime(day.year, day.month, day.day - 1, 18),
  DateTime(day.year, day.month, day.day, 12),
);

/// Shorter screen-off stretches are not counted as a night's rest.
const Duration minimumRest = Duration(hours: 2);

/// The longest time inside [windowStart]..[windowEnd] with the screen off,
/// given the screen-on spans. Null when no stretch reaches [minimumRest].
///
/// A stretch must begin by 6 AM: a phone left alone after getting up in the
/// morning is not the night's rest.
(DateTime, DateTime)? longestScreenOff(
  List<(DateTime, DateTime)> screenOn,
  DateTime windowStart,
  DateTime windowEnd,
) {
  final List<(DateTime, DateTime)> spans =
      <(DateTime, DateTime)>[
        for (final (DateTime s, DateTime e) in screenOn)
          if (e.isAfter(windowStart) && s.isBefore(windowEnd))
            (
              s.isBefore(windowStart) ? windowStart : s,
              e.isAfter(windowEnd) ? windowEnd : e,
            ),
      ]..sort(
        ((DateTime, DateTime) a, (DateTime, DateTime) b) =>
            a.$1.compareTo(b.$1),
      );

  (DateTime, DateTime)? best;
  DateTime cursor = windowStart;
  final DateTime latestStart = windowStart.add(const Duration(hours: 12));
  void consider(DateTime from, DateTime to) {
    if (!to.isAfter(from) || from.isAfter(latestStart)) return;
    if (best == null || to.difference(from) > best!.$2.difference(best!.$1)) {
      best = (from, to);
    }
  }

  for (final (DateTime s, DateTime e) in spans) {
    consider(cursor, s);
    if (e.isAfter(cursor)) cursor = e;
  }
  consider(cursor, windowEnd);
  if (best == null || best!.$2.difference(best!.$1) < minimumRest) {
    return null;
  }
  return best;
}

/// Total screen-on time inside [start]..[end].
int screenOnMsWithin(
  List<(DateTime, DateTime)> screenOn,
  DateTime start,
  DateTime end,
) {
  int total = 0;
  for (final (DateTime s, DateTime e) in screenOn) {
    final DateTime from = s.isBefore(start) ? start : s;
    final DateTime to = e.isAfter(end) ? end : e;
    if (to.isAfter(from)) total += to.difference(from).inMilliseconds;
  }
  return total;
}

/// Builds a day from what Android reports. [rest] is the reading of the
/// night window (see [restWindowFor]).
PhoneDay phoneDayFrom({
  required DateTime day,
  required UsageRange usage,
  required UsageRange? rest,
  required DateTime now,
}) {
  final DateTime start = DateTime(day.year, day.month, day.day);
  final DateTime end = DateTime(day.year, day.month, day.day + 1);
  final List<DateTime> unlocks =
      usage.unlocks
          .where((DateTime t) => !t.isBefore(start) && t.isBefore(end))
          .toList()
        ..sort();
  final (DateTime windowStart, DateTime windowEnd) = restWindowFor(start);
  final (DateTime, DateTime)? restSpan = rest == null
      ? null
      : longestScreenOff(
          rest.screenOn,
          windowStart,
          now.isBefore(windowEnd) ? now : windowEnd,
        );
  return PhoneDay(
    date: start,
    screenOnMs: screenOnMsWithin(usage.screenOn, start, end),
    unlocks: unlocks.length,
    firstPickup: unlocks.isEmpty ? null : unlocks.first,
    restStart: restSpan?.$1,
    restEnd: restSpan?.$2,
    complete: !now.isBefore(end),
  );
}

/// `3h 12m`, `45m`, `0m`.
String formatDuration(Duration d) {
  final int minutes = d.inMinutes;
  final int h = minutes ~/ 60;
  final int m = minutes % 60;
  if (h == 0) return '${m}m';
  return m == 0 ? '${h}h' : '${h}h ${m}m';
}

/// How [value] compares with the [average] of earlier days, in plain words.
/// Within 15% either way counts as usual. Null without an average.
String? comparedWithUsual(int value, int? average) {
  if (average == null || average <= 0) return null;
  final double ratio = value / average;
  if (ratio < 0.85) return 'Less than your usual';
  if (ratio > 1.15) return 'More than your usual';
  return 'About your usual';
}
