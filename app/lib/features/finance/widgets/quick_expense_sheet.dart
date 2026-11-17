import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../amount_validation.dart';
import '../quick_again.dart';

/// What the quick sheet was closed with.
sealed class QuickExpenseResult {
  const QuickExpenseResult();
}

class QuickExpense extends QuickExpenseResult {
  const QuickExpense(this.amount, this.category);

  final double amount;
  final String category;
}

/// The user asked for the full form (custom amount, income, date, note).
class QuickExpenseMoreOptions extends QuickExpenseResult {
  const QuickExpenseMoreOptions();
}

const List<int> _amounts = <int>[20, 50, 100, 200];

const List<(String, IconData)> _categories = <(String, IconData)>[
  ('Food', Icons.restaurant_rounded),
  ('Transport', Icons.directions_bus_rounded),
  ('School', Icons.school_rounded),
  ('Other', Icons.more_horiz_rounded),
];

const List<FontFeature> _tabular = <FontFeature>[FontFeature.tabularFigures()];

/// Two taps to log an expense dated today: an amount, then a category.
/// [again] resolves to recent repeated expenses that log in one tap; the
/// sheet opens at once and shows them when they arrive.
Future<QuickExpenseResult?> showQuickExpenseSheet(
  BuildContext context, {
  Future<List<RepeatExpense>>? again,
}) {
  return showModalBottomSheet<QuickExpenseResult>(
    context: context,
    useRootNavigator: true,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (BuildContext ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
      child: _QuickExpenseSheet(again: again),
    ),
  );
}

class _QuickExpenseSheet extends StatefulWidget {
  const _QuickExpenseSheet({required this.again});

  final Future<List<RepeatExpense>>? again;

  @override
  State<_QuickExpenseSheet> createState() => _QuickExpenseSheetState();
}

class _QuickExpenseSheetState extends State<_QuickExpenseSheet> {
  /// A preset amount, or null while none is picked or "Other" is in use.
  int? _preset;
  bool _custom = false;
  final TextEditingController _customAmount = TextEditingController();
  List<RepeatExpense> _again = const <RepeatExpense>[];

  @override
  void initState() {
    super.initState();
    widget.again
        ?.then((List<RepeatExpense> found) {
          if (mounted) setState(() => _again = found);
        })
        .catchError((Object _) {
          // Without suggestions the sheet still works.
        });
  }

  /// The amount to log, or null when there is none yet.
  double? get _amount {
    if (!_custom) return _preset?.toDouble();
    if (validateAmount(_customAmount.text) != null) return null;
    return double.parse(_customAmount.text.trim());
  }

  @override
  void dispose() {
    _customAmount.dispose();
    super.dispose();
  }

  String _label(double amount) => amount == amount.roundToDouble()
      ? '₱${amount.round()}'
      : '₱${amount.toStringAsFixed(2)}';

  void _log(double amount, String category) {
    HapticFeedback.lightImpact();
    Navigator.pop(context, QuickExpense(amount, category));
  }

  /// [tiles] in rows of [columns]; a short last row shares the full width.
  Widget _grid(List<Widget> tiles, int columns) {
    final List<Widget> rows = <Widget>[];
    for (int i = 0; i < tiles.length; i += columns) {
      final List<Widget> row = <Widget>[];
      for (int j = i; j < i + columns && j < tiles.length; j++) {
        if (j > i) row.add(AppSpacing.gapSm);
        row.add(Expanded(child: tiles[j]));
      }
      if (i > 0) rows.add(AppSpacing.gapSm);
      rows.add(Row(children: row));
    }
    return Column(children: rows);
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = context.colors;
    final TextTheme textStyles = context.textStyles;
    // Past this scale four or five tiles no longer fit on one row.
    final bool large = MediaQuery.textScalerOf(context).scale(16) > 18.4;
    final String? customError = _customAmount.text.trim().isEmpty
        ? null
        : validateAmount(_customAmount.text);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          AppSpacing.md,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              'Quick expense',
              style: textStyles.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            AppSpacing.gapXs,
            Text(
              _amount == null ? 'Pick an amount' : 'Now pick a category',
              style: textStyles.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            AppSpacing.gapLg,
            if (_again.isNotEmpty) ...<Widget>[
              Text('Again', style: textStyles.labelMedium),
              AppSpacing.gapXs,
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.xs,
                children: <Widget>[
                  for (final RepeatExpense r in _again)
                    ActionChip(
                      label: Text(
                        '${_label(r.amount)} ${r.category}',
                        style: const TextStyle(fontFeatures: _tabular),
                      ),
                      onPressed: () => _log(r.amount, r.category),
                    ),
                ],
              ),
              AppSpacing.gapMd,
            ],
            _grid(<Widget>[
              for (final int amount in _amounts)
                _Tile(
                  selected: !_custom && _preset == amount,
                  onTap: () => setState(() {
                    _preset = amount;
                    _custom = false;
                  }),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      '₱$amount',
                      maxLines: 1,
                      softWrap: false,
                      style: textStyles.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontFeatures: _tabular,
                      ),
                    ),
                  ),
                ),
              _Tile(
                selected: _custom,
                onTap: () => setState(() => _custom = true),
                child: Text('Other', style: textStyles.titleSmall),
              ),
            ], large ? 3 : 5),
            if (_custom) ...<Widget>[
              AppSpacing.gapMd,
              TextField(
                controller: _customAmount,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: 'Amount',
                  prefixText: '₱ ',
                  errorText: customError,
                  border: const OutlineInputBorder(
                    borderRadius: AppRadius.medium,
                  ),
                ),
                onChanged: (_) => setState(() {}),
              ),
            ],
            AppSpacing.gapMd,
            _grid(<Widget>[
              for (final (String name, IconData icon) in _categories)
                _Tile(
                  selected: false,
                  onTap: _amount == null ? null : () => _log(_amount!, name),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Icon(icon, size: AppSizes.iconMd),
                      AppSpacing.gapXs,
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          name,
                          maxLines: 1,
                          softWrap: false,
                          style: textStyles.labelMedium,
                        ),
                      ),
                    ],
                  ),
                ),
            ], large ? 2 : 4),
            AppSpacing.gapSm,
            TextButton(
              onPressed: () =>
                  Navigator.pop(context, const QuickExpenseMoreOptions()),
              child: const Text('Income or another date'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.selected,
    required this.onTap,
    required this.child,
  });

  final bool selected;
  final VoidCallback? onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = context.colors;
    final bool enabled = onTap != null;

    return Opacity(
      opacity: enabled ? 1 : 0.4,
      child: Material(
        color: selected ? colors.primaryContainer : colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.medium,
          side: BorderSide(
            color: selected ? colors.primary : colors.outlineVariant,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 64),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
