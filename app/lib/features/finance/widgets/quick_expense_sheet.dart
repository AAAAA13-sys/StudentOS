import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';

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

/// Two taps to log an expense dated today: an amount, then a category.
Future<QuickExpenseResult?> showQuickExpenseSheet(BuildContext context) {
  return showModalBottomSheet<QuickExpenseResult>(
    context: context,
    showDragHandle: true,
    builder: (BuildContext ctx) => const _QuickExpenseSheet(),
  );
}

class _QuickExpenseSheet extends StatefulWidget {
  const _QuickExpenseSheet();

  @override
  State<_QuickExpenseSheet> createState() => _QuickExpenseSheetState();
}

class _QuickExpenseSheetState extends State<_QuickExpenseSheet> {
  int? _amount;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = context.colors;
    final TextTheme textStyles = context.textStyles;

    return SafeArea(
      child: Padding(
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
            Row(
              children: <Widget>[
                for (final int amount in _amounts) ...<Widget>[
                  if (amount != _amounts.first) AppSpacing.gapSm,
                  Expanded(
                    child: _Tile(
                      selected: _amount == amount,
                      onTap: () => setState(() => _amount = amount),
                      child: Text(
                        '₱$amount',
                        style: textStyles.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          fontFeatures: const <FontFeature>[
                            FontFeature.tabularFigures(),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
            AppSpacing.gapMd,
            Row(
              children: <Widget>[
                for (final (String name, IconData icon)
                    in _categories) ...<Widget>[
                  if (name != _categories.first.$1) AppSpacing.gapSm,
                  Expanded(
                    child: _Tile(
                      selected: false,
                      onTap: _amount == null
                          ? null
                          : () {
                              HapticFeedback.lightImpact();
                              Navigator.pop(
                                context,
                                QuickExpense(_amount!.toDouble(), name),
                              );
                            },
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Icon(icon, size: AppSizes.iconMd),
                          AppSpacing.gapXs,
                          Text(
                            name,
                            style: textStyles.labelMedium,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
            AppSpacing.gapSm,
            TextButton(
              onPressed: () =>
                  Navigator.pop(context, const QuickExpenseMoreOptions()),
              child: const Text('Custom amount, income or another date'),
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
