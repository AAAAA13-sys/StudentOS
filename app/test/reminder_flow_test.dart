import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studentos/core/db/app_database.dart';
import 'package:studentos/features/calendar/calendar_controller.dart';
import 'package:studentos/features/calendar/calendar_repository.dart';
import 'package:studentos/features/calendar/calendar_screen.dart';
import 'package:studentos/features/calendar/event.dart';
import 'package:studentos/features/calendar/reminder_platform.dart';
import 'package:studentos/features/focus/alarm.dart';
import 'package:studentos/features/focus/focus_platform.dart';
import 'package:studentos/features/focus/focus_repository.dart';
import 'package:studentos/main.dart';

import 'focus_test.dart' show FakeFocusPlatform;

class FakeReminderPlatform implements ReminderPlatform {
  final List<List<Map<String, Object?>>> calls = <List<Map<String, Object?>>>[];

  @override
  Future<void> sync(List<Map<String, Object?>> reminders) async =>
      calls.add(reminders);
}

class _RoutePlatform extends FakeFocusPlatform {
  _RoutePlatform(this.route);

  String? route;

  @override
  Future<String?> takeRoute() async {
    final String? r = route;
    route = null;
    return r;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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

  CalendarEvent soon(int minutes, {String title = 'Lab'}) => CalendarEvent(
    id: 0,
    title: title,
    startsAt: DateTime.now().add(Duration(minutes: minutes)),
    reminderMinutes: 10,
  );

  test('add, update and delete re-sync the reminders', () async {
    final FakeReminderPlatform platform = FakeReminderPlatform();
    final ProviderContainer c = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(database),
        reminderPlatformProvider.overrideWithValue(platform),
      ],
    );
    addTearDown(c.dispose);
    await c.read(calendarControllerProvider.future);
    final CalendarController controller = c.read(
      calendarControllerProvider.notifier,
    );
    await controller.syncReminders();
    expect(platform.calls.last, isEmpty);

    await controller.addEvent(soon(120));
    await controller.syncReminders();
    expect(platform.calls.last, hasLength(1));

    await controller.addEvents(<CalendarEvent>[soon(180), soon(240)]);
    await controller.syncReminders();
    expect(platform.calls.last, hasLength(3));

    final CalendarEvent first = c.read(calendarControllerProvider).value!.first;
    await controller.updateEvent(first.copyWith(title: 'Renamed'));
    await controller.syncReminders();
    expect(platform.calls.last.map((m) => m['title']), contains('Renamed'));

    await controller.deleteEvent(first.id);
    await controller.syncReminders();
    expect(platform.calls.last, hasLength(2));
    for (final Map<String, Object?> m in platform.calls.last) {
      expect(m.keys, containsAll(<String>['id', 'fireAt', 'route']));
    }
  });

  testWidgets('the editor defaults to 10 min and saves the chosen reminder', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(800, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final FakeReminderPlatform reminders = FakeReminderPlatform();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(database),
          focusPlatformProvider.overrideWithValue(FakeFocusPlatform()),
          reminderPlatformProvider.overrideWithValue(reminders),
        ],
        child: const MaterialApp(home: CalendarScreen()),
      ),
    );
    await settle(tester);

    Future<void> openEditor() async {
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();
    }

    Future<void> save(String title) async {
      await tester.enterText(find.byType(TextFormField).first, title);
      await tester.tap(find.text('Save event'));
      await tester.pumpAndSettle();
      await settle(tester);
    }

    await openEditor();
    expect(find.text('Remind me'), findsOneWidget);
    expect(find.text('10 min before'), findsOneWidget);
    await save('Default one');

    await openEditor();
    await tester.tap(find.byKey(const ValueKey<String>('reminder-field')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('30 min before').last);
    await tester.pumpAndSettle();
    await save('Chosen one');

    await openEditor();
    await tester.tap(find.text('Exam / Quiz'));
    await tester.pumpAndSettle();
    expect(find.text('1 day before'), findsOneWidget);
    await save('Exam one');

    await openEditor();
    await tester.tap(find.byKey(const ValueKey<String>('reminder-field')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('None').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Exam / Quiz'));
    await tester.pumpAndSettle();
    expect(find.text('1 day before'), findsNothing);
    await save('Touched one');

    final List<CalendarEvent> events = (await tester.runAsync(
      () => CalendarRepository(database).getEvents(),
    ))!;
    int? lead(String t) =>
        events.firstWhere((e) => e.title == t).reminderMinutes;
    expect(lead('Default one'), 10);
    expect(lead('Chosen one'), 30);
    expect(lead('Exam one'), 1440);
    expect(lead('Touched one'), isNull);
    expect(reminders.calls, isNotEmpty);
  });

  testWidgets('a reminder tap opens that day in the Calendar', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(database),
          focusPlatformProvider.overrideWithValue(
            _RoutePlatform('day:2026-11-20'),
          ),
          reminderPlatformProvider.overrideWithValue(FakeReminderPlatform()),
        ],
        child: const StudentOSApp(),
      ),
    );
    await settle(tester);
    await tester.pumpAndSettle();
    final ProviderContainer c = ProviderScope.containerOf(
      tester.element(find.byType(NavigationBar)),
    );
    expect(c.read(calendarShowDayProvider), DateTime(2026, 11, 20));
    expect(find.textContaining('Nov 20'), findsWidgets);
  });

  testWidgets('a snoozed alarm shows when it rings again', (
    WidgetTester tester,
  ) async {
    final FakeFocusPlatform platform = FakeFocusPlatform();
    final Alarm alarm = await FocusRepository(database).createAlarm(
      const Alarm(id: 0, hour: 6, minute: 15, days: 0x7F, label: 'Gym'),
    );
    platform.snoozed = <int, DateTime>{
      alarm.id: DateTime.now().add(const Duration(minutes: 5)),
    };
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(database),
          focusPlatformProvider.overrideWithValue(platform),
        ],
        child: const MaterialApp(home: CalendarScreen()),
      ),
    );
    await settle(tester);
    await tester.tap(find.text('Alarms'));
    await settle(tester);
    await settle(tester);
    expect(find.textContaining('Snoozed until'), findsOneWidget);
    expect(find.textContaining('Rings'), findsNothing);
  });
}
