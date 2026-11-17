import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../calendar/calendar_controller.dart';
import '../finance/finance_controller.dart';
import '../finance/finance_repository.dart';
import '../finance/transaction.dart';
import '../notes/notes_controller.dart';
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
    Provider<List<PonponInsight>>((Ref ref) {
      return calendarInsights(
        events: ref.watch(calendarControllerProvider).value ?? const [],
        shifts: ref.watch(workControllerProvider).value ?? const [],
        now: ref.read(ponponClockProvider)(),
      );
    });

/// Only while the month on show is the current one.
final FutureProvider<List<PonponInsight>>
financeInsightsProvider = FutureProvider<List<PonponInsight>>((Ref ref) async {
  final FinanceState state = await ref.watch(financeControllerProvider.future);
  final DateTime now = ref.read(ponponClockProvider)();
  final DateFormat month = DateFormat('yyyy-MM');
  if (state.month != month.format(now)) return const <PonponInsight>[];
  final List<Transaction> last = await ref
      .read(financeRepositoryProvider)
      .getTransactions(month: month.format(DateTime(now.year, now.month - 1)));
  return financeInsights(
    thisMonth: state.transactions,
    lastMonth: last,
    now: now,
  );
});

/// Silent while a search or tag filter narrows the list.
final Provider<List<PonponInsight>> notesInsightsProvider =
    Provider<List<PonponInsight>>((Ref ref) {
      final NotesState? state = ref.watch(notesControllerProvider).value;
      if (state == null ||
          state.searchQuery.isNotEmpty ||
          state.selectedTag != null) {
        return const <PonponInsight>[];
      }
      return notesInsights(
        notes: state.notes,
        events: ref.watch(calendarControllerProvider).value ?? const [],
        now: ref.read(ponponClockProvider)(),
      );
    });
