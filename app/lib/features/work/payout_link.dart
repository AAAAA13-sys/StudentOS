import '../finance/transaction.dart';
import 'shift.dart';

/// The note "I got paid" writes on the income it creates: `4 hrs at Cafe`.
final RegExp _payoutNote = RegExp(r'^[\d.]+ hrs at (.+)$');

/// Whether [tx] looks like income created by "I got paid".
bool isPayout(Transaction tx) =>
    tx.type == 'income' &&
    tx.category == 'Part-time Job' &&
    _payoutNote.hasMatch(tx.note ?? '');

DateTime _dayStart(DateTime d) => DateTime(d.year, d.month, d.day);

/// The paid shifts that the payout [income] most likely settled, so that
/// deleting it can set them back to unpaid.
///
/// "I got paid" stores no link, so the match follows how it creates the
/// income: shifts at the workplaces named in the note that ended by the end
/// of the income's day and after the day of the previous payout at that same
/// workplace ([payouts] are the other payouts; those created earlier, with a
/// lower id, count).
List<Shift> shiftsPaidBy(
  Transaction income,
  Iterable<Shift> shifts,
  Iterable<Transaction> payouts,
) {
  if (!isPayout(income)) return const <Shift>[];
  final String jobs = _payoutNote.firstMatch(income.note!)!.group(1)!;
  final DateTime end = _dayStart(income.occurredOn)
      .add(const Duration(days: 1));
  final DateTime incomeDay = _dayStart(income.occurredOn);

  /// Only earlier payouts that share the workplace settled its older shifts.
  DateTime floorFor(String job) {
    DateTime floor = DateTime.fromMillisecondsSinceEpoch(0);
    for (final Transaction other in payouts) {
      if (other.id >= income.id || !isPayout(other)) continue;
      final String otherJobs = _payoutNote.firstMatch(other.note!)!.group(1)!;
      if (!(otherJobs == job || otherJobs.split(', ').contains(job))) continue;
      final DateTime day = _dayStart(other.occurredOn);
      final DateTime after = day.isBefore(incomeDay)
          ? day.add(const Duration(days: 1))
          : day;
      if (after.isAfter(floor)) floor = after;
    }
    return floor;
  }

  return <Shift>[
    for (final Shift s in shifts)
      if (s.paid &&
          (jobs == s.job || jobs.split(', ').contains(s.job)) &&
          s.endsAt.isAfter(floorFor(s.job)) &&
          !s.endsAt.isAfter(end))
        s,
  ];
}
