/// The most a single transaction may be, in pesos.
const double maxAmount = 1000000;

/// A message for an amount typed as [text], or null when it is acceptable.
String? validateAmount(String? text) {
  final String value = (text ?? '').trim();
  if (value.isEmpty) return 'Enter an amount';
  final double? amount = double.tryParse(value);
  if (amount == null || amount.isNaN || amount.isInfinite) {
    return 'Enter a valid amount';
  }
  if (amount <= 0) return 'Amount must be more than ₱0';
  if (amount > maxAmount) return 'Amount can’t be more than ₱1,000,000';
  return null;
}
