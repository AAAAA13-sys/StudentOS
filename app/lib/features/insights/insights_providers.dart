import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../calendar/calendar_controller.dart';
import '../finance/bill.dart';
import '../finance/bills_controller.dart';
import '../finance/finance_controller.dart';
import '../finance/finance_repository.dart';
import '../finance/goals_controller.dart';
import '../finance/savings_goal.dart';
import '../finance/transaction.dart';
import '../notes/note.dart';
import '../notes/notes_controller.dart';
import '../tasks/task_item.dart';
import '../tasks/tasks_controller.dart';
import '../work/payday.dart';
import '../work/shift.dart';
import '../work/work_controller.dart';
import 'calendar_insights.dart';
import 'finance_insights.dart';
import 'notes_insights.dart';
import 'ponpon_insight.dart';

/// Where a talk bubble can sit.
enum PonponSurface { calendar, finance, notes }

/// The clock the insights read; tests override it.
final Provider<DateTime Function()> ponponClockProvider =
    Provider<DateTime Function()>((Ref ref) => DateTime.now);

/// How often tips that depend on the clock are recomputed while on screen.
const Duration ponponRefreshEvery = Duration(seconds: 30);

/// Ticks every [ponponRefreshEvery] while some tip is on screen, and stops
/// when none is (auto-disposed with the insight providers).
final StreamProvider<int> ponponTickProvider = StreamProvider.autoDispose<int>(
  (Ref ref) => Stream<int>.periodic(ponponRefreshEvery, (int i) => i + 1),
);

/// The surfaces whose bubble was closed. In memory only: it comes back on the
/// next app start.
class PonponDismissals extends Notifier<Set<PonponSurface>> {
  @override
  Set<PonponSurface> build() => const <PonponSurface>{};

  void dismiss(PonponSurface surface) =>
      state = <PonponSurface>{...state, surface};
}

final NotifierProvider<PonponDismissals, Set<PonponSurface>>
ponponDismissalsProvider =
    NotifierProvider<PonponDismissals, Set<PonponSurface>>(
      PonponDismissals.new,
    );

final Provider<List<PonponInsight>> calendarInsightsProvider =
    Provider.autoDispose<List<PonponInsight>>((Ref ref) {
      ref.watch(ponponTickProvider);
      return calendarInsights(
        events: ref.watch(calendarControllerProvider).value ?? const [],
        shifts: ref.watch(workControllerProvider).value ?? const [],
        tasks: ref.watch(tasksControllerProvider).value ?? const <TaskItem>[],
        now: ref.read(ponponClockProvider)(),
      );
    });

/// Only while the month on show is the current one.
final FutureProvider<List<PonponInsight>> financeInsightsProvider =
    FutureProvider.autoDispose<List<PonponInsight>>((Ref ref) async {
      ref.watch(ponponTickProvider);
      final FinanceState state = await ref.watch(
        financeControllerProvider.future,
      );
      final DateTime now = ref.read(ponponClockProvider)();
      final DateFormat month = DateFormat('yyyy-MM');
      if (state.month != month.format(now)) return const <PonponInsight>[];
      final List<Transaction> last = await ref
          .read(financeRepositoryProvider)
          .getTransactions(
            month: month.format(DateTime(now.year, now.month - 1)),
          );
      final List<Shift> shifts =
          ref.watch(workControllerProvider).value ?? const <Shift>[];
      final List<Bill> bills =
          ref.watch(billsControllerProvider).value ?? const <Bill>[];
      final List<SavingsGoal> goals =
          ref.watch(goalsControllerProvider).value ?? const <SavingsGoal>[];
      return financeInsights(
        thisMonth: state.transactions,
        lastMonth: last,
        now: now,
        payday: ref.watch(paydayProvider),
        waitingPayCents: WorkSummary.of(shifts, now).workedPayCents,
        bills: bills,
        goals: goals,
      );
    });

/// Silent while a search or tag filter narrows the Notes list.
final Provider<List<PonponInsight>> notesInsightsProvider =
    Provider.autoDispose<List<PonponInsight>>((Ref ref) {
      ref.watch(ponponTickProvider);
      final NotesView view = ref.watch(notesViewProvider);
      final NotesState? state = ref.watch(notesControllerProvider).value;
      final List<TaskItem> tasks =
          ref.watch(tasksControllerProvider).value ?? const <TaskItem>[];
      if (view == NotesView.notes &&
          (state == null ||
              state.searchQuery.isNotEmpty ||
              state.selectedTag != null)) {
        return const <PonponInsight>[];
      }
      return notesInsights(
        notes: state?.notes ?? const <Note>[],
        events: ref.watch(calendarControllerProvider).value ?? const [],
        tasks: tasks,
        now: ref.read(ponponClockProvider)(),
      );
    });
