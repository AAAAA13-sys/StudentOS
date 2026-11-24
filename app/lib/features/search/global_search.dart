import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/db/export_sheet.dart';
import '../../core/widgets/capture_request.dart';
import '../calendar/calendar_screen.dart';
import '../calendar/calendar_repository.dart';
import '../calendar/event.dart';
import '../finance/bill.dart';
import '../finance/bills_repository.dart';
import '../finance/finance_controller.dart';
import '../finance/finance_repository.dart';
import '../finance/goals_controller.dart';
import '../finance/goals_repository.dart';
import '../finance/iou_item.dart';
import '../finance/ious_repository.dart';
import '../finance/savings_goal.dart';
import '../finance/transaction.dart';
import '../focus/alarm.dart';
import '../focus/clock_panels.dart';
import '../focus/focus_controller.dart';
import '../focus/focus_plan.dart';
import '../focus/focus_platform.dart';
import '../focus/focus_repository.dart';
import '../insights/month_review_screen.dart';
import '../notes/note.dart';
import '../notes/note_editor_sheet.dart';
import '../notes/notes_repository.dart';
import '../tasks/task_item.dart';
import '../tasks/tasks_controller.dart';
import '../tasks/tasks_panel.dart';
import '../tasks/tasks_repository.dart';
import '../work/shift.dart';
import '../work/work_repository.dart';

/// All entity and command kinds surfaced in the cross-tab command palette.
enum SearchHitKind {
  command,
  event,
  shift,
  task,
  note,
  transaction,
  bill,
  goal,
  iou,
  alarm,
}

/// Filter chips shown in the command palette sheet.
const List<String> searchGroupFilters = <String>[
  'All',
  'Commands',
  'Calendar',
  'Finance',
  'Notes',
];

/// A single actionable result or quick command in the global search palette.
@immutable
class SearchHit {
  const SearchHit({
    required this.kind,
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.searchText,
    this.rankBoost = 0,
    required this.onSelect,
  });

  final SearchHitKind kind;
  final String title;
  final String subtitle;
  final String badge;
  final String searchText;
  final int rankBoost;
  final Future<void> Function(BuildContext hostContext, WidgetRef ref) onSelect;
}

String _pesoText(double amount) => NumberFormat.currency(
  symbol: '₱',
  decimalDigits: amount == amount.roundToDouble() ? 0 : 2,
).format(amount);

String _alarmTimeText(Alarm alarm) => DateFormat(
  'h:mm a',
).format(DateTime(2026, 1, 1, alarm.hour, alarm.minute));

