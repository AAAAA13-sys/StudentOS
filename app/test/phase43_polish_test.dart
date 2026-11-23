import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studentos/core/db/app_database.dart';
import 'package:studentos/core/theme/app_theme.dart';
import 'package:studentos/core/widgets/ponpon.dart';
import 'package:studentos/features/calendar/calendar_repository.dart';
import 'package:studentos/features/calendar/calendar_screen.dart';
import 'package:studentos/features/calendar/event.dart';
import 'package:studentos/features/finance/bill.dart';
import 'package:studentos/features/finance/bills_repository.dart';
import 'package:studentos/features/finance/finance_screen.dart';
import 'package:studentos/features/focus/focus_controller.dart';
import 'package:studentos/features/focus/focus_platform.dart';
import 'package:studentos/features/focus/focus_settings_sheet.dart';
import 'package:studentos/features/work/day_shifts.dart';
import 'package:studentos/features/work/shift.dart';
import 'package:studentos/features/work/work_repository.dart';

class _TestFocusPlatform implements FocusPlatform {
  PhoneReadiness ready = const PhoneReadiness(accessibility: false);
  int readinessCalls = 0;

  @override
  Future<void> syncAlarms(List<Map<String, Object?>> alarms) async {}

  @override
  Future<List<int>> takeFiredOnce() async => <int>[];

  @override
  Future<Map<int, DateTime>> snoozes() async => <int, DateTime>{};

  @override
  Future<void> testAlarm(Map<String, Object?> alarm) async {}

  @override
  Future<({String uri, String name})?> pickSound(String? current) async => null;

  @override
  Future<PhoneReadiness> readiness() async {
    readinessCalls++;
    return ready;
  }

  @override
  Future<void> openSetting(String which) async {}

  @override
  Future<void> startFocus(Map<String, Object?> session) async {}

  @override
  Future<void> stopFocus() async {}

  @override
  Future<void> setPinned(bool pinned) async {}

  @override
  Future<List<InstalledApp>> launchableApps() async => <InstalledApp>[];

  @override
  Future<String?> takeRoute() async => null;

  @override
  Future<bool> pinWidget(String which) async => false;

  @override
  void onRouteWaiting(void Function() onRoute) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> settle(WidgetTester tester) async {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pumpAndSettle();
  }

  group('Finance empty month Ponpon deduplication', () {
    testWidgets(
      'hides empty-state Ponpon while talk bubble is active, restores on close',
      (WidgetTester tester) async {
        final AppDatabase db = AppDatabase(NativeDatabase.memory());
        addTearDown(db.close);
        final DateTime today = dateOnly(DateTime.now());

        await tester.runAsync(() {
          return BillsRepository(db).createBill(
            Bill(
              id: 0,
              title: 'Rent',
              amountCents: 350000,
              category: 'Other',
              cadence: 'monthly:${today.day}',
              nextDueOn: formatDateKey(today),
            ),
          );
        });

        await tester.pumpWidget(
          ProviderScope(
            overrides: [appDatabaseProvider.overrideWithValue(db)],
            child: MaterialApp(
              theme: AppTheme.light,
              home: const FinanceScreen(),
            ),
          ),
        );
        await settle(tester);

        expect(find.text('No transactions this month'), findsOneWidget);
        expect(find.textContaining('Bill due today: Rent'), findsOneWidget);
        // Only the talk bubble's 48dp Ponpon is shown; the 88dp empty-state
        // Ponpon is suppressed.
        expect(find.byType(Ponpon), findsOneWidget);

        // Dismiss the talk bubble -> empty-state Ponpon returns.
        await tester.tap(find.byTooltip('Hide Ponpon tips'));
        await settle(tester);

        expect(find.textContaining('Bill due today: Rent'), findsNothing);
        expect(find.byType(Ponpon), findsOneWidget);
        final Ponpon emptyPonpon = tester.widget<Ponpon>(find.byType(Ponpon));
        expect(emptyPonpon.size, 88);
      },
    );
  });

