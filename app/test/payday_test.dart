import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studentos/core/db/app_database.dart';
import 'package:studentos/features/finance/finance_screen.dart';
import 'package:studentos/features/finance/transaction.dart';
import 'package:studentos/features/insights/finance_insights.dart';
import 'package:studentos/features/insights/ponpon_insight.dart';
import 'package:studentos/features/work/payday.dart';
import 'package:studentos/features/work/shift.dart';
import 'package:studentos/features/work/work_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('parse and serialize', () {
    test('round-trips every kind', () {
      for (final PaydaySchedule s in <PaydaySchedule>[
        PaydaySchedule.none,
        PaydaySchedule.weekly(5),
        PaydaySchedule.semimonthly,
        PaydaySchedule.monthly(25),
        PaydaySchedule.monthly(31),
      ]) {
        expect(PaydaySchedule.parse(s.serialize()), s);
      }
      expect(PaydaySchedule.weekly(5).serialize(), 'weekly:5');
      expect(PaydaySchedule.monthly(25).serialize(), 'monthly:25');
    });

    test('bad strings become none', () {
      for (final String? bad in <String?>[
        null,
        '',
        'nope',
        'weekly',
        'weekly:',
        'weekly:0',
        'weekly:8',
        'weekly:x',
        'monthly:0',
        'monthly:32',
        'monthly:5:5',
        'semimonthly:3',
      ]) {
        expect(PaydaySchedule.parse(bad), PaydaySchedule.none, reason: '$bad');
      }
    });
  });

  group('nextPayday', () {
    test('none has no payday', () {
      expect(nextPayday(PaydaySchedule.none, DateTime(2026, 11, 18)), isNull);
    });

    test('weekly counts today and finds the coming weekday', () {
      final PaydaySchedule friday = PaydaySchedule.weekly(DateTime.friday);
      // Nov 20 2026 is a Friday.
      expect(
        nextPayday(friday, DateTime(2026, 11, 20, 23, 59)),
        DateTime(2026, 11, 20),
      );
      expect(
        nextPayday(friday, DateTime(2026, 11, 21)),
        DateTime(2026, 11, 27),
      );
      expect(
        nextPayday(friday, DateTime(2026, 11, 19)),
        DateTime(2026, 11, 20),
      );
      // Crosses the month and year end.
      expect(nextPayday(friday, DateTime(2026, 12, 29)), DateTime(2027, 1, 1));
    });

    test('semimonthly is the 15th and the last day', () {
      const PaydaySchedule s = PaydaySchedule.semimonthly;
      expect(nextPayday(s, DateTime(2026, 11, 3)), DateTime(2026, 11, 15));
      expect(nextPayday(s, DateTime(2026, 11, 15)), DateTime(2026, 11, 15));
      expect(nextPayday(s, DateTime(2026, 11, 16)), DateTime(2026, 11, 30));
      expect(nextPayday(s, DateTime(2026, 12, 31)), DateTime(2026, 12, 31));
      expect(nextPayday(s, DateTime(2027, 1, 1)), DateTime(2027, 1, 15));
      // February, common and leap.
      expect(nextPayday(s, DateTime(2027, 2, 16)), DateTime(2027, 2, 28));
      expect(nextPayday(s, DateTime(2028, 2, 16)), DateTime(2028, 2, 29));
    });

    test('monthly clamps to the last day and rolls over the year', () {
      final PaydaySchedule s = PaydaySchedule.monthly(31);
      expect(nextPayday(s, DateTime(2026, 11, 3)), DateTime(2026, 11, 30));
      expect(nextPayday(s, DateTime(2026, 11, 30)), DateTime(2026, 11, 30));
      expect(nextPayday(s, DateTime(2027, 2, 1)), DateTime(2027, 2, 28));
      expect(nextPayday(s, DateTime(2028, 2, 1)), DateTime(2028, 2, 29));
      final PaydaySchedule k = PaydaySchedule.monthly(25);
      expect(nextPayday(k, DateTime(2026, 12, 26)), DateTime(2027, 1, 25));
      expect(nextPayday(k, DateTime(2026, 12, 25)), DateTime(2026, 12, 25));
    });
  });

  group('labels', () {
    test('today, tomorrow, weekday and date', () {
      final PaydaySchedule friday = PaydaySchedule.weekly(DateTime.friday);
      expect(paydayLabel(friday, DateTime(2026, 11, 20)), 'Payday today');
      expect(paydayLabel(friday, DateTime(2026, 11, 19)), 'Payday tomorrow');
      expect(
        paydayLabel(friday, DateTime(2026, 11, 17)),
        'Payday Fri · in 3 days',
      );
      expect(
        paydayLabel(PaydaySchedule.semimonthly, DateTime(2026, 11, 18)),
        'Payday Nov 30 · in 12 days',
      );
      expect(
        paydayLabel(PaydaySchedule.semimonthly, DateTime(2026, 11, 24)),
        'Payday Mon · in 6 days',
      );
      expect(paydayLabel(PaydaySchedule.none, DateTime(2026, 11, 18)), '');
    });

    test('schedule text', () {
      expect(describePayday(PaydaySchedule.none), 'Not set');
      expect(describePayday(PaydaySchedule.weekly(5)), 'Every Friday');
      expect(
        describePayday(PaydaySchedule.semimonthly),
        'Every 15th and end of month',
      );
      expect(
        describePayday(PaydaySchedule.monthly(25)),
        'Every month on the 25th',
      );
      expect(ordinal(1), '1st');
      expect(ordinal(22), '22nd');
      expect(ordinal(11), '11th');
      expect(ordinal(31), '31st');
    });
  });

  group('Ponpon', () {
    final DateTime payDay = DateTime(2026, 11, 30, 10);
    final List<Transaction> month = <Transaction>[
      Transaction(
        id: 1,
        type: 'income',
        amount: 3000,
        category: 'Allowance',
        occurredOn: DateTime(2026, 11, 1),
      ),
    ];

    bool hasTip(List<PonponInsight> list) =>
        list.any((PonponInsight i) => i.text.startsWith('Payday today'));

    List<PonponInsight> run({
      required DateTime now,
      required PaydaySchedule schedule,
      required int waiting,
      List<Transaction>? tx,
    }) => financeInsights(
      thisMonth: tx ?? month,
      lastMonth: const <Transaction>[],
      now: now,
      payday: schedule,
      waitingPayCents: waiting,
    );

    test('fires only on payday with pay waiting', () {
      final List<PonponInsight> tips = run(
        now: payDay,
        schedule: PaydaySchedule.semimonthly,
        waiting: 123450,
      );
      expect(
        tips.map((PonponInsight i) => i.text),
        contains('Payday today: ₱1,234.50 waiting. Got paid?'),
      );
      // Nothing waiting.
      expect(
        hasTip(
          run(now: payDay, schedule: PaydaySchedule.semimonthly, waiting: 0),
        ),
        isFalse,
      );
      // Not a payday.
      expect(
        hasTip(
          run(
            now: DateTime(2026, 11, 29),
            schedule: PaydaySchedule.semimonthly,
            waiting: 50000,
          ),
        ),
        isFalse,
      );
      // No schedule.
      expect(
        hasTip(run(now: payDay, schedule: PaydaySchedule.none, waiting: 50000)),
        isFalse,
      );
    });

    test('speaks even before any transaction this month', () {
      expect(
        hasTip(
          run(
            now: payDay,
            schedule: PaydaySchedule.monthly(30),
            waiting: 50000,
            tx: const <Transaction>[],
          ),
        ),
        isTrue,
      );
    });
  });

  testWidgets('Setting a payday in the sheet shows on the Work pay row and '
      'persists', (WidgetTester tester) async {
    final AppDatabase database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);

    Future<void> settle() async {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pumpAndSettle();
    }

    final DateTime now = DateTime.now();
    await tester.runAsync(
      () => WorkRepository(database).createShifts(<Shift>[
        Shift(
          id: 0,
          job: 'Cafe',
          startsAt: DateTime(now.year, now.month, now.day - 3, 9),
          durationMinutes: 240,
          breakMinutes: 0,
          hourlyRateCents: 10000,
          paid: false,
        ),
      ]),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(database)],
        child: const MaterialApp(home: FinanceScreen()),
      ),
    );
    await settle();
    expect(find.text('Work pay'), findsOneWidget);
    expect(find.textContaining('Payday', findRichText: true), findsNothing);

    await tester.tap(find.text('Work pay'));
    await settle();
    expect(find.text('Not set'), findsOneWidget);
    await tester.tap(find.text('Payday'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Weekly'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Fri'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await settle();

    expect(find.text('Every Friday'), findsOneWidget);
    expect(
      find.textContaining(' · Payday', findRichText: true),
      findsOneWidget,
    );

    final SettingRow? row = await tester.runAsync<SettingRow?>(
      () => (database.select(
        database.settingRows,
      )..where((t) => t.key.equals('payday'))).getSingleOrNull(),
    );
    expect(row?.value, 'weekly:5');
  });
}
