/// How much can be spent today without running short before the month ends.
///
/// The money on hand at the start of today is spread evenly over the days
/// left in the month (today included); what is already spent today comes off
/// today's share. Overspending today simply lowers tomorrow's share.
class SafeToSpend {
  const SafeToSpend({
    required this.leftToday,
    required this.spentToday,
    required this.daysLeft,
    required this.hasFunds,
  });

  factory SafeToSpend.calculate({
    required int balanceCents,
    required int spentTodayCents,
    required int daysLeft,
  }) {
    final int days = daysLeft < 1 ? 1 : daysLeft;
    final int startOfDayCents = balanceCents + spentTodayCents;
    final int leftCents = startOfDayCents <= 0
        ? 0
        : startOfDayCents ~/ days - spentTodayCents;
    return SafeToSpend(
      leftToday: (leftCents < 0 ? 0 : leftCents) / 100,
      spentToday: spentTodayCents / 100,
      daysLeft: days,
      hasFunds: startOfDayCents > 0,
    );
  }

  /// Never negative.
  final double leftToday;

  final double spentToday;

  /// Days left in the month, counting today.
  final int daysLeft;

  /// False when there was no money on hand at the start of today.
  final bool hasFunds;
}
