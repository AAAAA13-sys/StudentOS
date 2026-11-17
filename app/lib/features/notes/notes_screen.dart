import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_top_bar.dart';
import '../../core/widgets/capture_request.dart';
import '../../core/widgets/confirm_dialog.dart';
import '../../core/checklist.dart';
import 'note.dart';
import 'note_editor_sheet.dart';
import 'notes_controller.dart';
import 'quiz_sheet.dart';
import '../../core/widgets/ponpon.dart';
import '../insights/insights_providers.dart';
import '../insights/ponpon_talk_slot.dart';

class NotesScreen extends ConsumerStatefulWidget {
  const NotesScreen({super.key});

  @override
  ConsumerState<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends ConsumerState<NotesScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<NotesState> notesState = ref.watch(
      notesControllerProvider,
    );
    final ColorScheme colors = context.colors;
    final TextTheme textStyles = context.textStyles;

    return CaptureListener(
      action: CaptureAction.addNote,
      onCapture: () => _showAddNoteDialog(context),
      child: Scaffold(
        appBar: const AppTopBar(title: 'Notes'),
        body: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.sm,
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search notes',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded),
                          tooltip: 'Clear search',
                          onPressed: () {
                            _searchController.clear();
                            ref
                                .read(notesControllerProvider.notifier)
                                .search('');
                          },
                        )
                      : null,
                  border: const OutlineInputBorder(
                    borderRadius: AppRadius.medium,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 0,
                    horizontal: AppSpacing.md,
                  ),
                ),
                onChanged: (String val) {
                  ref.read(notesControllerProvider.notifier).search(val.trim());
                },
              ),
            ),
            PonponTalkSlot(
              surface: PonponSurface.notes,
              suppress: notesState.value?.notes.isEmpty ?? true,
            ),
            notesState.when(
              loading: () => const Expanded(
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (Object err, _) => Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Icon(
                        Icons.error_outline_rounded,
                        size: 48,
                        color: colors.error,
                      ),
                      AppSpacing.gapMd,
                      Text('Failed to load notes: $err'),
                      AppSpacing.gapLg,
                      FilledButton(
                        onPressed: () => ref
                            .read(notesControllerProvider.notifier)
                            .refresh(),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
              data: (NotesState state) {
                final List<Object> rows = _listRows(state.notes);
                return Expanded(
                  child: Column(
                    children: <Widget>[
                      if (state.tags.isNotEmpty)
                        SizedBox(
                          height: 48,
                          child: ListView.separated(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.lg,
                            ),
                            scrollDirection: Axis.horizontal,
                            itemCount: state.tags.length + 1,
                            separatorBuilder: (_, _) => AppSpacing.gapSm,
                            itemBuilder: (BuildContext ctx, int index) {
                              if (index == 0) {
                                final bool isSelected =
                                    state.selectedTag == null;
                                return FilterChip(
                                  label: const Text('All'),
                                  selected: isSelected,
                                  onSelected: (_) {
                                    ref
                                        .read(notesControllerProvider.notifier)
                                        .selectTag(null);
                                  },
                                );
                              }
                              final String tag = state.tags[index - 1];
                              final bool isSelected = state.selectedTag == tag;
                              return FilterChip(
                                label: Text('#$tag'),
                                selected: isSelected,
                                onSelected: (_) {
                                  ref
                                      .read(notesControllerProvider.notifier)
                                      .selectTag(isSelected ? null : tag);
                                },
                              );
                            },
                          ),
                        ),
                      Expanded(
                        child: state.notes.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: <Widget>[
                                    Ponpon(
                                      mood: state.searchQuery.isNotEmpty
                                          ? PonponMood.smug
                                          : PonponMood.happy,
                                      size: 88,
                                    ),
                                    AppSpacing.gapMd,
                                    Text(
                                      state.searchQuery.isNotEmpty
                                          ? 'No notes match "${state.searchQuery}"'
                                          : 'No notes yet',
                                      textAlign: TextAlign.center,
                                      style: textStyles.titleMedium?.copyWith(
                                        color: colors.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : RefreshIndicator(
                                onRefresh: () => ref
                                    .read(notesControllerProvider.notifier)
                                    .refresh(),
                                child: ListView.separated(
                                  padding: const EdgeInsets.fromLTRB(
                                    AppSpacing.lg,
                                    AppSpacing.sm,
                                    AppSpacing.lg,
                                    96,
                                  ),
                                  itemCount: rows.length,
                                  separatorBuilder: (_, _) => AppSpacing.gapSm,
                                  itemBuilder:
                                      (BuildContext context, int index) {
                                        final Object row = rows[index];
                                        if (row is String) {
                                          return _SectionLabel(row);
                                        }
                                        return _NoteCard(note: row as Note);
                                      },
                                ),
                              ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _showAddNoteDialog(context),
          child: const Icon(Icons.add_rounded),
        ),
      ),
    );
  }

  /// Notes with "Pinned" and "Others" labels, but only when something is
  /// pinned; otherwise the plain list.
  List<Object> _listRows(List<Note> notes) {
    final List<Note> pinned = notes.where((Note n) => n.pinned).toList();
    if (pinned.isEmpty) return notes;
    final List<Note> others = notes.where((Note n) => !n.pinned).toList();
    return <Object>[
      'Pinned',
      ...pinned,
      if (others.isNotEmpty) ...<Object>['Others', ...others],
    ];
  }

  Future<void> _showAddNoteDialog(BuildContext context) {
    return showNoteEditor(
      context,
      ref,
      Note(id: 0, title: '', body: '', tags: const <String>[]),
      onCreate: (Note draft) =>
          ref.read(notesControllerProvider.notifier).addNote(draft),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xs),
      child: Text(
        label,
        style: context.textStyles.labelMedium?.copyWith(
          color: context.colors.onSurfaceVariant,
        ),
      ),
    );
  }
}

/// One note in the list: title with a pin button, a two-line preview, up to
/// five tickable checklist rows, and one meta row with the date, the
/// recall-card chip and the tags. Long-press deletes; the editor sheet has a
/// delete button too.
class _NoteCard extends ConsumerWidget {
  const _NoteCard({required this.note});

  final Note note;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ColorScheme colors = context.colors;
    final TextTheme textStyles = context.textStyles;
    final DateTime? updated = note.updatedAt?.toLocal();
    final List<ChecklistItem> items = note.checklistItems;
    final int doneCount = items.where((ChecklistItem i) => i.done).length;
    // The checklist lines are shown as rows, so keep them out of the preview.
    final String preview = items.isEmpty
        ? note.body
        : note.body
              .split('\n')
              .where(
                (String l) => parseChecklist(l).isEmpty && l.trim().isNotEmpty,
              )
              .join('\n');

    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        borderRadius: AppRadius.large,
        onTap: () => showNoteEditor(context, ref, note),
        onLongPress: () async {
          final bool confirmed = await confirmDestructive(
            context,
            title: 'Delete note?',
            message: '"${note.title}" will be removed.',
          );
          if (confirmed) {
            await ref
                .read(notesControllerProvider.notifier)
                .deleteNote(note.id);
          }
        },
        child: Padding(
          padding: const EdgeInsets.only(
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            bottom: AppSpacing.md,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.md),
                      child: Text(
                        note.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textStyles.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: note.pinned ? 'Unpin note' : 'Pin note',
                    constraints: const BoxConstraints(
                      minWidth: 48,
                      minHeight: 48,
                    ),
                    icon: Icon(
                      note.pinned
                          ? Icons.push_pin_rounded
                          : Icons.push_pin_outlined,
                      size: 20,
                      color: note.pinned
                          ? colors.primary
                          : colors.onSurfaceVariant,
                    ),
                    onPressed: () => ref
                        .read(notesControllerProvider.notifier)
                        .setPinned(note.id, pinned: !note.pinned),
                  ),
                ],
              ),
              if (preview.isNotEmpty) ...<Widget>[
                Text(
                  preview,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: textStyles.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
              if (items.isNotEmpty) ...<Widget>[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '$doneCount of ${items.length} done',
                  style: textStyles.labelSmall?.copyWith(
                    color: colors.onSurfaceVariant,
                    fontFeatures: const <FontFeature>[
                      FontFeature.tabularFigures(),
                    ],
                  ),
                ),
                for (int i = 0; i < items.length && i < 5; i++)
                  InkWell(
                    borderRadius: AppRadius.small,
                    onTap: () => ref
                        .read(notesControllerProvider.notifier)
                        .updateNote(
                          note.id,
                          title: note.title,
                          body: toggleChecklistLine(note.body, i),
                          tags: note.tags,
                        ),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 48),
                      child: Row(
                        children: <Widget>[
                          Icon(
                            items[i].done
                                ? Icons.check_box_rounded
                                : Icons.check_box_outline_blank_rounded,
                            size: 18,
                            color: items[i].done
                                ? colors.primary
                                : colors.onSurfaceVariant,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              items[i].text,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: textStyles.bodySmall?.copyWith(
                                decoration: items[i].done
                                    ? TextDecoration.lineThrough
                                    : null,
                                color: items[i].done
                                    ? colors.onSurfaceVariant
                                    : colors.onSurface,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (items.length > 5)
                  Text(
                    '+${items.length - 5} more',
                    style: textStyles.labelSmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
              ],
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.xs,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: <Widget>[
                  if (updated != null)
                    Text(
                      DateFormat('MMM d, h:mm a').format(updated),
                      style: textStyles.labelSmall?.copyWith(
                        color: colors.onSurfaceVariant,
                        fontFeatures: const <FontFeature>[
                          FontFeature.tabularFigures(),
                        ],
                      ),
                    ),
                  if (note.recallCards.isNotEmpty)
                    InkWell(
                      borderRadius: AppRadius.pill,
                      onTap: () => showQuizSheet(context, note),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: colors.primaryContainer,
                          borderRadius: AppRadius.pill,
                          border: Border.all(
                            color: colors.primary.withValues(alpha: 0.3),
                            width: 0.75,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Icon(
                              Icons.bolt_rounded,
                              size: 14,
                              color: colors.primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${note.recallCards.length} ${note.recallCards.length == 1 ? 'card' : 'cards'} • Practice Recall',
                              style: textStyles.labelSmall?.copyWith(
                                color: colors.onPrimaryContainer,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  for (final String t in note.tags)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: colors.secondaryContainer,
                        borderRadius: AppRadius.small,
                      ),
                      child: Text(
                        '#$t',
                        style: textStyles.labelSmall?.copyWith(
                          color: colors.onSecondaryContainer,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
