import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_top_bar.dart';
import '../../core/widgets/capture_request.dart';
import '../../core/widgets/confirm_dialog.dart';
import '../../core/widgets/month_switcher.dart';
import 'finance_controller.dart';
import 'finance_repository.dart';
import 'amount_validation.dart';
import 'quick_again.dart';
import 'transaction.dart';
import 'widgets/quick_expense_sheet.dart';
import '../work/work_controller.dart';
import '../work/payday.dart';
import '../work/shift.dart';
import '../work/work_pay_card.dart';
import '../../core/widgets/ponpon.dart';
import '../insights/insights_providers.dart';
import '../insights/ponpon_talk_slot.dart';

const List<FontFeature> _tabular = <FontFeature>[FontFeature.tabularFigures()];

final NumberFormat _peso = NumberFormat.currency(symbol: '₱', decimalDigits: 2);

/// Whole pesos when there are no centavos: `₱50`, else `₱37.50`.
String _short(double amount) => NumberFormat.currency(
  symbol: '₱',
  decimalDigits: amount == amount.roundToDouble() ? 0 : 2,
).format(amount);

class FinanceScreen extends ConsumerWidget {
  const FinanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<FinanceState> financeState = ref.watch(
      financeControllerProvider,
    );
    final ColorScheme colors = context.colors;
    final TextTheme textStyles = context.textStyles;

