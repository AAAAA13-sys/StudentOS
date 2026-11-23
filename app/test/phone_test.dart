import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studentos/core/db/app_database.dart';
import 'package:studentos/core/db/backup.dart';
import 'package:studentos/features/calendar/event.dart';
import 'package:studentos/features/phone/phone_controller.dart';
import 'package:studentos/features/phone/phone_day.dart';
import 'package:studentos/features/phone/phone_repository.dart';
import 'package:studentos/features/phone/phone_screen.dart';
import 'package:studentos/features/phone/phone_usage.dart';
import 'package:studentos/features/work/shift.dart';

/// Answers from a fixed list of screen-on spans and app totals, the way
/// Android would, and forgets anything before [forgetBefore].
class FakeUsage implements PhoneUsageSource {
  FakeUsage({
    this.access = true,
    this.spans = const <(DateTime, DateTime)>[],
    this.apps = const <AppUsage>[],
    this.unlocks = const <DateTime>[],
    DateTime? forgetBefore,
  }) : forgetBefore = forgetBefore ?? DateTime(2000);

  bool access;
  List<(DateTime, DateTime)> spans;
  List<AppUsage> apps;
  List<DateTime> unlocks;
  DateTime forgetBefore;
  int queries = 0;

  @override
  Future<bool> hasAccess() async => access;

  @override
  Future<bool> openAccessSettings() async => true;