/// Builds the fixed set of cross-app quick commands.
List<SearchHit> buildQuickCommands() {
  return <SearchHit>[
    SearchHit(
      kind: SearchHitKind.command,
      title: 'Quick expense',
      subtitle: 'Log spending on Finance',
      badge: 'Command',
      searchText: 'quick expense log spend money cashflow finance',
      rankBoost: 30,
      onSelect: (BuildContext hostContext, WidgetRef _) async {
        final ProviderContainer container = ProviderScope.containerOf(
          hostContext,
        );
        container.read(financeViewProvider.notifier).show(FinanceView.cashflow);
        GoRouter.maybeOf(hostContext)?.go('/finance');
        container
            .read(captureRequestProvider.notifier)
            .request(CaptureAction.addExpense);
      },
    ),
    SearchHit(
      kind: SearchHitKind.command,
      title: 'New task',
      subtitle: 'Add a to-do in Notes > Tasks',
      badge: 'Command',
      searchText: 'new task add todo checklist notes',
      rankBoost: 28,
      onSelect: (BuildContext hostContext, WidgetRef ref) async {
        final ProviderContainer container = ProviderScope.containerOf(
          hostContext,
        );
        container.read(notesViewProvider.notifier).show(NotesView.tasks);
        GoRouter.maybeOf(hostContext)?.go('/notes?view=tasks');
        await showTaskEditor(hostContext, ref);
      },
    ),
    SearchHit(
      kind: SearchHitKind.command,
      title: 'New event',
      subtitle: 'Add to Calendar schedule',
      badge: 'Command',
      searchText: 'new event add class schedule calendar',
      rankBoost: 26,
      onSelect: (BuildContext hostContext, WidgetRef _) async {
        final ProviderContainer container = ProviderScope.containerOf(
          hostContext,
        );
        container
            .read(calendarViewProvider.notifier)
            .show(CalendarView.schedule);
        GoRouter.maybeOf(hostContext)?.go('/calendar');
        container
            .read(captureRequestProvider.notifier)
            .request(CaptureAction.addEvent);
      },
    ),
    SearchHit(
      kind: SearchHitKind.command,
      title: 'New note',
      subtitle: 'Write a note in Notes',
      badge: 'Command',
      searchText: 'new note add write lecture notes',
      rankBoost: 24,
      onSelect: (BuildContext hostContext, WidgetRef _) async {
        final ProviderContainer container = ProviderScope.containerOf(
          hostContext,
        );
        container.read(notesViewProvider.notifier).show(NotesView.notes);
        GoRouter.maybeOf(hostContext)?.go('/notes');
        container
            .read(captureRequestProvider.notifier)
            .request(CaptureAction.addNote);
      },
    ),
    SearchHit(
      kind: SearchHitKind.command,
      title: 'Start focus',
      subtitle: 'Open timer and start a focus session',
      badge: 'Command',
      searchText: 'start focus timer pomodoro study session',
      rankBoost: 22,
      onSelect: (BuildContext hostContext, WidgetRef _) async {
        final ProviderContainer container = ProviderScope.containerOf(
          hostContext,
        );
        container.read(calendarViewProvider.notifier).show(CalendarView.focus);
        GoRouter.maybeOf(hostContext)?.go('/calendar?view=focus');
        final FocusState focus = await container.read(
          focusControllerProvider.future,
        );
        if (focus.session != null) return;
        if (focus.settings.lockdown == Lockdown.strict) {
          final PhoneReadiness ready = await container
              .read(focusPlatformProvider)
              .readiness();
          if (!ready.accessibility) return;
        }
        await container.read(focusControllerProvider.notifier).start();
      },
    ),
    SearchHit(
      kind: SearchHitKind.command,
      title: 'Month in review',
      subtitle: 'Money, work, study and phone rest',
      badge: 'Command',
      searchText: 'month in review summary insights report',
      rankBoost: 20,
      onSelect: (BuildContext hostContext, WidgetRef _) async {
        final GoRouter? router = GoRouter.maybeOf(hostContext);
        if (router != null) {
          await router.push('/review');
        } else {
          await Navigator.of(hostContext, rootNavigator: true).push(
            MaterialPageRoute<void>(builder: (_) => const MonthReviewScreen()),
          );
        }
      },
    ),
    SearchHit(
      kind: SearchHitKind.command,
      title: 'Export CSV / summary',
      subtitle: 'Transactions, shifts, IOUs and review',
      badge: 'Command',
      searchText: 'export csv markdown summary transactions shifts ious',
      rankBoost: 18,
      onSelect: (BuildContext hostContext, WidgetRef _) async {
        final ProviderContainer container = ProviderScope.containerOf(
          hostContext,
        );
        await showExportSheet(
          hostContext,
          container,
          ScaffoldMessenger.of(hostContext),
        );
      },
    ),
    SearchHit(
      kind: SearchHitKind.command,
      title: 'Back up to a file',
      subtitle: 'Save a full JSON backup on this device',
      badge: 'Command',
      searchText: 'back up backup json export save data',
      rankBoost: 16,
      onSelect: (BuildContext hostContext, WidgetRef _) async {
        final ProviderContainer container = ProviderScope.containerOf(
          hostContext,
        );
        await runBackupExport(container, ScaffoldMessenger.of(hostContext));
      },
    ),
    SearchHit(
      kind: SearchHitKind.command,
      title: 'Add Today widget',
      subtitle: 'Next class, alarm and focus timer',
      badge: 'Command',
      searchText: 'add today widget calendar home screen pin',
      rankBoost: 14,
      onSelect: (BuildContext hostContext, WidgetRef _) async {
        await _pinHomeWidget(hostContext, 'calendar');
      },
    ),
    SearchHit(
      kind: SearchHitKind.command,
      title: 'Add Money widget',
      subtitle: 'Spent today and left this month',
      badge: 'Command',
      searchText: 'add money widget finance home screen pin',
      rankBoost: 12,
      onSelect: (BuildContext hostContext, WidgetRef _) async {
        await _pinHomeWidget(hostContext, 'finance');
      },
    ),
  ];
}

