import 'event.dart';
import 'reminder_field.dart';

/// What an `.ics` file turned into.
class IcsImportResult {
  const IcsImportResult({
    required this.events,
    required this.skipped,
    required this.warnings,
  });

  /// Events ready to save (id 0). A weekly rule with several BYDAY days is
  /// already expanded to one event per day.
  final List<CalendarEvent> events;

  /// VEVENT blocks that could not be imported.
  final int skipped;

  /// Human-readable notes about things that were approximated or ignored.
  final List<String> warnings;
}

/// Parses an iCalendar (RFC 5545) file. Never throws: anything it cannot use
/// is counted in [IcsImportResult.skipped] or described in
/// [IcsImportResult.warnings].
///
/// Time zones: a `Z` (UTC) time is converted to the phone's local time. A
/// time with `TZID=` or no zone is taken as local wall time, i.e. the clock
/// reading in the file is kept as-is and the zone is ignored. That is right
/// for a timetable exported in the student's own zone.
///
/// Recurrence mapping onto the app's model (`none`/`daily`/`weekly`/
/// `monthly` + an end date): FREQ=DAILY/WEEKLY/MONTHLY with INTERVAL 1;
/// UNTIL becomes the end date; COUNT is converted to an end date; weekly
/// BYDAY gives one weekly event per listed day. Anything else (other FREQ,
/// INTERVAL above 1, BYDAY on daily/monthly, RECURRENCE-ID overrides,
/// cancelled events) is skipped; EXDATE is ignored with a warning.
IcsImportResult parseIcs(String source) {
  final List<CalendarEvent> events = <CalendarEvent>[];
  int skipped = 0;
  bool exdateSeen = false;
  bool allDaySeen = false;

  try {
    final List<_Prop> props = _readProps(source);
    List<_Prop>? current;
    int alarmDepth = 0;

    for (final _Prop p in props) {
      if (p.name == 'BEGIN' && p.value.toUpperCase() == 'VEVENT') {
        current = <_Prop>[];
        alarmDepth = 0;
        continue;
      }
      if (current == null) continue;
      if (p.name == 'BEGIN') {
        alarmDepth++;
        continue;
      }
      if (p.name == 'END') {
        if (p.value.toUpperCase() == 'VEVENT' && alarmDepth == 0) {
          final _Built? built = _buildEvents(current);
          if (built == null) {
            skipped++;
          } else {
            events.addAll(built.events);
            exdateSeen = exdateSeen || built.hadExdate;
            allDaySeen = allDaySeen || built.allDay;
          }
          current = null;
        } else if (alarmDepth > 0) {
          alarmDepth--;
        }
        continue;
      }
      if (alarmDepth == 0) current.add(p);
    }
    if (current != null) skipped++; // VEVENT never closed
  } catch (_) {
    skipped++;
  }

  return IcsImportResult(
    events: events,
    skipped: skipped,
    warnings: <String>[
      if (exdateSeen)
        'Some repeating events had excluded dates (EXDATE). Those dates '
            'will still show.',
      if (allDaySeen)
        'All-day events are imported as 24 hour events with no reminder.',
    ],
  );
}

class _Prop {
  _Prop(this.name, this.params, this.value);
  final String name;
  final Map<String, String> params;
  final String value;
}

class _Built {
  _Built(this.events, {required this.hadExdate, required this.allDay});
  final List<CalendarEvent> events;
  final bool hadExdate;
  final bool allDay;
}

List<_Prop> _readProps(String source) {
  final List<String> raw = source.split(RegExp(r'\r\n|\n|\r'));
  final List<String> lines = <String>[];
  for (final String line in raw) {
    if (line.isNotEmpty && (line[0] == ' ' || line[0] == '\t')) {
      if (lines.isNotEmpty) lines[lines.length - 1] += line.substring(1);
    } else if (line.trim().isNotEmpty) {
      lines.add(line);
    }
  }
  final List<_Prop> props = <_Prop>[];
  for (final String line in lines) {
    // The first colon outside double quotes separates name+params from value.
    bool quoted = false;
    int colon = -1;
    for (int i = 0; i < line.length; i++) {
      final String c = line[i];
      if (c == '"') {
        quoted = !quoted;
      } else if (c == ':' && !quoted) {
        colon = i;
        break;
      }
    }
    if (colon < 0) continue;
    final List<String> head = _splitOutsideQuotes(line.substring(0, colon));
    final Map<String, String> params = <String, String>{};
    for (final String part in head.skip(1)) {
      final int eq = part.indexOf('=');
      if (eq > 0) {
        params[part.substring(0, eq).toUpperCase()] = part
            .substring(eq + 1)
            .replaceAll('"', '');
      }
    }
    props.add(
      _Prop(head.first.trim().toUpperCase(), params, line.substring(colon + 1)),
    );
  }
  return props;
}

