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
import '../iou_item.dart';
import '../ious_controller.dart';

const List<FontFeature> _tabular = <FontFeature>[FontFeature.tabularFigures()];

final NumberFormat _peso = NumberFormat.currency(symbol: '₱', decimalDigits: 2);

String _formatAmountInput(double amount) =>
    amount.toStringAsFixed(amount == amount.roundToDouble() ? 0 : 2);

/// IOUs & splits ledger view inside `Finance > IOUs`.
///
/// Open IOUs stay strictly separate from personal `Transactions`, monthly
/// balance, Safe-to-Spend, and `MoneyWidgetSync` unless explicitly logged in
/// Cashflow on settlement.
class IousPanel extends ConsumerStatefulWidget {
  const IousPanel({super.key});

  @override
  ConsumerState<IousPanel> createState() => _IousPanelState();
}

class _IousPanelState extends ConsumerState<IousPanel> {
  IouFilter _filter = IouFilter.open;

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<IouItem>> iousAsync = ref.watch(
      iousControllerProvider,
    );
    final ColorScheme colors = context.colors;
    final TextTheme textStyles = context.textStyles;
    final List<IouItem>? allItems = iousAsync.value;
    final List<IouItem> filtered = allItems == null
        ? const <IouItem>[]
        : _applyFilter(allItems, _filter);