Future<void> _pinHomeWidget(BuildContext hostContext, String which) async {
  final ProviderContainer container = ProviderScope.containerOf(hostContext);
  final ScaffoldMessengerState messenger = ScaffoldMessenger.of(hostContext);
  final bool ok = await container.read(focusPlatformProvider).pinWidget(which);
  if (!ok) {
    messenger.showSnackBar(
      const SnackBar(
        content: Text(
          'Your launcher cannot add it from here. Long-press '
          'the home screen, tap Widgets and find StudentOS.',
        ),
      ),
    );
  }
}

/// Loads quick commands plus a parallel snapshot of all 9 local repositories.
Future<List<SearchHit>> loadGlobalSearchSnapshot(WidgetRef ref, {DateTime? now}) {
  return _loadSnapshot(
    calendarRepo: ref.read(calendarRepositoryProvider),
    workRepo: ref.read(workRepositoryProvider),
    tasksRepo: ref.read(tasksRepositoryProvider),
    notesRepo: ref.read(notesRepositoryProvider),
    financeRepo: ref.read(financeRepositoryProvider),
    billsRepo: ref.read(billsRepositoryProvider),
    goalsRepo: ref.read(goalsRepositoryProvider),
    iousRepo: ref.read(iousRepositoryProvider),
    focusRepo: ref.read(focusRepositoryProvider),
    now: now,
  );
}

/// Container-based variant of [loadGlobalSearchSnapshot] for tests and callers
/// without a [WidgetRef].
Future<List<SearchHit>> loadGlobalSearchSnapshotFromContainer(
  ProviderContainer container, {
  DateTime? now,
}) {
  return _loadSnapshot(
    calendarRepo: container.read(calendarRepositoryProvider),
    workRepo: container.read(workRepositoryProvider),
    tasksRepo: container.read(tasksRepositoryProvider),
    notesRepo: container.read(notesRepositoryProvider),
    financeRepo: container.read(financeRepositoryProvider),
    billsRepo: container.read(billsRepositoryProvider),
    goalsRepo: container.read(goalsRepositoryProvider),
    iousRepo: container.read(iousRepositoryProvider),
    focusRepo: container.read(focusRepositoryProvider),
    now: now,
  );
}

Future<List<SearchHit>> _loadSnapshot({
  required CalendarRepository calendarRepo,
  required WorkRepository workRepo,
  required TaskRepository tasksRepo,
  required NotesRepository notesRepo,
  required FinanceRepository financeRepo,
  required BillsRepository billsRepo,
  required GoalsRepository goalsRepo,
  required IousRepository iousRepo,
  required FocusRepository focusRepo,
  DateTime? now,
}) async {
  final DateTime current = now ?? DateTime.now();
  final DateTime todayStart = DateTime(current.year, current.month, current.day);

  final (
    List<CalendarEvent> events,
    List<Shift> shifts,
    List<TaskItem> tasks,
    List<Note> notes,
    List<Transaction> transactions,
    List<Bill> bills,
    List<SavingsGoal> goals,
    List<IouItem> ious,
    List<Alarm> alarms,
  ) = await (
    calendarRepo.getEvents(),
    workRepo.getShifts(),
    tasksRepo.getTasks(),
    notesRepo.getNotes(),
    financeRepo.getTransactions(),
    billsRepo.getBills(),
    goalsRepo.getGoals(),
    iousRepo.getIous(),
    focusRepo.getAlarms(),
  ).wait;

  return <SearchHit>[
    ...buildQuickCommands(),
    for (final CalendarEvent event in events)
      _eventHit(event, todayStart),
    for (final Shift shift in shifts) _shiftHit(shift),
    for (final TaskItem task in tasks) _taskHit(task, current),
    for (final Note note in notes) _noteHit(note),
    for (final Transaction tx in transactions) _transactionHit(tx),
    for (final Bill bill in bills) _billHit(bill, current),
    for (final SavingsGoal goal in goals) _goalHit(goal),
    for (final IouItem iou in ious) _iouHit(iou),
    for (final Alarm alarm in alarms) _alarmHit(alarm),
  ];
}

