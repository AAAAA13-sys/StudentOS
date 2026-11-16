import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../safe_to_spend.dart';

class SafeToSpendCard extends StatelessWidget {
  const SafeToSpendCard({
    required this.value,
    required this.onSetAllowanceDay,
    required this.onSetReserved,
    super.key,
  });

  final SafeToSpend value;

  /// Called when the user wants to pick the next allowance day.
  final VoidCallback onSetAllowanceDay;

  /// Called when the user wants to change the money set aside for bills.
  final VoidCallback onSetReserved;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = context.colors;
    final TextTheme textStyles = context.textStyles;
    final NumberFormat money = NumberFormat.currency(
      symbol: '₱',
      decimalDigits: 2,
    );
    const List<FontFeature> tabular = <FontFeature>[
      FontFeature.tabularFigures(),
    ];

    final String days = value.untilAllowance
        ? (value.daysLeft == 1
              ? 'Allowance arrives tomorrow'
              : '${value.daysLeft} days until allowance')
        : (value.daysLeft == 1
              ? 'Last day of the month'
              : '${value.daysLeft} days left this month');
    final String detail = !value.hasFunds
        ? 'Add your allowance to see what is safe to spend.'
        : value.reserved > 0 && value.leftToday == 0 && value.spentToday == 0
        ? 'Everything on hand is set aside for bills.'
        : value.spentToday > 0
        ? '$days · ${money.format(value.spentToday)} spent today'
        : days;

    final ButtonStyle linkStyle = TextButton.styleFrom(
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
      foregroundColor: colors.primary,
    );

    return Container(
      width: double.infinity,
      padding: AppSpacing.card,
      decoration: BoxDecoration(
        color: colors.primaryContainer,
        borderRadius: AppRadius.large,
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Safe to spend today',
            style: textStyles.labelLarge?.copyWith(
              color: colors.onPrimaryContainer,
            ),
          ),
          AppSpacing.gapXs,
          Text(
            money.format(value.leftToday),
            style: textStyles.displaySmall?.copyWith(
              fontWeight: FontWeight.w700,
              fontFeatures: tabular,
              color: colors.onPrimaryContainer,
            ),
          ),
          AppSpacing.gapXs,
          Text(
            detail,
            style: textStyles.bodySmall?.copyWith(
              fontFeatures: tabular,
              color: colors.onPrimaryContainer,
            ),
          ),
          Wrap(
            spacing: AppSpacing.lg,
            children: <Widget>[
              TextButton(
                style: linkStyle,
                onPressed: onSetAllowanceDay,
                child: Text(
                  value.untilAllowance
                      ? 'Change allowance day'
                      : 'Set next allowance day',
                ),
              ),
              TextButton(
                style: linkStyle,
                onPressed: onSetReserved,
                child: Text(
                  value.reserved > 0
                      ? '${money.format(value.reserved)} set aside for bills'
                      : 'Set aside for bills',
                  style: const TextStyle(fontFeatures: tabular),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