List<String> _splitOutsideQuotes(String s) {
  final List<String> parts = <String>[];
  final StringBuffer buf = StringBuffer();
  bool quoted = false;
  for (int i = 0; i < s.length; i++) {
    final String c = s[i];
    if (c == '"') quoted = !quoted;
    if (c == ';' && !quoted) {
      parts.add(buf.toString());
      buf.clear();
    } else {
      buf.write(c);
    }
  }
  parts.add(buf.toString());
  return parts;
}

String _unescape(String s) {
  final StringBuffer out = StringBuffer();
  for (int i = 0; i < s.length; i++) {
    final String c = s[i];
    if (c == r'\' && i + 1 < s.length) {
      final String n = s[++i];
      out.write(n == 'n' || n == 'N' ? '\n' : n);
    } else {
      out.write(c);
    }
  }
  return out.toString();
}

({DateTime time, bool allDay})? _parseDateTime(_Prop p) {
  final String v = p.value.trim();
  final RegExpMatch? m = RegExp(
    r'^(\d{4})(\d{2})(\d{2})(?:T(\d{2})(\d{2})(\d{2})?(Z)?)?$',
    caseSensitive: false,
  ).firstMatch(v);
  if (m == null) return null;
  final int y = int.parse(m[1]!);
  final int mo = int.parse(m[2]!);
  final int d = int.parse(m[3]!);
  if (mo < 1 || mo > 12 || d < 1 || d > 31) return null;
  final bool dateOnly = m[4] == null || p.params['VALUE'] == 'DATE';
  if (dateOnly) return (time: DateTime(y, mo, d), allDay: true);
  final int h = int.parse(m[4]!);
  final int mi = int.parse(m[5]!);
  final int s = m[6] == null ? 0 : int.parse(m[6]!);
  if (h > 23 || mi > 59 || s > 60) return null;
  final DateTime time = m[7] != null
      ? DateTime.utc(y, mo, d, h, mi, s).toLocal()
      : DateTime(y, mo, d, h, mi, s);
  return (time: time, allDay: false);
}

int? _parseDuration(String value) {
  final RegExpMatch? m = RegExp(
    r'^[+-]?P(?:(\d+)W)?(?:(\d+)D)?(?:T(?:(\d+)H)?(?:(\d+)M)?(?:(\d+)S)?)?$',
  ).firstMatch(value.trim().toUpperCase());
  if (m == null) return null;
  int n(int i) => m[i] == null ? 0 : int.parse(m[i]!);
  return n(1) * 7 * 1440 + n(2) * 1440 + n(3) * 60 + n(4) + n(5) ~/ 60;
}

const Map<String, int> _weekdays = <String, int>{
  'MO': DateTime.monday,
  'TU': DateTime.tuesday,
  'WE': DateTime.wednesday,
  'TH': DateTime.thursday,
  'FR': DateTime.friday,
  'SA': DateTime.saturday,
  'SU': DateTime.sunday,
};

