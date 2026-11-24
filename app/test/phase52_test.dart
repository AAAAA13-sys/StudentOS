import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studentos/core/db/app_database.dart';
import 'package:studentos/core/widgets/ponpon.dart';
import 'package:studentos/features/calendar/calendar_repository.dart';
import 'package:studentos/features/calendar/event.dart';
import 'package:studentos/features/calendar/widget_sync.dart';
import 'package:studentos/features/focus/alarm.dart';
import 'package:studentos/features/focus/clock_panels.dart';
import 'package:studentos/features/focus/focus_platform.dart';
import 'package:studentos/features/focus/wake_plan.dart';
import 'package:studentos/features/insights/calendar_insights.dart';
import 'package:studentos/features/insights/ponpon_insight.dart';
import 'package:studentos/features/insights/ponpon_talk_slot.dart';
import 'package:studentos/features/notes/note.dart';
import 'package:studentos/features/notes/notes_repository.dart';
import 'package:studentos/features/phone/phone_controller.dart';
import 'package:studentos/features/phone/phone_usage.dart';
import 'package:studentos/features/tasks/task_item.dart';
import 'package:studentos/features/tasks/tasks_controller.dart';
import 'package:studentos/features/tasks/tasks_repository.dart';
import 'package:studentos/features/work/shift.dart';
import 'package:studentos/features/work/work_repository.dart';

