import 'package:flutter_test/flutter_test.dart';
import 'package:studentos/core/widgets/ponpon.dart';
import 'package:studentos/features/calendar/event.dart';
import 'package:studentos/features/finance/bill.dart';
import 'package:studentos/features/finance/savings_goal.dart';
import 'package:studentos/features/finance/transaction.dart';
import 'package:studentos/features/insights/calendar_insights.dart';
import 'package:studentos/features/insights/finance_insights.dart';
import 'package:studentos/features/insights/notes_insights.dart';
import 'package:studentos/features/insights/ponpon_insight.dart';
import 'package:studentos/features/notes/note.dart';
import 'package:studentos/features/tasks/task_item.dart';
import 'package:studentos/features/work/shift.dart';

void main() {
  group('formatting', () {
    test('pesoText drops zero centavos and keeps real ones', () {
      expect(pesoText(2300), '₱2,300');
      expect(pesoText(37.5), '₱37.50');
      expect(pesoText(0), '₱0');
    });

    test('spanText reads minutes and hours', () {
      expect(spanText(const Duration(minutes: 25)), '25 min');
      expect(spanText(const Duration(minutes: 90)), '1 h 30 min');
      expect(spanText(const Duration(hours: 2)), '2 h');
      expect(spanText(const Duration(seconds: 61)), '2 min');
    });

    test('rankInsights sorts by priority, keeps order of ties, caps at 4', () {
      final List<PonponInsight> ranked = rankInsights(<PonponInsight>[
        const PonponInsight(text: 'e', priority: 5),
        const PonponInsight(text: 'b1', priority: 1),
        const PonponInsight(text: 'a', priority: 0),
        const PonponInsight(text: 'b2', priority: 1),
        const PonponInsight(text: 'd', priority: 4),
      ]);
      expect(ranked.map((PonponInsight i) => i.text), <String>[
        'a',
        'b1',
        'b2',
        'd',
      ]);
    });
  });

  group('calendarInsights', () {
    // Tuesday 17 Nov 2026, 2:00 PM.
    final DateTime now = DateTime(2026, 11, 17, 14);

    CalendarEvent event(
      String title,
      DateTime at, {
      String? location,
      String recurrence = 'none',
      int durationMinutes = 60,
      bool done = false,
    }) => CalendarEvent(
      id: title.hashCode,
      title: title,
      startsAt: at,
      durationMinutes: durationMinutes,
      location: location,
      recurrence: recurrence,
      done: done,
    );

    List<String> texts(List<PonponInsight> l) =>
        l.map((PonponInsight i) => i.text).toList();

    test('says nothing with no events', () {
      expect(calendarInsights(events: const [], now: now), isEmpty);
    });

    test('next event within 2 hours, with its room', () {
      final List<PonponInsight> r = calendarInsights(
        events: <CalendarEvent>[
          event(
            'Physics 101',
            DateTime(2026, 11, 17, 14, 25),
            location: 'Room 301',
          ),
        ],
        now: now,
      );
      expect(r.first.text, 'In 25 min · Room 301: Physics 101');
      expect(r.first.mood, PonponMood.happy);
    });

    test('2 hours exactly counts, one minute more does not', () {
      expect(
        texts(
          calendarInsights(
            events: <CalendarEvent>[event('A', DateTime(2026, 11, 17, 16))],
            now: now,
          ),
        ),
        contains('In 2 h: A'),
      );
      expect(
        texts(
          calendarInsights(
            events: <CalendarEvent>[event('A', DateTime(2026, 11, 17, 16, 1))],
            now: now,
          ),
        ).any((String t) => t.endsWith(': A')),
        isFalse,
      );
    });

    test('a recurring event counts through its recurrence', () {
      final List<PonponInsight> r = calendarInsights(
        events: <CalendarEvent>[
          event(
            'Weekly lab',
            DateTime(2026, 11, 10, 14, 30),
            recurrence: 'weekly',
          ),
        ],
        now: now,
      );
      expect(r.first.text, 'In 30 min: Weekly lab');
    });

    test('a started event is not "soon"', () {
      final List<PonponInsight> r = calendarInsights(
        events: <CalendarEvent>[event('Gone', DateTime(2026, 11, 17, 13))],
        now: now,
      );
      expect(texts(r).any((String t) => t.contains('Gone in')), isFalse);
    });

    test('exam within 7 days is a focused nudge', () {
      final List<PonponInsight> r = calendarInsights(
        events: <CalendarEvent>[event('Chem Exam', DateTime(2026, 11, 20, 9))],
        now: now,
      );
      final PonponInsight exam = r.firstWhere(
        (PonponInsight i) => i.text.startsWith('Exam '),
      );
      expect(
        exam.text,
        'Exam in 3 days: Chem Exam. A focus session would help.',
      );
      expect(exam.mood, PonponMood.focused);
    });

    test('assignment tomorrow, and nothing past 7 days', () {
      expect(
        texts(
          calendarInsights(
            events: <CalendarEvent>[
              event('Essay due', DateTime(2026, 11, 18, 9)),
            ],
            now: now,
          ),
        ),
        contains('Assignment tomorrow: Essay due. A focus session would help.'),
      );
      expect(
        texts(
          calendarInsights(
            events: <CalendarEvent>[
              event('Final exam', DateTime(2026, 11, 25, 9)),
            ],
            now: now,
          ),
        ).any((String t) => t.startsWith('Exam ')),
        isFalse,
      );
    });

    test('late night with an early start tomorrow is smug', () {
      final List<PonponInsight> r = calendarInsights(
        events: <CalendarEvent>[
          event('Physics 101', DateTime(2026, 11, 18, 8)),
        ],
        now: DateTime(2026, 11, 17, 23, 30),
      );
      expect(r.first.text, 'Still awake? 8:00 AM tomorrow: Physics 101.');
      expect(r.first.mood, PonponMood.smug);
      expect(
        texts(r).any((String t) => t.startsWith('Tomorrow starts')),
        isFalse,
      );
    });

    test(
      'late night with a late start tomorrow just names the first event',
      () {
        final List<PonponInsight> r = calendarInsights(
          events: <CalendarEvent>[
            event('Physics 101', DateTime(2026, 11, 18, 13)),
          ],
          now: DateTime(2026, 11, 17, 23, 30),
        );
        expect(r.first.text, 'Tomorrow starts at 1:00 PM with Physics 101.');
      },
    );

    test('tomorrow starts at the first event of tomorrow', () {
      final List<PonponInsight> r = calendarInsights(
        events: <CalendarEvent>[
          event('B', DateTime(2026, 11, 18, 11)),
          event('A', DateTime(2026, 11, 18, 8)),
        ],
        now: now,
      );
      expect(texts(r), contains('Tomorrow starts at 8:00 AM with A.'));
    });

    test('midnight rollover: 11:50 PM sees a 12:30 AM event as soon', () {
      final CalendarEvent e = event(
        'Night shift class',
        DateTime(2026, 11, 18, 0, 30),
      );
      expect(
        calendarInsights(
          events: <CalendarEvent>[e],
          now: DateTime(2026, 11, 17, 23, 50),
        ).first.text,
        'In 40 min: Night shift class',
      );
      // Ten minutes after midnight the same event is today's.
      expect(
        calendarInsights(
          events: <CalendarEvent>[e],
          now: DateTime(2026, 11, 18, 0, 10),
        ).first.text,
        'In 20 min: Night shift class',
      );
    });

    test('busiest remaining day this week needs 3 things', () {
      List<CalendarEvent> wed(int n) => <CalendarEvent>[
        for (int i = 0; i < n; i++) event('W$i', DateTime(2026, 11, 18, 9 + i)),
      ];
      expect(
        texts(calendarInsights(events: wed(4), now: now)),
        contains('Wednesday is your busiest day: 4 things.'),
      );
      expect(
        texts(calendarInsights(events: wed(2), now: now))
            .any((String t) => t.contains('busiest')),
        isFalse,
      );
    });

    test('busiest day ignores next week', () {
      // Monday 23 Nov is after this Sunday.
      expect(
        texts(
          calendarInsights(
            events: <CalendarEvent>[
              for (int i = 0; i < 4; i++)
                event('N$i', DateTime(2026, 11, 23, 9 + i)),
            ],
            now: now,
          ),
        ).any((String t) => t.contains('busiest')),
        isFalse,
      );
    });

    test('nothing left today is sleepy', () {
      final List<PonponInsight> r = calendarInsights(
        events: <CalendarEvent>[event('Morning', DateTime(2026, 11, 17, 9))],
        now: DateTime(2026, 11, 17, 18),
      );
      expect(r.single.text, 'Nothing else today. Rest up.');
      expect(r.single.mood, PonponMood.sleepy);
    });

    test('a shift still ahead is named and keeps the day from being over', () {
      final List<PonponInsight> r = calendarInsights(
        events: <CalendarEvent>[event('Morning', DateTime(2026, 11, 17, 9))],
        shifts: <Shift>[
          Shift(
            id: 1,
            job: 'Cafe',
            startsAt: DateTime(2026, 11, 17, 17),
            durationMinutes: 240,
          ),
        ],
        now: now,
      );
      expect(texts(r), contains('Cafe shift at 5:00 PM today.'));
      expect(texts(r), isNot(contains('Nothing else today. Rest up.')));
    });

    test('never more than 4, ordered by priority', () {
      final List<PonponInsight> r = calendarInsights(
        events: <CalendarEvent>[
          event('Soon', DateTime(2026, 11, 17, 14, 30)),
          event('Chem Exam', DateTime(2026, 11, 19, 9)),
          event('T1', DateTime(2026, 11, 18, 8)),
          event('T2', DateTime(2026, 11, 18, 9)),
          event('T3', DateTime(2026, 11, 18, 10)),
        ],
        shifts: <Shift>[
          Shift(
            id: 1,
            job: 'Cafe',
            startsAt: DateTime(2026, 11, 17, 17),
            durationMinutes: 60,
          ),
        ],
        now: now,
      );
      expect(r.length, lessThanOrEqualTo(4));
      final List<int> p = r.map((PonponInsight i) => i.priority).toList();
      expect(p, orderedEquals(<int>[...p]..sort()));
      expect(r.first.text, startsWith('In 30 min: Soon'));
    });

    test('done events stop firing Ponpon nudges', () {
      final List<PonponInsight> r = calendarInsights(
        events: <CalendarEvent>[
          event('Soon Exam', DateTime(2026, 11, 17, 14, 20), done: true),
          event('Morning Exam', DateTime(2026, 11, 18, 8), done: true),
          event('E1', DateTime(2026, 11, 18, 9), done: true),
          event('E2', DateTime(2026, 11, 18, 10), done: true),
        ],
        now: now,
      );
      expect(r, isEmpty);
    });

    test(
      'isAllDay events stay out of clock-time tips and defer to timed events',
      () {
        final DateTime lateNight = DateTime(2026, 11, 17, 22, 30);
        // Only an all-day event tomorrow -> no "In X min" or "12:00 AM" tip.
        final List<PonponInsight> onlyAllDay = calendarInsights(
          events: <CalendarEvent>[
            event(
              'Foundation Day',
              DateTime(2026, 11, 18, 0, 0),
              durationMinutes: 1440,
            ),
          ],
          now: lateNight,
        );
        expect(onlyAllDay, isEmpty);

        // An all-day event plus an 8:00 AM class tomorrow -> picks 8:00 AM.
        final List<PonponInsight> withClass = calendarInsights(
          events: <CalendarEvent>[
            event(
              'Foundation Day',
              DateTime(2026, 11, 18, 0, 0),
              durationMinutes: 1440,
            ),
            event('Physics 101', DateTime(2026, 11, 18, 8)),
          ],
          now: lateNight,
        );
        expect(
          withClass.single.text,
          'Still awake? 8:00 AM tomorrow: Physics 101.',
        );

        // Midday check still skips "Tomorrow starts at 12:00 AM".
        final List<PonponInsight> middayAllDay = calendarInsights(
          events: <CalendarEvent>[
            event(
              'Foundation Day',
              DateTime(2026, 11, 18, 0, 0),
              durationMinutes: 1440,
            ),
          ],
          now: now,
        );
        expect(middayAllDay, isEmpty);

        // All-day exam today still nudges without clock-time claims.
        final List<PonponInsight> allDayExamToday = calendarInsights(
          events: <CalendarEvent>[
            event(
              'Lab Exam',
              DateTime(2026, 11, 17, 0, 0),
              durationMinutes: 1440,
            ),
          ],
          now: now,
        );
        expect(
          texts(allDayExamToday),
          contains('Exam today: Lab Exam. A focus session would help.'),
        );
        expect(
          texts(allDayExamToday).any((String t) => t.contains('12:00 AM')),
          isFalse,
        );
      },
    );
  });

  group('financeInsights', () {
    // Friday 20 Nov 2026, 8:00 PM.
    final DateTime now = DateTime(2026, 11, 20, 20);

    Transaction tx(
      int day,
      double amount, {
      String category = 'Food',
      String type = 'expense',
      int month = 11,
      int year = 2026,
    }) => Transaction(
      id: 0,
      type: type,
      amount: amount,
      category: category,
      occurredOn: DateTime(year, month, day),
    );

    List<String> texts(List<PonponInsight> l) =>
        l.map((PonponInsight i) => i.text).toList();

    final Transaction income = tx(
      1,
      9000,
      category: 'Allowance',
      type: 'income',
    );

    test('says nothing with no transactions', () {
      expect(
        financeInsights(thisMonth: const [], lastMonth: const [], now: now),
        isEmpty,
      );
    });

    test('today well above the daily average', () {
      // 1,900 over 19 days = 100 a day; 400 today.
      final List<PonponInsight> r = financeInsights(
        thisMonth: <Transaction>[income, tx(2, 1900), tx(20, 400)],
        lastMonth: const [],
        now: now,
      );
      expect(
        r.first.text,
        'You spent ₱400 today, well above your usual ₱100 a day.',
      );
      expect(r.first.mood, PonponMood.smug);
    });

    test('today well under the daily average', () {
      final List<PonponInsight> r = financeInsights(
        thisMonth: <Transaction>[income, tx(2, 1900), tx(20, 20)],
        lastMonth: const [],
        now: now,
      );
      expect(
        texts(r),
        contains('Only ₱20 spent today, under your usual ₱100 a day.'),
      );
    });

    test('a small difference is not worth saying', () {
      final List<PonponInsight> r = financeInsights(
        thisMonth: <Transaction>[income, tx(2, 1900), tx(20, 110)],
        lastMonth: const [],
        now: now,
      );
      expect(texts(r).any((String t) => t.contains('usual')), isFalse);
    });

    test('no daily comparison in the first days of the month', () {
      final List<PonponInsight> r = financeInsights(
        thisMonth: <Transaction>[income, tx(1, 100), tx(3, 900)],
        lastMonth: const [],
        now: DateTime(2026, 11, 3, 20),
      );
      expect(texts(r).any((String t) => t.contains('usual')), isFalse);
    });

    test('top category share', () {
      final List<PonponInsight> r = financeInsights(
        thisMonth: <Transaction>[
          income,
          tx(2, 2300),
          tx(3, 1500, category: 'Other'),
          tx(4, 1300, category: 'Transport'),
          tx(20, 100, category: 'Other'),
        ],
        lastMonth: const [],
        now: now,
      );
      expect(
        texts(r),
        contains('Food is 44% of your spending this month (₱2,300).'),
      );
    });

    test('no category line when spending is spread thin', () {
      final List<PonponInsight> r = financeInsights(
        thisMonth: <Transaction>[
          income,
          tx(2, 100, category: 'Food'),
          tx(3, 100, category: 'Transport'),
          tx(4, 100, category: 'School'),
          tx(5, 100, category: 'Other'),
        ],
        lastMonth: const [],
        now: now,
      );
      expect(
        texts(r).any((String t) => t.contains('% of your spending')),
        isFalse,
      );
    });

    test('above last month by the same day, ignoring later days', () {
      final List<PonponInsight> r = financeInsights(
        thisMonth: <Transaction>[
          income,
          tx(2, 2600, category: 'Food'),
          tx(20, 0.0),
        ],
        lastMonth: <Transaction>[
          tx(5, 2000, month: 10),
          tx(25, 9000, month: 10),
        ],
        now: now,
      );
      expect(
        texts(r),
        contains('You are ₱600 above last month by this day (₱2,000).'),
      );
    });

    test('under last month', () {
      final List<PonponInsight> r = financeInsights(
        thisMonth: <Transaction>[income, tx(2, 1000)],
        lastMonth: <Transaction>[tx(5, 2000, month: 10)],
        now: now,
      );
      expect(
        texts(r),
        contains('You are ₱1,000 under last month by this day (₱2,000).'),
      );
    });

    test('no last-month line without last-month data', () {
      final List<PonponInsight> r = financeInsights(
        thisMonth: <Transaction>[income, tx(2, 1000)],
        lastMonth: const [],
        now: now,
      );
      expect(texts(r).any((String t) => t.contains('last month')), isFalse);
    });

    test('March 31 compares with all of a 28 day February', () {
      final List<PonponInsight> r = financeInsights(
        thisMonth: <Transaction>[
          tx(1, 1500, month: 3, category: 'Allowance', type: 'income'),
          tx(2, 1500, month: 3),
        ],
        lastMonth: <Transaction>[tx(28, 1000, month: 2)],
        now: DateTime(2026, 3, 31, 12),
      );
      expect(
        texts(r),
        contains('You are ₱500 above last month by this day (₱1,000).'),
      );
    });

    test('January compares with December', () {
      final List<PonponInsight> r = financeInsights(
        thisMonth: <Transaction>[
          tx(1, 5000, month: 1, category: 'Allowance', type: 'income'),
          tx(2, 400, month: 1),
        ],
        lastMonth: <Transaction>[tx(3, 1000, month: 12, year: 2025)],
        now: DateTime(2027, 1, 10, 12),
      );
      expect(
        texts(r),
        contains('You are ₱600 under last month by this day (₱1,000).'),
      );
    });

    test('more out than in is smug and comes first', () {
      final List<PonponInsight> r = financeInsights(
        thisMonth: <Transaction>[
          tx(1, 2500, category: 'Allowance', type: 'income'),
          tx(2, 3000),
        ],
        lastMonth: const [],
        now: now,
      );
      expect(
        r.first.text,
        'You spent ₱3,000 and ₱2,500 came in. That is ₱500 more out than in.',
      );
      expect(r.first.mood, PonponMood.smug);
    });

    test('nothing spent yet today', () {
      final List<PonponInsight> r = financeInsights(
        thisMonth: <Transaction>[income, tx(2, 100)],
        lastMonth: const [],
        now: now,
      );
      expect(texts(r), contains('Nothing spent yet today.'));
    });

    test('income only still gets a friendly line, never Safe-to-Spend', () {
      final List<PonponInsight> r = financeInsights(
        thisMonth: <Transaction>[income],
        lastMonth: const [],
        now: now,
      );
      expect(texts(r), <String>['Nothing spent yet today.']);
    });

    test('at most 4', () {
      final List<PonponInsight> r = financeInsights(
        thisMonth: <Transaction>[
          tx(1, 1000, category: 'Allowance', type: 'income'),
          tx(2, 1900),
          tx(20, 400),
        ],
        lastMonth: <Transaction>[tx(5, 1000, month: 10)],
        now: now,
        bills: const <Bill>[
          Bill(
            id: 1,
            title: 'Rent',
            amountCents: 350000,
            category: 'Other',
            cadence: 'monthly:20',
            nextDueOn: '2026-11-20',
          ),
        ],
      );
      expect(r.length, lessThanOrEqualTo(4));
    });

    test('due bill speaks even on an empty month, plain without !', () {
      final List<PonponInsight> oneDue = financeInsights(
        thisMonth: const <Transaction>[],
        lastMonth: const <Transaction>[],
        now: now,
        bills: const <Bill>[
          Bill(
            id: 1,
            title: 'Rent',
            amountCents: 350000,
            category: 'Other',
            cadence: 'monthly:20',
            nextDueOn: '2026-11-20',
          ),
        ],
      );
      expect(oneDue.single.text, 'Bill due today: Rent (₱3,500).');
      expect(oneDue.single.text.contains('!'), isFalse);

      final List<PonponInsight> oneOverdue = financeInsights(
        thisMonth: const <Transaction>[],
        lastMonth: const <Transaction>[],
        now: now,
        bills: const <Bill>[
          Bill(
            id: 2,
            title: 'Wifi',
            amountCents: 129950,
            category: 'Other',
            cadence: 'monthly:18',
            nextDueOn: '2026-11-18',
          ),
        ],
      );
      expect(oneOverdue.single.text, 'Bill overdue: Wifi (₱1,299.50).');

      final List<PonponInsight> multiDue = financeInsights(
        thisMonth: const <Transaction>[],
        lastMonth: const <Transaction>[],
        now: now,
        bills: const <Bill>[
          Bill(
            id: 1,
            title: 'Rent',
            amountCents: 350000,
            category: 'Other',
            cadence: 'monthly:20',
            nextDueOn: '2026-11-20',
          ),
          Bill(
            id: 2,
            title: 'Load',
            amountCents: 70000,
            category: 'Other',
            cadence: 'weekly:5',
            nextDueOn: '2026-11-19',
          ),
          Bill(
            id: 3,
            title: 'Paused',
            amountCents: 10000,
            category: 'Other',
            cadence: 'monthly:1',
            nextDueOn: '2026-11-01',
            active: false,
          ),
          Bill(
            id: 4,
            title: 'Future',
            amountCents: 10000,
            category: 'Other',
            cadence: 'monthly:25',
            nextDueOn: '2026-11-25',
          ),
        ],
      );
      expect(multiDue.single.text, '2 bills due (₱4,200).');
    });

    test('near-target and due-soon savings goals emit seeGoals tips', () {
      final List<PonponInsight> nearTarget = financeInsights(
        thisMonth: const <Transaction>[],
        lastMonth: const <Transaction>[],
        now: now,
        goals: <SavingsGoal>[
          SavingsGoal(
            id: 1,
            title: 'Headphones',
            targetCents: 100000,
            savedCents: 85000,
            createdAt: DateTime(2026, 11, 1),
          ),
        ],
      );
      expect(nearTarget.single.text, 'Almost there: Headphones is ₱150 away.');
      expect(nearTarget.single.priority, 2);
      expect(nearTarget.single.action, PonponAction.seeGoals);

      final List<PonponInsight> dueToday = financeInsights(
        thisMonth: <Transaction>[income],
        lastMonth: const <Transaction>[],
        now: now,
        goals: <SavingsGoal>[
          SavingsGoal(
            id: 2,
            title: 'Lab Fee',
            targetCents: 50000,
            savedCents: 20000,
            targetDate: '2026-11-20',
            createdAt: DateTime(2026, 11, 1),
          ),
        ],
      );
      expect(
        dueToday.map((PonponInsight i) => i.text),
        contains('Lab Fee target is today (₱300 to go).'),
      );
      final PonponInsight dueTip = dueToday.firstWhere(
        (PonponInsight i) => i.text.startsWith('Lab Fee'),
      );
      expect(dueTip.priority, 3);
      expect(dueTip.action, PonponAction.seeGoals);

      final List<PonponInsight> dueSoon = financeInsights(
        thisMonth: const <Transaction>[],
        lastMonth: const <Transaction>[],
        now: now,
        goals: <SavingsGoal>[
          SavingsGoal(
            id: 3,
            title: 'Tuition',
            targetCents: 100000,
            savedCents: 10000,
            targetDate: '2026-11-25',
            createdAt: DateTime(2026, 11, 1),
          ),
          SavingsGoal(
            id: 4,
            title: 'Already Reached',
            targetCents: 10000,
            savedCents: 10000,
            targetDate: '2026-11-20',
            createdAt: DateTime(2026, 11, 1),
          ),
        ],
      );
      expect(
        dueSoon.single.text,
        'Tuition target is in 5 days (₱900 to go).',
      );
      expect(dueSoon.single.action, PonponAction.seeGoals);
    });
  });

  group('notesInsights', () {
    final DateTime now = DateTime(2026, 11, 17, 22);

    Note note(int id, {String body = 'plain', List<String> tags = const []}) =>
        Note(id: id, title: 'N$id', body: body, tags: tags);

    List<String> texts(List<PonponInsight> l) =>
        l.map((PonponInsight i) => i.text).toList();

    test('says nothing with no notes, even with events', () {
      expect(
        notesInsights(
          notes: const [],
          events: <CalendarEvent>[
            CalendarEvent(
              id: 1,
              title: 'X',
              startsAt: DateTime(2026, 11, 18, 8),
              noteId: 1,
            ),
          ],
          now: now,
        ),
        isEmpty,
      );
    });

    test('counts notes that hold quiz cards', () {
      final List<PonponInsight> r = notesInsights(
        notes: <Note>[
          note(1, body: 'Q: F?\nA: ma'),
          note(2, body: 'Mitochondria :: Powerhouse'),
          note(3, body: 'Q: x\nA: y'),
          note(4),
        ],
        now: now,
      );
      expect(r.single.text, '3 notes have quiz cards. Quiz yourself?');
      expect(r.single.mood, PonponMood.focused);
    });

    test('singular for one note', () {
      expect(
        notesInsights(
          notes: <Note>[note(1, body: 'Q: a\nA: b')],
          now: now,
        ).single.text,
        '1 note has quiz cards. Quiz yourself?',
      );
    });

    test('an event in the next 24 hours with a note', () {
      final List<PonponInsight> r = notesInsights(
        notes: <Note>[note(7)],
        events: <CalendarEvent>[
          CalendarEvent(
            id: 1,
            title: 'Physics 101',
            startsAt: DateTime(2026, 11, 18, 8),
            noteId: 7,
          ),
        ],
        now: now,
      );
      expect(r.first.text, 'Review your note before 8:00 AM: Physics 101.');
    });

    test('ignores events past 24 hours, done events, or orphan notes', () {
      final List<PonponInsight> r = notesInsights(
        notes: <Note>[note(7)],
        events: <CalendarEvent>[
          CalendarEvent(
            id: 1,
            title: 'Far',
            startsAt: DateTime(2026, 11, 19, 8),
            noteId: 7,
          ),
          CalendarEvent(
            id: 2,
            title: 'Orphan',
            startsAt: DateTime(2026, 11, 18, 8),
            noteId: 99,
          ),
          CalendarEvent(
            id: 3,
            title: 'Finished Exam',
            startsAt: DateTime(2026, 11, 18, 8),
            noteId: 7,
            done: true,
          ),
        ],
        now: now,
      );
      expect(r, isEmpty);
    });

    test('a recurring event with a note counts', () {
      final List<PonponInsight> r = notesInsights(
        notes: <Note>[note(7)],
        events: <CalendarEvent>[
          CalendarEvent(
            id: 1,
            title: 'Daily review',
            startsAt: DateTime(2026, 11, 1, 8),
            recurrence: 'daily',
            noteId: 7,
          ),
        ],
        now: now,
      );
      expect(r.first.text, 'Review your note before 8:00 AM: Daily review.');
    });

    test('most used tag needs two notes, ties go alphabetical', () {
      expect(
        notesInsights(
          notes: <Note>[
            note(1, tags: <String>['physics', 'math']),
            note(2, tags: <String>['physics']),
            note(3, tags: <String>['math']),
          ],
          now: now,
        ).map((PonponInsight i) => i.text),
        contains('#math is your most used tag (2 notes).'),
      );
      expect(
        texts(
          notesInsights(
            notes: <Note>[
              note(1, tags: <String>['a']),
              note(2, tags: <String>['b']),
            ],
            now: now,
          ),
        ),
        isEmpty,
      );
    });

    test('surfaces overdue and today tasks with seeTasks action, non-scolding', () {
      final List<PonponInsight> overdue = notesInsights(
        notes: const <Note>[],
        tasks: <TaskItem>[
          const TaskItem(
            id: 1,
            title: 'Submit lab report',
            dueOn: '2026-11-16',
          ),
          const TaskItem(
            id: 2,
            title: 'Done old task',
            dueOn: '2026-11-15',
            done: true,
          ),
        ],
        now: now,
      );
      expect(overdue.single.text, '1 task is past due: Submit lab report.');
      expect(overdue.single.action, PonponAction.seeTasks);
      expect(overdue.single.text.contains('!'), isFalse);

      final List<PonponInsight> todayOnly = notesInsights(
        notes: const <Note>[],
        tasks: <TaskItem>[
          const TaskItem(id: 1, title: 'Read chapter 4', dueOn: '2026-11-17'),
          const TaskItem(id: 2, title: 'Pack bag', dueOn: '2026-11-17'),
        ],
        now: now,
      );
      expect(todayOnly.single.text, '2 tasks due today.');
      expect(todayOnly.single.mood, PonponMood.focused);
      expect(todayOnly.single.action, PonponAction.seeTasks);
    });
  });

  group('calendarInsights task rules', () {
    final DateTime now = DateTime(2026, 11, 17, 14);

    test('nudges overdue and due-today tasks with seeTasks action', () {
      final List<PonponInsight> overdue = calendarInsights(
        events: const <CalendarEvent>[],
        tasks: const <TaskItem>[
          TaskItem(id: 1, title: 'Email prof', dueOn: '2026-11-16'),
        ],
        now: now,
      );
      expect(
        overdue.single.text,
        '1 task from earlier is still open: Email prof.',
      );
      expect(overdue.single.action, PonponAction.seeTasks);
      expect(overdue.single.text.contains('!'), isFalse);

      final List<PonponInsight> today = calendarInsights(
        events: const <CalendarEvent>[],
        tasks: const <TaskItem>[
          TaskItem(id: 2, title: 'Finish worksheet', dueOn: '2026-11-17'),
        ],
        now: now,
      );
      expect(today.single.text, 'Task due today: Finish worksheet.');
      expect(today.single.action, PonponAction.seeTasks);
    });
  });
}