SearchHit _eventHit(CalendarEvent event, DateTime todayStart) {
  final DateTime target = (event.nextOccurrence(todayStart) ?? event.startsAt)
      .toLocal();
  final String whenText = event.isAllDay
      ? '${DateFormat('MMM d').format(target)} · All day'
      : DateFormat('MMM d · h:mm a').format(target);
  final String location = event.location?.trim() ?? '';
  final String subtitle = location.isEmpty ? whenText : '$whenText · $location';
  final String typeTerms = <String>[
    if (event.isExam) 'exam',
    if (event.isAssignment) 'assignment',
    if (event.recurrence != 'none') event.recurrence,
  ].join(' ');

  return SearchHit(
    kind: SearchHitKind.event,
    title: event.title,
    subtitle: subtitle,
    badge: 'Event',
    searchText:
        'calendar event $typeTerms ${event.location ?? ''} ${event.notes ?? ''} '
        '${DateFormat('yyyy-MM-dd MMMM').format(target)}',
    rankBoost: event.done ? -5 : 8,
    onSelect: (BuildContext hostContext, WidgetRef _) async {
      final ProviderContainer container = ProviderScope.containerOf(
        hostContext,
      );
      container.read(calendarViewProvider.notifier).show(CalendarView.schedule);
      container.read(calendarShowDayProvider.notifier).show(target);
      GoRouter.maybeOf(hostContext)?.go('/calendar');
    },
  );
}

SearchHit _shiftHit(Shift shift) {
  final DateTime start = shift.startsAt.toLocal();
  final String subtitle =
      '${DateFormat('MMM d · h:mm a').format(start)} · '
      '${formatHours(shift.paidMinutes)} h${shift.paid ? ' · Paid' : ''}';
  return SearchHit(
    kind: SearchHitKind.shift,
    title: shift.job,
    subtitle: subtitle,
    badge: 'Shift',
    searchText:
        'work shift ${shift.job} ${shift.paid ? 'paid' : 'unpaid'} '
        '${DateFormat('yyyy-MM-dd MMMM').format(start)}',
    rankBoost: 4,
    onSelect: (BuildContext hostContext, WidgetRef _) async {
      final ProviderContainer container = ProviderScope.containerOf(
        hostContext,
      );
      container.read(calendarViewProvider.notifier).show(CalendarView.schedule);
      container.read(calendarShowDayProvider.notifier).show(start);
      GoRouter.maybeOf(hostContext)?.go('/calendar');
    },
  );
}

SearchHit _taskHit(TaskItem task, DateTime now) {
  final String dueLabel = taskDueLabel(task, now);
  final String notes = task.notes?.trim() ?? '';
  final List<String> parts = <String>[
    if (task.done) 'Done',
    if (dueLabel.isNotEmpty) dueLabel,
    if (task.isRepeating) TaskRepeat.label(task.repeat),
    if (notes.isNotEmpty) notes,
  ];
  return SearchHit(
    kind: SearchHitKind.task,
    title: task.title,
    subtitle: parts.isEmpty ? 'Open task' : parts.join(' · '),
    badge: 'Task',
    searchText:
        'task todo ${task.notes ?? ''} ${task.dueOn ?? ''} '
        '${task.done ? 'done completed' : 'open'}',
    rankBoost: task.done ? -5 : 10,
    onSelect: (BuildContext hostContext, WidgetRef _) async {
      final ProviderContainer container = ProviderScope.containerOf(
        hostContext,
      );
      container.read(notesViewProvider.notifier).show(NotesView.tasks);
      GoRouter.maybeOf(hostContext)?.go('/notes?view=tasks');
    },
  );
}

SearchHit _noteHit(Note note) {
  final String firstBodyLine = note.body
      .split('\n')
      .map((String line) => line.trim())
      .firstWhere((String line) => line.isNotEmpty, orElse: () => '');
  final String tagLine = note.tags.map((String t) => '#$t').join(' ');
  final List<String> parts = <String>[
    if (tagLine.isNotEmpty) tagLine,
    if (firstBodyLine.isNotEmpty) firstBodyLine,
  ];
  return SearchHit(
    kind: SearchHitKind.note,
    title: note.title,
    subtitle: parts.isEmpty ? 'Note' : parts.join(' · '),
    badge: 'Note',
    searchText: 'note ${note.body} $tagLine ${note.pinned ? 'pinned' : ''}',
    rankBoost: note.pinned ? 8 : 5,
    onSelect: (BuildContext hostContext, WidgetRef ref) async {
      final ProviderContainer container = ProviderScope.containerOf(
        hostContext,
      );
      container.read(notesViewProvider.notifier).show(NotesView.notes);
      GoRouter.maybeOf(hostContext)?.go('/notes');
      await showNoteEditor(hostContext, ref, note);
    },
  );
}

