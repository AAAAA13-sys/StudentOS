import '../../core/widgets/ponpon.dart';
import '../finance/bill.dart';
import '../finance/transaction.dart';
import '../work/payday.dart';
import 'ponpon_insight.dart';

double _sum(Iterable<Transaction> tx) =>
    tx.fold<double>(0, (double s, Transaction t) => s + t.amount);

/// What Ponpon says about spending. [thisMonth] holds the transactions of
/// [now]'s month and [lastMonth] those of the month before. Pure.
List<PonponInsight> financeInsights({
  required List<Transaction> thisMonth,
  required List<Transaction> lastMonth,
  required DateTime now,
  PaydaySchedule payday = PaydaySchedule.none,
  int waitingPayCents = 0,
  List<Bill> bills = const <Bill>[],
}) {
  final PonponInsight? paydayTip =
      waitingPayCents > 0 && isPaydayToday(payday, now)
      ? PonponInsight(
          text:
              'Payday today: ${pesoText(waitingPayCents / 100)} waiting. Got paid?',
          priority: 1,
        )
      : null;

  final List<Bill> dueBills = <Bill>[
    for (final Bill bill in bills)
      if (bill.isDueOnOrBefore(now)) bill,
  ];
  final PonponInsight? billTip;
  if (dueBills.isEmpty) {
    billTip = null;
  } else if (dueBills.length == 1) {
    final Bill bill = dueBills.single;
    final String verb = bill.isOverdue(now) ? 'overdue' : 'due today';
    billTip = PonponInsight(
      text: 'Bill $verb: ${bill.title} (${pesoText(bill.amount)}).',
      priority: 1,
    );
  } else {
    final int totalCents = dueBills.fold<int>(
      0,
      (int s, Bill b) => s + b.amountCents,
    );
    billTip = PonponInsight(
      text: '${dueBills.length} bills due (${pesoText(totalCents / 100)}).',
      priority: 1,
    );
  }

  if (thisMonth.isEmpty) {
    return rankInsights(<PonponInsight>[?paydayTip, ?billTip]);
  }
  final List<Transaction> spent = <Transaction>[
    for (final Transaction t in thisMonth)
      if (t.type == 'expense') t,
  ];
  final List<Transaction> earned = <Transaction>[
    for (final Transaction t in thisMonth)
      if (t.type == 'income') t,
  ];
  final List<PonponInsight> out = <PonponInsight>[];
  final double totalSpent = _sum(spent);
  final double totalIn = _sum(earned);

  // More went out than came in.
  if (totalSpent > totalIn && totalSpent > 0) {
    out.add(
      PonponInsight(
        text:
            'You spent ${pesoText(totalSpent)} and ${pesoText(totalIn)} came in. That is ${pesoText(totalSpent - totalIn)} more out than in.',
        mood: PonponMood.smug,
        priority: 0,
      ),
    );
  }

  // Today against the daily average of the days before today.
  final double today = _sum(
    spent.where(
      (Transaction t) =>
          t.occurredOn.year == now.year &&
          t.occurredOn.month == now.month &&
          t.occurredOn.day == now.day,
    ),
  );
  final int priorDays = now.day - 1;
  final double average = priorDays > 0 ? (totalSpent - today) / priorDays : 0;
  if (priorDays >= 3 && average > 0) {
    if (today >= average * 1.5 && today - average >= 50) {
      out.add(
        PonponInsight(
          text:
              'You spent ${pesoText(today)} today, well above your usual ${pesoText(average)} a day.',
          mood: PonponMood.smug,
          priority: 1,
        ),
      );
    } else if (today > 0 && today <= average * 0.5 && average - today >= 50) {
      out.add(
        PonponInsight(
          text:
              'Only ${pesoText(today)} spent today, under your usual ${pesoText(average)} a day.',
          priority: 3,
        ),
      );
    }
  }

  // The biggest slice of spending.
  if (totalSpent > 0) {
    final Map<String, double> byCategory = <String, double>{};
    for (final Transaction t in spent) {
      byCategory[t.category] = (byCategory[t.category] ?? 0) + t.amount;
    }
    final List<MapEntry<String, double>> ranked = byCategory.entries.toList()
      ..sort((a, b) {
        final int c = b.value.compareTo(a.value);
        return c != 0 ? c : a.key.compareTo(b.key);
      });
    final MapEntry<String, double> top = ranked.first;
    final int share = (top.value / totalSpent * 100).round();
    if (share >= 30) {
      out.add(
        PonponInsight(
          text:
              '${top.key} is $share% of your spending this month (${pesoText(top.value)}).',
          priority: 2,
        ),
      );
    }
  }

  // This month against last month, up to the same day of the month.
  final int lastMonthLength = DateTime(now.year, now.month, 0).day;
  final int cutoff = now.day < lastMonthLength ? now.day : lastMonthLength;
  final double lastSoFar = _sum(
    lastMonth.where(
      (Transaction t) => t.type == 'expense' && t.occurredOn.day <= cutoff,
    ),
  );
  if (lastSoFar > 0) {
    final double diff = totalSpent - lastSoFar;
    if (diff.abs() >= 100 && diff.abs() >= lastSoFar * 0.15) {
      out.add(
        diff > 0
            ? PonponInsight(
                text:
                    'You are ${pesoText(diff)} above last month by this day (${pesoText(lastSoFar)}).',
                mood: PonponMood.smug,
                priority: 2,
              )
            : PonponInsight(
                text:
                    'You are ${pesoText(-diff)} under last month by this day (${pesoText(lastSoFar)}).',
                priority: 2,
              ),
      );
    }
  }

  if (paydayTip != null) out.add(paydayTip);
  if (billTip != null) out.add(billTip);

  // Nothing spent yet today.
  if (today == 0) {
    out.add(const PonponInsight(text: 'Nothing spent yet today.', priority: 6));
  }

  return rankInsights(out);
}
