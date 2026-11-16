import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studentos/core/db/app_database.dart';
import 'package:studentos/core/db/backup.dart';
import 'package:studentos/features/focus/alarm.dart';
import 'package:studentos/features/focus/focus_controller.dart';
import 'package:studentos/features/focus/focus_plan.dart';
import 'package:studentos/features/focus/focus_platform.dart';
import 'package:studentos/features/focus/focus_repository.dart';
import 'package:studentos/features/calendar/calendar_screen.dart';

/// Records what the app asks of Android.
class FakeFocusPlatform implements FocusPlatform {
  List<Map<String, Object?>> synced = <Map<String, Object?>>[];
  List<int> firedOnce = <int>[];
  Map<String, Object?>? focus;
  final List<bool> pins = <bool>[];
  PhoneReadiness ready = const PhoneReadiness(accessibility: true);

  @override
  Future<void> syncAlarms(List<Map<String, Object?>> alarms) async =>
      synced = alarms;

  @override
  Future<List<int>> takeFiredOnce() async {
    final List<int> ids = firedOnce;
    firedOnce = <int>[];
    return ids;
  }

  @override
  Future<void> testAlarm(Map<String, Object?> alarm) async {}

  @override
  Future<({String uri, String name})?> pickSound(String? current) async => null;

  @override
  Future<PhoneReadiness> readiness() async => ready;

  @override
  Future<void> openSetting(String which) async {}

  @override
  Future<void> startFocus(Map<String, Object?> session) async =>
      focus = session;

  @override
  Future<void> stopFocus() async => focus = null;

  @override
  Future<void> setPinned(bool pinned) async => pins.add(pinned);

  @override
  Future<List<InstalledApp>> launchableApps() async => const <InstalledApp>[];

  @override
  Future<String?> takeRoute() async => null;

  @override
  void onRouteWaiting(void Function() onRoute) {}

  @override
  Future<bool> pinWidget(String which) async => true;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase database;
  setUp(() => database = AppDatabase(NativeDatabase.memory()));
  tearDown(() => database.close());