String _dateKey(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

_Built? _buildEvents(List<_Prop> props) {
  _Prop? find(String name) {
    for (final _Prop p in props) {
      if (p.name == name) return p;
    }
    return null;
  }

  if (find('RECURRENCE-ID') != null) return null;
  if (find('STATUS')?.value.trim().toUpperCase() == 'CANCELLED') return null;

  final _Prop? startProp = find('DTSTART');
  if (startProp == null) return null;
  final ({DateTime time, bool allDay})? start = _parseDateTime(startProp);
  if (start == null) return null;

  int duration = start.allDay ? 1440 : 60;
  final _Prop? endProp = find('DTEND');
  final _Prop? durProp = find('DURATION');
  if (endProp != null) {
    final ({DateTime time, bool allDay})? end = _parseDateTime(endProp);
    if (end != null) {
      final int minutes = end.time.difference(start.time).inMinutes;
      if (minutes > 0) duration = minutes;
    }
  } else if (durProp != null) {
    final int? minutes = _parseDuration(durProp.value);
    if (minutes != null && minutes > 0) duration = minutes;
  }

  final String title = _unescape(find('SUMMARY')?.value ?? '').trim();
  final String location = _unescape(find('LOCATION')?.value ?? '').trim();
  final String notes = _unescape(find('DESCRIPTION')?.value ?? '').trim();
  final String safeTitle = title.isEmpty ? 'Untitled event' : title;

  String recurrence = 'none';
  String? until;
  Set<int> days = <int>{start.time.weekday};

  final _Prop? rule = find('RRULE');
  if (rule != null) {
    final Map<String, String> r = <String, String>{};
    for (final String part in rule.value.split(';')) {
      final int eq = part.indexOf('=');
      if (eq > 0) {
        r[part.substring(0, eq).trim().toUpperCase()] = part
            .substring(eq + 1)
            .trim()
            .toUpperCase();
      }
    }
    final String? freq = r['FREQ'];
    recurrence = switch (freq) {
      'DAILY' => 'daily',
      'WEEKLY' => 'weekly',
      'MONTHLY' => 'monthly',
      _ => '',
    };
    if (recurrence.isEmpty) return null;
    final int interval = int.tryParse(r['INTERVAL'] ?? '1') ?? 0;
    if (interval != 1) return null;

    if (r.containsKey('BYDAY')) {
      if (recurrence != 'weekly') return null;
      final Set<int> parsed = <int>{};
      for (final String token in r['BYDAY']!.split(',')) {
        final int? wd = _weekdays[token.replaceAll(RegExp(r'[+\-\d]'), '')];
        if (wd == null) return null;
        parsed.add(wd);
      }
      if (parsed.isEmpty) return null;
      days = parsed;
    }
    if (r.containsKey('BYMONTHDAY') || r.containsKey('BYSETPOS')) {
      return null;
    }

    if (r.containsKey('UNTIL')) {
      final ({DateTime time, bool allDay})? u = _parseDateTime(
        _Prop('UNTIL', const <String, String>{}, r['UNTIL']!),
      );
      if (u == null) return null;
      until = _dateKey(u.time);
    } else if (r.containsKey('COUNT')) {
      final int? count = int.tryParse(r['COUNT']!);
      if (count == null || count < 1) return null;
      until = _dateKey(_countToEnd(start.time, recurrence, days, count));
    }
  }

  final DateTime base = start.time;
  final List<int> ordered = days.toList()..sort();
  final int? reminder = start.allDay
      ? null
      : (_isExam(safeTitle, notes)
            ? examReminderMinutes
            : defaultReminderMinutes);
  final List<CalendarEvent> built = <CalendarEvent>[
    for (final int wd in ordered)
      CalendarEvent(
        id: 0,
        title: safeTitle,
        startsAt: DateTime(
          base.year,
          base.month,
          base.day + (recurrence == 'weekly' ? (wd - base.weekday) % 7 : 0),
          base.hour,
          base.minute,
        ),
        durationMinutes: duration,
        location: location.isEmpty ? null : location,
        notes: notes.isEmpty ? null : notes,
        recurrence: recurrence,
        recurrenceUntil: until,
        reminderMinutes: reminder,
      ),
  ];
  return _Built(built, hadExdate: find('EXDATE') != null, allDay: start.allDay);
}

bool _isExam(String title, String notes) => CalendarEvent(
  id: 0,
  title: title,
  startsAt: DateTime(2000),
  notes: notes,
).isExam;

/// The date of the COUNT-th occurrence overall.
DateTime _countToEnd(DateTime start, String freq, Set<int> days, int count) {
  switch (freq) {
    case 'daily':
      return DateTime(start.year, start.month, start.day + count - 1);
    case 'weekly':
      int seen = 0;
      for (int i = 0; i < count * 7 + 7; i++) {
        final DateTime day = DateTime(start.year, start.month, start.day + i);
        if (days.contains(day.weekday) && ++seen == count) return day;
      }
      return start;
    default:
      final DateTime first = DateTime(start.year, start.month + count - 1);
      final int last = DateTime(first.year, first.month + 1, 0).day;
      return DateTime(
        first.year,
        first.month,
        start.day > last ? last : start.day,
      );
  }
}
