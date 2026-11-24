import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../finance_controller.dart';
import '../transaction.dart';

const List<FontFeature> _tabular = <FontFeature>[FontFeature.tabularFigures()];

final NumberFormat _peso = NumberFormat.currency(symbol: '₱', decimalDigits: 2);

/// Opens the month's category breakdown modal sheet for Expenses & Income.
/// Tapping any category filters Finance > Cashflow to that category and closes
/// the sheet.
Future<void> showCategoryBreakdownSheet(
  BuildContext context,
  WidgetRef ref, {
  required FinanceSummary summary,
  required List<Transaction> transactions,
}) {
  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (BuildContext ctx) => _CategoryBreakdownSheet(
      summary: summary,
      transactions: transactions,
    ),
  );
}

class _CategoryBreakdownSheet extends ConsumerWidget {
  const _CategoryBreakdownSheet({
    required this.summary,
    required this.transactions,
  });

  final FinanceSummary summary;
  final List<Transaction> transactions;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ColorScheme colors = context.colors;
    final TextTheme textStyles = context.textStyles;
    final ModuleColors money =
        Theme.of(context).extension<ModuleColors>() ?? ModuleColors.light;

    final Map<(String, String), int> counts = <(String, String), int>{};
    for (final Transaction tx in transactions) {
      counts.update(
        (tx.category, tx.type),
        (int c) => c + 1,
        ifAbsent: () => 1,
      );
    }

    final List<CategoryBreakdown> expenses = summary.byCategory
        .where((CategoryBreakdown c) => c.type == 'expense')
        .toList();
    final List<CategoryBreakdown> incomes = summary.byCategory
        .where((CategoryBreakdown c) => c.type == 'income')
        .toList();

    Widget buildSection({
      required String title,
      required List<CategoryBreakdown> items,
      required double sectionTotal,
      required Color accentColor,
    }) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(
              top: AppSpacing.sm,
              bottom: AppSpacing.xs,
            ),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    title,
                    style: textStyles.labelLarge?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ),
                Text(
                  _peso.format(sectionTotal),
                  style: textStyles.labelLarge?.copyWith(
                    color: accentColor,
                    fontWeight: FontWeight.w700,
                    fontFeatures: _tabular,
                  ),
                ),
              ],
            ),
          ),
          Card(
            margin: EdgeInsets.zero,
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: <Widget>[
                for (int i = 0; i < items.length; i++) ...<Widget>[
                  if (i > 0) Divider(height: 1, color: colors.outlineVariant),
                  _CategoryRow(
                    item: items[i],
                    count: counts[(items[i].category, items[i].type)] ?? 0,
                    share: sectionTotal > 0
                        ? (items[i].total / sectionTotal).clamp(0.0, 1.0)
                        : 0.0,
                    accentColor: accentColor,
                    onTap: () {
                      ref
                          .read(financeFilterProvider.notifier)
                          .setCategory(items[i].category, type: items[i].type);
                      Navigator.pop(context);
                    },
                  ),
                ],
              ],
            ),
          ),
        ],
      );
    }

    return SafeArea(
      top: false,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.78,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                'Category breakdown',
                style: textStyles.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              AppSpacing.gapXs,
              Text(
                'Tap a category to filter Cashflow',
                style: textStyles.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
              AppSpacing.gapMd,
              if (expenses.isEmpty && incomes.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
                  child: Text(
                    'No categories this month.',
                    style: textStyles.bodyMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                )
              else
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    children: <Widget>[
                      if (expenses.isNotEmpty) ...<Widget>[
                        buildSection(
                          title: 'Expenses',
                          items: expenses,
                          sectionTotal: summary.totalExpenses,
                          accentColor: colors.error,
                        ),
                        AppSpacing.gapMd,
                      ],
                      if (incomes.isNotEmpty)
                        buildSection(
                          title: 'Income',
                          items: incomes,
                          sectionTotal: summary.totalIncome,
                          accentColor: money.income,
                        ),
                    ],
                  ),
                ),
              AppSpacing.gapLg,
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({
    required this.item,
    required this.count,
    required this.share,
    required this.accentColor,
    required this.onTap,
  });

  final CategoryBreakdown item;
  final int count;
  final double share;
  final Color accentColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = context.colors;
    final TextTheme textStyles = context.textStyles;
    final int percent = (share * 100).round();

    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: AppSizes.minTouchTarget),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      '${item.category} ($count)',
                      style: textStyles.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontFeatures: _tabular,
                      ),
                    ),
                  ),
                  AppSpacing.gapSm,
                  Text(
                    '${_peso.format(item.total)} · $percent%',
                    style: textStyles.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      fontFeatures: _tabular,
                    ),
                  ),
                ],
              ),
              AppSpacing.gapXs,
              ClipRRect(
                borderRadius: AppRadius.pill,
                child: LinearProgressIndicator(
                  value: share,
                  minHeight: 5,
                  color: accentColor,
                  backgroundColor: colors.surfaceContainerHigh,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
