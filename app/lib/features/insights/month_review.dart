import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../finance/goals_repository.dart';
import '../finance/iou_item.dart';
import '../finance/ious_repository.dart';
import '../finance/finance_repository.dart';
import '../finance/savings_goal.dart';
import '../finance/transaction.dart';
import '../focus/focus_plan.dart';
import '../focus/focus_repository.dart';
import '../notes/recall_item.dart';
import '../notes/recall_repository.dart';
import '../phone/phone_day.dart';
import '../phone/phone_repository.dart';
import '../phone/phone_usage.dart';
import '../tasks/task_item.dart';
import '../tasks/tasks_repository.dart';
import '../work/shift.dart';
import '../work/work_repository.dart';

/// Expense total and transaction count for one category inside a [MonthReview].
class MonthExpenseCategory {
  const MonthExpenseCategory({
    required this.category,
    required this.cents,
    required this.count,
  });

  final String category;
  final int cents;
  final int count;
}

/// Focus time and session count for one study target inside a [MonthReview].
class MonthStudyTarget {
  const MonthStudyTarget({
    required this.label,
    required this.focusMs,
    required this.sessions,
  });

  final String label;
  final int focusMs;
  final int sessions;
}

/// Pure, immutable summary of one calendar month (`YYYY-MM`) across Money,
/// Work & Study, and Phone Rest & Screen Time.
class MonthReview {
  const MonthReview({
    required this.month,
    required this.incomeCents,
    required this.expenseCents,
    required this.transactionCount,
    required this.topExpenseCategories,
    required this.goalsSavedCents,
    required this.goalsCount,
    required this.goalsReachedCount,
    required this.openOwedCents,
    required this.openOwingCents,
    required this.openIousCount,
    required this.settledInMonthCount,
    required this.settledOwedInMonthCents,
    required this.settledOwingInMonthCents,
    required this.shiftCount,
    required this.paidShiftCount,
    required this.paidShiftMinutes,
    required this.paidShiftPayCents,
    required this.unpaidShiftCount,
    required this.unpaidShiftMinutes,
    required this.unpaidShiftPayCents,
    required this.focusMs,
    required this.focusSessions,
    required this.completedFocusSessions,
    required this.focusRounds,
    required this.topStudyTargets,
    required this.tasksCompletedCount,
    required this.recallReviewedCount,
    required this.hasPhoneAccess,
    required this.daysWithPhone,
    required this.avgScreenOnMs,
    required this.avgRestDuration,
    required this.daysWithRest,
  });

  final String month;

  // Money
  final int incomeCents;
  final int expenseCents;
  int get netCents => incomeCents - expenseCents;
  final int transactionCount;
  final List<MonthExpenseCategory> topExpenseCategories;
  final int goalsSavedCents;
  final int goalsCount;
  final int goalsReachedCount;
  final int openOwedCents;
  final int openOwingCents;
  final int openIousCount;
  final int settledInMonthCount;
  final int settledOwedInMonthCents;
  final int settledOwingInMonthCents;
  int get settledInMonthCents =>
      settledOwedInMonthCents + settledOwingInMonthCents;

  // Work & Study
  final int shiftCount;
  final int paidShiftCount;
  final int paidShiftMinutes;
  final int paidShiftPayCents;
  final int unpaidShiftCount;
  final int unpaidShiftMinutes;
  final int unpaidShiftPayCents;
  int get totalShiftMinutes => paidShiftMinutes + unpaidShiftMinutes;
  int get totalShiftPayCents => paidShiftPayCents + unpaidShiftPayCents;

  final int focusMs;
  final int focusSessions;
  final int completedFocusSessions;
  final int focusRounds;
  final List<MonthStudyTarget> topStudyTargets;
  final int tasksCompletedCount;
  final int recallReviewedCount;

  // Phone Rest & Screen Time
  final bool hasPhoneAccess;
  final int daysWithPhone;
  final int? avgScreenOnMs;
  final Duration? avgRestDuration;
  final int daysWithRest;

  bool get isEmpty =>
      transactionCount == 0 &&
      shiftCount == 0 &&
      focusSessions == 0 &&
      tasksCompletedCount == 0 &&
      recallReviewedCount == 0 &&
      daysWithPhone == 0;
}

/// Parses `YYYY-MM` into `(start, end)` local midnight bounds `[start, end)`.
(DateTime, DateTime) monthDateRange(String month) {
  final RegExpMatch? match = RegExp(
    r'^(\d{4})-(\d{2})$',
  ).firstMatch(month.trim());
  final DateTime now = DateTime.now();
  final int year = match != null ? int.parse(match.group(1)!) : now.year;
  final int monthNum = match != null
      ? int.parse(match.group(2)!).clamp(1, 12)
      : now.month;
  final DateTime start = DateTime(year, monthNum, 1);
  final DateTime end = DateTime(year, monthNum + 1, 1);
  return (start, end);
}

