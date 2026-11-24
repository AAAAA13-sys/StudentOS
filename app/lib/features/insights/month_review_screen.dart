import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/db/portable_export.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/month_switcher.dart';
import '../phone/phone_day.dart';
import '../work/shift.dart';
import 'month_review.dart';

const List<FontFeature> _tabular = <FontFeature>[FontFeature.tabularFigures()];

final NumberFormat _peso = NumberFormat.currency(symbol: '₱', decimalDigits: 2);

String _formatMoney(int cents) {
  final String formatted = _peso.format(cents.abs() / 100);
  return cents < 0 ? '-$formatted' : formatted;
}

/// Monthly summary across Money, Work & Study, and Phone Rest & Screen Time.
class MonthReviewScreen extends ConsumerStatefulWidget {
  const MonthReviewScreen({this.initialMonth, super.key});

  final String? initialMonth;

  @override
  ConsumerState<MonthReviewScreen> createState() => _MonthReviewScreenState();
}

class _MonthReviewScreenState extends ConsumerState<MonthReviewScreen> {
  late String _month =
      widget.initialMonth ?? DateFormat('yyyy-MM').format(DateTime.now());

  Future<void> _exportMarkdown(MonthReview review) async {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    try {
      final String markdown = exportMonthReviewMarkdown(review);
      final Uri? saved = await FilePicker.saveFile(
        fileName: 'studentos-review-${review.month}.md',
        bytes: utf8.encode(markdown),
        mimeType: 'text/markdown',
      );
      if (!mounted) return;
      if (saved != null) {
        messenger
          ..hideCurrentSnackBar()
          ..showSnackBar(const SnackBar(content: Text('Summary saved')));
      }
    } catch (_) {
      if (!mounted) return;
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Could not save summary')),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<MonthReview> reviewAsync = ref.watch(
      monthlyReviewProvider(_month),
    );
    final DateTime monthDate =
        DateTime.tryParse('$_month-01') ?? DateTime.now();
    final ColorScheme colors = context.colors;

    return Scaffold(
      appBar: AppBar(title: const Text('Month in Review')),
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(monthlyReviewProvider(_month));
            await ref.read(monthlyReviewProvider(_month).future);
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.xs,
              AppSpacing.lg,
              AppSpacing.xxl,
            ),
            children: <Widget>[
              MonthSwitcher(
                month: monthDate,
                onChanged: (DateTime next) => setState(() {
                  _month = DateFormat('yyyy-MM').format(next);
                }),
              ),
              AppSpacing.gapSm,
              reviewAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.xxl),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (Object _, StackTrace _) => Card(
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: AppSpacing.card,
                    child: Column(
                      children: <Widget>[
                        Icon(
                          Icons.error_outline_rounded,
                          size: 40,
                          color: colors.error,
                        ),
                        AppSpacing.gapMd,
                        const Text('Could not build your month review.'),
                        AppSpacing.gapLg,
                        FilledButton(
                          onPressed: () =>
                              ref.invalidate(monthlyReviewProvider(_month)),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                ),
                data: (MonthReview review) => Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    _MoneyCard(review: review),
                    AppSpacing.gapMd,
                    _WorkStudyCard(review: review),
                    AppSpacing.gapMd,
                    _PhoneCard(review: review),
                    AppSpacing.gapLg,
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(
                          AppSizes.buttonHeight,
                        ),
                      ),
                      onPressed: () => _exportMarkdown(review),
                      icon: const Icon(Icons.file_download_outlined),
                      label: const Text('Export summary (.md)'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MoneyCard extends StatelessWidget {
  const _MoneyCard({required this.review});

  final MonthReview review;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = context.colors;
    final TextTheme textStyles = context.textStyles;
    final ModuleColors money = context.moduleColors;
    final TextStyle? statValueStyle = textStyles.titleSmall?.copyWith(
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
            _SectionHeader(
              icon: Icons.account_balance_wallet_outlined,
              color: money.finance,
              title: 'Money',
            ),
            AppSpacing.gapMd,
            Text(
              'Net cashflow',
              style: textStyles.labelMedium?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            Text(
              _formatMoney(review.netCents),
              style: textStyles.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                fontFeatures: _tabular,
                color: review.netCents >= 0 ? colors.primary : colors.error,
              ),
            ),
            AppSpacing.gapSm,
            Wrap(
              spacing: AppSpacing.lg,
              runSpacing: AppSpacing.xs,
              children: <Widget>[
                Text(
                  'Income ${_formatMoney(review.incomeCents)}',
                  style: statValueStyle?.copyWith(color: money.income),
                ),
                Text(
                  'Spent ${_formatMoney(review.expenseCents)}',
                  style: statValueStyle?.copyWith(color: colors.error),
                ),
              ],
            ),
            if (review.topExpenseCategories.isNotEmpty) ...<Widget>[
              AppSpacing.gapMd,
              Divider(height: 1, color: colors.outlineVariant),
              AppSpacing.gapSm,
              Text(
                'Top spending',
                style: textStyles.labelMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
              AppSpacing.gapXs,
              for (final MonthExpenseCategory cat
                  in review.topExpenseCategories.take(3))
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          '${cat.category} (${cat.count})',
                          style: textStyles.bodyMedium?.copyWith(
                            fontFeatures: _tabular,
                          ),
                        ),
                      ),
                      Text(
                        _formatMoney(cat.cents),
                        style: textStyles.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          fontFeatures: _tabular,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
            AppSpacing.gapMd,
            Divider(height: 1, color: colors.outlineVariant),
            AppSpacing.gapSm,
            _MetricRow(
              label: 'Savings pockets stashed',
              value: _formatMoney(review.goalsSavedCents),
              detail: review.goalsCount == 0
                  ? null
                  : '${review.goalsCount} ${review.goalsCount == 1 ? 'goal' : 'goals'}'
                        '${review.goalsReachedCount > 0 ? ' · ${review.goalsReachedCount} reached' : ''}',
            ),
            AppSpacing.gapXs,
            _MetricRow(
              label: 'Open IOUs (${review.openIousCount})',
              value:
                  '+${_formatMoney(review.openOwedCents)} / -${_formatMoney(review.openOwingCents)}',
            ),
            AppSpacing.gapXs,
            _MetricRow(
              label: 'Settled this month',
              value: '${review.settledInMonthCount}',
              detail: review.settledInMonthCount > 0
                  ? _formatMoney(review.settledInMonthCents)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _WorkStudyCard extends StatelessWidget {
  const _WorkStudyCard({required this.review});

  final MonthReview review;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = context.colors;
    final TextTheme textStyles = context.textStyles;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: AppSpacing.card,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            _SectionHeader(
              icon: Icons.school_outlined,
              color: colors.primary,
              title: 'Work & Study',
            ),
            AppSpacing.gapMd,
            if (review.shiftCount == 0)
              _MetricRow(label: 'Shifts', value: 'None logged')
            else ...<Widget>[
              _MetricRow(
                label: 'Paid shifts (${review.paidShiftCount})',
                value:
                    '${formatHours(review.paidShiftMinutes)}h · ${_formatMoney(review.paidShiftPayCents)}',
              ),
              AppSpacing.gapXs,
              _MetricRow(
                label: 'Unpaid shifts (${review.unpaidShiftCount})',
                value:
                    '${formatHours(review.unpaidShiftMinutes)}h · ${_formatMoney(review.unpaidShiftPayCents)}',
              ),
            ],
            AppSpacing.gapMd,
            Divider(height: 1, color: colors.outlineVariant),
            AppSpacing.gapSm,
            _MetricRow(
              label: 'Focus time',
              value: review.focusSessions == 0
                  ? 'None logged'
                  : formatDuration(Duration(milliseconds: review.focusMs)),
              detail: review.focusSessions == 0
                  ? null
                  : '${review.completedFocusSessions}/${review.focusSessions} sessions · ${review.focusRounds} rounds',
            ),
            if (review.topStudyTargets.isNotEmpty) ...<Widget>[
              AppSpacing.gapSm,
              Text(
                'Top studied',
                style: textStyles.labelMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
              AppSpacing.gapXs,
              for (final MonthStudyTarget target
                  in review.topStudyTargets.take(3))
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          target.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textStyles.bodyMedium,
                        ),
                      ),
                      AppSpacing.gapSm,
                      Text(
                        formatDuration(Duration(milliseconds: target.focusMs)),
                        style: textStyles.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          fontFeatures: _tabular,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
            AppSpacing.gapMd,
            Divider(height: 1, color: colors.outlineVariant),
            AppSpacing.gapSm,
            _MetricRow(
              label: 'Tasks completed',
              value: '${review.tasksCompletedCount}',
            ),
            AppSpacing.gapXs,
            _MetricRow(
              label: 'Recall cards reviewed',
              value: '${review.recallReviewedCount}',
            ),
          ],
        ),
      ),
    );
  }
}

class _PhoneCard extends StatelessWidget {
  const _PhoneCard({required this.review});

  final MonthReview review;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = context.colors;
    final TextTheme textStyles = context.textStyles;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: AppSpacing.card,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            _SectionHeader(
              icon: Icons.bedtime_outlined,
              color: colors.primary,
              title: 'Phone Rest & Screen Time',
            ),
            AppSpacing.gapMd,
            if (review.daysWithPhone == 0)
              Text(
                review.hasPhoneAccess
                    ? 'No screen time recorded'
                    : 'Screen time access off',
                style: textStyles.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              )
            else ...<Widget>[
              _MetricRow(
                label: 'Average screen time',
                value: formatDuration(
                  Duration(milliseconds: review.avgScreenOnMs ?? 0),
                ),
              ),
              AppSpacing.gapXs,
              _MetricRow(
                label: 'Average phone rest',
                value: review.avgRestDuration != null
                    ? formatDuration(review.avgRestDuration!)
                    : 'No rest recorded',
              ),
              AppSpacing.gapXs,
              Text(
                'Based on ${review.daysWithPhone} '
                '${review.daysWithPhone == 1 ? 'day' : 'days'}',
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

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.icon,
    required this.color,
    required this.title,
  });

  final IconData icon;
  final Color color;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Icon(icon, size: AppSizes.iconSm, color: color),
        AppSpacing.gapSm,
        Text(
          title,
          style: context.textStyles.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _MetricRow extends StatelessWidget {
  const _MetricRow({
    required this.label,
    required this.value,
    this.detail,
  });

  final String label;
  final String value;
  final String? detail;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = context.colors;
    final TextTheme textStyles = context.textStyles;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(label, style: textStyles.bodyMedium),
              if (detail != null)
                Text(
                  detail!,
                  style: textStyles.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                    fontFeatures: _tabular,
                  ),
                ),
            ],
          ),
        ),
        AppSpacing.gapSm,
        Text(
          value,
          style: textStyles.bodyMedium?.copyWith(
            fontWeight: FontWeight.w700,
            fontFeatures: _tabular,
          ),
        ),
      ],
    );
  }
}
