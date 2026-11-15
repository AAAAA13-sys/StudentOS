import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../safe_to_spend.dart';

class SafeToSpendCard extends StatelessWidget {
  const SafeToSpendCard({required this.value, super.key});

  final SafeToSpend value;

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

    final String days = value.daysLeft == 1
        ? 'Last day of the month'
        : '${value.daysLeft} days left this month';
    final String detail = !value.hasFunds
        ? 'Add your allowance to see what is safe to spend.'
        : value.spentToday > 0
        ? '$days · ${money.format(value.spentToday)} spent today'
        : days;

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
        ],
      ),
    );
  }
}
