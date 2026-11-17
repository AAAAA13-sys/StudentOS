import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studentos/core/db/app_database.dart';
import 'package:studentos/features/finance/amount_validation.dart';
import 'package:studentos/features/finance/finance_repository.dart';
import 'package:studentos/features/finance/quick_again.dart';
import 'package:studentos/features/finance/transaction.dart';
import 'package:studentos/features/finance/widgets/quick_expense_sheet.dart';
import 'package:studentos/features/notes/note.dart';
import 'package:studentos/features/finance/finance_screen.dart';
import 'package:studentos/features/notes/note_editor_sheet.dart';
import 'package:studentos/features/notes/notes_repository.dart';
import 'package:studentos/features/notes/notes_screen.dart';
import 'package:studentos/features/notes/quiz_session.dart';
import 'package:studentos/features/work/payout_link.dart';
import 'package:studentos/features/work/shift.dart';
import 'package:studentos/features/work/work_controller.dart';
import 'package:studentos/features/work/work_repository.dart';

Transaction expense(double amount, String category, DateTime on) => Transaction(
  id: 0,
  type: 'expense',
  amount: amount,
  category: category,
  occurredOn: on,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('frequentExpenses', () {
    final DateTime now = DateTime(2026, 11, 17, 10);

    test('keeps pairs seen twice or more, most frequent first, max 3', () {
      final List<Transaction> txs = <Transaction>[
        for (int i = 0; i < 3; i++)
          expense(45, 'Food', DateTime(2026, 11, 10 + i)),
        for (int i = 0; i < 2; i++)
          expense(20, 'Transport', DateTime(2026, 11, 1 + i)),
        for (int i = 0; i < 2; i++)
          expense(100, 'School', DateTime(2026, 11, 5)),
        for (int i = 0; i < 2; i++) expense(15, 'Other', DateTime(2026, 11, 2)),
        expense(99, 'Food', DateTime(2026, 11, 12)), // once only
      ];
      final List<RepeatExpense> top = frequentExpenses(txs, now);
      expect(top.length, 3);
      expect(top.first.amount, 45);
      expect(top.first.category, 'Food');
      expect(top.first.count, 3);
      // Ties on count go to the most recent.
      expect(top[1].category, 'School');
      expect(top[2].category, 'Transport');
    });

    test('ignores income, old and future entries; empty when none qualify', () {
      final List<Transaction> txs = <Transaction>[
        expense(45, 'Food', DateTime(2026, 11, 16)),
        expense(45, 'Food', DateTime(2026, 9, 1)), // older than 30 days
        expense(30, 'Food', DateTime(2026, 11, 20)), // future
        expense(30, 'Food', DateTime(2026, 11, 21)),
        Transaction(
          id: 0,
          type: 'income',
          amount: 500,
          category: 'Allowance',
          occurredOn: DateTime(2026, 11, 3),
        ),
        Transaction(
          id: 0,
          type: 'income',
          amount: 500,
          category: 'Allowance',
          occurredOn: DateTime(2026, 11, 4),
        ),
      ];
      expect(frequentExpenses(txs, now), isEmpty);
    });
  });

  group('validateAmount', () {
    test('accepts normal amounts up to 1,000,000', () {
      expect(validateAmount('45'), isNull);
      expect(validateAmount(' 37.50 '), isNull);
      expect(validateAmount('1000000'), isNull);
    });

    test('rejects empty, zero, negative, junk and too large', () {
      expect(validateAmount(null), isNotNull);
      expect(validateAmount(''), 'Enter an amount');
      expect(validateAmount('abc'), 'Enter a valid amount');
      expect(validateAmount('0'), contains('more than'));
      expect(validateAmount('-5'), contains('more than'));
      expect(validateAmount('1000000.01'), contains('1,000,000'));
      expect(validateAmount('9999999999'), contains('1,000,000'));
    });
  });

  group('QuizSession', () {
    test('tallies right answers and retries only the missed cards', () {
      final QuizSession s = QuizSession(4);
      expect(s.done, isFalse);
      s.mark(0, right: true);
      s.mark(1, right: false);
      s.mark(2, right: true);
      expect(s.done, isFalse);
      s.mark(3, right: false);
      expect(s.done, isTrue);
      expect(s.tally, '2 of 4 right');
      expect(s.missed, <int>[1, 3]);

      final QuizSession retry = s.retryMissed();
      expect(retry.active, <int>[1, 3]);
      expect(retry.done, isFalse);
      retry.mark(1, right: true);
      retry.mark(3, right: true);
      expect(retry.tally, '2 of 2 right');
      expect(retry.missed, isEmpty);
    });
  });

  group('paid shifts follow their payout', () {
    late AppDatabase database;
    setUp(() => database = AppDatabase(NativeDatabase.memory()));
    tearDown(() => database.close());

    Shift cafe(DateTime start) => Shift(
      id: 0,
      job: 'Cafe',
      startsAt: start,
      durationMinutes: 240,
      hourlyRateCents: 10000,
    );

    test('deleting a payout makes only its shifts unpaid again', () async {
      final ProviderContainer container = ProviderContainer(
        overrides: [appDatabaseProvider.overrideWithValue(database)],
      );
      addTearDown(container.dispose);
      final WorkRepository repo = WorkRepository(database);
      final FinanceRepository finance = FinanceRepository(database);
      await repo.createShifts(<Shift>[
        cafe(DateTime(2026, 11, 8, 17)),
        cafe(DateTime(2026, 11, 9, 17)),
      ]);
      await container.read(workControllerProvider.future);
      final WorkController work = container.read(
        workControllerProvider.notifier,
      );
      await work.gotPaid(800, now: DateTime(2026, 11, 10, 12));
      await repo.createShifts(<Shift>[
        cafe(DateTime(2026, 11, 20, 17)),
        cafe(DateTime(2026, 11, 21, 17)),
      ]);
      await work.addShifts(const <Shift>[]);
      await work.gotPaid(800, now: DateTime(2026, 11, 24, 12));
      expect((await repo.getShifts()).every((Shift s) => s.paid), isTrue);

      final List<Transaction> payouts = await finance.getTransactions();
      final Transaction second = payouts.first;
      expect(second.occurredOn, DateTime(2026, 11, 24));
      await work.unpayForDeletedIncome(second);

      final List<Shift> after = await repo.getShifts();
      expect(after.map((Shift s) => s.paid).toList(), <bool>[
        true,
        true,
        false,
        false,
      ]);
    });

    test('income that is not from "I got paid" changes nothing', () async {
      final ProviderContainer container = ProviderContainer(
        overrides: [appDatabaseProvider.overrideWithValue(database)],
      );
      addTearDown(container.dispose);
      final WorkRepository repo = WorkRepository(database);
      await repo.createShifts(<Shift>[cafe(DateTime(2026, 11, 8, 17))]);
      await repo.markPaid(<int>[(await repo.getShifts()).single.id]);
      await container.read(workControllerProvider.future);
      await container
          .read(workControllerProvider.notifier)
          .unpayForDeletedIncome(
            Transaction(
              id: 5,
              type: 'income',
              amount: 100,
              category: 'Allowance',
              occurredOn: DateTime(2026, 11, 10),
              note: '4 hrs at Cafe',
            ),
          );
      expect((await repo.getShifts()).single.paid, isTrue);
    });

    test('shifts list in date and time order', () {
      final List<Shift> sorted = inDateOrder(<Shift>[
        cafe(DateTime(2026, 11, 9, 17)),
        cafe(DateTime(2026, 11, 8, 18)),
        cafe(DateTime(2026, 11, 8, 9)),
      ]);
      expect(sorted.map((Shift s) => s.startsAt.hour).toList(), <int>[
        9,
        18,
        17,
      ]);
    });
  });

  group('Quick expense layout', () {
    testWidgets('amounts and categories stay whole at font scale 1.3', (
      WidgetTester tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(360, 740));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(360, 740),
              textScaler: TextScaler.linear(1.3),
            ),
            child: Builder(
              builder: (BuildContext context) => Scaffold(
                body: TextButton(
                  onPressed: () => showQuickExpenseSheet(
                    context,
                    again: Future<List<RepeatExpense>>.value(
                      const <RepeatExpense>[RepeatExpense(45, 'Food', 3)],
                    ),
                  ),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.text('₱45 Food'), findsOneWidget);
      for (final String label in <String>['₱200', 'Transport']) {
        final Finder f = find.text(label);
        expect(f, findsOneWidget);
        // One line: the text is no taller than a single scaled line.
        expect(tester.getSize(f).height, lessThan(30), reason: label);
      }
      expect(tester.takeException(), isNull);
    });
  });

  group('Note editor discard prompt', () {
    Future<void> openEditor(WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Consumer(
              builder: (BuildContext context, WidgetRef ref, _) => Scaffold(
                body: TextButton(
                  onPressed: () => showNoteEditor(
                    context,
                    ref,
                    Note(id: 0, title: '', body: '', tags: const <String>[]),
                    onCreate: (Note _) async {},
                  ),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
    }

    testWidgets('Cancel closes at once when nothing was typed', (
      WidgetTester tester,
    ) async {
      await openEditor(tester);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.text('Discard changes?'), findsNothing);
      expect(find.text('New note'), findsNothing);
    });

    testWidgets('Cancel with typed text asks first; Keep editing stays', (
      WidgetTester tester,
    ) async {
      await openEditor(tester);
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Title (optional)'),
        'Biology',
      );
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.text('Discard changes?'), findsOneWidget);

      await tester.tap(find.text('Cancel').last);
      await tester.pumpAndSettle();
      expect(find.text('Discard changes?'), findsNothing);
      expect(find.text('New note'), findsOneWidget);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Discard'));
      await tester.pumpAndSettle();
      expect(find.text('New note'), findsNothing);
    });

    testWidgets('the system back button asks too', (WidgetTester tester) async {
      await openEditor(tester);
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Title (optional)'),
        'Biology',
      );
      await tester.pump();
      final bool handled = await tester.binding.handlePopRoute();
      expect(handled, isTrue);
      await tester.pumpAndSettle();
      expect(find.text('Discard changes?'), findsOneWidget);
    });
  });

  test('an older payout at another workplace does not hide the shift', () {
    Transaction payout(int id, DateTime on, String note) => Transaction(
      id: id,
      type: 'income',
      amount: 400,
      category: 'Part-time Job',
      occurredOn: on,
      note: note,
    );
    final Transaction older = payout(
      1,
      DateTime(2026, 11, 16),
      '8 hrs at Jollibee',
    );
    final Transaction mine = payout(
      2,
      DateTime(2026, 11, 17),
      '4 hrs at QAShop',
    );
    final Shift shop = Shift(
      id: 9,
      job: 'QAShop',
      startsAt: DateTime(2026, 11, 16, 10),
      durationMinutes: 240,
      paid: true,
    );
    expect(
      shiftsPaidBy(mine, <Shift>[shop], <Transaction>[older, mine]),
      <Shift>[shop],
    );
    // The same workplace still raises the floor.
    final Transaction sameShop = payout(
      1,
      DateTime(2026, 11, 16),
      '4 hrs at QAShop',
    );
    expect(
      shiftsPaidBy(mine, <Shift>[shop], <Transaction>[sameShop, mine]),
      isEmpty,
    );
  });

  group('Finance and Notes layout', () {
    late AppDatabase database;
    setUp(() => database = AppDatabase(NativeDatabase.memory()));
    tearDown(() => database.close());

    Future<void> settle(WidgetTester tester) async {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('the Logged snackbar stays clear of the + button', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [appDatabaseProvider.overrideWithValue(database)],
          child: MaterialApp(
            home: Scaffold(
              body: const FinanceScreen(),
              bottomNavigationBar: NavigationBar(
                destinations: const <Widget>[
                  NavigationDestination(icon: Icon(Icons.home), label: 'A'),
                  NavigationDestination(icon: Icon(Icons.work), label: 'B'),
                ],
              ),
            ),
          ),
        ),
      );
      await settle(tester);
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();
      await tester.tap(find.text('₱50'));
      await tester.pump();
      await tester.tap(find.text('Transport'));
      await settle(tester);
      await tester.pump(const Duration(milliseconds: 600));

      final Finder bar = find.byType(SnackBar);
      expect(bar, findsOneWidget);
      // The visible bar, not the transparent margin around it.
      final Rect snack = tester.getRect(
        find.descendant(of: bar, matching: find.byType(Material)).first,
      );
      final Rect fab = tester.getRect(find.byType(FloatingActionButton));
      expect(snack.overlaps(fab), isFalse, reason: '$snack vs $fab');
      await tester.pumpAndSettle(const Duration(seconds: 3));
    });

    testWidgets('the tag row does not move when a tag is selected', (
      WidgetTester tester,
    ) async {
      final NotesRepository repo = NotesRepository(database);
      await tester.runAsync(() async {
        await repo.createNote(
          Note(id: 0, title: 'One', body: 'a', tags: const <String>['math']),
        );
        await repo.createNote(
          Note(id: 0, title: 'Two', body: 'b', tags: const <String>['art']),
        );
      });
      await tester.pumpWidget(
        ProviderScope(
          overrides: [appDatabaseProvider.overrideWithValue(database)],
          child: const MaterialApp(home: NotesScreen()),
        ),
      );
      await settle(tester);

      final Finder chip = find.widgetWithText(FilterChip, '#math');
      expect(chip, findsOneWidget);
      final double before = tester.getTopLeft(chip).dy;
      await tester.tap(chip);
      await settle(tester);
      expect(find.widgetWithText(FilterChip, '#art'), findsOneWidget);
      expect(tester.getTopLeft(chip).dy, before);
      await tester.tap(chip);
      await settle(tester);
      expect(tester.getTopLeft(chip).dy, before);
    });
  });
}
