import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studentos/features/calendar/calendar_controller.dart';
import 'package:studentos/features/calendar/calendar_screen.dart';
import 'package:studentos/features/calendar/event.dart';
import 'package:studentos/features/finance/finance_controller.dart';
import 'package:studentos/features/finance/finance_screen.dart';
import 'package:studentos/features/finance/transaction.dart';
import 'package:studentos/features/notes/note.dart';
import 'package:studentos/features/notes/notes_controller.dart';
import 'package:studentos/features/notes/notes_screen.dart';

class FakeCalendarController extends CalendarController {
  @override
  Future<List<CalendarEvent>> build() async {
    return <CalendarEvent>[
      CalendarEvent(
        id: 1,
        title: 'Math 101 Lecture',
        startsAt: DateTime(2026, 11, 15, 9, 0),
        durationMinutes: 90,
        location: 'Room 304',
        recurrence: 'daily',
      ),
    ];
  }
}

class FakeFinanceController extends FinanceController {
  @override
  Future<FinanceState> build() async {
    return FinanceState(
      month: '2026-11',
      transactions: <Transaction>[
        Transaction(
          id: 1,
          type: 'income',
          amount: 5000.0,
          category: 'Allowance',
          occurredOn: DateTime(2026, 11, 15),
          note: 'Weekly allowance',
        ),
        Transaction(
          id: 2,
          type: 'expense',
          amount: 150.0,
          category: 'Food',
          occurredOn: DateTime(2026, 11, 15),
          note: 'Lunch at cafeteria',
        ),
      ],
      summary: const FinanceSummary(
        month: '2026-11',
        totalIncome: 5000.0,
        totalExpenses: 150.0,
        balance: 4850.0,
        byCategory: <CategoryBreakdown>[
          CategoryBreakdown(
            category: 'Allowance',
            type: 'income',
            total: 5000.0,
          ),
          CategoryBreakdown(category: 'Food', type: 'expense', total: 150.0),
        ],
      ),
      categories: const <String>['Food', 'Transport', 'Allowance', 'Other'],
    );
  }
}

