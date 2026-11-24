import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../calendar/calendar_controller.dart';
import '../../calendar/event.dart';
import '../../insights/insights_providers.dart';
import '../../notes/recall_controller.dart';
import '../../tasks/task_item.dart';
import '../../tasks/tasks_controller.dart';
import '../focus_controller.dart';
import '../focus_plan.dart';

const List<FontFeature> _tabular = <FontFeature>[FontFeature.tabularFigures()];

/// Opens the bottom sheet to pick a task, upcoming event, or due recall deck
/// to bind to the next focus session.
Future<void> showFocusIntentionPicker(BuildContext context, WidgetRef ref) {
  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (BuildContext ctx) => const _FocusIntentionSheet(),
  );
}

class _FocusIntentionSheet extends ConsumerWidget {
  const _FocusIntentionSheet();

  Future<void> _pick(
    BuildContext context,
    WidgetRef ref,
    FocusIntention? intention,
  ) async {
    await ref.read(focusControllerProvider.notifier).setIntention(intention);
    if (context.mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ColorScheme colors = context.colors;
    final TextTheme text = context.textStyles;
    final DateTime now = ref.watch(ponponClockProvider)();
    final DateTime today = DateTime(now.year, now.month, now.day);
    final DateTime horizon = DateTime(now.year, now.month, now.day + 15);
    final FocusIntention? current = ref
        .watch(focusControllerProvider)
        .value
        ?.intention;

    final List<TaskItem> allTasks =
        ref.watch(tasksControllerProvider).value ?? const <TaskItem>[];
    final List<TaskItem> openTasks =
        allTasks.where((TaskItem t) => !t.done).toList()
          ..sort((TaskItem a, TaskItem b) {
            final int byStatus = a
                .dueStatus(now)
                .index
                .compareTo(b.dueStatus(now).index);
            if (byStatus != 0) return byStatus;
            final DateTime? da = a.dueDate;
            final DateTime? db = b.dueDate;
            if (da != null && db != null) {
              final int byDate = da.compareTo(db);
              if (byDate != 0) return byDate;
            } else if (da != null || db != null) {
              return da != null ? -1 : 1;
            }
            return a.id.compareTo(b.id);
          });

    final List<CalendarEvent> allEvents =
        ref.watch(calendarControllerProvider).value ?? const <CalendarEvent>[];
    final List<({CalendarEvent event, DateTime at})> upcomingEvents =
        <({CalendarEvent event, DateTime at})>[
          for (final CalendarEvent e in allEvents)
            if (!e.done)
              if (e.nextOccurrence(today) case final DateTime at)
                if (at.isBefore(horizon)) (event: e, at: at),
        ]..sort((a, b) {
          final bool aTrack = a.event.isExam || a.event.isAssignment;
          final bool bTrack = b.event.isExam || b.event.isAssignment;
          if (aTrack != bTrack) return aTrack ? -1 : 1;
          return a.at.compareTo(b.at);
        });

    final RecallDeckState? recall = ref.watch(recallControllerProvider).value;
    final int dueCardsCount = recall?.dueCards.length ?? 0;

    return SafeArea(
      top: false,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.78,
        ),
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            0,
            AppSpacing.lg,
            AppSpacing.xl,
          ),
          children: <Widget>[
            Text(
              'Focus on',
              style: text.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            AppSpacing.gapMd,
            _SectionCard(
              children: <Widget>[
                _OptionRow(
                  icon: Icons.all_inclusive_rounded,
                  title: 'Anything (no specific target)',
                  selected: current == null,
                  onTap: () => _pick(context, ref, null),
                ),
              ],
            ),
            if (openTasks.isNotEmpty) ...<Widget>[
              AppSpacing.gapMd,
              Text(
                'Tasks',
                style: text.labelMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
              AppSpacing.gapXs,
              _SectionCard(
                children: <Widget>[
                  for (final TaskItem task in openTasks)
                    _OptionRow(
                      icon: Icons.check_circle_outline_rounded,
                      title: task.title,
                      subtitle: taskDueLabel(task, now),
                      subtitleColor: task.dueStatus(now) == TaskDueStatus.overdue
                          ? colors.error
                          : null,
                      selected:
                          current?.type == FocusTargetType.task &&
                          current?.id == task.id,
                      onTap: () => _pick(
                        context,
                        ref,
                        FocusIntention(
                          type: FocusTargetType.task,
                          id: task.id,
                          label: task.title,
                        ),
                      ),
                    ),
                ],
              ),
            ],
            if (upcomingEvents.isNotEmpty) ...<Widget>[
              AppSpacing.gapMd,
              Text(
                'Upcoming Events',
                style: text.labelMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
              AppSpacing.gapXs,
              _SectionCard(
                children: <Widget>[
                  for (final ({CalendarEvent event, DateTime at}) item
                      in upcomingEvents)
                    _OptionRow(
                      icon: item.event.isExam || item.event.isAssignment
                          ? Icons.event_available_rounded
                          : Icons.event_rounded,
                      title: item.event.title,
                      subtitle: _eventSubtitle(item.event, item.at, today),
                      selected:
                          current?.type == FocusTargetType.event &&
                          current?.id == item.event.id,
                      onTap: () => _pick(
                        context,
                        ref,
                        FocusIntention(
                          type: FocusTargetType.event,
                          id: item.event.id,
                          label: item.event.title,
                        ),
                      ),
                    ),
                ],
              ),
            ],
            if (dueCardsCount > 0) ...<Widget>[
              AppSpacing.gapMd,
              Text(
                'Recall Deck',
                style: text.labelMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
              AppSpacing.gapXs,
              _SectionCard(
                children: <Widget>[
                  _OptionRow(
                    icon: Icons.bolt_rounded,
                    title: 'Recall deck ($dueCardsCount due)',
                    selected: current?.type == FocusTargetType.recall,
                    onTap: () => _pick(
                      context,
                      ref,
                      FocusIntention(
                        type: FocusTargetType.recall,
                        label: 'Recall deck ($dueCardsCount due)',
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  static String _eventSubtitle(
    CalendarEvent event,
    DateTime at,
    DateTime today,
  ) {
    final String? badge = event.countdownBadge(today, on: at);
    final String when = event.isAllDay
        ? DateFormat('MMM d').format(at)
        : DateFormat('MMM d · h:mm a').format(at);
    return badge == null ? when : '$badge · $when';
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = context.colors;
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: colors.surfaceContainerLowest,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.large,
        side: BorderSide(color: colors.outlineVariant),
      ),
      child: Column(
        children: <Widget>[
          for (int i = 0; i < children.length; i++) ...<Widget>[
            if (i > 0) Divider(height: 1, color: colors.outlineVariant),
            children[i],
          ],
        ],
      ),
    );
  }
}

class _OptionRow extends StatelessWidget {
  const _OptionRow({
    required this.icon,
    required this.title,
    required this.selected,
    required this.onTap,
    this.subtitle = '',
    this.subtitleColor,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color? subtitleColor;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = context.colors;
    final TextTheme text = context.textStyles;
    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: AppSizes.minTouchTarget),
        child: Container(
          color: selected
              ? colors.primaryContainer.withValues(alpha: 0.35)
              : null,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            children: <Widget>[
              Icon(
                icon,
                size: AppSizes.iconSm,
                color: selected ? colors.primary : colors.onSurfaceVariant,
              ),
              AppSpacing.gapMd,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: text.bodyMedium?.copyWith(
                        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                        color: colors.onSurface,
                      ),
                    ),
                    if (subtitle.isNotEmpty)
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: text.labelSmall?.copyWith(
                          color: subtitleColor ?? colors.onSurfaceVariant,
                          fontFeatures: _tabular,
                        ),
                      ),
                  ],
                ),
              ),
              if (selected)
                Icon(
                  Icons.check_rounded,
                  size: AppSizes.iconSm,
                  color: colors.primary,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
