import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';

import 'finance_repository.dart';
import 'transaction.dart';

String _two(int n) => n.toString().padLeft(2, '0');

/// Writes the home-screen Money widget data for the current month and today,
/// whatever month the Finance screen is showing.
///
/// Keys read by `FinanceWidgetProvider.kt`: `money_day` (yyyy-MM-dd),
/// `money_spent_today` (centavos), `money_month` (yyyy-MM) and
/// `money_month_balance` (centavos). The widget treats a stale day as ₱0
/// spent and a stale month as a new month.
Future<void> syncMoneyWidget(FinanceRepository repo, {DateTime? now}) async {
  try {
    final DateTime today = now ?? DateTime.now();
    final String month = '${today.year}-${_two(today.month)}';
    final String day = '$month-${_two(today.day)}';

    final FinanceSummary summary = await repo.getSummary(month: month);
    final List<Transaction> monthRows = await repo.getTransactions(
      month: month,
    );
    int spentTodayCents = 0;
    for (final Transaction t in monthRows) {
      final DateTime d = t.occurredOn;
      if (t.type == 'expense' &&
          d.year == today.year &&
          d.month == today.month &&
          d.day == today.day) {
        spentTodayCents += (t.amount * 100).round();
      }
    }

    await HomeWidget.saveWidgetData<String>('money_day', day);
    await HomeWidget.saveWidgetData<int>('money_spent_today', spentTodayCents);
    await HomeWidget.saveWidgetData<String>('money_month', month);
    await HomeWidget.saveWidgetData<int>(
      'money_month_balance',
      (summary.balance * 100).round(),
    );
    for (final String key in <String>[
      'safe_spend_amount',
      'safe_spend_note',
      'safe_spend_date',
    ]) {
      await HomeWidget.saveWidgetData<String>(key, null);
    }
    await HomeWidget.updateWidget(
      name: 'FinanceWidgetProvider',
      androidName: 'FinanceWidgetProvider',
    );
  } catch (error) {
    debugPrint('Money widget sync failed: $error');
  }
}
