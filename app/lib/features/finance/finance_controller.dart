import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'finance_repository.dart';
import 'money_widget_sync.dart';
import 'transaction.dart';

class FinanceState {
  const FinanceState({
    required this.month,
    required this.transactions,
    required this.summary,
    required this.categories,
  });

  final String month;
  final List<Transaction> transactions;
  final FinanceSummary summary;
  final List<String> categories;
}

class FinanceController extends AsyncNotifier<FinanceState> {
  FinanceRepository get _repo => ref.read(financeRepositoryProvider);

  @override
  FutureOr<FinanceState> build() async {
    final String month = DateFormat('yyyy-MM').format(DateTime.now());
    return _loadMonth(month);
  }

  Future<FinanceState> _loadMonth(String month) async {
    final List<Transaction> transactions = await _repo.getTransactions(
      month: month,
    );
    final FinanceSummary summary = await _repo.getSummary(month: month);
    _syncWidget();

    return FinanceState(
      month: month,
      transactions: transactions,
      summary: summary,
      categories: FinanceRepository.categories,
    );
  }

  /// Refreshes the home-screen Money widget; best-effort, never blocks the UI.
  void _syncWidget() {
    unawaited(
      syncMoneyWidget(_repo).catchError((Object _) {
        // The widget may not be placed, or the platform is absent.
      }),
    );
  }

  Future<void> setMonth(String month) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _loadMonth(month));
  }

  Future<void> updateTransaction(Transaction tx) async {
    await _repo.updateTransaction(tx);
    final String month =
        state.value?.month ?? DateFormat('yyyy-MM').format(DateTime.now());
    state = await AsyncValue.guard(() => _loadMonth(month));
  }

  Future<void> addTransaction(Transaction tx) async {
    await _repo.createTransaction(tx);
    final String month =
        state.value?.month ?? DateFormat('yyyy-MM').format(DateTime.now());
    state = await AsyncValue.guard(() => _loadMonth(month));
  }

  Future<void> deleteTransaction(int id) async {
    await _repo.deleteTransaction(id);
    final String month =
        state.value?.month ?? DateFormat('yyyy-MM').format(DateTime.now());
    state = await AsyncValue.guard(() => _loadMonth(month));
  }

  Future<void> refresh() async {
    final String month =
        state.value?.month ?? DateFormat('yyyy-MM').format(DateTime.now());
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _loadMonth(month));
  }
}

final AsyncNotifierProvider<FinanceController, FinanceState>
financeControllerProvider =
    AsyncNotifierProvider<FinanceController, FinanceState>(
      FinanceController.new,
    );