SearchHit _transactionHit(Transaction tx) {
  final String note = tx.note?.trim() ?? '';
  final String title = note.isEmpty ? tx.category : '${tx.category} · $note';
  final String sign = tx.type == 'income' ? '+' : '-';
  final String subtitle =
      '$sign${_pesoText(tx.amount)} · ${DateFormat('MMM d, yyyy').format(tx.occurredOn)}';
  final String monthKey = DateFormat('yyyy-MM').format(tx.occurredOn);

  return SearchHit(
    kind: SearchHitKind.transaction,
    title: title,
    subtitle: subtitle,
    badge: tx.type == 'income' ? 'Income' : 'Expense',
    searchText:
        'transaction finance cashflow ${tx.type} ${tx.category} $note '
        '${tx.amount} $monthKey ${DateFormat('MMMM').format(tx.occurredOn)}',
    rankBoost: 3,
    onSelect: (BuildContext hostContext, WidgetRef _) async {
      final ProviderContainer container = ProviderScope.containerOf(
        hostContext,
      );
      container.read(financeViewProvider.notifier).show(FinanceView.cashflow);
      container.read(financeFilterProvider.notifier).clearAll();
      GoRouter.maybeOf(hostContext)?.go('/finance');
      await container.read(financeControllerProvider.notifier).setMonth(
        monthKey,
      );
    },
  );
}

SearchHit _billHit(Bill bill, DateTime now) {
  final String due = billDuePhrase(bill, now);
  final List<String> parts = <String>[
    _pesoText(bill.amount),
    bill.category,
    if (due.isNotEmpty) due,
    if (!bill.active) 'Paused',
  ];
  final String thisMonth = DateFormat('yyyy-MM').format(now);
  return SearchHit(
    kind: SearchHitKind.bill,
    title: bill.title,
    subtitle: parts.join(' · '),
    badge: 'Bill',
    searchText:
        'bill recurring finance ${bill.category} ${bill.cadence} '
        '${bill.active ? 'active' : 'paused'}',
    rankBoost: 4,
    onSelect: (BuildContext hostContext, WidgetRef _) async {
      final ProviderContainer container = ProviderScope.containerOf(
        hostContext,
      );
      container.read(financeViewProvider.notifier).show(FinanceView.cashflow);
      container.read(financeFilterProvider.notifier).clearAll();
      GoRouter.maybeOf(hostContext)?.go('/finance');
      await container.read(financeControllerProvider.notifier).setMonth(
        thisMonth,
      );
    },
  );
}

SearchHit _goalHit(SavingsGoal goal) {
  return SearchHit(
    kind: SearchHitKind.goal,
    title: goal.title,
    subtitle:
        '${_pesoText(goal.savedAmount)} / ${_pesoText(goal.targetAmount)} (${goal.percentLabel})',
    badge: 'Goal',
    searchText: 'goal savings finance ${goal.targetDate ?? ''}',
    rankBoost: goal.isReached ? -2 : 5,
    onSelect: (BuildContext hostContext, WidgetRef _) async {
      final ProviderContainer container = ProviderScope.containerOf(
        hostContext,
      );
      container.read(financeViewProvider.notifier).show(FinanceView.goals);
      GoRouter.maybeOf(hostContext)?.go('/finance?view=goals');
    },
  );
}

SearchHit _iouHit(IouItem iou) {
  final String note = iou.note?.trim() ?? '';
  final List<String> parts = <String>[
    _pesoText(iou.amount),
    iou.settled ? 'Settled' : 'Open',
    if (note.isNotEmpty) note,
  ];
  return SearchHit(
    kind: SearchHitKind.iou,
    title: '${iou.person} · ${iou.direction.label}',
    subtitle: parts.join(' · '),
    badge: 'IOU',
    searchText:
        'iou split finance ${iou.person} ${iou.direction.label} $note '
        '${iou.settled ? 'settled' : 'open'}',
    rankBoost: iou.settled ? -2 : 6,
    onSelect: (BuildContext hostContext, WidgetRef _) async {
      final ProviderContainer container = ProviderScope.containerOf(
        hostContext,
      );
      container.read(financeViewProvider.notifier).show(FinanceView.ious);
      GoRouter.maybeOf(hostContext)?.go('/finance?view=ious');
    },
  );
}