  group('Alarm', () {
    // Monday 16 November 2026.
    final DateTime monday10pm = DateTime(2026, 11, 16, 22);

    test('rings next on the right day', () {
      const Alarm weekdays = Alarm(id: 1, hour: 6, minute: 30, days: 0x1F);
      expect(weekdays.nextRing(monday10pm), DateTime(2026, 11, 17, 6, 30));
      // Friday night skips the weekend.
      expect(
        weekdays.nextRing(DateTime(2026, 11, 20, 22)),
        DateTime(2026, 11, 23, 6, 30),
      );
      const Alarm once = Alarm(id: 2, hour: 23, minute: 0);
      expect(once.nextRing(monday10pm), DateTime(2026, 11, 16, 23));
      expect(once.copyWith(enabled: false).nextRing(monday10pm), isNull);
      // Sunday only (bit 6).
      const Alarm sunday = Alarm(id: 3, hour: 8, minute: 0, days: 0x40);
      expect(sunday.nextRing(monday10pm), DateTime(2026, 11, 22, 8));
    });

    test('describes its days, challenge and countdown', () {
      expect(const Alarm(id: 1, hour: 6, minute: 0).daysLabel, 'Once');
      expect(
        const Alarm(id: 1, hour: 6, minute: 0, days: 0x7F).daysLabel,
        'Every day',
      );
      expect(
        const Alarm(id: 1, hour: 6, minute: 0, days: 0x1F).daysLabel,
        'Weekdays',
      );
      expect(
        const Alarm(id: 1, hour: 6, minute: 0, days: 0x15).daysLabel,
        'Mon, Wed, Fri',
      );
      expect(
        const Alarm(id: 1, hour: 6, minute: 0).challengeSummary,
        '3 medium sums',
      );
      const Alarm surprise = Alarm(
        id: 1,
        hour: 6,
        minute: 0,
        challenge: AlarmChallenge.random,
      );
      expect(surprise.challengeSummary, 'Random challenge');
      // Android picks the actual challenge at ring time.
      expect(surprise.toNative()['challenge'], 'random');
      expect(AlarmChallenge.fromKey('random'), AlarmChallenge.random);
      expect(ringsIn(const Duration(hours: 7, minutes: 20)), 'in 7 h 20 min');
      expect(ringsIn(const Duration(seconds: 20)), 'in less than a minute');
      // An empty sentence falls back to the default one for Android.
      expect(
        const Alarm(id: 1, hour: 6, minute: 0).toNative()['phrase'],
        defaultAlarmPhrase,
      );
    });

    test(
      'saved alarms reach Android; one-time alarms that rang turn off',
      () async {
        final FakeFocusPlatform platform = FakeFocusPlatform();
        final ProviderContainer c = ProviderContainer(
          overrides: [
            appDatabaseProvider.overrideWithValue(database),
            focusPlatformProvider.overrideWithValue(platform),
          ],
        );
        addTearDown(c.dispose);
        await c.read(alarmControllerProvider.future);
        final AlarmController alarms = c.read(alarmControllerProvider.notifier);
        final Alarm once = await alarms.save(
          const Alarm(id: 0, hour: 5, minute: 45, label: 'Exam day'),
        );
        await alarms.save(
          const Alarm(
            id: 0,
            hour: 6,
            minute: 0,
            days: 0x1F,
            challenge: AlarmChallenge.type,
            phrase: 'Up and at it',
          ),
        );
        expect(platform.synced.length, 2);
        expect(platform.synced.first['label'], 'Exam day');
        expect(platform.synced.last['challenge'], 'type');
        expect(platform.synced.last['phrase'], 'Up and at it');

        platform.firedOnce = <int>[once.id];
        await alarms.refresh();
        final List<Alarm> after = c.read(alarmControllerProvider).value!;
        expect(after.first.enabled, isFalse);
        expect(after.last.enabled, isTrue);
        expect(platform.synced.first['enabled'], isFalse);
      },
    );

    test('alarms and focus history are kept in a backup', () async {
      final FocusRepository repo = FocusRepository(database);
      await repo.createAlarm(
        const Alarm(id: 0, hour: 6, minute: 0, challenge: AlarmChallenge.shake),
      );
      await repo.logSession(
        startedAt: DateTime(2026, 11, 16, 9),
        endedAt: DateTime(2026, 11, 16, 10),
        focusMs: 3000000,
        rounds: 2,
        endedEarly: false,
      );
      final String json = await BackupService(database).exportJson();
      expect(json, contains('"format": 4'));
      final AppDatabase target = AppDatabase(NativeDatabase.memory());
      addTearDown(target.close);
      await BackupService(target).restoreJson(json);
      final FocusRepository restored = FocusRepository(target);
      expect(
        (await restored.getAlarms()).single.challenge,
        AlarmChallenge.shake,
      );
      expect((await restored.totalsSince(DateTime(2026, 11, 16))).rounds, 2);
    });
  });

