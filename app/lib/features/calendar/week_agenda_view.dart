import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/ponpon.dart';
import '../work/add_shift_sheet.dart';
import '../work/shift.dart';
import 'event.dart';
import 'status_pill.dart';
import 'week_agenda.dart';

const List<FontFeature> _tabular = <FontFeature>[FontFeature.tabularFigures()];

String _pesos(int cents) =>
    NumberFormat.currency(symbol: '₱', decimalDigits: 2).format(cents / 100);

/// Schedule > Week: seven days from [anchor] as one scrolling list with a
/// range header, a free-day line for empty days and a totals footer.
class WeekAgendaView extends ConsumerWidget {
  const WeekAgendaView({
    required this.events,
    required this.shifts,
    required this.anchor,
    required this.onAnchorChanged,
    required this.onEventTap,
    required this.onAddClass,
    required this.onRefresh,
    super.key,
  });

  final List<CalendarEvent> events;
  final List<Shift> shifts;

  /// First of the seven days shown.
  final DateTime anchor;
  final ValueChanged<DateTime> onAnchorChanged;
  final ValueChanged<CalendarEvent> onEventTap;
  final VoidCallback onAddClass;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ColorScheme colors = context.colors;
    final TextTheme textStyles = context.textStyles;
    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    final WeekAgenda week = buildWeekAgenda(
      events: events,
      shifts: shifts,
      start: anchor,
      now: now,
    );
    final DateFormat dayFormat = DateFormat('EEE, MMM d');
    final DateFormat md = DateFormat('MMM d');
    final String range = week.start.year == week.end.year
        ? '${md.format(week.start)} – ${md.format(week.end)}'
        : '${DateFormat('MMM d, y').format(week.start)} – '
              '${DateFormat('MMM d, y').format(week.end)}';

    DateTime shifted(int days) =>
        DateTime(anchor.year, anchor.month, anchor.day + days);

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: <Widget>[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              child: Row(
                children: <Widget>[
                  IconButton(
                    icon: const Icon(Icons.chevron_left_rounded),
                    tooltip: 'Previous week',
                    onPressed: () => onAnchorChanged(shifted(-7)),
                  ),
                  Expanded(
                    child: Text(
                      range,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textStyles.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontFeatures: _tabular,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right_rounded),
                    tooltip: 'Next week',
                    onPressed: () => onAnchorChanged(shifted(7)),
                  ),
                  TextButton(
                    style: TextButton.styleFrom(
                      minimumSize: const Size(0, AppSizes.minTouchTarget),
                    ),
                    onPressed: () => onAnchorChanged(today),
                    child: const Text('Today'),
                  ),
                ],
              ),
            ),
          ),
          if (week.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    const Ponpon(mood: PonponMood.sleepy, size: 88),
                    AppSpacing.gapMd,
                    Text(
                      'Nothing planned this week.',
                      style: textStyles.titleMedium?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                    AppSpacing.gapSm,
                    FilledButton.tonalIcon(
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Add a class'),
                      onPressed: onAddClass,
                    ),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.xs,
                AppSpacing.lg,
                96,
              ),
              sliver: SliverList.list(
                children: <Widget>[
                  for (final AgendaDay day in week.days) ...<Widget>[
                    Padding(
                      padding: const EdgeInsets.only(
                        top: AppSpacing.md,
                        bottom: AppSpacing.xs,
                      ),
                      child: Semantics(
                        header: true,
                        child: Text(
                          dayHeading(day.day, today, dayFormat.format),
                          style: textStyles.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: day.day == today
                                ? colors.primary
                                : colors.onSurface,
                          ),
                        ),
                      ),
                    ),
                    if (day.isFree)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                        child: Text(
                          'Free day',
                          style: textStyles.bodyMedium?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      )
                    else
                      for (final AgendaItem item in day.items)
                        Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                          child: item.isShift
                              ? _ShiftRow(item: item)
                              : _EventRow(
                                  item: item,
                                  today: today,
                                  onTap: () => onEventTap(item.event!),
                                ),
                        ),
                  ],
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.lg),
                    child: Text(
                      weekFooter(week, _pesos, today: today),
                      textAlign: TextAlign.center,
                      style: textStyles.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                        fontFeatures: _tabular,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// The hairline card both row kinds sit in.
class _RowCard extends StatelessWidget {
  const _RowCard({required this.onTap, required this.child});

  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: context.colors.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.large,
        side: BorderSide(color: context.colors.outlineVariant, width: 1.0),
      ),
      child: InkWell(
        borderRadius: AppRadius.large,
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: AppSizes.minTouchTarget),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

class _OverlapLine extends StatelessWidget {
  const _OverlapLine(this.other);

  final String other;

  @override
  Widget build(BuildContext context) {
    final Color muted = context.colors.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Row(
        children: <Widget>[
          Icon(Icons.warning_amber_rounded, size: 14, color: muted),
          AppSpacing.gapXs,
          Flexible(
            child: Text(
              'Overlaps with $other',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.textStyles.bodySmall?.copyWith(color: muted),
            ),
          ),
        ],
      ),
    );
  }
}

