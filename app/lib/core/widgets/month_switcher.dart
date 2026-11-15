import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../theme/app_theme.dart';

/// `‹  November 2026  ›`. Tapping the label returns to the current month.
class MonthSwitcher extends StatelessWidget {
  const MonthSwitcher({
    required this.month,
    required this.onChanged,
    super.key,
  });

  /// Any day in the month being shown.
  final DateTime month;

  /// Called with the first day of the newly chosen month.
  final ValueChanged<DateTime> onChanged;

  @override
  Widget build(BuildContext context) {
    final DateTime now = DateTime.now();
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        IconButton(
          icon: const Icon(Icons.chevron_left_rounded),
          tooltip: 'Previous month',
          onPressed: () => onChanged(DateTime(month.year, month.month - 1)),
        ),
        TextButton(
          onPressed: () => onChanged(DateTime(now.year, now.month)),
          child: Text(
            DateFormat('MMMM yyyy').format(month),
            style: context.textStyles.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: context.colors.onSurface,
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right_rounded),
          tooltip: 'Next month',
          onPressed: () => onChanged(DateTime(month.year, month.month + 1)),
        ),
      ],
    );
  }
}
