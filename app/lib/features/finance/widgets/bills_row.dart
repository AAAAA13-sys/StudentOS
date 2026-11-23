import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../work/payday.dart';
import '../amount_validation.dart';
import '../bill.dart';
import '../bills_controller.dart';
import '../finance_repository.dart';

const List<FontFeature> _tabular = <FontFeature>[FontFeature.tabularFigures()];

final NumberFormat _money = NumberFormat.currency(
  symbol: '₱',
  decimalDigits: 2,
);

/// Compact Finance row for recurring bills: shows due or next upcoming bill,
/// offers 1-tap logging when due, and opens [showBillsSheet] on tap.
class BillsRow extends ConsumerWidget {
  const BillsRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<Bill> bills =
        ref.watch(billsControllerProvider).value ?? const <Bill>[];
    final DateTime today = dateOnly(DateTime.now());
    final List<Bill> due = <Bill>[
      for (final Bill bill in bills)
        if (bill.isDueOnOrBefore(today)) bill,
    ];
    final List<Bill> active = <Bill>[
      for (final Bill bill in bills)
        if (bill.active) bill,
    ];

    final ColorScheme colors = context.colors;
    final TextTheme textStyles = context.textStyles;
    final TextStyle? baseSubtitle = textStyles.bodySmall?.copyWith(
      color: colors.onSurfaceVariant,
      fontFeatures: _tabular,
    );

    final Widget subtitle;
    final Widget trailing;

    if (due.length == 1) {
      final Bill bill = due.single;
      final bool overdue = bill.isOverdue(today);
      final String phrase = overdue ? billDuePhrase(bill, today) : 'due today';
      subtitle = Text(
        '${bill.title} · ${_money.format(bill.amount)} $phrase',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: baseSubtitle?.copyWith(
          color: overdue ? colors.error : colors.primary,
          fontWeight: FontWeight.w700,
        ),
      );
      trailing = TextButton(
        onPressed: () => _logOne(context, ref, bill),
        child: const Text('Log'),
      );
    } else if (due.length > 1) {
      final int totalCents = due.fold<int>(
        0,
        (int sum, Bill b) => sum + b.amountCents,
      );
      final bool anyOverdue = due.any((Bill b) => b.isOverdue(today));
      subtitle = Text(
        '${due.length} bills due · ${_money.format(totalCents / 100)}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: baseSubtitle?.copyWith(
          color: anyOverdue ? colors.error : colors.primary,
          fontWeight: FontWeight.w700,
        ),
      );
      trailing = TextButton(
        onPressed: () => _logAll(context, ref, due.length),
        child: const Text('Log all'),
      );
    } else if (active.isNotEmpty) {
      final Bill next = active.first;
      subtitle = Text(
        'Next: ${next.title} · ${_money.format(next.amount)} · '
        '${billDuePhrase(next, today)}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: baseSubtitle,
      );
      trailing = Icon(
        Icons.chevron_right_rounded,
        color: colors.onSurfaceVariant,
      );
    } else {
      subtitle = Text(
        bills.isEmpty ? 'No bills set' : '${bills.length} paused',
        style: baseSubtitle,
      );
      trailing = Icon(
        Icons.chevron_right_rounded,
        color: colors.onSurfaceVariant,
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md),
      child: Card(
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          minTileHeight: 56,
          onTap: () => showBillsSheet(context),
          leading: Icon(Icons.receipt_long_rounded, color: colors.primary),
          title: Text(
            'Recurring bills',
            style: textStyles.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          subtitle: subtitle,
          trailing: trailing,
        ),
      ),
    );
  }

  Future<void> _logOne(BuildContext context, WidgetRef ref, Bill bill) async {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    await ref.read(billsControllerProvider.notifier).logBill(bill);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 56 + 16 + 16),
          duration: const Duration(seconds: 2),
          content: Text('Logged ${bill.title} · ${_money.format(bill.amount)}'),
        ),
      );
  }

  Future<void> _logAll(BuildContext context, WidgetRef ref, int count) async {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    await ref.read(billsControllerProvider.notifier).logAllDue();
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 56 + 16 + 16),
          duration: const Duration(seconds: 2),
          content: Text('Logged $count bills'),
        ),
      );
  }
}