/// Pure aggregator computing a [MonthReview] for [month] (`YYYY-MM`).
MonthReview buildMonthReview({
  required String month,
  required List<Transaction> transactions,
  required List<SavingsGoal> goals,
  required List<IouItem> ious,
  required List<Shift> shifts,
  required List<FocusLog> focusLogs,
  required List<TaskItem> tasks,
  required List<RecallReview> recallReviews,
  required List<PhoneDay> phoneDays,
  required bool hasPhoneAccess,
}) {
  final (DateTime start, DateTime end) = monthDateRange(month);
  bool inMonth(DateTime dt) => !dt.isBefore(start) && dt.isBefore(end);

  // 1. Money: cashflow transactions in centavos.
  int incomeCents = 0;
  int expenseCents = 0;
  int txCount = 0;
  final Map<String, ({int cents, int count})> expenseGroups =
      <String, ({int cents, int count})>{};
  for (final Transaction tx in transactions) {
    if (!inMonth(tx.occurredOn)) continue;
    txCount++;
    final int cents = (tx.amount * 100).round();
    if (tx.type == 'income') {
      incomeCents += cents;
    } else {
      expenseCents += cents;
      final ({int cents, int count})? prev = expenseGroups[tx.category];
      expenseGroups[tx.category] = (
        cents: (prev?.cents ?? 0) + cents,
        count: (prev?.count ?? 0) + 1,
      );
    }
  }
  final List<MonthExpenseCategory> topExpenseCategories =
      <MonthExpenseCategory>[
        for (final MapEntry<String, ({int cents, int count})> e
            in expenseGroups.entries)
          MonthExpenseCategory(
            category: e.key,
            cents: e.value.cents,
            count: e.value.count,
          ),
      ]..sort((MonthExpenseCategory a, MonthExpenseCategory b) {
        final int byCents = b.cents.compareTo(a.cents);
        return byCents != 0 ? byCents : a.category.compareTo(b.category);
      });

  // Savings pockets snapshot.
  int goalsSavedCents = 0;
  int goalsReachedCount = 0;
  for (final SavingsGoal goal in goals) {
    goalsSavedCents += goal.savedCents;
    if (goal.isReached) goalsReachedCount++;
  }

  // IOUs: open snapshot + settled inside [month].
  int openOwedCents = 0;
  int openOwingCents = 0;
  int openIousCount = 0;
  int settledInMonthCount = 0;
  int settledOwedInMonthCents = 0;
  int settledOwingInMonthCents = 0;
  for (final IouItem iou in ious) {
    if (!iou.settled) {
      openIousCount++;
      if (iou.direction == IouDirection.owed) {
        openOwedCents += iou.amountCents;
      } else {
        openOwingCents += iou.amountCents;
      }
    } else if (iou.settledAt != null && inMonth(iou.settledAt!)) {
      settledInMonthCount++;
      if (iou.direction == IouDirection.owed) {
        settledOwedInMonthCents += iou.amountCents;
      } else {
        settledOwingInMonthCents += iou.amountCents;
      }
    }
  }

  // 2. Work & Study.
  int shiftCount = 0;
  int paidShiftCount = 0;
  int paidShiftMinutes = 0;
  int paidShiftPayCents = 0;
  int unpaidShiftCount = 0;
  int unpaidShiftMinutes = 0;
  int unpaidShiftPayCents = 0;
  for (final Shift shift in shifts) {
    if (!inMonth(shift.startsAt)) continue;
    shiftCount++;
    if (shift.paid) {
      paidShiftCount++;
      paidShiftMinutes += shift.paidMinutes;
      paidShiftPayCents += shift.payCents;
    } else {
      unpaidShiftCount++;
      unpaidShiftMinutes += shift.paidMinutes;
      unpaidShiftPayCents += shift.payCents;
    }
  }

  int focusMs = 0;
  int focusSessions = 0;
  int completedFocusSessions = 0;
  int focusRounds = 0;
  final Map<String, ({int focusMs, int sessions})> targetGroups =
      <String, ({int focusMs, int sessions})>{};
  for (final FocusLog log in focusLogs) {
    if (!inMonth(log.endedAt)) continue;
    focusSessions++;
    if (!log.endedEarly) completedFocusSessions++;
    focusMs += log.focusMs;
    focusRounds += log.rounds;
    final String? label = log.intention?.label.trim();
    if (label != null && label.isNotEmpty) {
      final ({int focusMs, int sessions})? prev = targetGroups[label];
      targetGroups[label] = (
        focusMs: (prev?.focusMs ?? 0) + log.focusMs,
        sessions: (prev?.sessions ?? 0) + 1,
      );
    }
  }
  final List<MonthStudyTarget> topStudyTargets = <MonthStudyTarget>[
    for (final MapEntry<String, ({int focusMs, int sessions})> e
        in targetGroups.entries)
      MonthStudyTarget(
        label: e.key,
        focusMs: e.value.focusMs,
        sessions: e.value.sessions,
      ),
  ]..sort((MonthStudyTarget a, MonthStudyTarget b) {
    final int byMs = b.focusMs.compareTo(a.focusMs);
    return byMs != 0 ? byMs : a.label.compareTo(b.label);
  });

  int tasksCompletedCount = 0;
  for (final TaskItem task in tasks) {
    if (task.done && task.doneAt != null && inMonth(task.doneAt!)) {
      tasksCompletedCount++;
    }
  }

  int recallReviewedCount = 0;
  for (final RecallReview review in recallReviews) {
    if (review.lastReviewedAt != null && inMonth(review.lastReviewedAt!)) {
      recallReviewedCount++;
    }
  }

  // 3. Phone Rest & Screen Time.
  int daysWithPhone = 0;
  int totalScreenOnMs = 0;
  int daysWithRest = 0;
  int totalRestMs = 0;
  for (final PhoneDay day in phoneDays) {
    if (!inMonth(day.date)) continue;
    daysWithPhone++;
    totalScreenOnMs += day.screenOnMs;
    final Duration? rest = day.rest;
    if (rest != null) {
      daysWithRest++;
      totalRestMs += rest.inMilliseconds;
    }
  }

  return MonthReview(
    month: month,
    incomeCents: incomeCents,
    expenseCents: expenseCents,
    transactionCount: txCount,
    topExpenseCategories: topExpenseCategories,
    goalsSavedCents: goalsSavedCents,
    goalsCount: goals.length,
    goalsReachedCount: goalsReachedCount,
    openOwedCents: openOwedCents,
    openOwingCents: openOwingCents,
    openIousCount: openIousCount,
    settledInMonthCount: settledInMonthCount,
    settledOwedInMonthCents: settledOwedInMonthCents,
    settledOwingInMonthCents: settledOwingInMonthCents,
    shiftCount: shiftCount,
    paidShiftCount: paidShiftCount,
    paidShiftMinutes: paidShiftMinutes,
    paidShiftPayCents: paidShiftPayCents,
    unpaidShiftCount: unpaidShiftCount,
    unpaidShiftMinutes: unpaidShiftMinutes,
    unpaidShiftPayCents: unpaidShiftPayCents,
    focusMs: focusMs,
    focusSessions: focusSessions,
    completedFocusSessions: completedFocusSessions,
    focusRounds: focusRounds,
    topStudyTargets: topStudyTargets,
    tasksCompletedCount: tasksCompletedCount,
    recallReviewedCount: recallReviewedCount,
    hasPhoneAccess: hasPhoneAccess,
    daysWithPhone: daysWithPhone,
    avgScreenOnMs: daysWithPhone == 0 ? null : totalScreenOnMs ~/ daysWithPhone,
    avgRestDuration: daysWithRest == 0
        ? null
        : Duration(milliseconds: totalRestMs ~/ daysWithRest),
    daysWithRest: daysWithRest,
  );
}

