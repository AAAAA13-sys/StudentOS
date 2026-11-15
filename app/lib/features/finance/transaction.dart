class Transaction {
  const Transaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.category,
    required this.occurredOn,
    this.note,
  });

  final int id;
  final String type; // 'income' | 'expense'
  final double amount;
  final String category;
  final DateTime occurredOn;
  final String? note;

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'] as int,
      type: json['type'] as String,
      amount: (json['amount'] as num).toDouble(),
      category: json['category'] as String,
      occurredOn: DateTime.parse(json['occurred_on'] as String),
      note: json['note'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'type': type,
      'amount': amount,
      'category': category,
      'occurred_on':
          '${occurredOn.year.toString().padLeft(4, '0')}-${occurredOn.month.toString().padLeft(2, '0')}-${occurredOn.day.toString().padLeft(2, '0')}',
      if (note != null) 'note': note,
    };
  }
}

class CategoryBreakdown {
  const CategoryBreakdown({
    required this.category,
    required this.type,
    required this.total,
  });

  final String category;
  final String type;
  final double total;

  factory CategoryBreakdown.fromJson(Map<String, dynamic> json) {
    return CategoryBreakdown(
      category: json['category'] as String,
      type: json['type'] as String,
      total: (json['total'] as num).toDouble(),
    );
  }
}

class FinanceSummary {
  const FinanceSummary({
    required this.month,
    required this.totalIncome,
    required this.totalExpenses,
    required this.balance,
    required this.byCategory,
  });

  final String month;
  final double totalIncome;
  final double totalExpenses;
  final double balance;
  final List<CategoryBreakdown> byCategory;

  factory FinanceSummary.fromJson(Map<String, dynamic> json) {
    return FinanceSummary(
      month: json['month'] as String? ?? '',
      totalIncome: (json['total_income'] as num?)?.toDouble() ?? 0.0,
      totalExpenses: (json['total_expenses'] as num?)?.toDouble() ?? 0.0,
      balance: (json['balance'] as num?)?.toDouble() ?? 0.0,
      byCategory: (json['by_category'] as List? ?? <dynamic>[])
          .whereType<Map<String, dynamic>>()
          .map(CategoryBreakdown.fromJson)
          .toList(),
    );
  }
}