class _EventRow extends StatelessWidget {
  const _EventRow({
    required this.item,
    required this.today,
    required this.onTap,
  });

  final AgendaItem item;
  final DateTime today;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = context.colors;
    final TextTheme textStyles = context.textStyles;
    final CalendarEvent event = item.event!;
    final String? countdown = event.countdownBadge(today, on: item.start);
    final String place = (event.location ?? '').trim();
    final bool trackable = event.isExam || event.isAssignment;

    return Opacity(
      opacity: event.done ? 0.55 : 1,
      child: _RowCard(
        onTap: onTap,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 64),
              child: Text(
                item.isAllDay
                    ? 'All day'
                    : DateFormat('h:mm a').format(item.start),
                maxLines: 1,
                softWrap: false,
                style: textStyles.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontFeatures: _tabular,
                ),
              ),
            ),
            AppSpacing.gapSm,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  if (trackable && event.done)
                    StatusPill(
                      icon: Icons.check_circle_rounded,
                      label: 'Done',
                      background: colors.primaryContainer,
                      foreground: colors.onPrimaryContainer,
                      border: colors.primary,
                    )
                  else if (countdown != null)
                    StatusPill(
                      icon: event.isExam
                          ? Icons.error_outline_rounded
                          : Icons.assignment_late_outlined,
                      label: event.isExam
                          ? 'Exam · $countdown'
                          : 'Due · $countdown',
                      background: event.isExam
                          ? colors.errorContainer
                          : colors.primaryContainer,
                      foreground: event.isExam
                          ? colors.onErrorContainer
                          : colors.onPrimaryContainer,
                      border: event.isExam ? colors.error : colors.primary,
                    ),
                  Text(
                    event.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: textStyles.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      decoration: event.done
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                  ),
                  if (place.isNotEmpty)
                    Text(
                      place,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textStyles.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  if (item.overlapsWith != null)
                    _OverlapLine(item.overlapsWith!),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShiftRow extends ConsumerWidget {
  const _ShiftRow({required this.item});

  final AgendaItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ColorScheme colors = context.colors;
    final TextTheme textStyles = context.textStyles;
    final Shift shift = item.shift!;
    final DateFormat time = DateFormat('h:mm a');
    final int pay = item.expectedPayCents;

    return _RowCard(
      onTap: () => editShift(context, ref, shift),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(
                Icons.work_outline_rounded,
                size: AppSizes.iconSm,
                color: colors.onSurfaceVariant,
              ),
              AppSpacing.gapMd,
              Expanded(
                child: Text(
                  '${item.title} · ${time.format(shift.startsAt)}–'
                  '${time.format(shift.endsAt)}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: textStyles.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontFeatures: _tabular,
                  ),
                ),
              ),
              if (pay > 0) ...<Widget>[
                AppSpacing.gapSm,
                Text(
                  _pesos(pay),
                  textAlign: TextAlign.right,
                  style: textStyles.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontFeatures: _tabular,
                  ),
                ),
              ],
            ],
          ),
          if (item.overlapsWith != null) _OverlapLine(item.overlapsWith!),
        ],
      ),
    );
  }
}
