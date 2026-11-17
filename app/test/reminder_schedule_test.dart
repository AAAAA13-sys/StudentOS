import 'package:flutter_test/flutter_test.dart';
import 'package:studentos/features/calendar/event.dart';
import 'package:studentos/features/calendar/reminder_schedule.dart';

void main() {
  final DateTime now = DateTime(2026, 11, 17, 8, 0);

  CalendarEvent event({
    int id = 1,
    String title = 'Physics',
    required DateTime at,
    int? lead = 15,
    String recurrence = 'none',
    String? until,
    String? location,
    int duration = 90,
  }) => CalendarEvent(
    id: id,
    title: title,
    startsAt: at,
    durationMinutes: duration,
    location: location,
    recurrence: recurrence,
    recurrenceUntil: until,
    reminderMinutes: lead,
  );

  test('a one-off 15 min ahead gives one reminder at its fire time', () {
    final DateTime start = now.add(const Duration(minutes: 15));
    final List<ReminderFire> out = upcomingReminders(<CalendarEvent>[
      event(at: start, lead: 15),
    ], now.subtract(const Duration(seconds: 1)));
    expect(out, hasLength(1));
    expect(out.single.fireAt, now);
    expect(out.single.startsAt, start);
  });

  test('no lead means no reminder', () {
    expect(
      upcomingReminders(<CalendarEvent>[
        event(at: now.add(const Duration(hours: 3)), lead: null),
      ], now),
      isEmpty,
    );
  });

  test('a passed fire time is skipped but the next occurrence is kept', () {
    final CalendarEvent e = event(
      at: now.add(const Duration(minutes: 5)),
      lead: 15,
      recurrence: 'daily',
    );
    final List<ReminderFire> out = upcomingReminders(<CalendarEvent>[e], now);
    expect(out.first.startsAt, now.add(const Duration(days: 1, minutes: 5)));
    expect(
      out.first.fireAt,
      now.add(const Duration(days: 1)).subtract(const Duration(minutes: 10)),
    );
  });

  test('a one-off whose fire time passed gives nothing', () {
    expect(
      upcomingReminders(<CalendarEvent>[
        event(at: now.add(const Duration(minutes: 5)), lead: 15),
      ], now),
      isEmpty,
    );
  });

  test('weekly gives two in 14 days', () {
    final List<ReminderFire> out = upcomingReminders(<CalendarEvent>[
      event(
        at: DateTime(2026, 11, 19, 9),
        recurrence: 'weekly',
        until: '2027-03-01',
      ),
    ], now);
    expect(out.map((f) => f.startsAt).toList(), <DateTime>[
      DateTime(2026, 11, 19, 9),
      DateTime(2026, 11, 26, 9),
    ]);
  });

  test('daily is capped at max', () {
    final CalendarEvent daily = event(
      at: DateTime(2026, 11, 18, 9),
      recurrence: 'daily',
    );
    expect(
      upcomingReminders(<CalendarEvent>[daily], now, max: 5),
      hasLength(5),
    );
    expect(upcomingReminders(<CalendarEvent>[daily], now), hasLength(13));
  });

  test('recurrenceUntil is respected', () {
    final List<ReminderFire> out = upcomingReminders(<CalendarEvent>[
      event(
        at: DateTime(2026, 11, 18, 9),
        recurrence: 'daily',
        until: '2026-11-20',
      ),
    ], now);
    expect(out, hasLength(3));
  });

  test('monthly on the 31st clamps to the month end', () {
    final CalendarEvent monthly = event(
      at: DateTime(2026, 12, 31, 9),
      recurrence: 'monthly',
    );
    final List<ReminderFire> jan = upcomingReminders(<CalendarEvent>[
      monthly,
    ], DateTime(2027, 1, 28));
    expect(jan.map((f) => f.startsAt).toList(), <DateTime>[
      DateTime(2027, 1, 31, 9),
    ]);
    final List<ReminderFire> feb = upcomingReminders(<CalendarEvent>[
      monthly,
    ], DateTime(2027, 2, 20));
    expect(feb.single.startsAt, DateTime(2027, 2, 28, 9));
  });

  test('1440 fires the day before and says Tomorrow', () {
    final List<ReminderFire> out = upcomingReminders(<CalendarEvent>[
      event(title: 'Midterm exam', at: DateTime(2026, 11, 20, 9), lead: 1440),
    ], now);
    expect(out.single.fireAt, DateTime(2026, 11, 19, 9));
    expect(out.single.title, 'Exam: Midterm exam');
    expect(out.single.text, startsWith('Tomorrow at 9:00 AM'));
  });

  test('reminders are sorted by fire time', () {
    final List<ReminderFire> out = upcomingReminders(<CalendarEvent>[
      event(id: 1, at: DateTime(2026, 11, 20, 9)),
      event(id: 2, at: DateTime(2026, 11, 18, 9)),
      event(id: 3, at: DateTime(2026, 11, 19, 9)),
    ], now);
    expect(out.map((f) => f.startsAt.day).toList(), <int>[18, 19, 20]);
  });

  test('ids are stable and differ per event and occurrence', () {
    List<ReminderFire> run() => upcomingReminders(<CalendarEvent>[
      event(id: 1, at: DateTime(2026, 11, 18, 9), recurrence: 'daily'),
      event(id: 2, at: DateTime(2026, 11, 18, 9), recurrence: 'daily'),
    ], now);
    final List<int> a = run().map((f) => f.id).toList();
    expect(a, run().map((f) => f.id).toList());
    expect(a.toSet(), hasLength(a.length));
    expect(a.every((int id) => id >= 0 && id <= 0x7fffffff), isTrue);
  });

  test('route and native map', () {
    final ReminderFire f = upcomingReminders(<CalendarEvent>[
      event(at: DateTime(2026, 11, 20, 9), location: 'Room 304'),
    ], now).single;
    expect(f.route, 'day:2026-11-20');
    expect(f.text, 'In 15 min · 9:00 AM–10:30 AM · Room 304');
    final Map<String, Object?> m = f.toNative();
    expect(m['fireAt'], f.fireAt.millisecondsSinceEpoch);
    expect(m['route'], 'day:2026-11-20');
  });

  test('location is left out when empty', () {
    final ReminderFire f = upcomingReminders(<CalendarEvent>[
      event(at: DateTime(2026, 11, 20, 9), location: '  '),
    ], now).single;
    expect(f.text.split(' · '), hasLength(2));
  });

  test('reminderLeadText', () {
    final DateTime start = DateTime(2026, 11, 20, 9);
    String t(int m) =>
        reminderLeadText(m, start, start.subtract(Duration(minutes: m)));
    expect(t(0), 'Starting now');
    expect(t(5), 'In 5 min');
    expect(t(30), 'In 30 min');
    expect(t(60), 'In 1 hour');
    expect(t(120), 'In 2 hours');
    expect(t(1440), 'Tomorrow at 9:00 AM');
  });
}