  group('Focus plan', () {
    final DateTime nine = DateTime(2026, 11, 16, 9);

    test('lays out rounds with short and long breaks', () {
      const FocusSettings s = FocusSettings(
        focusMinutes: 25,
        shortBreakMinutes: 5,
        longBreakMinutes: 15,
        rounds: 5,
        longBreakEvery: 4,
      );
      expect(
        s.sequence.map(((PhaseKind, Duration) p) => p.$1.key).join(' '),
        'focus short focus short focus short focus long focus',
      );
      final FocusSession session = startSession(s, nine);
      expect(
        session.endsAt,
        nine.add(const Duration(minutes: 25 * 5 + 15 + 15)),
      );
      expect(session.totalRounds, 5);
      // One round, no breaks: a plain timer.
      expect(const FocusSettings(rounds: 1).sequence.length, 1);
    });

    test('pausing stops the clock and resuming shifts what is left', () {
      final FocusSession s = startSession(
        const FocusSettings(rounds: 2, focusMinutes: 25, shortBreakMinutes: 5),
        nine,
      );
      final DateTime tenIn = nine.add(const Duration(minutes: 10));
      final FocusSession paused = s.pause(tenIn);
      expect(paused.lockedAt(tenIn), isFalse);
      // Twenty minutes later nothing has moved.
      final DateTime later = tenIn.add(const Duration(minutes: 20));
      expect(paused.remaining(later), const Duration(minutes: 15));
      expect(
        paused.focusMsUntil(later),
        const Duration(minutes: 10).inMilliseconds,
      );
      final FocusSession resumed = paused.resume(later);
      expect(resumed.remaining(later), const Duration(minutes: 15));
      expect(resumed.endsAt, s.endsAt.add(const Duration(minutes: 20)));
      expect(resumed.lockedAt(later), isTrue);
    });

    test('skipping keeps focus time but not the round', () {
      final FocusSession s = startSession(
        const FocusSettings(rounds: 2, focusMinutes: 25, shortBreakMinutes: 5),
        nine,
      );
      final DateTime at = nine.add(const Duration(minutes: 10));
      final FocusSession skipped = s.skip(at);
      expect(skipped.phaseAt(at)!.kind, PhaseKind.shortBreak);
      expect(skipped.remaining(at), const Duration(minutes: 5));
      expect(
        skipped.focusMsUntil(at),
        const Duration(minutes: 10).inMilliseconds,
      );
      expect(skipped.roundsDoneAt(at), 0);
      // Zero-length phases are not sent to Android.
      expect((skipped.toNative()['phases']! as List<Object?>).length, 2);
      // Survives being stored and read back.
      final FocusSession again = FocusSession.decode(skipped.encode())!;
      expect(again.focusBankedMs, skipped.focusBankedMs);
      expect(again.endsAt, skipped.endsAt);
    });

    test('a session is logged when stopped, and Android is told', () async {
      final FakeFocusPlatform platform = FakeFocusPlatform();
      final ProviderContainer c = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(database),
          focusPlatformProvider.overrideWithValue(platform),
        ],
      );
      addTearDown(c.dispose);
      await c.read(focusControllerProvider.future);
      final FocusController focus = c.read(focusControllerProvider.notifier);
      DateTime now = DateTime.now();
      focus.clockNow = () => now;
      await focus.saveSettings(
        const FocusSettings(
          focusMinutes: 25,
          rounds: 2,
          lockdown: Lockdown.light,
        ),
      );
      await focus.start();
      expect(platform.focus, isNotNull);
      expect(platform.focus!['lockdown'], 'light');
      // Light lockdown pins the app during focus.
      expect(platform.pins.last, isTrue);

      now = now.add(const Duration(minutes: 26)); // into the break
      await focus.tick();
      expect(platform.pins.last, isFalse);

      await focus.stop();
      expect(platform.focus, isNull);
      final FocusState state = c.read(focusControllerProvider).value!;
      expect(state.session, isNull);
      expect(state.todayRounds, 1);
      expect(state.todayFocusMs, const Duration(minutes: 25).inMilliseconds);
    });
  });

  testWidgets('The Calendar tab switches between alarms and the focus timer', (
    WidgetTester tester,
  ) async {
    final FakeFocusPlatform platform = FakeFocusPlatform();
    await FocusRepository(database).createAlarm(
      const Alarm(id: 0, hour: 6, minute: 15, days: 0x1F, label: 'Gym'),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(database),
          focusPlatformProvider.overrideWithValue(platform),
        ],
        child: const MaterialApp(home: CalendarScreen()),
      ),
    );
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pump();
    await tester.tap(find.text('Alarms'));
    await tester.pump();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pump();
    expect(find.text('Gym'), findsOneWidget);
    expect(find.text('6:15 AM'), findsOneWidget);
    expect(find.textContaining('3 medium sums'), findsOneWidget);

    await tester.tap(find.text('Focus'));
    await tester.pump();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pump();
    expect(find.text('Start focusing'), findsOneWidget);
    expect(find.text('25 min focus'), findsOneWidget);
  });
}
