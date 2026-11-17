import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studentos/core/db/app_database.dart';
import 'package:studentos/features/calendar/calendar_repository.dart';
import 'package:studentos/features/calendar/calendar_screen.dart';
import 'package:studentos/features/calendar/event.dart';
import 'package:studentos/features/calendar/ics_import.dart';
import 'package:studentos/features/calendar/ics_import_sheet.dart';
import 'package:studentos/features/calendar/reminder_platform.dart';
import 'package:studentos/features/focus/focus_platform.dart';

import 'focus_test.dart' show FakeFocusPlatform;
import 'reminder_flow_test.dart' show FakeReminderPlatform;

String ics(List<String> lines) =>
    'BEGIN:VCALENDAR\r\nVERSION:2.0\r\n${lines.join('\r\n')}\r\nEND:VCALENDAR\r\n';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('parseIcs', () {
    test('unfolds lines and unescapes text', () {
      final IcsImportResult r = parseIcs(
        ics(<String>[
          'BEGIN:VEVENT',
          'SUMMARY:Math\\, Physics\\; and a very long',
          '  title that wraps',
          'LOCATION:Room 4\\\\B',
          'DESCRIPTION:Line one\\nLine two',
          'DTSTART:20261120T090000',
          'DTEND:20261120T103000',
          'END:VEVENT',
        ]),
      );
      expect(r.skipped, 0);
      final CalendarEvent e = r.events.single;
      expect(e.title, 'Math, Physics; and a very long title that wraps');
      expect(e.location, r'Room 4\B');
      expect(e.notes, 'Line one\nLine two');
      expect(e.startsAt, DateTime(2026, 11, 20, 9));
      expect(e.durationMinutes, 90);
      expect(e.recurrence, 'none');
      expect(e.reminderMinutes, 10);
    });

    test('converts UTC to local, TZID stays wall time, DURATION works', () {
      final IcsImportResult r = parseIcs(
        ics(<String>[
          'BEGIN:VEVENT',
          'SUMMARY:Utc',
          'DTSTART:20261120T090000Z',
          'DURATION:PT2H',
          'END:VEVENT',
          'BEGIN:VEVENT',
          'SUMMARY:Zoned',
          'DTSTART;TZID=Asia/Manila:20261120T090000',
          'END:VEVENT',
        ]),
      );
      expect(r.events[0].startsAt, DateTime.utc(2026, 11, 20, 9).toLocal());
      expect(r.events[0].durationMinutes, 120);
      expect(r.events[1].startsAt, DateTime(2026, 11, 20, 9));
      expect(r.events[1].durationMinutes, 60);
    });

    test('all-day events become 24 hour events without a reminder', () {
      final IcsImportResult r = parseIcs(
        ics(<String>[
          'BEGIN:VEVENT',
          'SUMMARY:Holiday',
          'DTSTART;VALUE=DATE:20261225',
          'DTEND;VALUE=DATE:20261226',
          'END:VEVENT',
        ]),
      );
      final CalendarEvent e = r.events.single;
      expect(e.startsAt, DateTime(2026, 12, 25));
      expect(e.durationMinutes, 1440);
      expect(e.reminderMinutes, isNull);
      expect(r.warnings, isNotEmpty);
    });

    test('weekly BYDAY with UNTIL becomes one event per day', () {
      // 2026-11-17 is a Tuesday.
      final IcsImportResult r = parseIcs(
        ics(<String>[
          'BEGIN:VEVENT',
          'SUMMARY:Class',
          'DTSTART:20261117T080000',
          'RRULE:FREQ=WEEKLY;BYDAY=TU,TH;UNTIL=20261231T000000Z',
          'EXDATE:20261124T080000',
          'END:VEVENT',
        ]),
      );
      expect(r.events, hasLength(2));
      expect(r.events[0].startsAt, DateTime(2026, 11, 17, 8));
      expect(r.events[1].startsAt, DateTime(2026, 11, 19, 8));
      expect(
        r.events.every((CalendarEvent e) => e.recurrence == 'weekly'),
        isTrue,
      );
      expect(r.events[0].recurrenceUntil, isNotNull);
      expect(r.warnings.any((String w) => w.contains('EXDATE')), isTrue);
    });

    test('COUNT is converted to an end date', () {
      final IcsImportResult r = parseIcs(
        ics(<String>[
          'BEGIN:VEVENT',
          'SUMMARY:Daily',
          'DTSTART:20261101T080000',
          'RRULE:FREQ=DAILY;COUNT=3',
          'END:VEVENT',
          'BEGIN:VEVENT',
          'SUMMARY:Weekly',
          'DTSTART:20261102T080000',
          'RRULE:FREQ=WEEKLY;COUNT=3',
          'END:VEVENT',
        ]),
      );
      expect(r.events[0].recurrenceUntil, '2026-11-03');
      expect(r.events[1].recurrenceUntil, '2026-11-16');
    });

    test('unsupported rules, alarms and bad blocks are skipped or ignored', () {
      final IcsImportResult r = parseIcs(
        ics(<String>[
          'BEGIN:VEVENT',
          'SUMMARY:Yearly',
          'DTSTART:20261101T080000',
          'RRULE:FREQ=YEARLY',
          'END:VEVENT',
          'BEGIN:VEVENT',
          'SUMMARY:Every other week',
          'DTSTART:20261101T080000',
          'RRULE:FREQ=WEEKLY;INTERVAL=2',
          'END:VEVENT',
          'BEGIN:VEVENT',
          'SUMMARY:No start',
          'END:VEVENT',
          'BEGIN:VEVENT',
          'SUMMARY:With alarm',
          'DTSTART:20261101T080000',
          'BEGIN:VALARM',
          'DESCRIPTION:ring ring',
          'END:VALARM',
          'END:VEVENT',
        ]),
      );
      expect(r.skipped, 3);
      expect(r.events.single.title, 'With alarm');
      expect(r.events.single.notes, isNull);
    });

    test('malformed input never throws', () {
      for (final String junk in <String>[
        '',
        'not a calendar at all',
        'BEGIN:VEVENT\nSUMMARY:Open',
        'BEGIN:VEVENT\nDTSTART:2026-99-99\nEND:VEVENT',
        'BEGIN:VEVENT\nDTSTART:20261301T250000\nEND:VEVENT',
        '\u0000\u0001: : ;;;\nEND:VEVENT\nEND:VEVENT',
      ]) {
        final IcsImportResult r = parseIcs(junk);
        expect(r.events, isEmpty, reason: junk);
      }
    });
  });

  group('import flow', () {
    late AppDatabase database;
    setUp(() => database = AppDatabase(NativeDatabase.memory()));
    tearDown(() => database.close());

    Future<void> settle(WidgetTester tester) async {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pump();
      await tester.pump();
    }

    testWidgets('preview then import, and importing twice adds nothing', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(800, 2600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      final String file = ics(<String>[
        'BEGIN:VEVENT',
        'SUMMARY:Chemistry',
        'DTSTART:20270105T090000',
        'RRULE:FREQ=WEEKLY;BYDAY=TU,TH',
        'END:VEVENT',
        'BEGIN:VEVENT',
        'SUMMARY:Odd one',
        'DTSTART:20270105T090000',
        'RRULE:FREQ=YEARLY',
        'END:VEVENT',
      ]);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWithValue(database),
            focusPlatformProvider.overrideWithValue(FakeFocusPlatform()),
            reminderPlatformProvider.overrideWithValue(FakeReminderPlatform()),
            icsFilePickerProvider.overrideWithValue(() async => file),
          ],
          child: const MaterialApp(home: CalendarScreen()),
        ),
      );
      await settle(tester);

      Future<void> openPreview() async {
        await tester.tap(find.byTooltip('More'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Import .ics file'));
        await tester.pumpAndSettle();
        await settle(tester);
        await tester.pumpAndSettle();
      }

      await openPreview();
      expect(find.text('2 events found'), findsOneWidget);
      expect(find.text('Chemistry'), findsNWidgets(2));
      expect(find.textContaining('1 event not supported'), findsOneWidget);
      await tester.tap(find.text('Import 2'));
      await tester.pumpAndSettle();
      await settle(tester);
      expect(find.text('Imported 2 events'), findsOneWidget);
      expect(find.textContaining('Jan 5'), findsWidgets);

      final List<CalendarEvent> saved = (await tester.runAsync(
        () => CalendarRepository(database).getEvents(),
      ))!;
      expect(saved, hasLength(2));

      await openPreview();
      expect(
        find.textContaining('2 events already in your calendar'),
        findsOneWidget,
      );
      expect(find.text('Nothing new to import.'), findsOneWidget);
      expect(
        tester
            .widget<FilledButton>(find.widgetWithText(FilledButton, 'Import'))
            .onPressed,
        isNull,
      );
    });
  });
}
