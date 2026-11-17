import 'package:intl/intl.dart';

import '../../core/widgets/ponpon.dart';

/// One thing Ponpon can say: a short sentence, the mood that goes with it and
/// a priority (lower is said first).
class PonponInsight {
  const PonponInsight({
    required this.text,
    required this.priority,
    this.mood = PonponMood.happy,
  });

  final String text;
  final PonponMood mood;
  final int priority;

  @override
  String toString() => 'PonponInsight($priority, $mood, $text)';
}

/// The most insights one screen offers.
const int maxInsights = 4;

/// Sorts by priority (stable) and keeps at most [maxInsights].
List<PonponInsight> rankInsights(Iterable<PonponInsight> all) {
  final List<PonponInsight> list = all.toList();
  final List<int> order = List<int>.generate(list.length, (int i) => i)
    ..sort((int a, int b) {
      final int byPriority = list[a].priority.compareTo(list[b].priority);
      return byPriority != 0 ? byPriority : a.compareTo(b);
    });
  return <PonponInsight>[for (final int i in order.take(maxInsights)) list[i]];
}

/// Whole pesos when there are no centavos, else two decimals: `₱2,300`.
String pesoText(double amount) {
  final bool whole = (amount - amount.roundToDouble()).abs() < 0.005;
  return NumberFormat.currency(
    symbol: '₱',
    decimalDigits: whole ? 0 : 2,
  ).format(whole ? amount.roundToDouble() : amount);
}

/// `8:00 AM`.
String clockText(DateTime at) => DateFormat('h:mm a').format(at);

/// `25 min`, `1 h 30 min`, `2 h`.
String spanText(Duration d) {
  final int minutes = (d.inSeconds / 60).ceil();
  if (minutes < 60) return '$minutes min';
  final int h = minutes ~/ 60;
  final int m = minutes % 60;
  return m == 0 ? '$h h' : '$h h $m min';
}
