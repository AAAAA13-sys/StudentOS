import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';
import 'package:intl/intl.dart';

import 'finance_repository.dart';
import 'safe_to_spend.dart';
import 'transaction.dart';

class FinanceState {
  const FinanceState({
    required this.month,
    required this.transactions,
    required this.summary,
    required this.categories,
    this.safeToSpend,
  });

  final String month;
  final List<Transaction> transactions;
  final FinanceSummary summary;
  final List<String> categories;

  /// Today's spending room; set only while the current month is shown.
  final SafeToSpend? safeToSpend;
}

class FinanceController extends AsyncNotifier<FinanceState> {
  FinanceRepository get _repo => ref.read(financeRepositoryProvider);

  @override
  FutureOr<FinanceState> build() async {
    final String month = DateFormat('yyyy-MM').format(DateTime.now());
    return _loadMonth(month);
  }

  Future<FinanceState> _loadMonth(String month) async {
    final List<Transaction> transactions =
        await _repo.getTransactions(month: month);
    final FinanceSummary summary = await _repo.getSummary(month: month);
    final DateTime today = DateTime.now();
    final SafeToSpend? safeToSpend =
        month == DateFormat('yyyy-MM').format(today)
        ? await _repo.getSafeToSpend(today)
        : null;
    if (safeToSpend != null) {
      unawaited(_syncWidget(safeToSpend));
    }

    return FinanceState(
      month: month,
      transactions: transactions,
      summary: summary,
      categories: FinanceRepository.categories,
      safeToSpend: safeToSpend,
    );
  }

  /// Shows today's spending room on the home-screen widget. It is only
  /// refreshed when the app runs, so it can be a day old.
  Future<void> _syncWidget(SafeToSpend value) async {
    try {
      await HomeWidget.saveWidgetData<String>(
        'safe_spend',
        value.hasFunds
            ? '₱${NumberFormat('#,##0').format(value.leftToday)} safe to spend today'
            : '',
      );
      await HomeWidget.updateWidget(
        name: 'CalendarWidgetProvider',
        androidName: 'CalendarWidgetProvider',
      );
    } catch (_) {
      // Best-effort: the widget may not be placed, or the platform is absent.
    }
  }

  Future<void> setMonth(String month) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _loadMonth(month));
  }

  Future<void> addTransaction(Transaction tx) async {
    await _repo.createTransaction(tx);
    final String month = state.value?.month ?? DateFormat('yyyy-MM').format(DateTime.now());
    state = await AsyncValue.guard(() => _loadMonth(month));
  }

  Future<void> deleteTransaction(int id) async {
    await _repo.deleteTransaction(id);
    final String month = state.value?.month ?? DateFormat('yyyy-MM').format(DateTime.now());
    state = await AsyncValue.guard(() => _loadMonth(month));
  }

  Future<void> refresh() async {
    final String month = state.value?.month ?? DateFormat('yyyy-MM').format(DateTime.now());
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _loadMonth(month));
  }
}

final AsyncNotifierProvider<FinanceController, FinanceState>
    financeControllerProvider =
    AsyncNotifierProvider<FinanceController, FinanceState>(
  FinanceController.new,
);