/// Lists all recurring bills sorted by `nextDueOn`, with 1-tap logging and
/// add/edit/delete actions.
Future<void> showBillsSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (BuildContext ctx) => const _BillsSheet(),
  );
}

class _BillsSheet extends ConsumerWidget {
  const _BillsSheet();

  Future<void> _delete(BuildContext context, WidgetRef ref, Bill bill) async {
    final bool confirmed = await confirmDestructive(
      context,
      title: 'Delete bill?',
      message: '${bill.title} (${_money.format(bill.amount)}) will be removed.',
    );
    if (!confirmed) return;
    await ref.read(billsControllerProvider.notifier).deleteBill(bill.id);
  }

  String _statusLine(Bill bill, DateTime today) {
    if (!bill.active) return 'Paused';
    final DateTime? due = bill.nextDueDate;
    if (due == null) return bill.nextDueOn;
    if (bill.isOverdue(today)) {
      return 'Overdue (${DateFormat('MMM d').format(due)})';
    }
    if (bill.isDueToday(today)) return 'Due today';
    return 'Next due ${DateFormat('MMM d, yyyy').format(due)}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<Bill> bills =
        ref.watch(billsControllerProvider).value ?? const <Bill>[];
    final DateTime today = dateOnly(DateTime.now());
    final ColorScheme colors = context.colors;
    final TextTheme textStyles = context.textStyles;

    return SafeArea(
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
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      'Recurring bills',
                      style: textStyles.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => _showBillEditorSheet(context, ref),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Add bill'),
                  ),
                ],
              ),
              if (bills.isEmpty) ...<Widget>[
                AppSpacing.gapMd,
                Text(
                  'No recurring bills yet. Add rent, wifi, or subscriptions to '
                  'log them when due.',
                  style: textStyles.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
                AppSpacing.gapLg,
                SizedBox(
                  height: AppSizes.buttonHeight,
                  child: FilledButton.icon(
                    onPressed: () => _showBillEditorSheet(context, ref),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Add bill'),
                  ),
                ),
              ] else
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: bills.length,
                    separatorBuilder: (BuildContext _, int _) =>
                        Divider(height: 1, color: colors.outlineVariant),
                    itemBuilder: (BuildContext ctx, int index) {
                      final Bill bill = bills[index];
                      final bool due = bill.isDueOnOrBefore(today);
                      final bool overdue = bill.isOverdue(today);
                      final Color statusColor = !bill.active
                          ? colors.onSurfaceVariant
                          : overdue
                          ? colors.error
                          : due
                          ? colors.primary
                          : colors.onSurfaceVariant;
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        minTileHeight: 56,
                        onTap: () =>
                            _showBillEditorSheet(context, ref, existing: bill),
                        title: Text(
                          bill.title,
                          style: textStyles.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: bill.active
                                ? colors.onSurface
                                : colors.onSurfaceVariant,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              '${_money.format(bill.amount)} · ${bill.category} · '
                              '${describeBillCadence(bill.cadence)}',
                              style: textStyles.bodySmall?.copyWith(
                                color: colors.onSurfaceVariant,
                                fontFeatures: _tabular,
                              ),
                            ),
                            Text(
                              '${_statusLine(bill, today)}'
                              '${bill.autoLog ? ' · auto-log' : ''}',
                              style: textStyles.bodySmall?.copyWith(
                                color: statusColor,
                                fontWeight: due ? FontWeight.w700 : null,
                                fontFeatures: _tabular,
                              ),
                            ),
                          ],
                        ),
                        trailing: due
                            ? TextButton(
                                onPressed: () => ref
                                    .read(billsControllerProvider.notifier)
                                    .logBill(bill),
                                child: const Text('Log'),
                              )
                            : IconButton(
                                icon: const Icon(
                                  Icons.delete_outline_rounded,
                                  size: 20,
                                ),
                                tooltip: 'Delete',
                                onPressed: () => _delete(context, ref, bill),
                              ),
                      );
                    },
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

Future<void> _showBillEditorSheet(
  BuildContext context,
  WidgetRef ref, {
  Bill? existing,
}) {
  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (BuildContext ctx) => _BillEditorSheet(existing: existing),
  );
}

class _BillEditorSheet extends ConsumerStatefulWidget {
  const _BillEditorSheet({this.existing});

  final Bill? existing;

  @override
  ConsumerState<_BillEditorSheet> createState() => _BillEditorSheetState();
}