class FakeNotesController extends NotesController {
  @override
  Future<NotesState> build() async {
    return NotesState(
      notes: <Note>[
        Note(
          id: 1,
          title: 'Physics Formula Sheet',
          body: 'Newtonian mechanics formulas and constants.',
          tags: const <String>['physics', 'exam'],
          updatedAt: DateTime(2026, 11, 15, 14, 0),
        ),
      ],
      tags: const <String>['physics', 'exam'],
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Calendar screen displays event and floating action button', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          calendarControllerProvider.overrideWith(FakeCalendarController.new),
        ],
        child: const MaterialApp(home: CalendarScreen()),
      ),
    );

    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('Math 101 Lecture'), findsOneWidget);
    expect(find.text('Room 304'), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsOneWidget);

    // Tap + button to open Add Event bottom sheet
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    expect(find.text('New Event'), findsOneWidget);
    expect(find.text('Title'), findsOneWidget);
  });

  testWidgets('Finance screen displays balance summary and transactions', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          financeControllerProvider.overrideWith(FakeFinanceController.new),
        ],
        child: const MaterialApp(home: FinanceScreen()),
      ),
    );

    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('Left this month'), findsOneWidget);
    expect(find.textContaining('Lunch at cafeteria'), findsOneWidget);
    expect(find.textContaining('Weekly allowance'), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsOneWidget);

    // Tap + button to open Add Transaction bottom sheet
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    expect(find.text('Quick expense'), findsOneWidget);
    expect(find.text('₱50'), findsOneWidget);

    await tester.tap(find.text('Income or another date'));
    await tester.pumpAndSettle();

    expect(find.text('Add Transaction'), findsOneWidget);
  });

  testWidgets('Notes screen displays notes list, search bar, and tags', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          notesControllerProvider.overrideWith(FakeNotesController.new),
        ],
        child: const MaterialApp(home: NotesScreen()),
      ),
    );

    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('Physics Formula Sheet'), findsOneWidget);
    expect(
      find.text('Newtonian mechanics formulas and constants.'),
      findsOneWidget,
    );
    expect(find.text('#physics'), findsWidgets);
    expect(find.byType(FloatingActionButton), findsOneWidget);

    // Tap + button to open Add Note bottom sheet
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    expect(find.text('New Note'), findsOneWidget);
    expect(find.text('Title (optional)'), findsOneWidget);
    expect(find.text('Note content'), findsOneWidget);
  });

  group('Student Features: Exam countdowns & in-event checklists', () {
    test('CalendarEvent detects exams and calculates countdown badges', () {
      final DateTime now = DateTime(2026, 11, 16, 10, 0);

      final CalendarEvent examToday = CalendarEvent(
        id: 1,
        title: 'Physics Midterm Exam',
        startsAt: DateTime(2026, 11, 16, 14, 0),
      );
      expect(examToday.isExam, isTrue);
      expect(examToday.isAssignment, isFalse);
      expect(examToday.countdownBadge(now), 'Today');

      final CalendarEvent quizTomorrow = CalendarEvent(
        id: 2,
        title: 'Calculus Quiz 3',
        startsAt: DateTime(2026, 11, 17, 9, 0),
      );
      expect(quizTomorrow.isExam, isTrue);
      expect(quizTomorrow.countdownBadge(now), 'Tomorrow');

      final CalendarEvent projectInFiveDays = CalendarEvent(
        id: 3,
        title: 'Computer Science Final Project Deadline',
        startsAt: DateTime(2026, 11, 21, 23, 59),
      );
      expect(projectInFiveDays.isAssignment, isTrue);
      expect(projectInFiveDays.countdownBadge(now), 'in 5 days');
    });

    test('Event type follows whole words and can be changed back', () {
      CalendarEvent event(String title, [String? notes]) => CalendarEvent(
        id: 1,
        title: title,
        startsAt: DateTime(2026, 11, 16, 9),
        notes: notes,
      );
      expect(event('Latest news club').isExam, isFalse);
      expect(event('Finalize thesis outline').isExam, isFalse);
      expect(event('Test 2').isExam, isTrue);

      final String? tagged = CalendarEvent.notesWithType('Room 2', 'exam');
      expect(tagged, 'Room 2\n#exam');
      expect(event('Physics', tagged).isExam, isTrue);
      // Picking General again removes the tag.
      expect(CalendarEvent.notesWithType(tagged, 'general'), 'Room 2');
      expect(CalendarEvent.notesWithType('#exam', 'general'), isNull);
      expect(
        CalendarEvent.notesWithType(tagged, 'assignment'),
        'Room 2\n#assignment',
      );
    });

    test('CalendarEvent parses and toggles markdown checklist items', () {
      final CalendarEvent event = CalendarEvent(
        id: 1,
        title: 'Chemistry Lab',
        startsAt: DateTime(2026, 11, 16, 13, 0),
        notes: '- [ ] Bring goggles\n- [x] Print lab sheet\n- [ ] Calculator',
      );

      final items = event.checklistItems;
      expect(items.length, 3);
      expect(items[0].text, 'Bring goggles');
      expect(items[0].done, isFalse);
      expect(items[1].text, 'Print lab sheet');
      expect(items[1].done, isTrue);
      expect(items[2].text, 'Calculator');
      expect(items[2].done, isFalse);

      final CalendarEvent toggled = event.toggleChecklistItem(0);
      final updatedItems = toggled.checklistItems;
      expect(updatedItems[0].done, isTrue);

      final CalendarEvent unToggled = toggled.toggleChecklistItem(1);
      final finalItems = unToggled.checklistItems;
      expect(finalItems[1].done, isFalse);
    });
  });

  group('Student Features: Active Recall in Notes', () {
    test('extractRecallCards parses multi-line Q&A and single-line cards', () {
      const String text = '''
Lecture 4: Cell Biology
Q: What is the mitochondria?
A: Powerhouse of the cell

Q: Function of ribosomes?
A: Protein synthesis

Osmosis :: Diffusion of water across a semipermeable membrane
''';

      final cards = extractRecallCards(text);
      expect(cards.length, 3);
      expect(cards[0].question, 'What is the mitochondria?');
      expect(cards[0].answer, 'Powerhouse of the cell');
      expect(cards[1].question, 'Function of ribosomes?');
      expect(cards[1].answer, 'Protein synthesis');
      expect(cards[2].question, 'Osmosis');
      expect(
        cards[2].answer,
        'Diffusion of water across a semipermeable membrane',
      );
    });
  });
}
