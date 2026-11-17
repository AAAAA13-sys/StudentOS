import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studentos/core/db/app_database.dart';
import 'package:studentos/features/calendar/calendar_repository.dart';
import 'package:studentos/features/calendar/calendar_screen.dart';
import 'package:studentos/features/calendar/event.dart';
import 'package:studentos/features/calendar/week_agenda.dart';
import 'package:studentos/features/insights/calendar_insights.dart';
import 'package:studentos/features/insights/ponpon_insight.dart';
import 'package:studentos/features/work/shift.dart';
import 'package:studentos/features/work/work_repository.dart';

CalendarEvent _event(
  String title,
  DateTime start, {
  String recurrence = 'none',
  String? until,
  int duration = 60,
  bool done = false,
}) => CalendarEvent(
  id: title.hashCode,
  title: title,
  startsAt: start,
  durationMinutes: duration,
  recurrence: recurrence,
  recurrenceUntil: until,
  done: done,
);

Shift _shift(
  DateTime start, {
  int minutes = 300,
  int rate = 9000,
  bool paid = false,
}) => Shift(
  id: 0,
  job: 'Cafe',
  startsAt: start,
  durationMinutes: minutes,
  hourlyRateCents: rate,
  paid: paid,
);

String _money(int cents) => '₱${(cents / 100).toStringAsFixed(2)}';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Wed Nov 18 2026.
  final DateTime start = DateTime(2026, 11, 18);

  WeekAgenda build(
    List<CalendarEvent> events, {
    List<Shift> shifts = const <Shift>[],
    DateTime? now,
  }) => buildWeekAgenda(events: events, shifts: shifts, start: start, now: now);

  group('buildWeekAgenda', () {
    test('has seven days from the anchor', () {
      final WeekAgenda week = build(const <CalendarEvent>[]);
      expect(week.days.length, 7);
      expect(week.days.first.day, DateTime(2026, 11, 18));
      expect(week.end, DateTime(2026, 11, 24));
      expect(week.isEmpty, isTrue);
      expect(week.days.every((AgendaDay d) => d.isFree), isTrue);
    });

    test('a weekly class repeats on its weekday and stops at its end date', () {
      final CalendarEvent cls = _event(
        'Math',
        DateTime(2026, 11, 4, 9), // a Wednesday
        recurrence: 'weekly',
        until: '2026-11-20',
      );
      final WeekAgenda week = build(<CalendarEvent>[cls]);
      expect(week.days[0].items.single.title, 'Math');
      expect(week.eventCount, 1);
      // Wed Nov 25 would match the weekday, but the series ended Nov 20.
      final WeekAgenda next = buildWeekAgenda(
        events: <CalendarEvent>[cls],
        shifts: const <Shift>[],
        start: DateTime(2026, 11, 25),
      );
      expect(next.isEmpty, isTrue);
    });

    test('a daily series fills every day at its clock time', () {
      final WeekAgenda week = build(<CalendarEvent>[
        _event('Standup', DateTime(2026, 10, 1, 8, 30), recurrence: 'daily'),
      ]);
      expect(week.eventCount, 7);
      expect(week.days[3].items.single.start, DateTime(2026, 11, 21, 8, 30));
    });

    test('orders all-day first, then by time, mixing shifts and events', () {
      final WeekAgenda week = build(
        <CalendarEvent>[
          _event('Late', DateTime(2026, 11, 18, 15)),
          _event('Early', DateTime(2026, 11, 18, 8)),
          _event('Holiday', DateTime(2026, 11, 18), duration: 1440),
        ],
        shifts: <Shift>[_shift(DateTime(2026, 11, 18, 11), minutes: 60)],
      );
      expect(
        week.days[0].items.map((AgendaItem i) => i.title).toList(),
        <String>['Holiday', 'Early', 'Shift · Cafe', 'Late'],
      );
    });

    test('an event past midnight is listed under its start day only', () {
      final WeekAgenda week = build(<CalendarEvent>[
        _event('Late study', DateTime(2026, 11, 18, 23), duration: 180),
      ]);
      expect(week.days[0].items.length, 1);
      expect(week.days[1].items, isEmpty);
    });

    test('overlap names the other item on both sides', () {
      final WeekAgenda week = build(<CalendarEvent>[
        _event('Math', DateTime(2026, 11, 18, 9), duration: 90),
        _event('Physics', DateTime(2026, 11, 18, 10)),
        _event('Lunch', DateTime(2026, 11, 18, 12)),
      ]);
      final List<AgendaItem> items = week.days[0].items;
      expect(items[0].overlapsWith, 'Physics');
      expect(items[1].overlapsWith, 'Math');
      expect(items[2].overlapsWith, isNull);
      expect(week.overlapCount, 2);
    });

    test('touching items do not overlap', () {
      final WeekAgenda week = build(<CalendarEvent>[
        _event('A', DateTime(2026, 11, 18, 9)),
        _event('B', DateTime(2026, 11, 18, 10)),
      ]);
      expect(week.overlapCount, 0);
    });

    test('done items and all-day items never overlap', () {
      final WeekAgenda week = build(<CalendarEvent>[
        _event('Done exam', DateTime(2026, 11, 18, 9), done: true),
        _event('Class', DateTime(2026, 11, 18, 9)),
        _event('Holiday', DateTime(2026, 11, 18), duration: 1440),
      ]);
      expect(week.overlapCount, 0);
    });

    test('a shift that runs into a class flags both', () {
      final WeekAgenda week = build(
        <CalendarEvent>[_event('Class', DateTime(2026, 11, 19, 13))],
        shifts: <Shift>[_shift(DateTime(2026, 11, 19, 12), minutes: 180)],
      );
      final List<AgendaItem> items = week.days[1].items;
      expect(
        items.firstWhere((AgendaItem i) => i.isShift).overlapsWith,
        'Class',
      );
      expect(
        items.firstWhere((AgendaItem i) => !i.isShift).overlapsWith,
        'Shift · Cafe',
      );
    });

    test('items that already ended are ignored when now is given', () {
      final List<CalendarEvent> events = <CalendarEvent>[
        _event('A', DateTime(2026, 11, 18, 9)),
        _event('B', DateTime(2026, 11, 18, 9, 30)),
      ];
      expect(build(events).overlapCount, 2);
      expect(build(events, now: DateTime(2026, 11, 18, 12)).overlapCount, 0);
    });
  });

  group('footer and heading', () {
    test('counts events and shifts and sums unpaid pay only', () {
      final WeekAgenda week = build(
        <CalendarEvent>[_event('Class', DateTime(2026, 11, 18, 9))],
        shifts: <Shift>[
          _shift(DateTime(2026, 11, 19, 13)), // 5 h at 90.00 = 450.00
          _shift(DateTime(2026, 11, 20, 13), paid: true),
        ],
      );
      expect(week.shiftCount, 2);
      expect(week.expectedPayCents, 45000);
      expect(
        weekFooter(week, _money),
        'This week: 1 event · 2 shifts · ₱450.00 expected pay',
      );
    });

    test('leaves the pay out when there is none', () {
      final WeekAgenda week = build(<CalendarEvent>[
        _event('A', DateTime(2026, 11, 18, 9)),
        _event('B', DateTime(2026, 11, 19, 9)),
      ]);
      expect(weekFooter(week, _money), 'This week: 2 events · 0 shifts');
    });

    test('a week that does not hold today is not called "This week"', () {
      final WeekAgenda week = build(<CalendarEvent>[
        _event('A', DateTime(2026, 11, 18, 9)),
      ]);
      expect(
        weekFooter(week, _money, today: DateTime(2026, 12, 1, 10)),
        'These 7 days: 1 event · 0 shifts',
      );
      expect(
        weekFooter(week, _money, today: week.end.add(const Duration(hours: 5))),
        'This week: 1 event · 0 shifts',
      );
    });

    test('a paid shift carries no amount', () {
      final WeekAgenda week = build(
        const <CalendarEvent>[],
        shifts: <Shift>[_shift(DateTime(2026, 11, 19, 13), paid: true)],
      );
      expect(week.days[1].items.single.expectedPayCents, 0);
      expect(week.expectedPayCents, 0);
    });

    test('headings say Today and Tomorrow, else the formatted date', () {
      String fmt(DateTime d) => 'D${d.day}';
      expect(dayHeading(DateTime(2026, 11, 18), start, fmt), 'Today');
      expect(dayHeading(DateTime(2026, 11, 19), start, fmt), 'Tomorrow');
      expect(dayHeading(DateTime(2026, 11, 20), start, fmt), 'D20');
    });
  });

  group('Ponpon overlap tip', () {
    final DateTime now = DateTime(2026, 11, 18, 7);

    test('offers See your week when something overlaps', () {
      final List<PonponInsight> tips = calendarInsights(
        events: <CalendarEvent>[
          _event('A', DateTime(2026, 11, 20, 9)),
          _event('B', DateTime(2026, 11, 20, 9, 30)),
        ],
        now: now,
      );
      final PonponInsight tip = tips.firstWhere(
        (PonponInsight t) => t.text.contains('overlap'),
      );
      expect(tip.text, '2 things overlap this week. Take a look?');
      expect(tip.action, PonponAction.seeWeek);
    });

    test('is silent when nothing overlaps', () {
      final List<PonponInsight> tips = calendarInsights(
        events: <CalendarEvent>[_event('A', DateTime(2026, 11, 20, 9))],
        now: now,
      );
      expect(
        tips.any((PonponInsight t) => t.text.contains('overlap')),
        isFalse,
      );
    });
  });

  group('Week view on the Calendar tab', () {
    late AppDatabase database;

    setUp(() => database = AppDatabase(NativeDatabase.memory()));
    tearDown(() => database.close());

    Future<void> settle(WidgetTester tester) async {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pumpAndSettle();
    }

    Future<void> open(WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [appDatabaseProvider.overrideWithValue(database)],
          child: const MaterialApp(home: CalendarScreen()),
        ),
      );
      await settle(tester);
    }

    testWidgets('switching to Week renders the list and remembers it', (
      WidgetTester tester,
    ) async {
      final DateTime now = DateTime.now();
      final DateTime today = DateTime(now.year, now.month, now.day);
      await tester.runAsync(() async {
        await CalendarRepository(database).createEvent(
          _event(
            'Chem lab',
            today.add(const Duration(hours: 23)),
            duration: 30,
          ),
        );
        await WorkRepository(database).createShifts(<Shift>[
          _shift(today.add(const Duration(days: 1, hours: 13))),
        ]);
      });
      await open(tester);

      // Month is the default.
      expect(find.byTooltip('Week view'), findsOneWidget);
      await tester.tap(find.byTooltip('Week view'));
      await settle(tester);

      expect(find.text('Today'), findsWidgets);
      expect(find.text('Tomorrow'), findsOneWidget);
      expect(find.text('Chem lab'), findsOneWidget);
      expect(find.textContaining('Shift · Cafe'), findsOneWidget);
      expect(find.text('₱450.00'), findsOneWidget);
      expect(find.text('Free day'), findsWidgets);
      await tester.scrollUntilVisible(
        find.textContaining('This week:'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(
        find.text('This week: 1 event · 1 shift · ₱450.00 expected pay'),
        findsOneWidget,
      );
      expect(find.byTooltip('Month view'), findsOneWidget);

      final List<SettingRow> rows = (await tester.runAsync(
        () => database.select(database.settingRows).get(),
      ))!;
      expect(
        rows.singleWhere((SettingRow r) => r.key == 'schedule_view').value,
        'week',
      );

      // A fresh start reads the stored choice back.
      await tester.pumpWidget(const SizedBox());
      await open(tester);
      await settle(tester);
      expect(find.byTooltip('Month view'), findsOneWidget);
      expect(find.text('Chem lab'), findsOneWidget);
    });

    testWidgets('an empty week offers Add a class; chevrons and Today work', (
      WidgetTester tester,
    ) async {
      await open(tester);
      await tester.tap(find.byTooltip('Week view'));
      await settle(tester);
      expect(find.text('Nothing planned this week.'), findsOneWidget);
      expect(find.text('Add a class'), findsOneWidget);

      final Finder range = find.textContaining(' – ');
      final String before = tester.widget<Text>(range.first).data!;
      await tester.tap(find.byTooltip('Next week'));
      await settle(tester);
      expect(tester.widget<Text>(range.first).data, isNot(before));
      await tester.tap(find.widgetWithText(TextButton, 'Today'));
      await settle(tester);
      expect(tester.widget<Text>(range.first).data, before);
    });
  });
}