import 'focus_test.dart' show FakeFocusPlatform;
import 'phone_test.dart' show FakeUsage;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  group('Shift-aware Wake Guard', () {
    final DateTime evening = DateTime(2026, 11, 17, 20, 0);

    test('triggers for unpaid/unworked shift within 24h', () {
      final Shift morningShift = Shift(
        id: 1,
        job: 'Jollibee',
        startsAt: DateTime(2026, 11, 18, 6, 30),
        durationMinutes: 240,
      );
      final CommitmentAlarmGap? gap = alarmGapForCommitments(
        events: <CalendarEvent>[
          CalendarEvent(
            id: 1,
            title: 'Math 101',
            startsAt: DateTime(2026, 11, 18, 9, 0),
          ),
        ],
        shifts: <Shift>[morningShift],
        alarms: const <Alarm>[],
        now: evening,
      );
      expect(gap, isNotNull);
      expect(gap!.title, 'Shift at Jollibee');
      expect(gap.start, DateTime(2026, 11, 18, 6, 30));
      expect(gap.isToday, isFalse);
      expect(gap.isShift, isTrue);

      final Alarm suggested = suggestedAlarmForCommitment(gap);
      expect(suggested.id, 0);
      expect((suggested.hour, suggested.minute), (5, 30));
      expect(suggested.label, 'Shift at Jollibee');
    });

    test('ignores paid, worked, or >24h shifts, and clears with alarm', () {
      final Shift paidShift = Shift(
        id: 1,
        job: 'Paid Cafe',
        startsAt: DateTime(2026, 11, 18, 6, 0),
        durationMinutes: 180,
        paid: true,
      );
      final Shift farShift = Shift(
        id: 2,
        job: 'Far Cafe',
        startsAt: DateTime(2026, 11, 18, 21, 0), // 25h from 20:00
        durationMinutes: 180,
      );
      expect(
        alarmGapForCommitments(
          events: const <CalendarEvent>[],
          shifts: <Shift>[paidShift, farShift],
          alarms: const <Alarm>[],
          now: evening,
        ),
        isNull,
      );

      final Shift activeShift = Shift(
        id: 3,
        job: 'Bakery',
        startsAt: DateTime(2026, 11, 18, 6, 0),
        durationMinutes: 240,
      );
      expect(
        alarmGapForCommitments(
          events: const <CalendarEvent>[],
          shifts: <Shift>[activeShift],
          alarms: const <Alarm>[
            Alarm(id: 1, hour: 5, minute: 0, days: 0x7F, enabled: true),
          ],
          now: evening,
        ),
        isNull,
      );
    });
  });

  group('Rest Squeeze detection', () {
    test('restSqueezeHours detects <8h and ignores >=8h', () {
      final DateTime end = DateTime(2026, 11, 17, 23, 0);
      expect(
        restSqueezeHours(
          shiftEndsAt: end,
          nextStartAt: DateTime(2026, 11, 18, 6, 0),
        ),
        7.0,
      );
      expect(
        restSqueezeHours(
          shiftEndsAt: end,
          nextStartAt: DateTime(2026, 11, 18, 7, 0),
        ),
        isNull,
      );
      expect(
        restSqueezeHours(
          shiftEndsAt: end,
          nextStartAt: DateTime(2026, 11, 18, 7, 0),
          thresholdHours: 9.0,
        ),
        8.0,
      );
      // Overlapping or earlier commitments are not rest gaps.
      expect(
        restSqueezeHours(
          shiftEndsAt: end,
          nextStartAt: DateTime(2026, 11, 17, 22, 30),
        ),
        isNull,
      );
    });

    test('restSqueezeFor finds closing shift followed by early class', () {
      final DateTime now = DateTime(2026, 11, 17, 15, 0);
      final Shift closing = Shift(
        id: 1,
        job: 'Milk Tea',
        startsAt: DateTime(2026, 11, 17, 18, 0),
        durationMinutes: 300, // ends 23:00
      );
      final CalendarEvent earlyClass = CalendarEvent(
        id: 1,
        title: 'Chem Lab',
        startsAt: DateTime(2026, 11, 18, 6, 0),
      );
      final RestSqueeze? squeeze = restSqueezeFor(
        events: <CalendarEvent>[earlyClass],
        shifts: <Shift>[closing],
        now: now,
      );
      expect(squeeze, isNotNull);
      expect(squeeze!.shift.id, 1);
      expect(squeeze.nextTitle, 'Chem Lab');
      expect(squeeze.gapHours, 7.0);

      // With an 8h+ gap it returns null.
      expect(
        restSqueezeFor(
          events: <CalendarEvent>[
            CalendarEvent(
              id: 2,
              title: 'Late Lecture',
              startsAt: DateTime(2026, 11, 18, 8, 0),
            ),
          ],
          shifts: <Shift>[closing],
          now: now,
        ),
        isNull,
      );
    });
  });

  group('Rest goal persistence & Wind-Down UI without Usage Access', () {
    test('restGoalHoursProvider persists {7, 8, 9} in SettingRows', () async {
      final ProviderContainer c1 = ProviderContainer(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
      );
      addTearDown(c1.dispose);
      expect(c1.read(restGoalHoursProvider), 8);

      await c1.read(restGoalHoursProvider.notifier).setHours(9);
      expect(c1.read(restGoalHoursProvider), 9);

      // Invalid value is ignored.
      await c1.read(restGoalHoursProvider.notifier).setHours(5);
      expect(c1.read(restGoalHoursProvider), 9);

      final SettingRow? row = await (db.select(
        db.settingRows,
      )..where((t) => t.key.equals('rest_goal_hours'))).getSingleOrNull();
      expect(row?.value, '9');

      // Fresh container loads persisted value.
      final ProviderContainer c2 = ProviderContainer(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
      );
      addTearDown(c2.dispose);
      c2.read(restGoalHoursProvider);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(c2.read(restGoalHoursProvider), 9);
    });

    testWidgets(
      'AlarmsPanel / PhoneCards shows Wind-Down chips & Rest Squeeze without Usage access',
      (WidgetTester tester) async {
        final DateTime now = DateTime.now();
        final DateTime morning = DateTime(now.year, now.month, now.day + 1, 7);
        final DateTime shiftStart = morning.subtract(const Duration(hours: 11));
        await tester.runAsync(() async {
          await CalendarRepository(db).createEvent(
            CalendarEvent(id: 0, title: 'Bio 101', startsAt: morning),
          );
          await WorkRepository(db).createShifts(<Shift>[
            Shift(
              id: 0,
              job: 'Cafe',
              startsAt: shiftStart,
              durationMinutes: 240, // ends 7h before morning class
            ),
          ]);
        });

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              appDatabaseProvider.overrideWithValue(db),
              focusPlatformProvider.overrideWithValue(FakeFocusPlatform()),
              phoneUsageSourceProvider.overrideWithValue(
                FakeUsage(access: false),
              ),
            ],
            child: const MaterialApp(home: Scaffold(body: AlarmsPanel())),
          ),
        );
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 120)),
        );
        await tester.pumpAndSettle();

        expect(find.text('Phone rest'), findsOneWidget);
        expect(find.text('7h'), findsOneWidget);
        expect(find.text('8h'), findsOneWidget);
        expect(find.text('9h'), findsOneWidget);
        expect(
          find.textContaining('For 8h of phone rest before it'),
          findsOneWidget,
        );
        expect(find.byIcon(Icons.nights_stay_outlined), findsOneWidget);
        expect(
          find.textContaining('Shift at Cafe ends'),
          findsOneWidget,
        );

        await tester.tap(find.text('9h'));
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 60)),
        );
        await tester.pumpAndSettle();
        expect(
          find.textContaining('For 9h of phone rest before it'),
          findsOneWidget,
        );
      },
    );
  });

  group('Today widget sync & check-off reconciliation', () {
    const MethodChannel channel = MethodChannel('home_widget');
    late Map<String, Object?> store;
    late List<String> updatedWidgets;

    setUp(() {
      store = <String, Object?>{};
      updatedWidgets = <String>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall call) async {
            final Map<Object?, Object?>? args =
                call.arguments as Map<Object?, Object?>?;
            switch (call.method) {
              case 'saveWidgetData':
                final String id = args!['id']! as String;
                final Object? data = args['data'];
                if (data == null) {
                  store.remove(id);
                } else {
                  store[id] = data;
                }
                return true;
              case 'getWidgetData':
                final String id = args!['id']! as String;
                return store[id] ?? args['defaultValue'];
              case 'updateWidget':
                updatedWidgets.add(args!['android']! as String);
                return true;
              default:
                return null;
            }
          });
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    test(
      'syncTodayWidget writes shifts, events, top 2 due tasks, and recall count',
      () async {
        final DateTime now = DateTime(2026, 11, 24, 10, 0);
        await CalendarRepository(db).createEvent(
          CalendarEvent(
            id: 0,
            title: 'Physics',
            startsAt: DateTime(2026, 11, 25, 8, 0),
          ),
        );
        await WorkRepository(db).createShifts(<Shift>[
          Shift(
            id: 0,
            job: 'Library',
            startsAt: DateTime(2026, 11, 24, 17, 0),
            durationMinutes: 180,
          ),
          Shift(
            id: 0,
            job: 'Old Paid',
            startsAt: DateTime(2026, 11, 24, 14, 0),
            durationMinutes: 120,
            paid: true,
          ),
        ]);
        // Mark the paid shift paid in DB (createShifts defaults paid=false).
        final List<Shift> allShifts = await WorkRepository(db).getShifts();
        await WorkRepository(db).markPaid(<int>[
          allShifts.firstWhere((Shift s) => s.job == 'Old Paid').id,
        ]);

        final TaskRepository taskRepo = TaskRepository(db);
        await taskRepo.createTask(
          const TaskItem(id: 0, title: 'Overdue lab', dueOn: '2026-11-23'),
        );
        await taskRepo.createTask(
          const TaskItem(id: 0, title: 'Today quiz', dueOn: '2026-11-24'),
        );
        await taskRepo.createTask(
          const TaskItem(id: 0, title: 'Today reading', dueOn: '2026-11-24'),
        );
        await taskRepo.createTask(
          const TaskItem(id: 0, title: 'Tomorrow task', dueOn: '2026-11-25'),
        );

        await NotesRepository(db).createNote(
          const Note(
            id: 0,
            title: 'Chem',
            body: 'Q: H2O?\nA: Water\nQ: NaCl?\nA: Salt',
            tags: <String>[],
          ),
        );

        await syncTodayWidget(db, now: now);

        final List<dynamic> events =
            jsonDecode(store['upcoming_events']! as String) as List<dynamic>;
        expect(events.length, 2);
        expect((events.first as Map)['t'], 'Shift: Library');
        expect((events.first as Map)['isShift'], isTrue);
        expect((events.last as Map)['t'], 'Physics');
        expect((events.last as Map)['isShift'], isFalse);

        final List<dynamic> tasks =
            jsonDecode(store['widget_tasks']! as String) as List<dynamic>;
        expect(tasks.length, 2);
        expect((tasks.first as Map)['title'], 'Overdue lab');
        expect((tasks.first as Map)['overdue'], isTrue);
        expect((tasks.first as Map)['dueOn'], '2026-11-23');
        expect(store['widget_tasks_open_due_count'], 3);
        expect(store['widget_recall_due'], 2);
        expect(updatedWidgets, contains('CalendarWidgetProvider'));
      },
    );

    test(
      'reconcileWidgetCompletedTasks marks one-off done and advances repeating via nextDuePast',
      () async {
        final TaskRepository taskRepo = TaskRepository(db);
        final int oneOffId = await taskRepo.createTask(
          const TaskItem(id: 0, title: 'Submit form', dueOn: '2026-11-24'),
        );
        final int repeatingId = await taskRepo.createTask(
          const TaskItem(
            id: 0,
            title: 'Take meds',
            dueOn: '2026-11-22',
            repeat: TaskRepeat.daily,
          ),
        );
        final int atMs = DateTime(2026, 11, 24, 9, 30).millisecondsSinceEpoch;
        store['widget_completed_task_ids'] = jsonEncode(<Map<String, Object>>[
          <String, Object>{'id': oneOffId, 'at': atMs},
          <String, Object>{'id': repeatingId, 'at': atMs},
        ]);

        final ProviderContainer c = ProviderContainer(
          overrides: [appDatabaseProvider.overrideWithValue(db)],
        );
        addTearDown(c.dispose);
        final List<TaskItem> loaded = await c.read(
          tasksControllerProvider.future,
        );

        expect(store.containsKey('widget_completed_task_ids'), isFalse);
        final TaskItem oneOff = loaded.firstWhere((t) => t.id == oneOffId);
        expect(oneOff.done, isTrue);
        expect(oneOff.doneAt, DateTime.fromMillisecondsSinceEpoch(atMs));

        final TaskItem repeating = loaded.firstWhere(
          (t) => t.id == repeatingId,
        );
        expect(repeating.done, isFalse);
        expect(repeating.dueOn, '2026-11-25');
      },
    );
  });

  group('Ponpon Rest Squeeze insight', () {
    test('calendarInsights emits sleepy seeAlarms tip on Rest Squeeze', () {
      final DateTime now = DateTime(2026, 11, 17, 15, 0);
      final List<PonponInsight> insights = calendarInsights(
        events: <CalendarEvent>[
          CalendarEvent(
            id: 1,
            title: 'Physics 101',
            startsAt: DateTime(2026, 11, 18, 6, 30),
          ),
        ],
        shifts: <Shift>[
          Shift(
            id: 1,
            job: 'Cafe',
            startsAt: DateTime(2026, 11, 17, 17, 0),
            durationMinutes: 360, // ends 23:00 -> 7h 30m before 6:30 AM
          ),
        ],
        now: now,
      );

      final PonponInsight tip = insights.firstWhere(
        (PonponInsight i) => i.action == PonponAction.seeAlarms,
      );
      expect(tip.mood, PonponMood.sleepy);
      expect(tip.priority, 2);
      expect(tip.action!.label, 'Check alarms');
      expect(tip.text, contains('7 h 30 min'));
    });

    testWidgets('runPonponAction(seeAlarms) switches to CalendarView.alarm', (
      WidgetTester tester,
    ) async {
      late WidgetRef capturedRef;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [appDatabaseProvider.overrideWithValue(db)],
          child: MaterialApp(
            home: Consumer(
              builder: (BuildContext context, WidgetRef ref, _) {
                capturedRef = ref;
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      );
      expect(capturedRef.read(calendarViewProvider), CalendarView.schedule);
      runPonponAction(
        tester.element(find.byType(SizedBox)),
        capturedRef,
        PonponAction.seeAlarms,
      );
      expect(capturedRef.read(calendarViewProvider), CalendarView.alarm);
    });
  });
}
