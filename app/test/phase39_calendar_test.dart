import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studentos/core/db/app_database.dart';
import 'package:studentos/features/calendar/calendar_repository.dart';
import 'package:studentos/features/calendar/calendar_screen.dart';
import 'package:studentos/features/calendar/event.dart';
import 'package:studentos/features/focus/alarm.dart';
import 'package:studentos/features/focus/wake_plan.dart';

CalendarEvent _event(
  String title,
  DateTime start, {
  String recurrence = 'none',
  int duration = 60,
  String? notes,
  int? noteId,
  bool done = false,
}) => CalendarEvent(
  id: 0,
  title: title,
  startsAt: start,
  durationMinutes: duration,
  recurrence: recurrence,
  notes: notes,
  noteId: noteId,
  done: done,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('countdown counts from the occurrence shown', () {
    final DateTime now = DateTime(2026, 11, 17, 10);

    test('a repeating exam is counted to the day being viewed', () {
      final CalendarEvent exam = _event(
        'Midterm exam',
        DateTime(2026, 11, 4, 9), // a Wednesday
        recurrence: 'weekly',
      );
      expect(exam.countdownBadge(now, on: DateTime(2026, 11, 25)), 'in 8 days');
      // Without a day it counts to the next occurrence, not the series start.
      expect(exam.countdownBadge(now), 'Tomorrow');
    });

    test('a daily series that began long ago is still counted', () {
      final CalendarEvent quiz = _event(
        'Daily quiz',
        DateTime(2026, 10, 1, 9),
        recurrence: 'daily',
      );
      expect(quiz.countdownBadge(now), 'Today');
      expect(quiz.countdownBadge(now, on: DateTime(2026, 11, 18)), 'Tomorrow');
      expect(quiz.countdownBadge(now, on: DateTime(2026, 12, 25)), isNull);
    });

    test('done items have no countdown', () {
      expect(
        _event(
          'Exam',
          DateTime(2026, 11, 18, 9),
          done: true,
        ).countdownBadge(now),
        isNull,
      );
    });
  });

  group('duration text', () {
    test('reads as people say it', () {
      expect(formatEventDuration(45), '45 min');
      expect(formatEventDuration(60), '1 h');
      expect(formatEventDuration(90), '1 h 30 min');
      expect(formatEventDuration(180), '3 h');
      expect(formatEventDuration(1440), 'All day');
      expect(formatEventDuration(2880), '2 days');
    });

    test('the editor always offers the current length', () {
      expect(durationChoices(60), containsAll(<int>[150, 180, 240]));
      expect(durationChoices(50), contains(50));
      expect(durationChoices(1440), contains(1440));
      final List<int> sorted = durationChoices(50);
      expect(sorted, orderedEquals(<int>[...sorted]..sort()));
    });

    test('midnight with 24 h is an all-day event', () {
      expect(
        _event('Holiday', DateTime(2026, 11, 25), duration: 1440).isAllDay,
        isTrue,
      );
      expect(
        _event('Late', DateTime(2026, 11, 25, 0, 30), duration: 1440).isAllDay,
        isFalse,
      );
    });
  });

  group('done', () {
    late AppDatabase db;
    setUp(() => db = AppDatabase(NativeDatabase.memory()));
    tearDown(() => db.close());

    test('schema is v8 and a new event is not done', () async {
      expect(db.schemaVersion, 8);
      final CalendarRepository repo = CalendarRepository(db);
      final CalendarEvent created = await repo.createEvent(
        _event('Exam', DateTime(2026, 11, 20, 9)),
      );
      expect((await repo.getEvents()).single.done, isFalse);
      // A row written without the column falls back to the default.
      await db
          .into(db.eventRows)
          .insert(
            EventRowsCompanion.insert(
              title: 'raw',
              startsAt: DateTime(2026, 11, 21),
            ),
          );
      final List<EventRow> rows = await db.select(db.eventRows).get();
      expect(rows.every((EventRow r) => r.done == false), isTrue);

      await repo.updateEvent(created.copyWith(done: true));
      expect(
        (await repo.getEvents()).firstWhere((e) => e.id == created.id).done,
        isTrue,
      );
    });

    test('a done event is left out of the widget next event', () async {
      final CalendarRepository repo = CalendarRepository(db);
      final DateTime soon = DateTime.now().add(const Duration(days: 1));
      final CalendarEvent exam = await repo.createEvent(
        _event('Final exam', soon),
      );
      await repo.createEvent(
        _event('Lunch', soon.add(const Duration(days: 2))),
      );
      expect((await repo.getNextEvent())!.title, 'Final exam');
      await repo.updateEvent(exam.copyWith(done: true));
      expect((await repo.getNextEvent())!.title, 'Lunch');
    });
  });

  group('alarm before the first class', () {
    final DateTime now = DateTime(2026, 11, 17, 20); // Tuesday evening
    final CalendarEvent physics = _event(
      'Physics 101',
      DateTime(2026, 11, 18, 8),
    );
    Alarm alarm(int h, int m, {bool enabled = true, int days = 0x1F}) =>
        Alarm(id: 1, hour: h, minute: m, days: days, enabled: enabled);

    test('no events tomorrow: nothing to say', () {
      expect(
        alarmGapFor(events: const <CalendarEvent>[], alarms: [], now: now),
        isNull,
      );
    });

    test('no alarm at all', () {
      final AlarmGap? gap = alarmGapFor(
        events: <CalendarEvent>[physics],
        alarms: <Alarm>[],
        now: now,
      );
      expect(gap!.event.title, 'Physics 101');
      expect(gap.start, DateTime(2026, 11, 18, 8));
      expect(gap.isToday, isFalse);
    });

    test('an alarm in the three hours before is enough', () {
      expect(
        alarmGapFor(
          events: <CalendarEvent>[physics],
          alarms: <Alarm>[alarm(6, 30)],
          now: now,
        ),
        isNull,
      );
    });

    test('too early, off, or on another weekday does not count', () {
      for (final Alarm a in <Alarm>[
        alarm(4, 30),
        alarm(6, 30, enabled: false),
        alarm(6, 30, days: 0x01), // Mondays only; tomorrow is Wednesday
        alarm(9, 0), // after it starts
      ]) {
        expect(
          alarmGapFor(
            events: <CalendarEvent>[physics],
            alarms: <Alarm>[a],
            now: now,
          ),
          isNotNull,
          reason: '${a.hour}:${a.minute} days ${a.days} enabled ${a.enabled}',
        );
      }
    });

    test('the first event of the day is the one checked', () {
      final CalendarEvent later = _event('Chem', DateTime(2026, 11, 18, 13));
      final AlarmGap? gap = alarmGapFor(
        events: <CalendarEvent>[later, physics],
        alarms: <Alarm>[],
        now: now,
      );
      expect(gap!.event.title, 'Physics 101');
    });

    test('done events and plain deadlines are ignored', () {
      expect(
        alarmGapFor(
          events: <CalendarEvent>[
            _event('Exam', DateTime(2026, 11, 18, 8), done: true),
            _event('Essay due', DateTime(2026, 11, 18, 8)),
          ],
          alarms: <Alarm>[],
          now: now,
        ),
        isNull,
      );
    });

    test('today counts while its first event is still an hour away', () {
      final DateTime morning = DateTime(2026, 11, 18, 5);
      expect(
        alarmGapFor(
          events: <CalendarEvent>[physics],
          alarms: <Alarm>[],
          now: morning,
        )!.isToday,
        isTrue,
      );
      // Too late to wake up an hour ahead: look at tomorrow instead.
      expect(
        alarmGapFor(
          events: <CalendarEvent>[physics],
          alarms: <Alarm>[],
          now: DateTime(2026, 11, 18, 7, 30),
        ),
        isNull,
      );
    });

    test('the suggested alarm is an unsaved one an hour before', () {
      final Alarm suggested = suggestedAlarm(
        alarmGapFor(
          events: <CalendarEvent>[physics],
          alarms: <Alarm>[],
          now: now,
        )!,
      );
      expect(suggested.id, 0);
      expect((suggested.hour, suggested.minute), (7, 0));
      expect(suggested.label, 'Physics 101');
      expect(suggested.days, 0); // one class, one alarm
    });
  });

  group('calendar screen', () {
    late AppDatabase db;
    setUp(() => db = AppDatabase(NativeDatabase.memory()));
    tearDown(() => db.close());

    Future<void> open(WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [appDatabaseProvider.overrideWithValue(db)],
          child: const MaterialApp(home: CalendarScreen()),
        ),
      );
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 150)),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('the day list is in time of day order', (
      WidgetTester tester,
    ) async {
      final DateTime today = DateTime.now();
      final DateTime day = DateTime(today.year, today.month, today.day);
      await tester.runAsync(() async {
        final CalendarRepository repo = CalendarRepository(db);
        // A weekly class that began long ago, in the afternoon.
        await repo.createEvent(
          _event(
            'Afternoon class',
            day
                .subtract(const Duration(days: 28))
                .add(const Duration(hours: 15)),
            recurrence: 'daily',
          ),
        );
        await repo.createEvent(
          _event('Early bird', day.add(const Duration(hours: 7))),
        );
      });
      await open(tester);

      expect(
        tester.getTopLeft(find.text('Early bird')).dy,
        lessThan(tester.getTopLeft(find.text('Afternoon class')).dy),
      );
    });

    testWidgets('an odd length opens the editor without trouble', (
      WidgetTester tester,
    ) async {
      final DateTime today = DateTime.now();
      await tester.runAsync(
        () => CalendarRepository(db).createEvent(
          _event(
            'Odd length',
            DateTime(today.year, today.month, today.day, 10),
            duration: 50,
          ),
        ),
      );
      await open(tester);
      await tester.tap(find.text('Odd length'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Edit event'), findsOneWidget);
      expect(find.text('50 min'), findsWidgets);
    });

    testWidgets('a deleted note goes back to Add note and the link clears', (
      WidgetTester tester,
    ) async {
      final DateTime today = DateTime.now();
      await tester.runAsync(
        () => CalendarRepository(db).createEvent(
          _event(
            'Orphan',
            DateTime(today.year, today.month, today.day, 10),
            noteId: 999,
          ),
        ),
      );
      await open(tester);
      expect(find.byTooltip('Open note'), findsNothing);
      expect(find.byTooltip('Add note'), findsOneWidget);

      await tester.tap(find.byTooltip('Add note'));
      await tester.pumpAndSettle();
      final List<CalendarEvent>? events = await tester.runAsync(
        () => CalendarRepository(db).getEvents(),
      );
      expect(events!.single.noteId, isNull);
    });

    testWidgets('system back asks before discarding a typed event', (
      WidgetTester tester,
    ) async {
      await open(tester);
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();
      expect(find.text('New event'), findsWidgets);

      // Untouched: back just closes.
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('Title'), findsNothing);

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).first, 'Typed title');
      await tester.pump();
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('Discard changes?'), findsOneWidget);

      // Keep editing: the text survives.
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.text('Typed title'), findsOneWidget);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Discard'));
      await tester.pumpAndSettle();
      expect(find.text('Typed title'), findsNothing);
      expect(find.text('Title'), findsNothing);
    });

    testWidgets('mark done swaps the countdown for a Done pill', (
      WidgetTester tester,
    ) async {
      final DateTime today = DateTime.now();
      await tester.runAsync(
        () => CalendarRepository(db).createEvent(
          _event('Chem exam', DateTime(today.year, today.month, today.day, 23)),
        ),
      );
      await open(tester);
      expect(find.text('Exam · Today'), findsOneWidget);

      await tester.tap(find.text('Mark done'));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pumpAndSettle();
      expect(find.text('Exam · Today'), findsNothing);
      expect(find.text('Done'), findsWidgets);
    });
  });
}
