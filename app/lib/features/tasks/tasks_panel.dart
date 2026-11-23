import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/confirm_dialog.dart';
import '../../core/widgets/ponpon.dart';
import '../insights/insights_providers.dart';
import '../insights/ponpon_talk_slot.dart';
import 'task_item.dart';
import 'tasks_controller.dart';

const List<FontFeature> _tabular = <FontFeature>[FontFeature.tabularFigures()];

/// Tasks view shown inside `Notes > Tasks`: filter chips (`Open`, `Today`,
/// `Done`), grouped hairline cards with >=48dp checkbox rows, and Ponpon
/// empty/insight states.
class TasksPanel extends ConsumerStatefulWidget {
  const TasksPanel({super.key});

  @override
  ConsumerState<TasksPanel> createState() => _TasksPanelState();
}

class _TasksPanelState extends ConsumerState<TasksPanel> {
  TaskFilter _filter = TaskFilter.open;

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<TaskItem>> tasksAsync = ref.watch(
      tasksControllerProvider,
    );
    final ColorScheme colors = context.colors;
    final TextTheme textStyles = context.textStyles;
    final DateTime now = DateTime.now();

    final List<TaskItem>? allTasks = tasksAsync.value;
    final List<({String label, List<TaskItem> items})> sections =
        allTasks == null
        ? const <({String label, List<TaskItem> items})>[]
        : _sectionsFor(allTasks, _filter, now);
    final bool isEmptyView = sections.isEmpty;

