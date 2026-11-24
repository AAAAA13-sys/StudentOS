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

/// In-memory filter state for the Finance > Cashflow transaction list.
class FinanceCashflowFilter {
  const FinanceCashflowFilter({
    this.query = '',
    this.type,
    this.category,
  });

  final String query;
  final String? type; // 'expense' | 'income' | null
  final String? category;

  bool get isActive =>
      query.trim().isNotEmpty || type != null || category != null;

  FinanceCashflowFilter copyWith({
    String? query,
    String? type,
    bool clearType = false,
    String? category,
    bool clearCategory = false,
  }) {
    return FinanceCashflowFilter(
      query: query ?? this.query,
      type: clearType ? null : (type ?? this.type),
      category: clearCategory ? null : (category ?? this.category),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is FinanceCashflowFilter &&
      other.query == query &&
      other.type == type &&
      other.category == category;

  @override
  int get hashCode => Object.hash(query, type, category);
}

class FinanceFilterNotifier extends Notifier<FinanceCashflowFilter> {
  @override
  FinanceCashflowFilter build() => const FinanceCashflowFilter();

  void setQuery(String query) {
    state = state.copyWith(query: query);
  }

  void setType(String? type) {
    state = type == null
        ? state.copyWith(clearType: true)
        : state.copyWith(type: type);
  }

  void setCategory(String? category, {String? type}) {
    state = FinanceCashflowFilter(
      query: state.query,
      type: type ?? state.type,
      category: category,
    );
  }

  void clearCategory() {
    state = state.copyWith(clearCategory: true);
  }

  void clearAll() {
    state = const FinanceCashflowFilter();
  }
}

final NotifierProvider<FinanceFilterNotifier, FinanceCashflowFilter>
financeFilterProvider =
    NotifierProvider<FinanceFilterNotifier, FinanceCashflowFilter>(
      FinanceFilterNotifier.new,
    );

/// Pure filter applying [filter] to [transactions].
List<Transaction> filterCashflowTransactions(
  List<Transaction> transactions,
  FinanceCashflowFilter filter,
) {
  if (!filter.isActive) return transactions;
  final String q = filter.query.trim().toLowerCase();
  return <Transaction>[
    for (final Transaction tx in transactions)
      if ((filter.type == null || tx.type == filter.type) &&
          (filter.category == null || tx.category == filter.category) &&
          (q.isEmpty ||
              tx.category.toLowerCase().contains(q) ||
              (tx.note?.toLowerCase().contains(q) ?? false)))
        tx,
  ];
}