class _BillEditorSheetState extends ConsumerState<_BillEditorSheet> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _amountController;
  late final DateTime _today;
  late String _category;
  late PaydayKind _kind;
  late int _weekday;
  late int _monthDay;
  late DateTime _nextDue;
  late bool _customDatePicked;
  late bool _active;
  late bool _autoLog;

  @override
  void initState() {
    super.initState();
    final Bill? existing = widget.existing;
    _today = dateOnly(DateTime.now());
    _titleController = TextEditingController(text: existing?.title ?? '');
    _amountController = TextEditingController(
      text: existing == null
          ? ''
          : existing.amount.toStringAsFixed(
              existing.amount == existing.amount.roundToDouble() ? 0 : 2,
            ),
    );
    String category = existing?.category ?? 'Other';
    if (!FinanceRepository.categories.contains(category)) {
      category = 'Other';
    }
    _category = category;

    final PaydaySchedule initialSchedule =
        existing?.schedule ?? PaydaySchedule.none;
    _kind = initialSchedule.isSet ? initialSchedule.kind : PaydayKind.monthly;
    _weekday = initialSchedule.kind == PaydayKind.weekly
        ? initialSchedule.day
        : _today.weekday;
    _monthDay = initialSchedule.kind == PaydayKind.monthly
        ? initialSchedule.day
        : _today.day;
    _nextDue =
        existing?.nextDueDate ?? nextPayday(_buildSchedule(), _today) ?? _today;
    _customDatePicked = existing != null;
    _active = existing?.active ?? true;
    _autoLog = existing?.autoLog ?? false;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  PaydaySchedule _buildSchedule() => switch (_kind) {
    PaydayKind.none => PaydaySchedule.monthly(_monthDay),
    PaydayKind.weekly => PaydaySchedule.weekly(_weekday),
    PaydayKind.semimonthly => PaydaySchedule.semimonthly,
    PaydayKind.monthly => PaydaySchedule.monthly(_monthDay),
  };

  void _syncDefaultDue() {
    if (!_customDatePicked) {
      _nextDue = nextPayday(_buildSchedule(), _today) ?? _today;
    }
  }

  @override
  Widget build(BuildContext context) {
    final Bill? existing = widget.existing;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: AppSpacing.lg,
          right: AppSpacing.lg,
        ),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(
                  existing == null ? 'New bill' : 'Edit bill',
                  style: context.textStyles.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                AppSpacing.gapLg,
                TextFormField(
                  controller: _titleController,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    hintText: 'Rent, Wifi, Load',
                    border: OutlineInputBorder(borderRadius: AppRadius.medium),
                  ),
                  validator: (String? val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Enter a title';
                    }
                    return null;
                  },
                ),
                AppSpacing.gapMd,
                TextFormField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  style: const TextStyle(fontFeatures: _tabular),
                  decoration: const InputDecoration(
                    labelText: 'Amount (₱)',
                    prefixText: '₱ ',
                    border: OutlineInputBorder(borderRadius: AppRadius.medium),
                  ),
                  validator: validateAmount,
                ),
                AppSpacing.gapMd,
                DropdownButtonFormField<String>(
                  initialValue: _category,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(borderRadius: AppRadius.medium),
                  ),
                  items: FinanceRepository.categories
                      .map(
                        (String c) => DropdownMenuItem<String>(
                          value: c,
                          child: Text(c),
                        ),
                      )
                      .toList(),
                  onChanged: (String? val) {
                    if (val != null) {
                      setState(() => _category = val);
                    }
                  },
                ),
                AppSpacing.gapMd,
                Text(
                  'Cadence',
                  style: context.textStyles.labelLarge?.copyWith(
                    color: context.colors.onSurfaceVariant,
                  ),
                ),
                AppSpacing.gapXs,
                SegmentedButton<PaydayKind>(
                  segments: const <ButtonSegment<PaydayKind>>[
                    ButtonSegment<PaydayKind>(
                      value: PaydayKind.weekly,
                      label: Text('Weekly'),
                    ),
                    ButtonSegment<PaydayKind>(
                      value: PaydayKind.semimonthly,
                      label: Text('15th & end'),
                    ),
                    ButtonSegment<PaydayKind>(
                      value: PaydayKind.monthly,
                      label: Text('Monthly'),
                    ),
                  ],
                  selected: <PaydayKind>{_kind},
                  onSelectionChanged: (Set<PaydayKind> selection) {
                    setState(() {
                      _kind = selection.first;
                      _syncDefaultDue();
                    });
                  },
                ),
                if (_kind == PaydayKind.weekly) ...<Widget>[
                  AppSpacing.gapSm,
                  Wrap(
                    spacing: AppSpacing.sm,
                    children: <Widget>[
                      for (int d = 1; d <= 7; d++)
                        ChoiceChip(
                          label: Text(weekdayName(d).substring(0, 3)),
                          selected: _weekday == d,
                          onSelected: (_) => setState(() {
                            _weekday = d;
                            _syncDefaultDue();
                          }),
                        ),
                    ],
                  ),
                ],
                if (_kind == PaydayKind.monthly) ...<Widget>[
                  AppSpacing.gapSm,
                  DropdownButtonFormField<int>(
                    initialValue: _monthDay,
                    decoration: const InputDecoration(
                      labelText: 'Day of the month',
                      border: OutlineInputBorder(
                        borderRadius: AppRadius.medium,
                      ),
                    ),
                    items: <DropdownMenuItem<int>>[
                      for (int d = 1; d <= 31; d++)
                        DropdownMenuItem<int>(value: d, child: Text('$d')),
                    ],
                    onChanged: (int? v) {
                      if (v != null) {
                        setState(() {
                          _monthDay = v;
                          _syncDefaultDue();
                        });
                      }
                    },
                  ),
                ],
                AppSpacing.gapMd,
                OutlinedButton.icon(
                  onPressed: () async {
                    final DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: _nextDue,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2035),
                    );
                    if (picked != null) {
                      setState(() {
                        _nextDue = dateOnly(picked);
                        _customDatePicked = true;
                      });
                    }
                  },
                  icon: const Icon(Icons.calendar_today_rounded, size: 18),
                  label: Text(
                    'Next due: ${DateFormat('MMM d, yyyy').format(_nextDue)}',
                    style: const TextStyle(fontFeatures: _tabular),
                  ),
                ),
                AppSpacing.gapSm,
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Active'),
                  subtitle: const Text('Surface when due'),
                  value: _active,
                  onChanged: (bool value) => setState(() => _active = value),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Auto-log when due'),
                  subtitle: const Text(
                    'Record expense automatically when Finance opens',
                  ),
                  value: _autoLog,
                  onChanged: (bool value) => setState(() => _autoLog = value),
                ),
                AppSpacing.gapLg,
                SizedBox(
                  height: AppSizes.buttonHeight,
                  child: FilledButton(
                    onPressed: () async {
                      if (!_formKey.currentState!.validate()) return;
                      final int amountCents =
                          (double.parse(_amountController.text.trim()) * 100)
                              .round();
                      final Bill bill = Bill(
                        id: existing?.id ?? 0,
                        title: _titleController.text.trim(),
                        amountCents: amountCents,
                        category: _category,
                        cadence: _buildSchedule().serialize(),
                        nextDueOn: formatDateKey(_nextDue),
                        active: _active,
                        autoLog: _autoLog,
                      );
                      final BillsController controller = ref.read(
                        billsControllerProvider.notifier,
                      );
                      if (existing == null) {
                        await controller.addBill(bill);
                      } else {
                        await controller.updateBill(bill);
                      }
                      if (context.mounted) Navigator.pop(context);
                    },
                    child: Text(existing == null ? 'Add bill' : 'Save changes'),
                  ),
                ),
                if (existing != null)
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      foregroundColor: context.colors.error,
                      minimumSize: const Size.fromHeight(
                        AppSizes.minTouchTarget,
                      ),
                    ),
                    icon: const Icon(Icons.delete_outline_rounded),
                    label: const Text('Delete bill'),
                    onPressed: () async {
                      final bool confirmed = await confirmDestructive(
                        context,
                        title: 'Delete bill?',
                        message:
                            '${existing.title} (${_money.format(existing.amount)}) '
                            'will be removed.',
                      );
                      if (!confirmed) return;
                      await ref
                          .read(billsControllerProvider.notifier)
                          .deleteBill(existing.id);
                      if (context.mounted) Navigator.pop(context);
                    },
                  ),
                AppSpacing.gapLg,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
