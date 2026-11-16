import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import 'add_shift_sheet.dart';
import 'shift.dart';
import 'work_controller.dart';

const List<FontFeature> _tabular = <FontFeature>[FontFeature.tabularFigures()];

final NumberFormat _money = NumberFormat.currency(
  symbol: '₱',
  decimalDigits: 2,
);

String _pesos(int cents) => _money.format(cents / 100);

/// What the shifts worked so far should pay, and what is still ahead. The
/// figure is only an estimate of pay not yet received, so it stays out of
/// the balance until "I got paid" records the real amount.
class WorkPayCard extends ConsumerWidget {
  const WorkPayCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<Shift> shifts =
        ref.watch(workControllerProvider).value ?? const <Shift>[];
    final WorkSummary summary = WorkSummary.of(shifts, DateTime.now());
    final ColorScheme colors = context.colors;
    final TextTheme textStyles = context.textStyles;
    final ButtonStyle linkStyle = TextButton.styleFrom(
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
    );

    return Card(
      margin: EdgeInsets.zero,
      child: Container(
        width: double.infinity,
        padding: AppSpacing.card,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Work pay',
              style: textStyles.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            AppSpacing.gapXs,
            if (summary.isEmpty)
              Text(
                'Log your shifts to see what your next pay should be.',
                style: textStyles.bodyMedium,
              )
            else ...<Widget>[
              if (summary.workedMinutes == 0)
                Text(
                  'Nothing waiting to be paid.',
                  style: textStyles.bodyMedium,
                )
              else ...<Widget>[
                Text(
                  _pesos(summary.workedPayCents),
                  style: textStyles.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontFeatures: _tabular,
                  ),
                ),
                AppSpacing.gapXs,
                Text(
                  '${formatHours(summary.workedMinutes)} hrs worked, not paid '
                  'yet. Before deductions.',
                  style: textStyles.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                    fontFeatures: _tabular,
                  ),
                ),
              ],
              if (summary.upcomingMinutes > 0)
                Text(
                  '${formatHours(summary.upcomingMinutes)} hrs still to '
                  'work · ${_pesos(summary.upcomingPayCents)}',
                  style: textStyles.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                    fontFeatures: _tabular,
                  ),
                ),
            ],
            Wrap(
              spacing: AppSpacing.lg,
              children: <Widget>[
                TextButton(
                  style: linkStyle,
                  onPressed: () => addShift(context, ref),
                  child: const Text('Add a shift'),
                ),
                if (!summary.isEmpty)
                  TextButton(
                    style: linkStyle,
                    onPressed: () => showShiftsSheet(context),
                    child: const Text('Shifts'),
                  ),
                if (summary.workedMinutes > 0)
                  TextButton(
                    style: linkStyle,
                    onPressed: () async {
                      final double? amount = await showDialog<double>(
                        context: context,
                        builder: (BuildContext ctx) => _GotPaidDialog(
                          expectedCents: summary.workedPayCents,
                        ),
                      );
                      if (amount != null) {
                        await ref
                            .read(workControllerProvider.notifier)
                            .gotPaid(amount);
                      }
                    },
                    child: const Text('I got paid'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Asks what was actually received and compares it with the logged hours.
class _GotPaidDialog extends StatefulWidget {
  const _GotPaidDialog({required this.expectedCents});

  final int expectedCents;

  @override
  State<_GotPaidDialog> createState() => _GotPaidDialogState();
}

class _GotPaidDialogState extends State<_GotPaidDialog> {
  late final TextEditingController _amount = TextEditingController(
    text: widget.expectedCents == 0
        ? ''
        : (widget.expectedCents / 100).toStringAsFixed(2),
  );
  String? _error;

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  void _save() {
    final double? amount = double.tryParse(_amount.text.trim());
    if (amount == null || amount <= 0) {
      setState(() => _error = 'Enter the amount you received');
      return;
    }
    Navigator.pop(context, amount);
  }

  @override
  Widget build(BuildContext context) {
    final double? typed = double.tryParse(_amount.text.trim());
    final int difference = typed == null || widget.expectedCents == 0
        ? 0
        : (typed * 100).round() - widget.expectedCents;
    final String? compare = difference == 0
        ? null
        : '${_pesos(difference.abs())} '
              '${difference < 0 ? 'less' : 'more'} than your hours '
              '(${_pesos(widget.expectedCents)}).';

    return AlertDialog(
      title: const Text('I got paid'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'Enter what you received. It is added as income, and the shifts '
            'worked so far are marked paid.',
          ),
          AppSpacing.gapLg,
          TextField(
            controller: _amount,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(fontFeatures: _tabular),
            decoration: InputDecoration(
              labelText: 'Amount received',
              prefixText: '₱ ',
              errorText: _error,
              border: const OutlineInputBorder(),
            ),
            onChanged: (_) => setState(() => _error = null),
            onSubmitted: (_) => _save(),
          ),
          if (compare != null) ...<Widget>[
            AppSpacing.gapSm,
            Text(
              compare,
              style: context.textStyles.bodySmall?.copyWith(
                fontFeatures: _tabular,
              ),
            ),
          ],
        ],
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }
}

/// Lists the shifts that are not paid yet, so a day can be removed.
Future<void> showShiftsSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (BuildContext ctx) => const _ShiftsSheet(),
  );
}

class _ShiftsSheet extends ConsumerWidget {
  const _ShiftsSheet();

  Future<void> _delete(BuildContext context, WidgetRef ref, Shift shift) async {
    final bool inSeries = shift.seriesId != null;
    final bool? andLater = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: const Text('Remove this shift?'),
        content: Text(
          '${shift.job}, ${DateFormat('EEE, MMM d').format(shift.startsAt)}',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          if (inSeries)
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('This and later'),
            ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: ctx.colors.error,
              foregroundColor: ctx.colors.onError,
            ),
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(inSeries ? 'Only this' : 'Remove'),
          ),
        ],
      ),
    );
    if (andLater == null) return;
    await ref
        .read(workControllerProvider.notifier)
        .deleteShift(shift, andLater: andLater);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final DateTime now = DateTime.now();
    final List<Shift> unpaid = <Shift>[
      for (final Shift shift
          in ref.watch(workControllerProvider).value ?? const <Shift>[])
        if (!shift.paid) shift,
    ];
    final ColorScheme colors = context.colors;
    final TextTheme textStyles = context.textStyles;
    final DateFormat day = DateFormat('EEE, MMM d');
    final DateFormat time = DateFormat('h:mm a');

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              'Shifts not paid yet',
              style: textStyles.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            AppSpacing.gapSm,
            if (unpaid.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
                child: Text(
                  'Nothing waiting to be paid.',
                  style: textStyles.bodyMedium,
                ),
              )
            else
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: unpaid.length,
                  separatorBuilder: (_, _) =>
                      Divider(height: 1, color: colors.outlineVariant),
                  itemBuilder: (BuildContext ctx, int index) {
                    final Shift shift = unpaid[index];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        '${day.format(shift.startsAt)} · '
                        '${time.format(shift.startsAt)} – '
                        '${time.format(shift.endsAt)}',
                        style: textStyles.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          fontFeatures: _tabular,
                        ),
                      ),
                      subtitle: Text(
                        '${shift.job} · ${formatHours(shift.paidMinutes)} hrs'
                        '${shift.hourlyRateCents > 0 ? ' · ${_pesos(shift.payCents)}' : ''}'
                        '${shift.isWorked(now) ? '' : ' · still to work'}',
                        style: textStyles.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                          fontFeatures: _tabular,
                        ),
                      ),
                      trailing: IconButton(
                        icon: const Icon(
                          Icons.delete_outline_rounded,
                          size: 20,
                        ),
                        tooltip: 'Remove',
                        onPressed: () => _delete(context, ref, shift),
                      ),
                    );
                  },
                ),
              ),
            AppSpacing.gapLg,
          ],
        ),
      ),
    );
  }
}
