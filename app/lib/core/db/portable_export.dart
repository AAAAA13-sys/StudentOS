import 'package:intl/intl.dart';

import '../../features/finance/iou_item.dart';
import '../../features/finance/transaction.dart';
import '../../features/insights/month_review.dart';
import '../../features/phone/phone_day.dart';
import '../../features/work/shift.dart';

/// Escapes one CSV cell safely against spreadsheet formula injection and
/// applies RFC 4180 quoting.
///
/// Any non-empty cell starting with `=`, `+`, `-`, `@`, `\t`, or `\r` is
/// prefixed with `'` so Excel, Google Sheets, and LibreOffice treat it as text.
String sanitizeCsvCell(String? value) {
  if (value == null || value.isEmpty) return '';
  String cell = value;
  final String first = cell[0];
  if (first == '=' ||
      first == '+' ||
      first == '-' ||
      first == '@' ||
      first == '\t' ||
      first == '\r') {
    cell = "'$cell";
  }
  if (cell.contains(',') ||
      cell.contains('"') ||
      cell.contains('\n') ||
      cell.contains('\r')) {
    cell = '"${cell.replaceAll('"', '""')}"';
  }
  return cell;
}

String _csvTable(List<List<String?>> rows) =>
    rows.map((List<String?> row) => row.map(sanitizeCsvCell).join(',')).join('\r\n');

/// Exports [transactions] as a formula-safe, RFC 4180 CSV document.
String exportTransactionsCsv(List<Transaction> transactions) {
  final DateFormat date = DateFormat('yyyy-MM-dd');
  return _csvTable(<List<String?>>[
    <String>['date', 'type', 'category', 'amount_php', 'note'],
    for (final Transaction tx in transactions)
      <String?>[
        date.format(tx.occurredOn),
        tx.type,
        tx.category,
        tx.amount.toStringAsFixed(2),
        tx.note ?? '',
      ],
  ]);
}

/// Exports [shifts] as a formula-safe, RFC 4180 CSV document.
String exportShiftsCsv(List<Shift> shifts) {
  final DateFormat date = DateFormat('yyyy-MM-dd');
  final DateFormat time = DateFormat('HH:mm');
  return _csvTable(<List<String?>>[
    <String>[
      'date',
      'start_time',
      'end_time',
      'job',
      'duration_minutes',
      'break_minutes',
      'paid_minutes',
      'hourly_rate_php',
      'pay_php',
      'paid',
    ],
    for (final Shift shift in shifts)
      <String?>[
        date.format(shift.startsAt),
        time.format(shift.startsAt),
        time.format(shift.endsAt),
        shift.job,
        shift.durationMinutes.toString(),
        shift.breakMinutes.toString(),
        shift.paidMinutes.toString(),
        (shift.hourlyRateCents / 100).toStringAsFixed(2),
        (shift.payCents / 100).toStringAsFixed(2),
        shift.paid ? 'yes' : 'no',
      ],
  ]);
}

/// Exports [ious] as a formula-safe, RFC 4180 CSV document.
String exportIousCsv(List<IouItem> ious) {
  final DateFormat date = DateFormat('yyyy-MM-dd');
  return _csvTable(<List<String?>>[
    <String>[
      'occurred_on',
      'person',
      'direction',
      'amount_php',
      'settled',
      'settled_on',
      'note',
    ],
    for (final IouItem iou in ious)
      <String?>[
        iou.occurredOn,
        iou.person,
        iou.direction.code,
        (iou.amountCents / 100).toStringAsFixed(2),
        iou.settled ? 'yes' : 'no',
        iou.settledAt != null ? date.format(iou.settledAt!) : '',
        iou.note ?? '',
      ],
  ]);
}

/// Exports [review] as a portable Markdown summary.
String exportMonthReviewMarkdown(MonthReview review) {
  final NumberFormat peso = NumberFormat.currency(symbol: '₱', decimalDigits: 2);
  String money(int cents) {
    final String formatted = peso.format(cents.abs() / 100);
    return cents < 0 ? '-$formatted' : formatted;
  }

  final (DateTime start, DateTime _) = monthDateRange(review.month);
  final String monthTitle = DateFormat('MMMM yyyy').format(start);

  final StringBuffer out = StringBuffer()
    ..writeln('# Month in Review — $monthTitle (${review.month})')
    ..writeln()
    ..writeln('## Money')
    ..writeln('- Income: ${money(review.incomeCents)}')
    ..writeln('- Expenses: ${money(review.expenseCents)}')
    ..writeln('- Net: ${money(review.netCents)}')
    ..writeln('- Transactions: ${review.transactionCount}');

  if (review.topExpenseCategories.isNotEmpty) {
    out.writeln('- Top expense categories:');
    for (final MonthExpenseCategory cat in review.topExpenseCategories.take(5)) {
      out.writeln(
        '  - ${cat.category}: ${money(cat.cents)} (${cat.count})',
      );
    }
  }

  out
    ..writeln(
      '- Savings goals stashed: ${money(review.goalsSavedCents)} '
      '(${review.goalsCount} ${review.goalsCount == 1 ? 'goal' : 'goals'}, '
      '${review.goalsReachedCount} reached)',
    )
    ..writeln(
      '- Open IOUs (${review.openIousCount}): owed to you '
      '${money(review.openOwedCents)}, you owe ${money(review.openOwingCents)}',
    )
    ..writeln(
      '- Settled this month: ${review.settledInMonthCount} '
      '(${money(review.settledInMonthCents)})',
    )
    ..writeln()
    ..writeln('## Work & Study')
    ..writeln(
      '- Shifts: ${review.shiftCount} '
      '(paid ${formatHours(review.paidShiftMinutes)}h · '
      '${money(review.paidShiftPayCents)}, '
      'unpaid ${formatHours(review.unpaidShiftMinutes)}h · '
      '${money(review.unpaidShiftPayCents)})',
    )
    ..writeln(
      '- Focus time: ${formatDuration(Duration(milliseconds: review.focusMs))} '
      '(${review.completedFocusSessions}/${review.focusSessions} '
      'completed sessions, ${review.focusRounds} rounds)',
    );

  if (review.topStudyTargets.isNotEmpty) {
    out.writeln('- Top study targets:');
    for (final MonthStudyTarget target in review.topStudyTargets.take(5)) {
      out.writeln(
        '  - ${target.label}: '
        '${formatDuration(Duration(milliseconds: target.focusMs))} '
        '(${target.sessions})',
      );
    }
  }

  out
    ..writeln('- Tasks completed: ${review.tasksCompletedCount}')
    ..writeln('- Recall cards reviewed: ${review.recallReviewedCount}')
    ..writeln()
    ..writeln('## Phone Rest & Screen Time');

  if (review.daysWithPhone == 0) {
    out.writeln(
      review.hasPhoneAccess
          ? '- No screen time recorded'
          : '- Screen time access off',
    );
  } else {
    out.writeln('- Days recorded: ${review.daysWithPhone}');
    if (review.avgScreenOnMs != null) {
      out.writeln(
        '- Average screen time: '
        '${formatDuration(Duration(milliseconds: review.avgScreenOnMs!))}',
      );
    }
    out.writeln(
      '- Average phone rest: '
      '${review.avgRestDuration != null ? formatDuration(review.avgRestDuration!) : 'No rest recorded'}',
    );
  }

  return out.toString();
}