  @override
  Future<UsageRange?> query(DateTime start, DateTime end) async {
    if (!access) return null;
    queries++;
    final List<(DateTime, DateTime)> inside = <(DateTime, DateTime)>[
      for (final (DateTime s, DateTime e) in spans)
        if (e.isAfter(start) && s.isBefore(end) && !e.isBefore(forgetBefore))
          (s, e),
    ];
    final List<DateTime> taps = <DateTime>[
      for (final DateTime t in unlocks)
        if (!t.isBefore(start) && t.isBefore(end) && !t.isBefore(forgetBefore))
          t,
    ];
    return UsageRange(
      apps: inside.isEmpty ? const <AppUsage>[] : apps,
      screenOn: inside,
      unlocks: taps,
      eventCount: inside.length * 2 + taps.length,
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase database;
  setUp(() => database = AppDatabase(NativeDatabase.memory()));
  tearDown(() => database.close());

  DateTime t(int day, int hour, [int minute = 0]) =>
      DateTime(2026, 11, day, hour, minute);

  test('Phone rest is the longest screen-off stretch of the night', () {
    final (DateTime, DateTime) window = restWindowFor(DateTime(2026, 11, 16));
    expect(window, (t(15, 18), t(16, 12)));

    final (DateTime, DateTime)? rest = longestScreenOff(
      <(DateTime, DateTime)>[
        (t(15, 20), t(15, 23, 40)),
        (t(16, 2, 10), t(16, 2, 15)), // a quick look at the clock
        (t(16, 6, 30), t(16, 7)),
      ],
      window.$1,
      window.$2,
    );
    // 2:15 to 6:30 beats 23:40 to 2:10.
    expect(rest, (t(16, 2, 15), t(16, 6, 30)));

    // Nothing longer than two hours: no rest is claimed.
    expect(
      longestScreenOff(
        <(DateTime, DateTime)>[
          for (int h = 18; h < 36; h++)
            (
              t(15, 0).add(Duration(hours: h)),
              t(15, 0).add(Duration(hours: h, minutes: 10)),
            ),
        ],
        window.$1,
        window.$2,
      ),
      isNull,
    );

    // Spans that overlap or start before the window are handled.
    expect(
      longestScreenOff(
        <(DateTime, DateTime)>[
          (t(15, 17), t(15, 19)),
          (t(15, 18, 30), t(15, 22)),
          (t(16, 7), t(16, 13)),
        ],
        window.$1,
        window.$2,
      ),
      (t(15, 22), t(16, 7)),
    );
  });

  test('Screen time counts only the part inside the day', () {
    expect(
      screenOnMsWithin(
        <(DateTime, DateTime)>[
          (t(15, 23, 30), t(16, 0, 30)),
          (t(16, 12), t(16, 13)),
        ],
        t(16, 0),
        t(17, 0),
      ),
      const Duration(minutes: 90).inMilliseconds,
    );
    expect(formatDuration(const Duration(minutes: 192)), '3h 12m');
    expect(formatDuration(const Duration(minutes: 45)), '45m');
    expect(formatDuration(const Duration(hours: 2)), '2h');
    expect(comparedWithUsual(100, 100), 'About your usual');
    expect(comparedWithUsual(80, 100), 'Less than your usual');
    expect(comparedWithUsual(120, 100), 'More than your usual');
    expect(comparedWithUsual(120, null), isNull);
  });

  test('The first commitment of a morning comes from events and shifts', () {
    final DateTime tuesday = DateTime(2026, 11, 17);
    final List<CalendarEvent> events = <CalendarEvent>[
      CalendarEvent(
        id: 1,
        title: 'Math101',
        startsAt: t(3, 9), // Tuesdays
        recurrence: 'weekly',
      ),
      CalendarEvent(id: 2, title: 'Dentist', startsAt: t(18, 8)),
    ];
    final List<Shift> shifts = <Shift>[
      Shift(
        id: 1,
        job: 'Jollibee',
        startsAt: t(17, 6, 30),
        durationMinutes: 240,
      ),
    ];
    expect(firstCommitment(tuesday, events, shifts), (
      title: 'Shift at Jollibee',
      at: t(17, 6, 30),
    ));
    expect(firstCommitment(tuesday, events, const <Shift>[]), (
      title: 'Math101',
      at: t(17, 9),
    ));
    expect(firstCommitment(DateTime(2026, 11, 19), events, shifts), isNull);
    expect(nextMorning(t(16, 23)), DateTime(2026, 11, 17));
    expect(nextMorning(t(16, 2)), DateTime(2026, 11, 16));
  });

  test('Copying keeps complete days and skips days Android forgot', () async {
    final FakeUsage usage = FakeUsage(
      spans: <(DateTime, DateTime)>[
        for (int d = 10; d <= 16; d++) ...<(DateTime, DateTime)>[
          (t(d, 7), t(d, 8)), // one hour each morning
          (t(d, 20), t(d, 21)), // one hour each evening
        ],
      ],
      apps: const <AppUsage>[
        AppUsage(
          package: 'com.zhiliaoapp.musically',
          label: 'TikTok',
          ms: 3000000,
        ),
      ],
      unlocks: <DateTime>[t(16, 7, 5), t(16, 20, 1)],
      forgetBefore: t(12, 0), // Android no longer has Nov 10 and 11
    );
    final PhoneRepository repo = PhoneRepository(database, usage);
    final DateTime now = t(16, 21, 30);

    expect(await repo.sync(now), isTrue);
    List<PhoneDay> days = await repo.getDays(t(1, 0));
    expect(days.map((PhoneDay d) => d.date.day), <int>[12, 13, 14, 15, 16]);
    final PhoneDay today = days.last;
    expect(today.complete, isFalse);
    expect(today.screenOnMs, const Duration(hours: 2).inMilliseconds);
    expect(today.unlocks, 2);
    expect(today.firstPickup, t(16, 7, 5));
    // Screen off from 9 PM on the 15th to 7 AM on the 16th.
    expect(today.restStart, t(15, 21));
    expect(today.restEnd, t(16, 7));
    expect(days.first.complete, isTrue);
    expect((await repo.getApps(t(16, 0))).single.label, 'TikTok');

    // Later Android forgets more; the stored complete days stay as they were.
    usage.forgetBefore = t(16, 0);
    usage.queries = 0;
    expect(await repo.sync(t(16, 22)), isTrue);
    days = await repo.getDays(t(1, 0));
    expect(days.length, 5);
    expect(days[1].screenOnMs, const Duration(hours: 2).inMilliseconds);
    // Complete days are not read again: only today (usage and its night
    // window) and the two days Android forgot, which are cheap to ask about.
    expect(usage.queries, 4);
  });

  test(
    'Phone days are kept in a backup; format 2 restores without them',
    () async {
      final PhoneRepository repo = PhoneRepository(
        database,
        FakeUsage(spans: <(DateTime, DateTime)>[(t(16, 7), t(16, 8))]),
      );
      await repo.sync(t(16, 9));
      final String json = await BackupService(database).exportJson();
      expect(json, contains('"format": ${BackupService.formatVersion}'));

      final AppDatabase target = AppDatabase(NativeDatabase.memory());
      addTearDown(target.close);
      await BackupService(target).restoreJson(json);
      final PhoneRepository restored = PhoneRepository(
        target,
        FakeUsage(access: false),
      );
      expect((await restored.getDays(t(1, 0))).single.screenOnMs, 3600000);

      await BackupService(target).restoreJson(
        '{"app":"studentos","format":2,"events":[],"transactions":[],'
        '"notes":[],"settings":[],"shifts":[]}',
      );
      expect(await restored.getDays(t(1, 0)), isEmpty);
    },
  );

  testWidgets('Without usage access the tab explains and offers Settings', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(database),
          phoneUsageSourceProvider.overrideWithValue(FakeUsage(access: false)),
        ],
        child: const MaterialApp(home: PhoneScreen()),
      ),
    );
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pumpAndSettle();
    expect(find.text('See your phone time'), findsOneWidget);
    expect(find.text('Open Usage access'), findsOneWidget);
  });

  testWidgets('With access the tab shows today, rest and top apps', (
    WidgetTester tester,
  ) async {
    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    final DateTime start = today.subtract(const Duration(hours: 1));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(database),
          phoneUsageSourceProvider.overrideWithValue(
            FakeUsage(
              spans: <(DateTime, DateTime)>[
                (start.subtract(const Duration(hours: 3)), start),
                (
                  today.add(const Duration(minutes: 1)),
                  today.add(const Duration(minutes: 2)),
                ),
              ],
              apps: const <AppUsage>[
                AppUsage(
                  package: 'com.facebook.katana',
                  label: 'Facebook',
                  ms: 60000,
                ),
              ],
            ),
          ),
        ],
        child: const MaterialApp(home: PhoneScreen()),
      ),
    );
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 200)),
    );
    await tester.pumpAndSettle();
    expect(find.text('Screen on today'), findsOneWidget);
    expect(find.text('Phone rest'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Facebook'), 200);
    expect(find.text('Facebook'), findsOneWidget);
  });
}
