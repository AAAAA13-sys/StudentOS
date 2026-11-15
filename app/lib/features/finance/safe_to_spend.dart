/// How much can be spent today without running short before the month ends.
///
/// The money on hand at the start of today is spread evenly over the days
/// left until the next allowance, or until the month ends when no allowance
/// day is set (today included); what is already spent today comes off
/// today's share. Overspending today simply lowers tomorrow's share.
class SafeToSpend {
  const SafeToSpend({
    required this.leftToday,
    required this.spentToday,
    required this.daysLeft,
    required this.hasFunds,
    this.untilAllowance = false,
  });

  factory SafeToSpend.calculate({
    required int balanceCents,
    required int spentTodayCents,
    required int daysLeft,
    bool untilAllowance = false,
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
      untilAllowance: untilAllowance,
    );
  }

  /// Never negative.
  final double leftToday;

  final double spentToday;

  /// Days the money has to last, counting today.
  final int daysLeft;

  /// True when [daysLeft] runs to the next allowance day rather than to the
  /// end of the month.
  final bool untilAllowance;

  /// False when there was no money on hand at the start of today.
  final bool hasFunds;
}
