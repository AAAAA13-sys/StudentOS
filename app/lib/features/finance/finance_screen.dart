import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_top_bar.dart';
import '../../core/widgets/confirm_dialog.dart';
import '../../core/widgets/month_switcher.dart';
import 'finance_controller.dart';
import 'finance_repository.dart';
import 'transaction.dart';
import 'widgets/quick_expense_sheet.dart';
import 'widgets/reserve_dialog.dart';
import 'widgets/safe_to_spend_card.dart';
import '../work/work_pay_card.dart';
import '../../core/widgets/ponpon.dart';

class FinanceScreen extends ConsumerWidget {
  const FinanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<FinanceState> financeState = ref.watch(
      financeControllerProvider,
    );
    final ColorScheme colors = context.colors;
    final TextTheme textStyles = context.textStyles;
    final currencyFormat = NumberFormat.currency(symbol: '₱', decimalDigits: 2);
    final ModuleColors money =
        Theme.of(context).extension<ModuleColors>() ?? ModuleColors.light;

    return Scaffold(
      appBar: const AppTopBar(title: 'Finance'),
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
          final List<CategoryBreakdown> expenseCategories = summary.byCategory
              .where((CategoryBreakdown c) => c.type == 'expense')
              .toList();
          final DateTime currentMonthDate =
              DateTime.tryParse('${state.month}-01') ?? DateTime.now();

          return RefreshIndicator(
            onRefresh: () =>
                ref.read(financeControllerProvider.notifier).refresh(),
            child: CustomScrollView(
              slivers: <Widget>[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      0,
                      AppSpacing.lg,
                      AppSpacing.lg,
                    ),
                    child: Column(
                      children: <Widget>[
                        MonthSwitcher(
                          month: currentMonthDate,
                          onChanged: (DateTime month) => ref
                              .read(financeControllerProvider.notifier)
                              .setMonth(DateFormat('yyyy-MM').format(month)),
                        ),
                        AppSpacing.gapMd,
                        if (state.safeToSpend != null) ...<Widget>[
                          SafeToSpendCard(
                            value: state.safeToSpend!,
                            onSetAllowanceDay: () async {
                              final DateTime now = DateTime.now();
                              final DateTime tomorrow = DateTime(
                                now.year,
                                now.month,
                                now.day + 1,
                              );
                              final DateTime? picked = await showDatePicker(
                                context: context,
                                helpText: 'Next allowance day',
                                initialDate: tomorrow,
                                firstDate: tomorrow,
                                lastDate: DateTime(now.year + 1, now.month),
                              );
                              if (picked != null) {
                                await ref
                                    .read(financeControllerProvider.notifier)
                                    .setNextAllowance(picked);
                              }
                            },
                            onSetReserved: () async {
                              final double? amount = await showReserveDialog(
                                context,
                                current: state.safeToSpend!.reserved,
                              );
                              if (amount != null) {
                                await ref
                                    .read(financeControllerProvider.notifier)
                                    .setReserved(amount);
                              }
                            },
                          ),
                          AppSpacing.gapMd,
                          const WorkPayCard(),
                          AppSpacing.gapMd,
                        ],
                        // Balance Summary Card
                        Card(
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
                                      child: SizedBox(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: <Widget>[
                                            Row(
                                              children: <Widget>[
                                                Icon(
                                                  Icons.arrow_downward_rounded,
                                                  size: 16,
                                                  color: money.income,
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
                                                color: money.income,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    AppSpacing.gapMd,
                                    Expanded(
                                      child: SizedBox(
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
                        if (expenseCategories.isNotEmpty) ...<Widget>[
                          AppSpacing.gapLg,
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Where it went',
                              style: textStyles.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          AppSpacing.gapSm,
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Wrap(
                              spacing: AppSpacing.sm,
                              runSpacing: AppSpacing.xs,
                              children: expenseCategories.map((
                                CategoryBreakdown cat,
                              ) {
                                final bool isIncome = cat.type == 'income';
                                return Chip(
                                  avatar: Icon(
                                    isIncome
                                        ? Icons.arrow_downward_rounded
                                        : Icons.arrow_upward_rounded,
                                    size: 14,
                                    color: isIncome
                                        ? money.income
                                        : colors.error,
                                  ),
                                  label: Text(
                                    '${cat.category}: ${currencyFormat.format(cat.total)}',
                                    style: textStyles.labelSmall,
                                  ),
                                );
                              }).toList(),
                            ),
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
                          const Ponpon(size: 88),
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
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      0,
                      AppSpacing.lg,
                      96,
                    ),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate((
                        BuildContext context,
                        int index,
                      ) {
                        final Transaction tx = state.transactions[index];
                        final bool isIncome = tx.type == 'income';

                        return Card(
                          margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                          clipBehavior: Clip.antiAlias,
                          child: ListTile(
                            onTap: () => _showAddTransactionDialog(
                              context,
                              ref,
                              existing: tx,
                            ),
                            leading: CircleAvatar(
                              backgroundColor: isIncome
                                  ? money.income.withValues(alpha: 0.12)
                                  : colors.errorContainer,
                              child: Icon(
                                isIncome
                                    ? Icons.arrow_downward_rounded
                                    : Icons.arrow_upward_rounded,
                                color: isIncome
                                    ? money.income
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
                                    fontFeatures: const <FontFeature>[
                                      FontFeature.tabularFigures(),
                                    ],
                                    color: isIncome
                                        ? money.income
                                        : colors.error,
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(
                                    Icons.delete_outline_rounded,
                                    size: 20,
                                    color: colors.onSurfaceVariant,
                                  ),
                                  tooltip: 'Delete',
                                  onPressed: () async {
                                    final bool
                                    confirmed = await confirmDestructive(
                                      context,
                                      title: 'Delete transaction?',
                                      message:
                                          '${tx.category} '
                                          '${currencyFormat.format(tx.amount)} '
                                          'will be removed.',
                                    );
                                    if (confirmed) {
                                      await ref
                                          .read(
                                            financeControllerProvider.notifier,
                                          )
                                          .deleteTransaction(tx.id);
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      }, childCount: state.transactions.length),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Quick expense',
        onPressed: () => _quickLog(context, ref),
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  Future<void> _quickLog(BuildContext context, WidgetRef ref) async {
    final QuickExpenseResult? result = await showQuickExpenseSheet(context);
    if (!context.mounted) return;
    switch (result) {
      case QuickExpense(:final double amount, :final String category):
        await ref
            .read(financeControllerProvider.notifier)
            .addTransaction(
              Transaction(
                id: 0,
                type: 'expense',
                amount: amount,
                category: category,
                occurredOn: DateTime.now(),
              ),
            );
        final String thisMonth = DateFormat('yyyy-MM').format(DateTime.now());
        if (ref.read(financeControllerProvider).value?.month != thisMonth) {
          await ref
              .read(financeControllerProvider.notifier)
              .setMonth(thisMonth);
        }
        if (!context.mounted) return;
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(
                'Logged ${NumberFormat.currency(symbol: '₱', decimalDigits: amount == amount.roundToDouble() ? 0 : 2).format(amount)} · $category',
              ),
            ),
          );
      case QuickExpenseMoreOptions():
        await _showAddTransactionDialog(context, ref);
      case null:
        break;
    }
  }

  /// The full transaction form; edits [existing] when one is given.
  Future<void> _showAddTransactionDialog(
    BuildContext context,
    WidgetRef ref, {
    Transaction? existing,
  }) async {
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();
    final TextEditingController amountController = TextEditingController(
      text: existing == null
          ? ''
          : existing.amount.toStringAsFixed(
              existing.amount == existing.amount.roundToDouble() ? 0 : 2,
            ),
    );
    final TextEditingController noteController = TextEditingController(
      text: existing?.note ?? '',
    );
    String type = existing?.type ?? 'expense';
    String category = existing?.category ?? 'Food';
    DateTime occurredOn = existing?.occurredOn ?? DateTime.now();

    const List<String> categories = FinanceRepository.categories;

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
                        existing == null
                            ? 'Add Transaction'
                            : 'Edit Transaction',
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
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Amount (₱)',
                          prefixText: '₱ ',
                          border: OutlineInputBorder(
                            borderRadius: AppRadius.medium,
                          ),
                        ),
                        validator: (String? val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Enter amount';
                          }
                          final double? amt = double.tryParse(val.trim());
                          if (amt == null || amt <= 0) {
                            return 'Must be greater than 0';
                          }
                          return null;
                        },
                      ),
                      AppSpacing.gapMd,
                      DropdownButtonFormField<String>(
                        initialValue: category,
                        decoration: const InputDecoration(
                          labelText: 'Category',
                          border: OutlineInputBorder(
                            borderRadius: AppRadius.medium,
                          ),
                        ),
                        items: categories
                            .map(
                              (String c) => DropdownMenuItem<String>(
                                value: c,
                                child: Text(c),
                              ),
                            )
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
                        icon: const Icon(
                          Icons.calendar_today_rounded,
                          size: 18,
                        ),
                        label: Text(
                          'Date: ${DateFormat('MMM d, yyyy').format(occurredOn)}',
                        ),
                      ),
                      AppSpacing.gapMd,
                      TextFormField(
                        controller: noteController,
                        decoration: const InputDecoration(
                          labelText: 'Note (optional)',
                          border: OutlineInputBorder(
                            borderRadius: AppRadius.medium,
                          ),
                        ),
                      ),
                      AppSpacing.gapXl,
                      SizedBox(
                        height: AppSizes.buttonHeight,
                        child: FilledButton(
                          onPressed: () {
                            if (!formKey.currentState!.validate()) return;
                            final double amt = double.parse(
                              amountController.text.trim(),
                            );

                            final Transaction tx = Transaction(
                              id: existing?.id ?? 0,
                              type: type,
                              amount: amt,
                              category: category,
                              occurredOn: occurredOn,
                              note: noteController.text.trim().isNotEmpty
                                  ? noteController.text.trim()
                                  : null,
                            );
                            final FinanceController controller = ref.read(
                              financeControllerProvider.notifier,
                            );
                            if (existing == null) {
                              controller.addTransaction(tx);
                            } else {
                              controller.updateTransaction(tx);
                            }
                            Navigator.pop(ctx);
                          },
                          child: Text(
                            existing == null
                                ? 'Save Transaction'
                                : 'Update Transaction',
                          ),
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
