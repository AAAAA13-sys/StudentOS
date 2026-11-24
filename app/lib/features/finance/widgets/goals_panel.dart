import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../core/widgets/ponpon.dart';
import '../../insights/insights_providers.dart';
import '../../insights/ponpon_talk_slot.dart';
import '../amount_validation.dart';
import '../goals_controller.dart';
import '../savings_goal.dart';

const List<FontFeature> _tabular = <FontFeature>[FontFeature.tabularFigures()];

final NumberFormat _peso = NumberFormat.currency(symbol: '₱', decimalDigits: 2);

String _formatAmountInput(double amount) =>
    amount.toStringAsFixed(amount == amount.roundToDouble() ? 0 : 2);

/// Savings pockets view inside `Finance > Goals`.
///
/// Goals are personal allocation buckets and stay isolated from cashflow
/// transactions and monthly spending balance.
class GoalsPanel extends ConsumerWidget {
  const GoalsPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<SavingsGoal>> goalsAsync = ref.watch(
      goalsControllerProvider,
    );
    final ColorScheme colors = context.colors;
    final TextTheme textStyles = context.textStyles;
    final List<SavingsGoal>? goals = goalsAsync.value;

    return Column(
      children: <Widget>[
        PonponTalkSlot(
          surface: PonponSurface.finance,
          suppress: goals == null || goals.isEmpty,
        ),
        Expanded(
          child: goalsAsync.when(
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
                  const Text('Couldn’t load your savings goals.'),
                  AppSpacing.gapLg,
                  FilledButton(
                    onPressed: () =>
                        ref.read(goalsControllerProvider.notifier).refresh(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
            data: (List<SavingsGoal> items) {
              if (items.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xl,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        const Ponpon(mood: PonponMood.happy, size: 88),
                        AppSpacing.gapMd,
                        Text(
                          'No savings goals yet',
                          textAlign: TextAlign.center,
                          style: textStyles.titleMedium?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                        AppSpacing.gapXs,
                        Text(
                          'Create a pocket for tuition, gear, or an emergency fund.',
                          textAlign: TextAlign.center,
                          style: textStyles.bodySmall?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              final int totalSavedCents = items.fold<int>(
                0,
                (int sum, SavingsGoal g) => sum + g.savedCents,
              );
              final int reachedCount = items
                  .where((SavingsGoal g) => g.isReached)
                  .length;
              final int activeCount = items.length - reachedCount;
              final DateTime now = DateTime.now();

              return RefreshIndicator(
                onRefresh: () =>
                    ref.read(goalsControllerProvider.notifier).refresh(),
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.sm,
                    AppSpacing.lg,
                    96,
                  ),
                  itemCount: items.length + 1,
                  separatorBuilder: (_, _) => AppSpacing.gapMd,
                  itemBuilder: (BuildContext context, int index) {
                    if (index == 0) {
                      return _SummaryCard(
                        totalSavedCents: totalSavedCents,
                        activeCount: activeCount,
                        reachedCount: reachedCount,
                      );
                    }
                    final SavingsGoal goal = items[index - 1];
                    return _GoalCard(goal: goal, now: now);
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.totalSavedCents,
    required this.activeCount,
    required this.reachedCount,
  });

  final int totalSavedCents;
  final int activeCount;
  final int reachedCount;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = context.colors;
    final TextTheme textStyles = context.textStyles;
    final ModuleColors money = context.moduleColors;

    final List<String> counts = <String>[
      if (activeCount > 0) '$activeCount active',
      if (reachedCount > 0) '$reachedCount reached',
    ];

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: AppSpacing.card,
        child: Row(
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Total stashed',
                    style: textStyles.labelLarge?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  AppSpacing.gapXs,
                  Text(
                    _peso.format(totalSavedCents / 100),
                    style: textStyles.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontFeatures: _tabular,
                      color: colors.primary,
                    ),
                  ),
                ],
              ),
            ),
            if (counts.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: reachedCount > 0 && activeCount == 0
                      ? money.income.withValues(alpha: 0.14)
                      : colors.primaryContainer.withValues(alpha: 0.55),
                  borderRadius: AppRadius.pill,
                ),
                child: Text(
                  counts.join(' · '),
                  style: textStyles.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontFeatures: _tabular,
                    color: reachedCount > 0 && activeCount == 0
                        ? money.income
                        : colors.onPrimaryContainer,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _GoalCard extends ConsumerWidget {
  const _GoalCard({required this.goal, required this.now});

  final SavingsGoal goal;
  final DateTime now;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ColorScheme colors = context.colors;
    final TextTheme textStyles = context.textStyles;
    final ModuleColors money = context.moduleColors;

    final String dateLabel = goalTargetDateLabel(goal, now);
    final int? days = goal.daysLeft(now);
    final bool overdue = !goal.isReached && days != null && days < 0;

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => showGoalEditor(context, ref, existing: goal),
        onLongPress: () => _confirmDeleteGoal(context, ref, goal),
        child: Padding(
          padding: AppSpacing.card,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    child: Text(
                      goal.title,
                      style: textStyles.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (dateLabel.isNotEmpty) ...<Widget>[
                    AppSpacing.gapSm,
                    Text(
                      dateLabel,
                      style: textStyles.labelMedium?.copyWith(
                        fontFeatures: _tabular,
                        fontWeight: overdue ? FontWeight.w700 : FontWeight.w500,
                        color: overdue ? colors.error : colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
              AppSpacing.gapSm,
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      '${_peso.format(goal.savedAmount)} / '
                      '${_peso.format(goal.targetAmount)}',
                      style: textStyles.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontFeatures: _tabular,
                      ),
                    ),
                  ),
                  Text(
                    goal.isReached ? 'Goal reached' : goal.percentLabel,
                    style: textStyles.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      fontFeatures: _tabular,
                      color: goal.isReached ? money.income : colors.primary,
                    ),
                  ),
                ],
              ),
              AppSpacing.gapSm,
              ClipRRect(
                borderRadius: AppRadius.pill,
                child: LinearProgressIndicator(
                  value: goal.progress,
                  minHeight: 6,
                  color: goal.isReached ? money.income : colors.primary,
                  backgroundColor: colors.surfaceContainerHighest,
                ),
              ),
              AppSpacing.gapMd,
              Row(
                children: <Widget>[
                  Expanded(
                    child: FilledButton.tonal(
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(0, AppSizes.minTouchTarget),
                      ),
                      onPressed: () => showAdjustGoalDialog(
                        context,
                        ref,
                        goal: goal,
                        deposit: true,
                      ),
                      child: const Text('+ Add'),
                    ),
                  ),
                  AppSpacing.gapSm,
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, AppSizes.minTouchTarget),
                      ),
                      onPressed: goal.savedCents > 0
                          ? () => showAdjustGoalDialog(
                              context,
                              ref,
                              goal: goal,
                              deposit: false,
                            )
                          : null,
                      child: const Text('- Take'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<bool> _confirmDeleteGoal(
  BuildContext context,
  WidgetRef ref,
  SavingsGoal goal,
) async {
  final bool confirmed = await confirmDestructive(
    context,
    title: 'Delete goal?',
    message:
        '"${goal.title}" (${_peso.format(goal.savedAmount)} stashed) will be removed.',
  );
  if (confirmed) {
    await ref.read(goalsControllerProvider.notifier).deleteGoal(goal.id);
  }
  return confirmed;
}

/// Opens a modal bottom sheet to create or edit a [SavingsGoal].
Future<void> showGoalEditor(
  BuildContext context,
  WidgetRef ref, {
  SavingsGoal? existing,
}) async {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController titleController = TextEditingController(
    text: existing?.title ?? '',
  );
  final TextEditingController targetController = TextEditingController(
    text: existing == null ? '' : _formatAmountInput(existing.targetAmount),
  );
  final TextEditingController savedController = TextEditingController(
    text: existing == null
        ? '0'
        : _formatAmountInput(existing.savedAmount),
  );

  final DateTime today = goalDateOnly(DateTime.now());
  DateTime? targetDate = existing?.targetDateTime;

  final String startTitle = titleController.text;
  final String startTarget = targetController.text;
  final String startSaved = savedController.text;
  final DateTime? startDate = targetDate;

  bool isDirty() =>
      titleController.text != startTitle ||
      targetController.text != startTarget ||
      savedController.text != startSaved ||
      targetDate != startDate;

  await showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    showDragHandle: true,
    isDismissible: false,
    enableDrag: false,
    builder: (BuildContext ctx) {
      Future<void> close() async {
        if (isDirty()) {
          final bool discard = await confirmDestructive(
            ctx,
            title: 'Discard changes?',
            message: 'What you entered for this goal will be lost.',
            confirmLabel: 'Discard',
          );
          if (!discard) return;
        }
        if (ctx.mounted) Navigator.pop(ctx);
      }

      return ListenableBuilder(
        listenable: Listenable.merge(<Listenable>[
          titleController,
          targetController,
          savedController,
        ]),
        builder: (BuildContext ctx, Widget? _) => PopScope(
          canPop: !isDirty(),
          onPopInvokedWithResult: (bool didPop, Object? _) {
            if (!didPop) close();
          },
          child: StatefulBuilder(
            builder: (BuildContext ctx, StateSetter setModalState) {
              return SafeArea(
                top: false,
                child: Padding(
                  padding: EdgeInsets.only(
                    bottom:
                        MediaQuery.of(ctx).viewInsets.bottom + AppSpacing.lg,
                    left: AppSpacing.lg,
                    right: AppSpacing.lg,
                  ),
                  child: Form(
                    key: formKey,
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          Text(
                            existing == null ? 'New goal' : 'Edit goal',
                            style: ctx.textStyles.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          AppSpacing.gapLg,
                          TextFormField(
                            controller: titleController,
                            autofocus: existing == null,
                            textCapitalization: TextCapitalization.sentences,
                            decoration: const InputDecoration(
                              labelText: 'Title',
                              hintText: 'Tuition, Laptop, Emergency fund',
                              border: OutlineInputBorder(
                                borderRadius: AppRadius.medium,
                              ),
                            ),
                            validator: (String? val) {
                              if (val == null || val.trim().isEmpty) {
                                return 'Enter a goal name';
                              }
                              return null;
                            },
                          ),
                          AppSpacing.gapMd,
                          TextFormField(
                            controller: targetController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            style: const TextStyle(fontFeatures: _tabular),
                            decoration: const InputDecoration(
                              labelText: 'Target amount (₱)',
                              prefixText: '₱ ',
                              border: OutlineInputBorder(
                                borderRadius: AppRadius.medium,
                              ),
                            ),
                            validator: validateAmount,
                          ),
                          AppSpacing.gapMd,
                          TextFormField(
                            controller: savedController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            style: const TextStyle(fontFeatures: _tabular),
                            decoration: const InputDecoration(
                              labelText: 'Already saved (₱)',
                              prefixText: '₱ ',
                              border: OutlineInputBorder(
                                borderRadius: AppRadius.medium,
                              ),
                            ),
                            validator: (String? val) {
                              final String raw = (val ?? '').trim();
                              if (raw.isEmpty) return null;
                              final double? parsed = double.tryParse(raw);
                              if (parsed == null ||
                                  parsed.isNaN ||
                                  parsed.isInfinite) {
                                return 'Enter a valid amount';
                              }
                              if (parsed < 0) {
                                return 'Amount cannot be negative';
                              }
                              if (parsed > maxAmount) {
                                return 'Amount can’t be more than ₱1,000,000';
                              }
                              return null;
                            },
                          ),
                          AppSpacing.gapMd,
                          Text(
                            'Target date (optional)',
                            style: ctx.textStyles.labelMedium?.copyWith(
                              color: ctx.colors.onSurfaceVariant,
                            ),
                          ),
                          AppSpacing.gapXs,
                          Wrap(
                            spacing: AppSpacing.sm,
                            runSpacing: AppSpacing.xs,
                            children: <Widget>[
                              ChoiceChip(
                                label: const Text('None'),
                                selected: targetDate == null,
                                onSelected: (_) =>
                                    setModalState(() => targetDate = null),
                              ),
                              ChoiceChip(
                                label: Text(
                                  targetDate != null
                                      ? DateFormat(
                                          'MMM d, yyyy',
                                        ).format(targetDate!)
                                      : 'Pick date',
                                  style: const TextStyle(
                                    fontFeatures: _tabular,
                                  ),
                                ),
                                selected: targetDate != null,
                                onSelected: (_) async {
                                  final DateTime? picked = await showDatePicker(
                                    context: ctx,
                                    initialDate: targetDate ?? today,
                                    firstDate: DateTime(2020),
                                    lastDate: DateTime(2035),
                                  );
                                  if (picked != null) {
                                    setModalState(
                                      () => targetDate = goalDateOnly(picked),
                                    );
                                  }
                                },
                              ),
                            ],
                          ),
                          AppSpacing.gapXl,
                          SizedBox(
                            height: AppSizes.buttonHeight,
                            child: FilledButton(
                              onPressed: () {
                                if (!formKey.currentState!.validate()) return;
                                final String cleanTitle =
                                    titleController.text.trim();
                                final int targetCents = (double.parse(
                                          targetController.text.trim(),
                                        ) *
                                        100)
                                    .round();
                                final String savedRaw =
                                    savedController.text.trim();
                                final int savedCents = savedRaw.isEmpty
                                    ? 0
                                    : (double.parse(savedRaw) * 100).round();
                                final String? dateKey = targetDate == null
                                    ? null
                                    : formatGoalDateKey(targetDate!);
                                final GoalsController controller = ref.read(
                                  goalsControllerProvider.notifier,
                                );
                                if (existing == null) {
                                  controller.addGoal(
                                    SavingsGoal(
                                      id: 0,
                                      title: cleanTitle,
                                      targetCents: targetCents,
                                      savedCents: savedCents,
                                      targetDate: dateKey,
                                      createdAt: DateTime.now(),
                                    ),
                                  );
                                } else {
                                  controller.updateGoal(
                                    existing.copyWith(
                                      title: cleanTitle,
                                      targetCents: targetCents,
                                      savedCents: savedCents,
                                      targetDate: dateKey,
                                      clearTargetDate: dateKey == null,
                                    ),
                                  );
                                }
                                Navigator.pop(ctx);
                              },
                              child: Text(
                                existing == null ? 'Save goal' : 'Save changes',
                              ),
                            ),
                          ),
                          TextButton(
                            style: TextButton.styleFrom(
                              minimumSize: const Size.fromHeight(
                                AppSizes.minTouchTarget,
                              ),
                            ),
                            onPressed: close,
                            child: const Text('Cancel'),
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
                              label: const Text('Delete goal'),
                              onPressed: () async {
                                final bool deleted = await _confirmDeleteGoal(
                                  ctx,
                                  ref,
                                  existing,
                                );
                                if (deleted && ctx.mounted) {
                                  Navigator.pop(ctx);
                                }
                              },
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      );
    },
  );
}

/// Dialog to deposit into or withdraw from a [SavingsGoal].
Future<void> showAdjustGoalDialog(
  BuildContext context,
  WidgetRef ref, {
  required SavingsGoal goal,
  required bool deposit,
}) async {
  final int? deltaCents = await showDialog<int>(
    context: context,
    builder: (BuildContext ctx) =>
        _AdjustGoalDialog(goal: goal, deposit: deposit),
  );
  if (deltaCents == null || deltaCents == 0) return;
  await ref
      .read(goalsControllerProvider.notifier)
      .adjustSaved(goal.id, deltaCents);
}

class _AdjustGoalDialog extends StatefulWidget {
  const _AdjustGoalDialog({required this.goal, required this.deposit});

  final SavingsGoal goal;
  final bool deposit;

  @override
  State<_AdjustGoalDialog> createState() => _AdjustGoalDialogState();
}

class _AdjustGoalDialogState extends State<_AdjustGoalDialog> {
  final TextEditingController _amount = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  void _setAmountCents(int cents) {
    setState(() {
      _amount.text = _formatAmountInput(cents / 100);
      _error = null;
    });
  }

  void _submit() {
    final String? problem = validateAmount(_amount.text);
    if (problem != null) {
      setState(() => _error = problem);
      return;
    }
    final int cents = (double.parse(_amount.text.trim()) * 100).round();
    if (!widget.deposit && cents > widget.goal.savedCents) {
      setState(() => _error = 'Exceeds saved balance');
      return;
    }
    Navigator.pop(context, widget.deposit ? cents : -cents);
  }

  @override
  Widget build(BuildContext context) {
    final List<int> quickPesos = <int>[50, 100, 500];
    return AlertDialog(
      title: Text(
        widget.deposit
            ? 'Deposit to ${widget.goal.title}'
            : 'Withdraw from ${widget.goal.title}',
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              'Current: ${_peso.format(widget.goal.savedAmount)} of '
              '${_peso.format(widget.goal.targetAmount)}',
              style: context.textStyles.bodySmall?.copyWith(
                color: context.colors.onSurfaceVariant,
                fontFeatures: _tabular,
              ),
            ),
            AppSpacing.gapMd,
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              children: <Widget>[
                for (final int pesos in quickPesos)
                  ActionChip(
                    label: Text(
                      '₱$pesos',
                      style: const TextStyle(fontFeatures: _tabular),
                    ),
                    onPressed: () => _setAmountCents(pesos * 100),
                  ),
                if (!widget.deposit && widget.goal.savedCents > 0)
                  ActionChip(
                    label: const Text('All'),
                    onPressed: () => _setAmountCents(widget.goal.savedCents),
                  ),
              ],
            ),
            AppSpacing.gapMd,
            TextField(
              controller: _amount,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              style: const TextStyle(fontFeatures: _tabular),
              decoration: InputDecoration(
                labelText: 'Amount (₱)',
                prefixText: '₱ ',
                errorText: _error,
                border: const OutlineInputBorder(
                  borderRadius: AppRadius.medium,
                ),
              ),
              onChanged: (_) {
                if (_error != null) setState(() => _error = null);
              },
              onSubmitted: (_) => _submit(),
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(widget.deposit ? 'Add' : 'Take'),
        ),
      ],
    );
  }
}