    return Column(
      children: <Widget>[
        _filterRow(),
        PonponTalkSlot(
          surface: PonponSurface.finance,
          suppress: allItems == null || filtered.isEmpty,
        ),
        Expanded(
          child: iousAsync.when(
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
                  const Text('Couldn’t load your IOUs.'),
                  AppSpacing.gapLg,
                  FilledButton(
                    onPressed: () =>
                        ref.read(iousControllerProvider.notifier).refresh(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
            data: (List<IouItem> items) {
              if (filtered.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xl,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Ponpon(
                          mood: _filter == IouFilter.open
                              ? PonponMood.happy
                              : PonponMood.sleepy,
                          size: 88,
                        ),
                        AppSpacing.gapMd,
                        Text(
                          _emptyTitle(_filter),
                          textAlign: TextAlign.center,
                          style: textStyles.titleMedium?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                        if (_filter == IouFilter.open) ...<Widget>[
                          AppSpacing.gapXs,
                          Text(
                            'Track who owes you or who you owe, separate from Cashflow.',
                            textAlign: TextAlign.center,
                            style: textStyles.bodySmall?.copyWith(
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }

              int owedCents = 0;
              int owingCents = 0;
              for (final IouItem item in items) {
                if (item.settled) continue;
                if (item.direction == IouDirection.owed) {
                  owedCents += item.amountCents;
                } else {
                  owingCents += item.amountCents;
                }
              }

              return RefreshIndicator(
                onRefresh: () =>
                    ref.read(iousControllerProvider.notifier).refresh(),
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.sm,
                    AppSpacing.lg,
                    96,
                  ),
                  itemCount: filtered.length + 1,
                  separatorBuilder: (_, _) => AppSpacing.gapMd,
                  itemBuilder: (BuildContext context, int index) {
                    if (index == 0) {
                      return _IouSummaryCard(
                        owedCents: owedCents,
                        owingCents: owingCents,
                      );
                    }
                    return _IouCard(item: filtered[index - 1]);
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _filterRow() {
    const List<(IouFilter, String)> options = <(IouFilter, String)>[
      (IouFilter.open, 'Open'),
      (IouFilter.owed, 'Owed to me'),
      (IouFilter.owing, 'I owe'),
      (IouFilter.settled, 'Settled'),
    ];
    return SizedBox(
      height: 48,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        scrollDirection: Axis.horizontal,
        itemCount: options.length,
        separatorBuilder: (_, _) => AppSpacing.gapSm,
        itemBuilder: (BuildContext ctx, int index) {
          final (IouFilter value, String label) = options[index];
          return FilterChip(
            showCheckmark: false,
            label: Text(label),
            selected: _filter == value,
            onSelected: (_) => setState(() => _filter = value),
          );
        },
      ),
    );
  }

  static List<IouItem> _applyFilter(List<IouItem> items, IouFilter filter) {
    return switch (filter) {
      IouFilter.open => items.where((IouItem i) => !i.settled).toList(),
      IouFilter.owed => items
          .where((IouItem i) => !i.settled && i.direction == IouDirection.owed)
          .toList(),
      IouFilter.owing => items
          .where((IouItem i) => !i.settled && i.direction == IouDirection.owing)
          .toList(),
      IouFilter.settled => items.where((IouItem i) => i.settled).toList(),
    };
  }

  static String _emptyTitle(IouFilter filter) => switch (filter) {
    IouFilter.open => 'No open IOUs',
    IouFilter.owed => 'No one owes you right now',
    IouFilter.owing => 'You do not owe anyone',
    IouFilter.settled => 'No settled IOUs yet',
  };
}

class _IouSummaryCard extends StatelessWidget {
  const _IouSummaryCard({
    required this.owedCents,
    required this.owingCents,
  });

  final int owedCents;
  final int owingCents;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = context.colors;
    final TextTheme textStyles = context.textStyles;
    final ModuleColors money = context.moduleColors;

    final int netCents = owedCents - owingCents;
    final String netText = netCents > 0
        ? '+${_peso.format(netCents / 100)}'
        : netCents < 0
        ? '-${_peso.format((-netCents) / 100)}'
        : _peso.format(0);
    final Color netColor = netCents > 0
        ? money.income
        : netCents < 0
        ? colors.error
        : colors.primary;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: AppSpacing.card,
        child: Row(
          children: <Widget>[
            Expanded(
              child: _SummaryColumn(
                label: 'Owed to you',
                value: _peso.format(owedCents / 100),
                color: money.income,
                textStyles: textStyles,
                colors: colors,
              ),
            ),
            Expanded(
              child: _SummaryColumn(
                label: 'You owe',
                value: _peso.format(owingCents / 100),
                color: colors.error,
                textStyles: textStyles,
                colors: colors,
              ),
            ),
            Expanded(
              child: _SummaryColumn(
                label: 'Net',
                value: netText,
                color: netColor,
                textStyles: textStyles,
                colors: colors,
                alignEnd: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryColumn extends StatelessWidget {
  const _SummaryColumn({
    required this.label,
    required this.value,
    required this.color,
    required this.textStyles,
    required this.colors,
    this.alignEnd = false,
  });

  final String label;
  final String value;
  final Color color;
  final TextTheme textStyles;
  final ColorScheme colors;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: alignEnd
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: textStyles.labelSmall?.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),
        AppSpacing.gapXs,
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: textStyles.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            fontFeatures: _tabular,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _IouCard extends ConsumerWidget {
  const _IouCard({required this.item});

  final IouItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ColorScheme colors = context.colors;
    final TextTheme textStyles = context.textStyles;
    final ModuleColors money = context.moduleColors;
    final bool isOwed = item.direction == IouDirection.owed;
    final Color dirColor = isOwed ? money.income : colors.error;
    final String dateText = DateFormat('MMM d').format(item.occurredOnDate);
    final String? cleanNote = item.note?.trim();
    final String subtitle = (cleanNote != null && cleanNote.isNotEmpty)
        ? '${item.direction.label} · $dateText · $cleanNote'
        : '${item.direction.label} · $dateText';

    final TextDecoration? strike = item.settled
        ? TextDecoration.lineThrough
        : null;

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => showIouEditor(context, ref, existing: item),
        onLongPress: () => _confirmDeleteIou(context, ref, item),
        child: Padding(
          padding: AppSpacing.card,
          child: Row(
            children: <Widget>[
              Expanded(
                child: Opacity(
                  opacity: item.settled ? 0.6 : 1.0,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              item.person,
                              style: textStyles.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                decoration: strike,
                              ),
                            ),
                          ),
                          AppSpacing.gapSm,
                          Text(
                            _peso.format(item.amount),
                            style: textStyles.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontFeatures: _tabular,
                              color: dirColor,
                              decoration: strike,
                            ),
                          ),
                        ],
                      ),
                      AppSpacing.gapXs,
                      Row(
                        children: <Widget>[
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm,
                              vertical: AppSpacing.xxs,
                            ),
                            decoration: BoxDecoration(
                              color: dirColor.withValues(alpha: 0.12),
                              borderRadius: AppRadius.pill,
                            ),
                            child: Text(
                              item.direction.label,
                              style: textStyles.labelSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: dirColor,
                              ),
                            ),
                          ),
                          AppSpacing.gapSm,
                          Expanded(
                            child: Text(
                              subtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: textStyles.bodySmall?.copyWith(
                                color: colors.onSurfaceVariant,
                                decoration: strike,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              AppSpacing.gapSm,
              if (item.settled)
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, AppSizes.minTouchTarget),
                  ),
                  onPressed: () =>
                      ref.read(iousControllerProvider.notifier).reopenIou(item),
                  child: const Text('Reopen'),
                )
              else
                FilledButton.tonal(
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, AppSizes.minTouchTarget),
                  ),
                  onPressed: () => _showSettleDialog(context, ref, item),
                  child: const Text('Settle'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<bool> _confirmDeleteIou(
  BuildContext context,
  WidgetRef ref,
  IouItem item,
) async {
  final bool confirmed = await confirmDestructive(
    context,
    title: 'Delete IOU?',
    message:
        '${item.person} (${item.direction.label} ${_peso.format(item.amount)}) '
        'will be removed.',
  );
  if (confirmed) {
    await ref.read(iousControllerProvider.notifier).deleteIou(item.id);
  }
  return confirmed;
}

Future<void> _showSettleDialog(
  BuildContext context,
  WidgetRef ref,
  IouItem item,
) async {
  final bool? logInCashflow = await showDialog<bool>(
    context: context,
    builder: (BuildContext ctx) => _SettleIouDialog(item: item),
  );
  if (logInCashflow == null) return;
  await ref
      .read(iousControllerProvider.notifier)
      .settleIou(item, logInCashflow: logInCashflow);
}

class _SettleIouDialog extends StatefulWidget {
  const _SettleIouDialog({required this.item});

  final IouItem item;

  @override
  State<_SettleIouDialog> createState() => _SettleIouDialogState();
}

class _SettleIouDialogState extends State<_SettleIouDialog> {
  bool _logInCashflow = false;

  @override
  Widget build(BuildContext context) {
    final bool isOwed = widget.item.direction == IouDirection.owed;
    final String amountText = _peso.format(widget.item.amount);
    return AlertDialog(
      title: Text('Settle with ${widget.item.person}?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            '${widget.item.direction.label} $amountText.',
            style: context.textStyles.bodyMedium?.copyWith(
              fontFeatures: _tabular,
            ),
          ),
          AppSpacing.gapMd,
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Record in Cashflow'),
            subtitle: Text(
              isOwed
                  ? 'Add $amountText as income today'
                  : 'Add $amountText as expense today',
            ),
            value: _logInCashflow,
            onChanged: (bool value) => setState(() => _logInCashflow = value),
          ),
        ],
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _logInCashflow),
          child: const Text('Settle'),
        ),
      ],
    );
  }
}

/// Opens a modal bottom sheet to create or edit an [IouItem], with an optional
/// split calculator that fills the per-person share into `Amount (₱)`.
Future<void> showIouEditor(
  BuildContext context,
  WidgetRef ref, {
  IouItem? existing,
}) async {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController personController = TextEditingController(
    text: existing?.person ?? '',
  );
  final TextEditingController amountController = TextEditingController(
    text: existing == null ? '' : _formatAmountInput(existing.amount),
  );
  final TextEditingController noteController = TextEditingController(
    text: existing?.note ?? '',
  );
  final TextEditingController totalBillController = TextEditingController();
  final TextEditingController splitWaysController = TextEditingController(
    text: '2',
  );

  final DateTime now = DateTime.now();
  final DateTime today = DateTime(now.year, now.month, now.day);
  IouDirection direction = existing?.direction ?? IouDirection.owed;
  DateTime occurredOn = existing?.occurredOnDate ?? today;
  bool splitEnabled = false;

  final IouDirection startDirection = direction;
  final String startPerson = personController.text;
  final String startAmount = amountController.text;
  final String startNote = noteController.text;
  final DateTime startDate = occurredOn;

  bool isDirty() =>
      direction != startDirection ||
      personController.text != startPerson ||
      amountController.text != startAmount ||
      noteController.text != startNote ||
      occurredOn != startDate ||
      splitEnabled;

  void recomputeSplit() {
    final double? total = double.tryParse(totalBillController.text.trim());
    final int? ways = int.tryParse(splitWaysController.text.trim());
    if (total == null || total.isNaN || total.isInfinite || total <= 0) {
      return;
    }
    if (ways == null || ways < 1) return;
    final int totalCents = (total * 100).round();
    final int shareCents = splitShareCents(totalCents, ways);
    amountController.text = _formatAmountInput(shareCents / 100);
  }

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
            message: 'What you entered for this IOU will be lost.',
            confirmLabel: 'Discard',
          );
          if (!discard) return;
        }
        if (ctx.mounted) Navigator.pop(ctx);
      }

      return ListenableBuilder(
        listenable: Listenable.merge(<Listenable>[
          personController,
          amountController,
          noteController,
          totalBillController,
          splitWaysController,
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
                            existing == null ? 'New IOU' : 'Edit IOU',
                            style: ctx.textStyles.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          AppSpacing.gapLg,
                          SegmentedButton<IouDirection>(
                            showSelectedIcon: false,
                            segments: const <ButtonSegment<IouDirection>>[
                              ButtonSegment<IouDirection>(
                                value: IouDirection.owed,
                                label: Text('Owes me'),
                              ),
                              ButtonSegment<IouDirection>(
                                value: IouDirection.owing,
                                label: Text('I owe'),
                              ),
                            ],
                            selected: <IouDirection>{direction},
                            onSelectionChanged: (Set<IouDirection> next) =>
                                setModalState(() => direction = next.first),
                          ),
                          AppSpacing.gapMd,
                          TextFormField(
                            controller: personController,
                            autofocus: existing == null,
                            textCapitalization: TextCapitalization.words,
                            decoration: const InputDecoration(
                              labelText: 'Person',
                              hintText: 'Sam, Alex, Groupmate',
                              border: OutlineInputBorder(
                                borderRadius: AppRadius.medium,
                              ),
                            ),
                            validator: (String? val) {
                              if (val == null || val.trim().isEmpty) {
                                return 'Enter a name';
                              }
                              return null;
                            },
                          ),
                          AppSpacing.gapSm,
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Split a total'),
                            subtitle: const Text(
                              'Compute each share from a group bill',
                            ),
                            value: splitEnabled,
                            onChanged: (bool value) {
                              setModalState(() {
                                splitEnabled = value;
                                if (value) recomputeSplit();
                              });
                            },
                          ),
                          if (splitEnabled) ...<Widget>[
                            AppSpacing.gapSm,
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Expanded(
                                  flex: 3,
                                  child: TextFormField(
                                    controller: totalBillController,
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                          decimal: true,
                                        ),
                                    style: const TextStyle(
                                      fontFeatures: _tabular,
                                    ),
                                    decoration: const InputDecoration(
                                      labelText: 'Total bill (₱)',
                                      prefixText: '₱ ',
                                      border: OutlineInputBorder(
                                        borderRadius: AppRadius.medium,
                                      ),
                                    ),
                                    onChanged: (_) => recomputeSplit(),
                                  ),
                                ),
                                AppSpacing.gapSm,
                                Expanded(
                                  flex: 2,
                                  child: TextFormField(
                                    controller: splitWaysController,
                                    keyboardType: TextInputType.number,
                                    style: const TextStyle(
                                      fontFeatures: _tabular,
                                    ),
                                    decoration: const InputDecoration(
                                      labelText: 'Split ways',
                                      border: OutlineInputBorder(
                                        borderRadius: AppRadius.medium,
                                      ),
                                    ),
                                    onChanged: (_) => recomputeSplit(),
                                  ),
                                ),
                              ],
                            ),
                          ],
                          AppSpacing.gapMd,
                          TextFormField(
                            controller: amountController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            style: const TextStyle(fontFeatures: _tabular),
                            decoration: const InputDecoration(
                              labelText: 'Amount (₱)',
                              prefixText: '₱ ',
                              border: OutlineInputBorder(
                                borderRadius: AppRadius.medium,
                              ),
                            ),
                            validator: validateAmount,
                          ),
                          AppSpacing.gapMd,
                          TextFormField(
                            controller: noteController,
                            textCapitalization: TextCapitalization.sentences,
                            decoration: const InputDecoration(
                              labelText: 'Note (optional)',
                              hintText: 'Lunch, Photocopier, Grab',
                              border: OutlineInputBorder(
                                borderRadius: AppRadius.medium,
                              ),
                            ),
                          ),
                          AppSpacing.gapMd,
                          Text(
                            'Date',
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
                                label: const Text('Today'),
                                selected: occurredOn == today,
                                onSelected: (_) =>
                                    setModalState(() => occurredOn = today),
                              ),
                              ChoiceChip(
                                label: Text(
                                  occurredOn != today
                                      ? DateFormat(
                                          'MMM d, yyyy',
                                        ).format(occurredOn)
                                      : 'Pick date',
                                  style: const TextStyle(
                                    fontFeatures: _tabular,
                                  ),
                                ),
                                selected: occurredOn != today,
                                onSelected: (_) async {
                                  final DateTime? picked = await showDatePicker(
                                    context: ctx,
                                    initialDate: occurredOn,
                                    firstDate: DateTime(2020),
                                    lastDate: DateTime(2035),
                                  );
                                  if (picked != null) {
                                    setModalState(
                                      () => occurredOn = DateTime(
                                        picked.year,
                                        picked.month,
                                        picked.day,
                                      ),
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
                                final String cleanPerson =
                                    personController.text.trim();
                                final int amountCents = (double.parse(
                                          amountController.text.trim(),
                                        ) *
                                        100)
                                    .round();
                                final String cleanNote =
                                    noteController.text.trim();
                                final String dateKey =
                                    formatIouDateKey(occurredOn);
                                final IousController controller = ref.read(
                                  iousControllerProvider.notifier,
                                );
                                if (existing == null) {
                                  controller.addIou(
                                    IouItem(
                                      id: 0,
                                      person: cleanPerson,
                                      direction: direction,
                                      amountCents: amountCents,
                                      note: cleanNote.isEmpty
                                          ? null
                                          : cleanNote,
                                      occurredOn: dateKey,
                                      createdAt: DateTime.now(),
                                    ),
                                  );
                                } else {
                                  controller.updateIou(
                                    existing.copyWith(
                                      person: cleanPerson,
                                      direction: direction,
                                      amountCents: amountCents,
                                      note: cleanNote.isEmpty
                                          ? null
                                          : cleanNote,
                                      clearNote: cleanNote.isEmpty,
                                      occurredOn: dateKey,
                                    ),
                                  );
                                }
                                Navigator.pop(ctx);
                              },
                              child: Text(
                                existing == null ? 'Save IOU' : 'Save changes',
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
                              label: const Text('Delete IOU'),
                              onPressed: () async {
                                final bool deleted = await _confirmDeleteIou(
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
