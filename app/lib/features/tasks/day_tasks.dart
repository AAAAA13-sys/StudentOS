import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import 'task_item.dart';
import 'tasks_controller.dart';
import 'tasks_panel.dart';

const List<FontFeature> _tabular = <FontFeature>[FontFeature.tabularFigures()];

/// Open tasks due on [day] (plus overdue open tasks when [day] is today),
/// shown on Calendar > Schedule day view right after `DayShifts`. Takes no
/// space when empty.
class DayTasks extends ConsumerWidget {
  const DayTasks({required this.day, super.key});

  final DateTime day;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<TaskItem> all =
        ref.watch(tasksControllerProvider).value ?? const <TaskItem>[];
    final DateTime selected = taskDateOnly(day);
    final DateTime today = taskDateOnly(DateTime.now());
    final bool isToday = selected == today;

    final List<TaskItem> matching = <TaskItem>[
      for (final TaskItem task in all)
        if (!task.done &&
            task.dueDate != null &&
            (task.dueDate == selected ||
                (isToday && task.dueDate!.isBefore(today))))
          task,
    ];
    if (matching.isEmpty) return const SizedBox.shrink();

    final ColorScheme colors = context.colors;
    final TextTheme textStyles = context.textStyles;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.xs,
        AppSpacing.lg,
        0,
      ),
      child: Column(
        children: <Widget>[
          for (final TaskItem task in matching)
            _DayTaskCard(
              task: task,
              today: today,
              colors: colors,
              textStyles: textStyles,
            ),
        ],
      ),
    );
  }
}

class _DayTaskCard extends ConsumerWidget {
  const _DayTaskCard({
    required this.task,
    required this.today,
    required this.colors,
    required this.textStyles,
  });

  final TaskItem task;
  final DateTime today;
  final ColorScheme colors;
  final TextTheme textStyles;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final DateTime? due = task.dueDate;
    final bool isOverdue = due != null && due.isBefore(today);
    final String? subtitleText = _subtitle(due, isOverdue);

    void toggle() =>
        ref.read(tasksControllerProvider.notifier).toggleDone(task);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Card(
        margin: EdgeInsets.zero,
        elevation: 0,
        color: colors.surfaceContainerLowest,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.large,
          side: BorderSide(color: colors.outlineVariant, width: 1.0),
        ),
        child: InkWell(
          borderRadius: AppRadius.large,
          onTap: () => showTaskEditor(context, ref, existing: task),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: AppSizes.minTouchTarget,
            ),
            child: Padding(
              padding: const EdgeInsets.only(
                left: AppSpacing.xs,
                right: AppSpacing.lg,
                top: AppSpacing.xs,
                bottom: AppSpacing.xs,
              ),
              child: Row(
                children: <Widget>[
                  Semantics(
                    container: true,
                    button: true,
                    checked: task.done,
                    label: task.title,
                    onTap: toggle,
                    child: ExcludeSemantics(
                      child: InkWell(
                        borderRadius: AppRadius.small,
                        onTap: toggle,
                        child: SizedBox(
                          width: AppSizes.minTouchTarget,
                          height: AppSizes.minTouchTarget,
                          child: Icon(
                            task.done
                                ? Icons.check_box_rounded
                                : Icons.check_box_outline_blank_rounded,
                            size: AppSizes.iconMd,
                            color: isOverdue
                                ? colors.error
                                : colors.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                  ),
                  AppSpacing.gapXs,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          task.title,
                          style: textStyles.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (subtitleText != null)
                          Text(
                            subtitleText,
                            style: textStyles.bodySmall?.copyWith(
                              color: isOverdue
                                  ? colors.error
                                  : colors.onSurfaceVariant,
                              fontWeight: isOverdue ? FontWeight.w600 : null,
                              fontFeatures: _tabular,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String? _subtitle(DateTime? due, bool isOverdue) {
    final List<String> parts = <String>[];
    if (isOverdue && due != null) {
      parts.add('Overdue · ${DateFormat('MMM d').format(due)}');
    } else {
      parts.add('Task');
    }
    if (task.isRepeating) {
      parts.add(TaskRepeat.label(task.repeat));
    }
    return parts.join(' · ');
  }
}