    return CaptureListener(
      action: CaptureAction.addExpense,
      onCapture: () => _quickLog(context, ref),
      child: Scaffold(
        appBar: const AppTopBar(title: 'Finance'),
        body: financeState.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (Object _, StackTrace _) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Icon(
                  Icons.error_outline_rounded,
                  size: 48,
                  color: colors.error,
                ),
                AppSpacing.gapMd,
                const Text('Couldn’t load your finances.'),
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
            final DateTime currentMonthDate =
                DateTime.tryParse('${state.month}-01') ?? DateTime.now();
            final bool thisMonth =
                state.month == DateFormat('yyyy-MM').format(DateTime.now());
            final List<MapEntry<DateTime, List<Transaction>>> days =
                _groupByDay(state.transactions);

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
                        AppSpacing.sm,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          MonthSwitcher(
                            month: currentMonthDate,
                            onChanged: (DateTime month) => ref
                                .read(financeControllerProvider.notifier)
                                .setMonth(DateFormat('yyyy-MM').format(month)),
                          ),
                          // An empty month already shows Ponpon below, so
                          // the bubble waits for a transaction, except on a
                          // payday with pay still waiting.
                          if (thisMonth &&
                              (state.transactions.isNotEmpty ||
                                  _paydayWithPayWaiting(ref)))
                            const PonponTalkSlot(
                              surface: PonponSurface.finance,
                              horizontalPadding: 0,
                            ),
                          _MonthCard(summary: state.summary),
                          if (thisMonth) const WorkPayRow(),
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
                              textAlign: TextAlign.center,
                              style: textStyles.titleMedium?.copyWith(
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
                          final MapEntry<DateTime, List<Transaction>> day =
                              days[index];
                          return _DayGroup(
                            day: day.key,
                            transactions: day.value,
                            onOpen: (Transaction tx) =>
                                _showAddTransactionDialog(
                                  context,
                                  ref,
                                  existing: tx,
                                ),
                          );
                        }, childCount: days.length),
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
      ),
    );
  }

  /// Transactions grouped by calendar day, newest day first.
  static List<MapEntry<DateTime, List<Transaction>>> _groupByDay(
    List<Transaction> all,
  ) {
    final Map<DateTime, List<Transaction>> byDay =
        <DateTime, List<Transaction>>{};
    for (final Transaction tx in all) {
      final DateTime d = DateTime(
        tx.occurredOn.year,
        tx.occurredOn.month,
        tx.occurredOn.day,
      );
      byDay.putIfAbsent(d, () => <Transaction>[]).add(tx);
    }
    return byDay.entries.toList()..sort(
      (
        MapEntry<DateTime, List<Transaction>> a,
        MapEntry<DateTime, List<Transaction>> b,
      ) => b.key.compareTo(a.key),
    );
  }

  Future<void> _quickLog(BuildContext context, WidgetRef ref) async {
    final QuickExpenseResult? result = await showQuickExpenseSheet(
      context,
      again: ref
          .read(financeRepositoryProvider)
          .getTransactions()
          .then(
            (List<Transaction> all) => frequentExpenses(all, DateTime.now()),
          ),
    );
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
              behavior: SnackBarBehavior.floating,
              // Clear of the + button: its height, its margin and some air.
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 56 + 16 + 16),
              duration: const Duration(seconds: 2),
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
      useRootNavigator: true,
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
                            ? 'New transaction'
                            : 'Edit transaction',
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
                          return validateAmount(val);
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
                                ? 'Add transaction'
                                : 'Save changes',
                          ),
                        ),
                      ),
                      if (existing != null)
                        TextButton.icon(
                          style: TextButton.styleFrom(
                            foregroundColor: ctx.colors.error,
                            minimumSize: const Size.fromHeight(
                              AppSizes.minTouchTarget,
                            ),
                          ),
                          icon: const Icon(Icons.delete_outline_rounded),
                          label: const Text('Delete transaction'),
                          onPressed: () async {
                            final bool confirmed = await confirmDestructive(
                              ctx,
                              title: 'Delete transaction?',
                              message:
                                  '${existing.category} '
                                  '${_peso.format(existing.amount)} '
                                  'will be removed.',
                            );
                            if (!confirmed) return;
                            await ref
                                .read(workControllerProvider.notifier)
                                .unpayForDeletedIncome(existing);
                            await ref
                                .read(financeControllerProvider.notifier)
                                .deleteTransaction(existing.id);
                            if (ctx.mounted) Navigator.pop(ctx);
                          },
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

/// The month's one hero: what is left, how much of the income is spent, and
/// where the spending went.
class _MonthCard extends StatelessWidget {
  const _MonthCard({required this.summary});

  final FinanceSummary summary;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = context.colors;
    final TextTheme textStyles = context.textStyles;
    final ModuleColors money =
        Theme.of(context).extension<ModuleColors>() ?? ModuleColors.light;
    final double spentShare = summary.totalIncome > 0
        ? (summary.totalExpenses / summary.totalIncome).clamp(0.0, 1.0)
        : (summary.totalExpenses > 0 ? 1.0 : 0.0);
    final List<CategoryBreakdown> top =
        summary.byCategory
            .where((CategoryBreakdown c) => c.type == 'expense')
            .toList()
          ..sort(
            (CategoryBreakdown a, CategoryBreakdown b) =>
                b.total.compareTo(a.total),
          );
    final TextStyle? figure = textStyles.titleSmall?.copyWith(
      fontWeight: FontWeight.w700,
      fontFeatures: _tabular,
    );

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: AppSpacing.card,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              'Left this month',
              style: textStyles.labelLarge?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            Text(
              _peso.format(summary.balance),
              style: textStyles.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                fontFeatures: _tabular,
                color: summary.balance >= 0 ? colors.primary : colors.error,
              ),
            ),
            AppSpacing.gapSm,
            ClipRRect(
              borderRadius: AppRadius.pill,
              child: LinearProgressIndicator(
                value: spentShare,
                minHeight: 6,
                color: colors.error,
                backgroundColor: money.income.withValues(alpha: 0.35),
              ),
            ),
            AppSpacing.gapSm,
            // Wraps onto two lines at large text sizes instead of cutting
            // the figures off.
            Wrap(
              spacing: AppSpacing.lg,
              runSpacing: AppSpacing.xs,
              children: <Widget>[
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Icon(
                      Icons.arrow_downward_rounded,
                      size: 16,
                      color: money.income,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      'Income ${_peso.format(summary.totalIncome)}',
                      style: figure?.copyWith(color: money.income),
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Icon(
                      Icons.arrow_upward_rounded,
                      size: 16,
                      color: colors.error,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      'Spent ${_peso.format(summary.totalExpenses)}',
                      style: figure?.copyWith(color: colors.error),
                    ),
                  ],
                ),
              ],
            ),
            if (top.isNotEmpty) ...<Widget>[
              AppSpacing.gapXs,
              Text(
                top
                    .take(3)
                    .map(
                      (CategoryBreakdown c) =>
                          '${c.category} ${_short(c.total)}',
                    )
                    .join(' · '),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textStyles.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                  fontFeatures: _tabular,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// One day's transactions: a date header and a single hairline card.
class _DayGroup extends StatelessWidget {
  const _DayGroup({
    required this.day,
    required this.transactions,
    required this.onOpen,
  });

  final DateTime day;
  final List<Transaction> transactions;
  final ValueChanged<Transaction> onOpen;

  static String _label(DateTime day) {
    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    if (day == today) return 'Today';
    if (day == DateTime(today.year, today.month, today.day - 1)) {
      return 'Yesterday';
    }
    return DateFormat('EEE, MMM d').format(day);
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = context.colors;
    final TextTheme textStyles = context.textStyles;
    final ModuleColors money =
        Theme.of(context).extension<ModuleColors>() ?? ModuleColors.light;

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(
              left: AppSpacing.xs,
              bottom: AppSpacing.xs,
            ),
            child: Text(
              _label(day),
              style: textStyles.labelMedium?.copyWith(
                color: colors.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Card(
            margin: EdgeInsets.zero,
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: <Widget>[
                for (int i = 0; i < transactions.length; i++) ...<Widget>[
                  if (i > 0) Divider(height: 1, color: colors.outlineVariant),
                  _row(transactions[i], colors, textStyles, money),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(
    Transaction tx,
    ColorScheme colors,
    TextTheme textStyles,
    ModuleColors money,
  ) {
    final bool isIncome = tx.type == 'income';
    final bool hasNote = tx.note != null && tx.note!.isNotEmpty;
    return ListTile(
      minTileHeight: 56,
      onTap: () => onOpen(tx),
      leading: CircleAvatar(
        radius: 18,
        backgroundColor: isIncome
            ? money.income.withValues(alpha: 0.12)
            : colors.errorContainer,
        child: Icon(
          isIncome ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
          color: isIncome ? money.income : colors.onErrorContainer,
          size: 18,
        ),
      ),
      title: Text(
        tx.category,
        style: textStyles.titleSmall?.copyWith(fontWeight: FontWeight.w700),
      ),
      subtitle: hasNote
          ? Text(
              tx.note!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textStyles.bodySmall,
            )
          : null,
      trailing: Text(
        '${isIncome ? '+' : '-'}${_peso.format(tx.amount)}',
        style: textStyles.titleSmall?.copyWith(
          fontWeight: FontWeight.bold,
          fontFeatures: _tabular,
          color: isIncome ? money.income : colors.error,
        ),
      ),
    );
  }
}

bool _paydayWithPayWaiting(WidgetRef ref) {
  final DateTime now = DateTime.now();
  if (!isPaydayToday(ref.watch(paydayProvider), now)) return false;
  final List<Shift> shifts =
      ref.watch(workControllerProvider).value ?? const <Shift>[];
  return WorkSummary.of(shifts, now).workedPayCents > 0;
}
