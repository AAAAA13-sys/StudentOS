import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_client.dart';
import '../../core/api/api_exception.dart';
import 'transaction.dart';

class FinanceRepository {
  const FinanceRepository(this._api);

  final ApiClient _api;

  Future<List<Transaction>> getTransactions({
    String? month,
    String? category,
  }) async {
    final Map<String, dynamic> query = <String, dynamic>{};
    if (month != null) query['month'] = month;
    if (category != null) query['category'] = category;

    final Object? json = await _api.get(
      '/api/finance/transactions',
      query: query.isNotEmpty ? query : null,
    );

    if (json is Map<String, dynamic> && json['data'] is List) {
      return (json['data'] as List)
          .whereType<Map<String, dynamic>>()
          .map(Transaction.fromJson)
          .toList();
    }
    throw const UnexpectedApiException();
  }

  Future<Transaction> createTransaction(Transaction transaction) async {
    final Object? json = await _api.post(
      '/api/finance/transactions',
      body: transaction.toJson(),
    );

    if (json is Map<String, dynamic> && json['data'] is Map<String, dynamic>) {
      return Transaction.fromJson(json['data'] as Map<String, dynamic>);
    }
    throw const UnexpectedApiException();
  }

  Future<void> deleteTransaction(int id) async {
    await _api.delete('/api/finance/transactions/$id');
  }

  Future<FinanceSummary> getSummary({String? month}) async {
    final Map<String, dynamic> query = <String, dynamic>{};
    if (month != null) query['month'] = month;

    final Object? json = await _api.get(
      '/api/finance/summary',
      query: query.isNotEmpty ? query : null,
    );

    if (json is Map<String, dynamic>) {
      return FinanceSummary.fromJson(json);
    }
    throw const UnexpectedApiException();
  }

  Future<List<String>> getCategories() async {
    final Object? json = await _api.get('/api/finance/categories');
    if (json is Map<String, dynamic> && json['data'] is List) {
      return (json['data'] as List).cast<String>();
    }
    return const <String>[
      'Food',
      'Transport',
      'School',
      'Entertainment',
      'Allowance',
      'Part-time Job',
      'Other',
    ];
  }
}

final Provider<FinanceRepository> financeRepositoryProvider =
    Provider<FinanceRepository>(
  (ref) => FinanceRepository(ref.watch(apiClientProvider)),
);
