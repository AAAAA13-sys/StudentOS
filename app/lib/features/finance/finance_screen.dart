import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import 'finance_controller.dart';
import 'transaction.dart';

class FinanceScreen extends ConsumerWidget {
  const FinanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<FinanceState> financeState =
        ref.watch(financeControllerProvider);
    final ColorScheme colors = context.colors;
    final TextTheme textStyles = context.textStyles;
    final currencyFormat = NumberFormat.currency(symbol: '₱', decimalDigits: 2);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu_rounded),
          tooltip: 'Open Menu',
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
        title: const Text('Finance Tracker'),
        centerTitle: true,
      ),
      body: financeState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (Object err, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(Icons.error_outline_rounded, size: 48, color: colors.error),
              AppSpacing.gapMd,
              Text('Error loading finance data: $err'),
              AppSpacing.gapLg,
              FilledButton(
                onPressed: () =>
                    ref.read(financeControllerProvider.notifier).refresh(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (FinanceState state) {
          final FinanceSummary summary = state.summary;
          final DateTime currentMonthDate =
              DateTime.tryParse('${state.month}-01') ?? DateTime.now();

          return RefreshIndicator(
            onRefresh: () =>
                ref.read(financeControllerProvider.notifier).refresh(),
            child: CustomScrollView(
              slivers: <Widget>[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: AppSpacing.screen,
                    child: Column(
                      children: <Widget>[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            IconButton(
                              icon: const Icon(Icons.chevron_left_rounded),
                              onPressed: () {
                                final DateTime prev = DateTime(
                                  currentMonthDate.year,
                                  currentMonthDate.month - 1,
                                );
                                ref
                                    .read(financeControllerProvider.notifier)
                                    .setMonth(DateFormat('yyyy-MM').format(prev));
                              },
                            ),
                            Text(
                              DateFormat('MMMM yyyy').format(currentMonthDate),
                              style: textStyles.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.chevron_right_rounded),
                              onPressed: () {
                                final DateTime next = DateTime(
                                  currentMonthDate.year,
                                  currentMonthDate.month + 1,
                                );
                                ref
                                    .read(financeControllerProvider.notifier)
                                    .setMonth(DateFormat('yyyy-MM').format(next));
                              },
                            ),
                          ],
                        ),
                        AppSpacing.gapMd,
                        // Balance Summary Card
                        Card(
                          elevation: 0,
                          color: colors.primaryContainer.withValues(alpha: 0.35),
                          shape: const RoundedRectangleBorder(
                            borderRadius: AppRadius.large,
                          ),
                          child: Padding(
                            padding: AppSpacing.card,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: <Widget>[
                                Text(
                                  'Net Balance',
                                  style: textStyles.bodyMedium?.copyWith(
                                    color: colors.onSurfaceVariant,
                                  ),
                                ),
                                AppSpacing.gapXs,
                                Text(
                                  currencyFormat.format(summary.balance),
                                  style: textStyles.headlineMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    fontFeatures: const <FontFeature>[
                                      FontFeature.tabularFigures(),
                                    ],
                                    color: summary.balance >= 0
                                        ? colors.primary
                                        : colors.error,
                                  ),
                                ),
                                AppSpacing.gapLg,
                                Row(
                                  children: <Widget>[
                                    Expanded(
                                      child: Container(
                                        padding: const EdgeInsets.all(AppSpacing.md),
                                        decoration: BoxDecoration(
                                          color: colors.surfaceContainerLow,
                                          borderRadius: AppRadius.medium,
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: <Widget>[
                                            Row(
                                              children: <Widget>[
                                                Icon(
                                                  Icons.arrow_downward_rounded,
                                                  size: 16,
                                                  color: Colors.green[700],
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  'Income',
                                                  style: textStyles.labelSmall,
                                                ),
                                              ],
                                            ),
                                            AppSpacing.gapXs,
                                            Text(
                                              currencyFormat.format(
                                                summary.totalIncome,
                                              ),
                                              style: textStyles.titleSmall?.copyWith(
                                                fontWeight: FontWeight.bold,
                                                fontFeatures: const <FontFeature>[
                                                  FontFeature.tabularFigures(),
                                                ],
                                                color: Colors.green[700],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    AppSpacing.gapMd,
                                    Expanded(
                                      child: Container(
                                        padding: const EdgeInsets.all(AppSpacing.md),
                                        decoration: BoxDecoration(
                                          color: colors.surfaceContainerLow,
                                          borderRadius: AppRadius.medium,
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: <Widget>[
                                            Row(
                                              children: <Widget>[
                                                Icon(
                                                  Icons.arrow_upward_rounded,
                                                  size: 16,
                                                  color: colors.error,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  'Expenses',
                                                  style: textStyles.labelSmall,
                                                ),
                                              ],
                                            ),
                                            AppSpacing.gapXs,
                                            Text(
                                              currencyFormat.format(
                                                summary.totalExpenses,
                                              ),
                                              style: textStyles.titleSmall?.copyWith(
                                                fontWeight: FontWeight.bold,
                                                fontFeatures: const <FontFeature>[
                                                  FontFeature.tabularFigures(),
                                                ],
                                                color: colors.error,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (summary.byCategory.isNotEmpty) ...<Widget>[
                          AppSpacing.gapLg,
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Category Breakdown',
                              style: textStyles.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          AppSpacing.gapSm,
                          Wrap(
                            spacing: AppSpacing.sm,
                            runSpacing: AppSpacing.xs,
                            children: summary.byCategory.map((CategoryBreakdown cat) {
                              final bool isIncome = cat.type == 'income';
                              return Chip(
                                avatar: Icon(
                                  isIncome
                                      ? Icons.arrow_downward_rounded
                                      : Icons.arrow_upward_rounded,
                                  size: 14,
                                  color: isIncome ? Colors.green[700] : colors.error,
                                ),
                                label: Text(
                                  '${cat.category}: ${currencyFormat.format(cat.total)}',
                                  style: textStyles.labelSmall,
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                        AppSpacing.gapXl,
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Transactions',
                            style: textStyles.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (state.transactions.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Icon(
                            Icons.receipt_long_outlined,
                            size: 56,
                            color: colors.outlineVariant,
                          ),
                          AppSpacing.gapMd,
                          Text(
                            'No transactions this month',
                            style: textStyles.bodyMedium?.copyWith(
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (BuildContext context, int index) {
                          final Transaction tx = state.transactions[index];
                          final bool isIncome = tx.type == 'income';

                          return Card(
                            elevation: 0,
                            margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                            color: colors.surfaceContainerLow,
                            shape: const RoundedRectangleBorder(
                              borderRadius: AppRadius.medium,
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: isIncome
                                    ? Colors.green[100]
                                    : colors.errorContainer,
                                child: Icon(
                                  isIncome
                                      ? Icons.arrow_downward_rounded
                                      : Icons.arrow_upward_rounded,
                                  color: isIncome
                                      ? Colors.green[800]
                                      : colors.onErrorContainer,
                                  size: 20,
                                ),
                              ),
                              title: Text(
                                tx.category,
                                style: textStyles.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                '${DateFormat('MMM d').format(tx.occurredOn)}${tx.note != null && tx.note!.isNotEmpty ? ' • ${tx.note}' : ''}',
                                style: textStyles.bodySmall,
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  Text(
                                    '${isIncome ? '+' : '-'}${currencyFormat.format(tx.amount)}',
                                    style: textStyles.titleSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: isIncome
                                          ? Colors.green[700]
                                          : colors.error,
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      Icons.delete_outline_rounded,
                                      size: 20,
                                      color: colors.outline,
                                    ),
                                    onPressed: () {
                                      ref
                                          .read(financeControllerProvider.notifier)
                                          .deleteTransaction(tx.id);
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                        childCount: state.transactions.length,
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTransactionDialog(context, ref),
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  Future<void> _showAddTransactionDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();
    final TextEditingController amountController = TextEditingController();
    final TextEditingController noteController = TextEditingController();
    String type = 'expense';
    String category = 'Food';
    DateTime occurredOn = DateTime.now();

    final List<String> categories =
        ref.read(financeControllerProvider).value?.categories ??
            const <String>[
              'Food',
              'Transport',
              'School',
              'Entertainment',
              'Allowance',
              'Part-time Job',
              'Other',
            ];

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext ctx) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
                left: AppSpacing.lg,
                right: AppSpacing.lg,
                top: AppSpacing.xl,
              ),
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Text(
                        'Add Transaction',
                        style: ctx.textStyles.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      AppSpacing.gapLg,
                      SegmentedButton<String>(
                        segments: const <ButtonSegment<String>>[
                          ButtonSegment<String>(
                            value: 'expense',
                            label: Text('Expense'),
                            icon: Icon(Icons.arrow_upward_rounded),
                          ),
                          ButtonSegment<String>(
                            value: 'income',
                            label: Text('Income'),
                            icon: Icon(Icons.arrow_downward_rounded),
                          ),
                        ],
                        selected: <String>{type},
                        onSelectionChanged: (Set<String> newSelection) {
                          setModalState(() {
                            type = newSelection.first;
                            if (type == 'income') {
                              category = 'Allowance';
                            } else {
                              category = 'Food';
                            }
                          });
                        },
                      ),
                      AppSpacing.gapLg,
                      TextFormField(
                        controller: amountController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Amount (₱)',
                          prefixText: '₱ ',
                          border: OutlineInputBorder(borderRadius: AppRadius.medium),
                        ),
                        validator: (String? val) {
                          if (val == null || val.trim().isEmpty) return 'Enter amount';
                          final double? amt = double.tryParse(val.trim());
                          if (amt == null || amt <= 0) return 'Must be greater than 0';
                          return null;
                        },
                      ),
                      AppSpacing.gapMd,
                      DropdownButtonFormField<String>(
                        initialValue: category,
                        decoration: const InputDecoration(
                          labelText: 'Category',
                          border: OutlineInputBorder(borderRadius: AppRadius.medium),
                        ),
                        items: categories
                            .map((String c) => DropdownMenuItem<String>(
                                  value: c,
                                  child: Text(c),
                                ))
                            .toList(),
                        onChanged: (String? val) {
                          if (val != null) setModalState(() => category = val);
                        },
                      ),
                      AppSpacing.gapMd,
                      OutlinedButton.icon(
                        onPressed: () async {
                          final DateTime? picked = await showDatePicker(
                            context: ctx,
                            initialDate: occurredOn,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2035),
                          );
                          if (picked != null) {
                            setModalState(() => occurredOn = picked);
                          }
                        },
                        icon: const Icon(Icons.calendar_today_rounded, size: 18),
                        label: Text('Date: ${DateFormat('MMM d, yyyy').format(occurredOn)}'),
                      ),
                      AppSpacing.gapMd,
                      TextFormField(
                        controller: noteController,
                        decoration: const InputDecoration(
                          labelText: 'Note (optional)',
                          border: OutlineInputBorder(borderRadius: AppRadius.medium),
                        ),
                      ),
                      AppSpacing.gapXl,
                      SizedBox(
                        height: AppSizes.buttonHeight,
                        child: FilledButton(
                          onPressed: () {
                            if (!formKey.currentState!.validate()) return;
                            final double amt =
                                double.parse(amountController.text.trim());

                            ref.read(financeControllerProvider.notifier).addTransaction(
                                  Transaction(
                                    id: 0,
                                    type: type,
                                    amount: amt,
                                    category: category,
                                    occurredOn: occurredOn,
                                    note: noteController.text.trim().isNotEmpty
                                        ? noteController.text.trim()
                                        : null,
                                  ),
                                );
                            Navigator.pop(ctx);
                          },
                          child: const Text('Save Transaction'),
                        ),
                      ),
                      AppSpacing.gapLg,
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