  group('Calendar Day view parity', () {
    testWidgets('DayShifts shows paid label and opens editShift on tap', (
      WidgetTester tester,
    ) async {
      final AppDatabase db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final DateTime day = DateTime(2026, 11, 20);

      await tester.runAsync(() async {
        final WorkRepository repo = WorkRepository(db);
        await repo.createShifts(<Shift>[
          Shift(
            id: 0,
            job: 'Cafe',
            startsAt: DateTime(2026, 11, 20, 9),
            durationMinutes: 240,
            hourlyRateCents: 10000,
          ),
        ]);
        final List<Shift> created = await repo.getShifts();
        await repo.markPaid(<int>[created.single.id]);
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [appDatabaseProvider.overrideWithValue(db)],
          child: MaterialApp(
            theme: AppTheme.light,
            home: Scaffold(body: DayShifts(day: day)),
          ),
        ),
      );
      await settle(tester);

      expect(find.text('Shift at Cafe'), findsOneWidget);
      expect(find.textContaining('· paid'), findsOneWidget);

      await tester.tap(find.text('Shift at Cafe'));
      await settle(tester);

      expect(find.text('Edit shift'), findsOneWidget);
    });

    testWidgets(
      'CalendarScreen sorts isAllDay first and dims/strikes done events',
      (WidgetTester tester) async {
        final AppDatabase db = AppDatabase(NativeDatabase.memory());
        addTearDown(db.close);
        final DateTime now = DateTime.now();
        final DateTime today = DateTime(now.year, now.month, now.day);

        await tester.runAsync(() async {
          final CalendarRepository repo = CalendarRepository(db);
          await repo.createEvent(
            CalendarEvent(
              id: 0,
              title: 'AAA Timed',
              startsAt: DateTime(today.year, today.month, today.day, 0, 0),
              durationMinutes: 60,
              done: true,
            ),
          );
          await repo.createEvent(
            CalendarEvent(
              id: 0,
              title: 'ZZZ All Day',
              startsAt: DateTime(today.year, today.month, today.day, 0, 0),
              durationMinutes: 1440,
            ),
          );
        });

        await tester.pumpWidget(
          ProviderScope(
            overrides: [appDatabaseProvider.overrideWithValue(db)],
            child: MaterialApp(
              theme: AppTheme.light,
              home: const CalendarScreen(),
            ),
          ),
        );
        await settle(tester);

        await tester.scrollUntilVisible(
          find.text('AAA Timed'),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();

        final double allDayY = tester.getTopLeft(find.text('ZZZ All Day')).dy;
        final double timedY = tester.getTopLeft(find.text('AAA Timed')).dy;
        expect(allDayY, lessThan(timedY));

        final Text doneTitle = tester.widget<Text>(find.text('AAA Timed'));
        expect(doneTitle.style?.decoration, TextDecoration.lineThrough);

        final Opacity doneOpacity = tester.widget<Opacity>(
          find
              .ancestor(
                of: find.text('AAA Timed'),
                matching: find.byType(Opacity),
              )
              .first,
        );
        expect(doneOpacity.opacity, 0.55);
      },
    );
  });

  group('Strict focus readiness refresh', () {
    testWidgets(
      'saving FocusSettings with strict lockdown invalidates readinessProvider',
      (WidgetTester tester) async {
        final AppDatabase db = AppDatabase(NativeDatabase.memory());
        addTearDown(db.close);
        final _TestFocusPlatform platform = _TestFocusPlatform();

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              appDatabaseProvider.overrideWithValue(db),
              focusPlatformProvider.overrideWithValue(platform),
            ],
            child: MaterialApp(
              theme: AppTheme.light,
              home: Scaffold(
                body: Consumer(
                  builder: (BuildContext context, WidgetRef ref, _) {
                    final PhoneReadiness? ready = ref
                        .watch(readinessProvider)
                        .value;
                    final FocusState? focus = ref
                        .watch(focusControllerProvider)
                        .value;
                    return Column(
                      children: <Widget>[
                        Text(
                          'ready:${ready?.accessibility}:${focus?.settings.lockdown.name}',
                        ),
                        FilledButton(
                          onPressed: () => showFocusSettings(context),
                          child: const Text('Open settings'),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        );
        await settle(tester);

        expect(find.text('ready:false:light'), findsOneWidget);
        final int initialCalls = platform.readinessCalls;

        await tester.tap(find.text('Open settings'));
        await settle(tester);

        final Finder sheetScrollable = find.byType(Scrollable).first;
        await tester.scrollUntilVisible(
          find.text('Strict'),
          150,
          scrollable: sheetScrollable,
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('Strict'));
        await settle(tester);

        // Simulate user having enabled Accessibility before tapping Save.
        platform.ready = const PhoneReadiness(accessibility: true);
        await tester.scrollUntilVisible(
          find.widgetWithText(FilledButton, 'Save'),
          150,
          scrollable: sheetScrollable,
        );
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(FilledButton, 'Save'));
        await settle(tester);

        expect(platform.readinessCalls, greaterThan(initialCalls));
        expect(find.text('ready:true:strict'), findsOneWidget);
      },
    );
  });
}
