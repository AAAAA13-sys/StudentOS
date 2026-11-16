/// How much can be spent today without running short before the month ends.
///
/// The money on hand at the start of today is spread evenly over the days
/// left until the next allowance, or until the month ends when no allowance
/// day is set (today included); what is already spent today comes off
/// today's share. Overspending today simply lowers tomorrow's share.
///
/// Money set aside for fixed bills (fare, laundry, fees) is taken off first,
/// so it is never counted as spendable.
class SafeToSpend {
  const SafeToSpend({
    required this.leftToday,
    required this.spentToday,
    required this.daysLeft,
    required this.hasFunds,
    this.untilAllowance = false,
    this.reserved = 0,
  });

  factory SafeToSpend.calculate({
    required int balanceCents,
    required int spentTodayCents,
    required int daysLeft,
    bool untilAllowance = false,
    int reservedCents = 0,
  }) {
    final int days = daysLeft < 1 ? 1 : daysLeft;
    final int reserved = reservedCents < 0 ? 0 : reservedCents;
    final int startOfDayCents = balanceCents + spentTodayCents;
    final int spendableCents = startOfDayCents - reserved;
    final int leftCents = spendableCents <= 0
        ? 0
        : spendableCents ~/ days - spentTodayCents;
    return SafeToSpend(
      leftToday: (leftCents < 0 ? 0 : leftCents) / 100,
      spentToday: spentTodayCents / 100,
      daysLeft: days,
      hasFunds: startOfDayCents > 0,
      untilAllowance: untilAllowance,
      reserved: reserved / 100,
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

  /// Money set aside for fixed bills; zero when none is set.
  final double reserved;
}
