/// Direction of an IOU relative to the user.
enum IouDirection {
  /// Someone owes the user money.
  owed('owed', 'Owes you'),

  /// The user owes someone money.
  owing('owing', 'You owe');

  const IouDirection(this.code, this.label);

  final String code;
  final String label;

  static IouDirection parse(String raw) =>
      raw == owing.code ? owing : owed;
}

/// An open or settled IOU / split inside Finance.
///
/// IOUs stay completely isolated from cashflow transactions, monthly balance,
/// Safe-to-Spend, and `MoneyWidgetSync` unless the user explicitly chooses to
/// record a settlement in cashflow.
class IouItem {
  const IouItem({
    required this.id,
    required this.person,
    required this.direction,
    required this.amountCents,
    this.note,
    required this.occurredOn,
    this.settled = false,
    this.settledAt,
    required this.createdAt,
  });

  final int id;
  final String person;
  final IouDirection direction;

  /// Amount in centavos.
  final int amountCents;

  final String? note;

  /// Date the IOU occurred as `YYYY-MM-DD`.
  final String occurredOn;

  final bool settled;
  final DateTime? settledAt;
  final DateTime createdAt;

  double get amount => amountCents / 100;

  DateTime get occurredOnDate =>
      parseIouDateKey(occurredOn) ??
      DateTime(createdAt.year, createdAt.month, createdAt.day);

  /// Calendar days elapsed from [occurredOnDate] to [now].
  int ageDays(DateTime now) {
    final DateTime start = occurredOnDate;
    return DateTime.utc(
      now.year,
      now.month,
      now.day,
    ).difference(DateTime.utc(start.year, start.month, start.day)).inDays;
  }

  IouItem copyWith({
    int? id,
    String? person,
    IouDirection? direction,
    int? amountCents,
    String? note,
    bool clearNote = false,
    String? occurredOn,
    bool? settled,
    DateTime? settledAt,
    bool clearSettledAt = false,
    DateTime? createdAt,
  }) {
    return IouItem(
      id: id ?? this.id,
      person: person ?? this.person,
      direction: direction ?? this.direction,
      amountCents: amountCents ?? this.amountCents,
      note: clearNote ? null : (note ?? this.note),
      occurredOn: occurredOn ?? this.occurredOn,
      settled: settled ?? this.settled,
      settledAt: clearSettledAt ? null : (settledAt ?? this.settledAt),
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

/// Computes one person's rounded share in centavos when splitting [totalCents]
/// evenly across [peopleCount] people.
int splitShareCents(int totalCents, int peopleCount) =>
    peopleCount <= 1 ? totalCents : (totalCents / peopleCount).round();

/// Formats [day] as `YYYY-MM-DD`.
String formatIouDateKey(DateTime day) {
  return '${day.year.toString().padLeft(4, '0')}-'
      '${day.month.toString().padLeft(2, '0')}-'
      '${day.day.toString().padLeft(2, '0')}';
}

/// Parses `YYYY-MM-DD` strictly to a local midnight [DateTime], or null.
DateTime? parseIouDateKey(String? text) {
  if (text == null) return null;
  final RegExpMatch? match = RegExp(
    r'^(\d{4})-(\d{2})-(\d{2})$',
  ).firstMatch(text.trim());
  if (match == null) return null;
  final int year = int.parse(match.group(1)!);
  final int month = int.parse(match.group(2)!);
  final int day = int.parse(match.group(3)!);
  if (month < 1 || month > 12 || day < 1 || day > 31) return null;
  final DateTime parsed = DateTime(year, month, day);
  if (parsed.year != year || parsed.month != month || parsed.day != day) {
    return null;
  }
  return parsed;
}