final monthlyReviewProvider =
    FutureProvider.autoDispose.family<MonthReview, String>((
      Ref ref,
      String month,
    ) async {
      final (DateTime start, DateTime end) = monthDateRange(month);
      final List<Transaction> transactions = await ref
          .watch(financeRepositoryProvider)
          .getTransactions(month: month);
      final List<SavingsGoal> goals = await ref
          .watch(goalsRepositoryProvider)
          .getGoals();
      final List<IouItem> ious = await ref
          .watch(iousRepositoryProvider)
          .getIous();
      final List<Shift> shifts = await ref
          .watch(workRepositoryProvider)
          .getShifts();
      final List<FocusLog> focusLogs = await ref
          .watch(focusRepositoryProvider)
          .getLogsInRange(start, end);
      final List<TaskItem> tasks = await ref
          .watch(tasksRepositoryProvider)
          .getTasks();
      final List<RecallReview> recallReviews = await ref
          .watch(recallRepositoryProvider)
          .getReviews();
      final List<PhoneDay> phoneDays = await ref
          .watch(phoneRepositoryProvider)
          .getDaysInMonth(month);

      bool hasPhoneAccess = false;
      try {
        hasPhoneAccess = await ref.watch(phoneUsageSourceProvider).hasAccess();
      } catch (_) {
        hasPhoneAccess = false;
      }

      return buildMonthReview(
        month: month,
        transactions: transactions,
        goals: goals,
        ious: ious,
        shifts: shifts,
        focusLogs: focusLogs,
        tasks: tasks,
        recallReviews: recallReviews,
        phoneDays: phoneDays,
        hasPhoneAccess: hasPhoneAccess,
      );
    });