    return Column(
      children: <Widget>[
        _filterRow(),
        PonponTalkSlot(
          surface: PonponSurface.notes,
          suppress: allTasks == null || isEmptyView,
        ),
        Expanded(
          child: tasksAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (Object _, _) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Icon(
                    Icons.error_outline_rounded,
                    size: 48,
                    color: colors.error,
                  ),
                  AppSpacing.gapMd,
                  const Text('Couldn’t load your tasks.'),
                  AppSpacing.gapLg,
                  FilledButton(
                    onPressed: () =>
                        ref.read(tasksControllerProvider.notifier).refresh(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
            data: (List<TaskItem> _) {
              if (sections.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Ponpon(
                          mood: _filter == TaskFilter.today
                              ? PonponMood.sleepy
                              : PonponMood.happy,
                          size: 88,
                        ),
                        AppSpacing.gapMd,
                        Text(
                          _emptyMessage(_filter),
                          textAlign: TextAlign.center,
                          style: textStyles.titleMedium?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
              return RefreshIndicator(
                onRefresh: () =>
                    ref.read(tasksControllerProvider.notifier).refresh(),
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.sm,
                    AppSpacing.lg,
                    96,
                  ),
                  itemCount: sections.length,
                  separatorBuilder: (_, _) => AppSpacing.gapMd,
                  itemBuilder: (BuildContext context, int index) {
                    final ({String label, List<TaskItem> items}) section =
                        sections[index];
                    return _TaskGroupCard(
                      label: section.label,
                      tasks: section.items,
                      now: now,
                    );
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
    const List<(TaskFilter, String)> options = <(TaskFilter, String)>[
      (TaskFilter.open, 'Open'),
      (TaskFilter.today, 'Today'),
      (TaskFilter.done, 'Done'),
    ];
    return SizedBox(
      height: 48,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        scrollDirection: Axis.horizontal,
        itemCount: options.length,
        separatorBuilder: (_, _) => AppSpacing.gapSm,
        itemBuilder: (BuildContext ctx, int index) {
          final (TaskFilter value, String label) = options[index];
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

  static String _emptyMessage(TaskFilter filter) => switch (filter) {
    TaskFilter.open => 'No open tasks',
    TaskFilter.today => 'Nothing due today',
    TaskFilter.done => 'No completed tasks yet',
  };

  static List<({String label, List<TaskItem> items})> _sectionsFor(
    List<TaskItem> tasks,
    TaskFilter filter,
    DateTime now,
  ) {
    if (filter == TaskFilter.done) {
      final List<TaskItem> done =
          tasks.where((TaskItem t) => t.done).toList()..sort((a, b) {
            final int byDone = (b.doneAt ?? DateTime(0)).compareTo(
              a.doneAt ?? DateTime(0),
            );
            return byDone != 0 ? byDone : b.id.compareTo(a.id);
          });
      if (done.isEmpty) return const <({String label, List<TaskItem> items})>[];
      return <({String label, List<TaskItem> items})>[
        (label: 'Done', items: done),
      ];
    }

    final List<TaskItem> overdue = <TaskItem>[];
    final List<TaskItem> today = <TaskItem>[];
    final List<TaskItem> upcoming = <TaskItem>[];
    final List<TaskItem> anytime = <TaskItem>[];

    for (final TaskItem task in tasks) {
      if (task.done) continue;
      switch (task.dueStatus(now)) {
        case TaskDueStatus.overdue:
          overdue.add(task);
        case TaskDueStatus.today:
          today.add(task);
        case TaskDueStatus.upcoming:
          upcoming.add(task);
        case TaskDueStatus.anytime:
          anytime.add(task);
      }
    }

    final List<({String label, List<TaskItem> items})> sections =
        <({String label, List<TaskItem> items})>[];
    if (overdue.isNotEmpty) {
      sections.add((label: 'Overdue', items: overdue));
    }
    if (today.isNotEmpty) {
      sections.add((label: 'Today', items: today));
    }
    if (filter == TaskFilter.open) {
      if (upcoming.isNotEmpty) {
        sections.add((label: 'Upcoming', items: upcoming));
      }
      if (anytime.isNotEmpty) {
        sections.add((label: 'Anytime', items: anytime));
      }
    }
    return sections;
  }
}

class _TaskGroupCard extends ConsumerWidget {
  const _TaskGroupCard({
    required this.label,
    required this.tasks,
    required this.now,
  });

  final String label;
  final List<TaskItem> tasks;
  final DateTime now;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ColorScheme colors = context.colors;
    final TextTheme textStyles = context.textStyles;
    final bool isOverdueSection = label == 'Overdue';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.xs),
          child: Text(
            label,
            style: textStyles.labelMedium?.copyWith(
              color: isOverdueSection ? colors.error : colors.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Card(
          margin: EdgeInsets.zero,
          elevation: 0,
          color: colors.surfaceContainerLowest,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.large,
            side: BorderSide(color: colors.outlineVariant, width: 1.0),
          ),
          child: Column(
            children: <Widget>[
              for (int i = 0; i < tasks.length; i++) ...<Widget>[
                if (i > 0) Divider(height: 1, color: colors.outlineVariant),
                _TaskRow(task: tasks[i], now: now),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _TaskRow extends ConsumerWidget {
  const _TaskRow({required this.task, required this.now});

  final TaskItem task;
  final DateTime now;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ColorScheme colors = context.colors;
    final TextTheme textStyles = context.textStyles;
    final TaskDueStatus status = task.dueStatus(now);
    final String dueText = taskDueLabel(task, now);
    final String notesText = (task.notes ?? '').trim();

    final Color dueColor = task.done
        ? colors.onSurfaceVariant
        : switch (status) {
            TaskDueStatus.overdue => colors.error,
            TaskDueStatus.today => colors.primary,
            _ => colors.onSurfaceVariant,
          };

    void toggle() =>
        ref.read(tasksControllerProvider.notifier).toggleDone(task);

    return InkWell(
      onTap: () => showTaskEditor(context, ref, existing: task),
      onLongPress: () => _confirmDeleteTask(context, ref, task),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: AppSizes.minTouchTarget),
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
                        color: task.done
                            ? colors.primary
                            : (status == TaskDueStatus.overdue
                                  ? colors.error
                                  : colors.onSurfaceVariant),
                      ),
                    ),
                  ),
                ),
              ),
              AppSpacing.gapXs,
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        task.title,
                        style: textStyles.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w500,
                          decoration: task.done
                              ? TextDecoration.lineThrough
                              : null,
                          color: task.done
                              ? colors.onSurfaceVariant
                              : colors.onSurface,
                        ),
                      ),
                      if (dueText.isNotEmpty ||
                          task.isRepeating ||
                          notesText.isNotEmpty) ...<Widget>[
                        const SizedBox(height: 2),
                        Wrap(
                          spacing: AppSpacing.sm,
                          runSpacing: 2,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: <Widget>[
                            if (dueText.isNotEmpty)
                              Text(
                                dueText,
                                style: textStyles.labelSmall?.copyWith(
                                  color: dueColor,
                                  fontWeight:
                                      !task.done &&
                                          (status == TaskDueStatus.overdue ||
                                              status == TaskDueStatus.today)
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  fontFeatures: _tabular,
                                ),
                              ),
                            if (task.isRepeating)
                              Text(
                                TaskRepeat.label(task.repeat),
                                style: textStyles.labelSmall?.copyWith(
                                  color: colors.onSurfaceVariant,
                                ),
                              ),
                          ],
                        ),
                        if (notesText.isNotEmpty)
                          Text(
                            notesText,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: textStyles.bodySmall?.copyWith(
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<bool> _confirmDeleteTask(
  BuildContext context,
  WidgetRef ref,
  TaskItem task,
) async {
  final bool confirmed = await confirmDestructive(
    context,
    title: 'Delete task?',
    message: '"${task.title}" will be removed.',
  );
  if (confirmed) {
    await ref.read(tasksControllerProvider.notifier).deleteTask(task.id);
  }
  return confirmed;
}

/// Opens a modal bottom sheet to create or edit a [TaskItem].
Future<void> showTaskEditor(
  BuildContext context,
  WidgetRef ref, {
  TaskItem? existing,
  DateTime? prefilledDue,
}) async {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController titleController = TextEditingController(
    text: existing?.title ?? '',
  );
  final TextEditingController notesController = TextEditingController(
    text: existing?.notes ?? '',
  );

  final DateTime today = taskDateOnly(DateTime.now());
  DateTime? dueDate =
      existing?.dueDate ??
      (prefilledDue == null ? null : taskDateOnly(prefilledDue));
  String repeat = existing?.repeat ?? TaskRepeat.none;

  final String startTitle = titleController.text;
  final String startNotes = notesController.text;
  final DateTime? startDue = dueDate;
  final String startRepeat = repeat;

  bool isDirty() =>
      titleController.text != startTitle ||
      notesController.text != startNotes ||
      dueDate != startDue ||
      repeat != startRepeat;

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
            message: 'What you entered for this task will be lost.',
            confirmLabel: 'Discard',
          );
          if (!discard) return;
        }
        if (ctx.mounted) Navigator.pop(ctx);
      }

      return ListenableBuilder(
        listenable: Listenable.merge(<Listenable>[
          titleController,
          notesController,
        ]),
        builder: (BuildContext ctx, Widget? _) => PopScope(
          canPop: !isDirty(),
          onPopInvokedWithResult: (bool didPop, Object? _) {
            if (!didPop) close();
          },
          child: StatefulBuilder(
            builder: (BuildContext ctx, StateSetter setModalState) {
              final DateTime tomorrow = DateTime(
                today.year,
                today.month,
                today.day + 1,
              );
              final bool isNone = dueDate == null;
              final bool isToday = dueDate == today;
              final bool isTomorrow = dueDate == tomorrow;
              final bool isCustom =
                  dueDate != null && !isToday && !isTomorrow;

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
                            existing == null ? 'New task' : 'Edit task',
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
                              hintText: 'Submit lab report',
                              border: OutlineInputBorder(
                                borderRadius: AppRadius.medium,
                              ),
                            ),
                            validator: (String? val) {
                              if (val == null || val.trim().isEmpty) {
                                return 'Enter a task title';
                              }
                              return null;
                            },
                          ),
                          AppSpacing.gapMd,
                          TextFormField(
                            controller: notesController,
                            maxLines: 3,
                            textCapitalization: TextCapitalization.sentences,
                            decoration: const InputDecoration(
                              labelText: 'Notes (optional)',
                              alignLabelWithHint: true,
                              border: OutlineInputBorder(
                                borderRadius: AppRadius.medium,
                              ),
                            ),
                          ),
                          AppSpacing.gapMd,
                          Text(
                            'Due date',
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
                                selected: isNone,
                                onSelected: (_) =>
                                    setModalState(() => dueDate = null),
                              ),
                              ChoiceChip(
                                label: const Text('Today'),
                                selected: isToday,
                                onSelected: (_) =>
                                    setModalState(() => dueDate = today),
                              ),
                              ChoiceChip(
                                label: const Text('Tomorrow'),
                                selected: isTomorrow,
                                onSelected: (_) =>
                                    setModalState(() => dueDate = tomorrow),
                              ),
                              ChoiceChip(
                                label: Text(
                                  isCustom
                                      ? DateFormat('MMM d, yyyy').format(dueDate!)
                                      : 'Pick date',
                                  style: const TextStyle(
                                    fontFeatures: _tabular,
                                  ),
                                ),
                                selected: isCustom,
                                onSelected: (_) async {
                                  final DateTime? picked = await showDatePicker(
                                    context: ctx,
                                    initialDate: dueDate ?? today,
                                    firstDate: DateTime(2020),
                                    lastDate: DateTime(2035),
                                  );
                                  if (picked != null) {
                                    setModalState(
                                      () => dueDate = taskDateOnly(picked),
                                    );
                                  }
                                },
                              ),
                            ],
                          ),
                          AppSpacing.gapMd,
                          Text(
                            'Repeat',
                            style: ctx.textStyles.labelMedium?.copyWith(
                              color: ctx.colors.onSurfaceVariant,
                            ),
                          ),
                          AppSpacing.gapXs,
                          Wrap(
                            spacing: AppSpacing.sm,
                            runSpacing: AppSpacing.xs,
                            children: <Widget>[
                              for (final String option in TaskRepeat.values)
                                ChoiceChip(
                                  label: Text(TaskRepeat.label(option)),
                                  selected: repeat == option,
                                  onSelected: (_) => setModalState(() {
                                    repeat = option;
                                    if (option != TaskRepeat.none &&
                                        dueDate == null) {
                                      dueDate = today;
                                    }
                                  }),
                                ),
                            ],
                          ),
                          AppSpacing.gapXl,
                          SizedBox(
                            height: AppSizes.buttonHeight,
                            child: FilledButton(
                              onPressed: () {
                                if (!formKey.currentState!.validate()) return;
                                final String? dueKey = dueDate == null
                                    ? null
                                    : formatTaskDateKey(dueDate!);
                                final String cleanTitle =
                                    titleController.text.trim();
                                final String cleanNotes =
                                    notesController.text.trim();
                                if (existing == null) {
                                  ref
                                      .read(tasksControllerProvider.notifier)
                                      .addTask(
                                        TaskItem(
                                          id: 0,
                                          title: cleanTitle,
                                          notes: cleanNotes.isEmpty
                                              ? null
                                              : cleanNotes,
                                          dueOn: dueKey,
                                          repeat: repeat,
                                        ),
                                      );
                                } else {
                                  ref
                                      .read(tasksControllerProvider.notifier)
                                      .updateTask(
                                        existing.copyWith(
                                          title: cleanTitle,
                                          notes: cleanNotes.isEmpty
                                              ? null
                                              : cleanNotes,
                                          clearNotes: cleanNotes.isEmpty,
                                          dueOn: dueKey,
                                          clearDueOn: dueKey == null,
                                          repeat: repeat,
                                        ),
                                      );
                                }
                                Navigator.pop(ctx);
                              },
                              child: Text(
                                existing == null ? 'Save task' : 'Save changes',
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: close,
                            child: const Text('Cancel'),
                          ),
                          if (existing != null)
                            TextButton.icon(
                              style: TextButton.styleFrom(
                                foregroundColor: ctx.colors.error,
                              ),
                              icon: const Icon(Icons.delete_outline_rounded),
                              label: const Text('Delete task'),
                              onPressed: () async {
                                final bool deleted = await _confirmDeleteTask(
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
