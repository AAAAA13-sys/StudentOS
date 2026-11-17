import 'transaction.dart';

/// An (amount, category) expense that was logged more than once lately.
class RepeatExpense {
  const RepeatExpense(this.amount, this.category, this.count);

  final double amount;
  final String category;
  final int count;
}

/// Up to [limit] expense pairs from the [days] days up to [now] that occur at
/// least [minCount] times, most frequent first (ties: most recent first).
List<RepeatExpense> frequentExpenses(
  Iterable<Transaction> transactions,
  DateTime now, {
  int limit = 3,
  int minCount = 2,
  int days = 30,
}) {
  final DateTime today = DateTime(now.year, now.month, now.day);
  final DateTime from = DateTime(today.year, today.month, today.day - days);
  final Map<(int, String), (int, DateTime)> seen =
      <(int, String), (int, DateTime)>{};
  for (final Transaction tx in transactions) {
    if (tx.type != 'expense') continue;
    final DateTime day = DateTime(
      tx.occurredOn.year,
      tx.occurredOn.month,
      tx.occurredOn.day,
    );
    if (day.isBefore(from) || day.isAfter(today)) continue;
    final (int, String) key = ((tx.amount * 100).round(), tx.category);
    final (int, DateTime)? old = seen[key];
    seen[key] = (
      (old?.$1 ?? 0) + 1,
      old != null && old.$2.isAfter(day) ? old.$2 : day,
    );
  }
  final List<MapEntry<(int, String), (int, DateTime)>> ranked =
      seen.entries.where((e) => e.value.$1 >= minCount).toList()..sort((a, b) {
        final int byCount = b.value.$1.compareTo(a.value.$1);
        if (byCount != 0) return byCount;
        return b.value.$2.compareTo(a.value.$2);
      });
  return <RepeatExpense>[
    for (final e in ranked.take(limit))
      RepeatExpense(e.key.$1 / 100, e.key.$2, e.value.$1),
  ];
}
