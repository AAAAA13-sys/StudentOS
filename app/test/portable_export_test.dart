import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studentos/core/db/app_database.dart';
import 'package:studentos/core/db/portable_export.dart';
import 'package:studentos/core/theme/app_theme.dart';
import 'package:studentos/core/widgets/app_drawer.dart';
import 'package:studentos/features/finance/iou_item.dart';
import 'package:studentos/features/finance/transaction.dart';
import 'package:studentos/features/insights/month_review.dart';
import 'package:studentos/features/work/shift.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('sanitizeCsvCell', () {
    test('returns empty string for null or empty', () {
      expect(sanitizeCsvCell(null), '');
      expect(sanitizeCsvCell(''), '');
    });

    test('prefixes dangerous formula starters with single quote', () {
      expect(sanitizeCsvCell('=1+1'), "'=1+1");
      expect(sanitizeCsvCell('+SUM(A1:A2)'), "'+SUM(A1:A2)");
      expect(sanitizeCsvCell('-100'), "'-100");
      expect(sanitizeCsvCell('@cmd'), "'@cmd");
      expect(sanitizeCsvCell('\t=HYPERLINK()'), "'\t=HYPERLINK()");
      expect(sanitizeCsvCell('\r=1+1'), '"\'\r=1+1"');
    });

    test('applies RFC 4180 quoting for commas, quotes, and newlines', () {
      expect(sanitizeCsvCell('Lunch, Coffee'), '"Lunch, Coffee"');
      expect(sanitizeCsvCell('Said "hi"'), '"Said ""hi"""');
      expect(sanitizeCsvCell('Line 1\nLine 2'), '"Line 1\nLine 2"');
      expect(sanitizeCsvCell('=A1,"bad"'), '"\'=A1,""bad"""');
    });
  });

  group('CSV & Markdown exporters', () {
    test('exportTransactionsCsv outputs CRLF lines and formula-safe cells', () {
      final String csv = exportTransactionsCsv(<Transaction>[
        Transaction(
          id: 1,
          type: 'expense',
          amount: 120.5,
          category: 'Food',
          occurredOn: DateTime(2026, 11, 20),
          note: '=cmd|calc, "lunch"',
        ),
      ]);
      final List<String> lines = csv.split('\r\n');
      expect(lines, hasLength(2));
      expect(lines.first, 'date,type,category,amount_php,note');
      expect(
        lines[1],
        '2026-11-20,expense,Food,120.50,"\'=cmd|calc, ""lunch"""',
      );
    });

    test('exportShiftsCsv formats shift times, break, pay, and safe job', () {
      final String csv = exportShiftsCsv(<Shift>[
        Shift(
          id: 1,
          job: '+Cafe, Main',
          startsAt: DateTime(2026, 11, 20, 9, 0),
          durationMinutes: 270,
          breakMinutes: 30,
          hourlyRateCents: 10000,
          paid: true,
        ),
      ]);
      final List<String> lines = csv.split('\r\n');
      expect(lines, hasLength(2));
      expect(
        lines.first,
        'date,start_time,end_time,job,duration_minutes,break_minutes,'
        'paid_minutes,hourly_rate_php,pay_php,paid',
      );
      expect(
        lines[1],
        '2026-11-20,09:00,13:30,"\'+Cafe, Main",270,30,240,100.00,400.00,yes',
      );
    });

    test('exportIousCsv exports open and settled IOUs safely', () {
      final String csv = exportIousCsv(<IouItem>[
        IouItem(
          id: 1,
          person: '@Sam',
          direction: IouDirection.owed,
          amountCents: 12550,
          note: 'Dinner\nSplit',
          occurredOn: '2026-11-18',
          settled: true,
          settledAt: DateTime(2026, 11, 22),
          createdAt: DateTime(2026, 11, 18),
        ),
      ]);
      final List<String> lines = csv.split('\r\n');
      expect(lines, hasLength(2));
      expect(
        lines.first,
        'occurred_on,person,direction,amount_php,settled,settled_on,note',
      );
      expect(
        lines[1],
        '2026-11-18,\'@Sam,owed,125.50,yes,2026-11-22,"Dinner\nSplit"',
      );
    });

    test('exportMonthReviewMarkdown formats all sections and phone states', () {
      final MonthReview offReview = buildMonthReview(
        month: '2026-11',
        transactions: <Transaction>[
          Transaction(
            id: 1,
            type: 'income',
            amount: 3000,
            category: 'Allowance',
            occurredOn: DateTime(2026, 11, 1),
          ),
          Transaction(
            id: 2,
            type: 'expense',
            amount: 500,
            category: 'Food',
            occurredOn: DateTime(2026, 11, 2),
          ),
        ],
        goals: const [],
        ious: const [],
        shifts: const [],
        focusLogs: const [],
        tasks: const [],
        recallReviews: const [],
        phoneDays: const [],
        hasPhoneAccess: false,
      );
      final String md = exportMonthReviewMarkdown(offReview);
      expect(md, contains('# Month in Review — November 2026 (2026-11)'));
      expect(md, contains('## Money'));
      expect(md, contains('Income: ₱3,000.00'));
      expect(md, contains('Expenses: ₱500.00'));
      expect(md, contains('## Work & Study'));
      expect(md, contains('## Phone Rest & Screen Time'));
      expect(md, contains('Screen time access off'));
    });
  });

  group('AppDrawer exports & review integration', () {
    testWidgets('AppDrawer opens ExportSheet with CSV and Markdown options', (
      WidgetTester tester,
    ) async {
      final AppDatabase db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [appDatabaseProvider.overrideWithValue(db)],
          child: MaterialApp(
            theme: AppTheme.light,
            home: Scaffold(
              appBar: AppBar(title: const Text('Home')),
              drawer: const AppDrawer(),
              body: const SizedBox.shrink(),
            ),
          ),
        ),
      );

      await tester.tap(find.byTooltip('Open navigation menu'));
      await tester.pumpAndSettle();

      expect(find.text('Month in review'), findsOneWidget);
      expect(find.text('Export CSV / summary'), findsOneWidget);

      await tester.tap(find.text('Export CSV / summary'));
      await tester.pumpAndSettle();

      expect(find.text('Transactions (current month .csv)'), findsOneWidget);
      expect(find.text('Transactions (all months .csv)'), findsOneWidget);
      expect(find.text('Work shifts / DTR (.csv)'), findsOneWidget);
      expect(find.text('IOUs ledger (.csv)'), findsOneWidget);
      expect(find.text('Month in review (current month .md)'), findsOneWidget);
    });
  });
}
