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
}