SearchHit _alarmHit(Alarm alarm) {
  final String time = _alarmTimeText(alarm);
  final String label = alarm.label.trim();
  return SearchHit(
    kind: SearchHitKind.alarm,
    title: label.isEmpty ? time : '$time · $label',
    subtitle:
        '${alarm.daysLabel} · ${alarm.enabled ? 'On' : 'Off'} · ${alarm.challengeSummary}',
    badge: 'Alarm',
    searchText:
        'alarm wake clock calendar $time $label ${alarm.daysLabel} '
        '${alarm.enabled ? 'on enabled' : 'off disabled'}',
    rankBoost: alarm.enabled ? 5 : -3,
    onSelect: (BuildContext hostContext, WidgetRef _) async {
      final ProviderContainer container = ProviderScope.containerOf(
        hostContext,
      );
      container.read(calendarViewProvider.notifier).show(CalendarView.alarm);
      GoRouter.maybeOf(hostContext)?.go('/calendar?view=alarm');
    },
  );
}

bool _matchesGroup(SearchHitKind kind, String? groupFilter) {
  return switch (groupFilter) {
    null || 'All' => true,
    'Commands' => kind == SearchHitKind.command,
    'Calendar' =>
      kind == SearchHitKind.event ||
          kind == SearchHitKind.shift ||
          kind == SearchHitKind.alarm,
    'Finance' =>
      kind == SearchHitKind.transaction ||
          kind == SearchHitKind.bill ||
          kind == SearchHitKind.goal ||
          kind == SearchHitKind.iou,
    'Notes' => kind == SearchHitKind.note || kind == SearchHitKind.task,
    _ => true,
  };
}

/// Filters and ranks [all] against whitespace-separated [query] tokens,
/// optional [filterKind], and optional [groupFilter] (`All`, `Commands`,
/// `Calendar`, `Finance`, `Notes`).
List<SearchHit> filterAndRankHits(
  List<SearchHit> all,
  String query, {
  SearchHitKind? filterKind,
  String? groupFilter,
}) {
  final String trimmed = query.trim().toLowerCase();
  final List<SearchHit> scoped = <SearchHit>[
    for (final SearchHit hit in all)
      if ((filterKind == null || hit.kind == filterKind) &&
          _matchesGroup(hit.kind, groupFilter))
        hit,
  ];

  if (trimmed.isEmpty) {
    if (filterKind == null && (groupFilter == null || groupFilter == 'All')) {
      return <SearchHit>[
        for (final SearchHit hit in scoped)
          if (hit.kind == SearchHitKind.command) hit,
      ];
    }
    return scoped;
  }

  final List<String> terms = trimmed.split(RegExp(r'\s+'));
  final List<({SearchHit hit, int score, int index})> matched =
      <({SearchHit hit, int score, int index})>[];

  for (int i = 0; i < scoped.length; i++) {
    final SearchHit hit = scoped[i];
    final String haystack =
        '${hit.title} ${hit.subtitle} ${hit.badge} ${hit.searchText}'
            .toLowerCase();
    bool matchesAll = true;
    for (final String term in terms) {
      if (!haystack.contains(term)) {
        matchesAll = false;
        break;
      }
    }
    if (!matchesAll) continue;

    final String titleLower = hit.title.toLowerCase();
    int score = hit.rankBoost;
    if (hit.kind == SearchHitKind.command) score += 30;
    if (titleLower == trimmed) {
      score += 1000;
    } else if (titleLower.startsWith(trimmed)) {
      score += 500;
    } else if (titleLower.contains(trimmed)) {
      score += 180;
    }
    for (final String term in terms) {
      if (titleLower.startsWith(term)) {
        score += 60;
      } else if (titleLower.contains(term)) {
        score += 35;
      }
    }
    matched.add((hit: hit, score: score, index: i));
  }

  matched.sort((a, b) {
    final int byScore = b.score.compareTo(a.score);
    return byScore != 0 ? byScore : a.index.compareTo(b.index);
  });

  return <SearchHit>[for (final entry in matched) entry.hit];
}
