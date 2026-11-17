import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/confirm_dialog.dart';
import 'note.dart';
import 'notes_controller.dart';

/// Opens [note] for editing in a bottom sheet.
///
/// With [onCreate], [note] is a draft that is not stored yet: saving calls
/// [onCreate] with the finished note instead of updating one, and closing
/// the sheet without saving stores nothing.
Future<void> showNoteEditor(
  BuildContext context,
  WidgetRef ref,
  Note note, {
  Future<void> Function(Note draft)? onCreate,
}) async {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController titleController = TextEditingController(
    text: note.title,
  );
  final TextEditingController bodyController = TextEditingController(
    text: note.body,
  );
  final TextEditingController tagsController = TextEditingController(
    text: note.tags.join(', '),
  );
  final FocusNode bodyFocus = FocusNode();

  await showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    // A stray tap outside must not throw away what was typed.
    isDismissible: false,
    enableDrag: false,
    builder: (BuildContext ctx) {
      return Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
          left: AppSpacing.lg,
          right: AppSpacing.lg,
          top: AppSpacing.xl,
        ),
        child: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(
                  onCreate == null ? 'Edit Note' : 'New Note',
                  style: ctx.textStyles.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                AppSpacing.gapLg,
                TextFormField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Title (optional)',
                    border: OutlineInputBorder(borderRadius: AppRadius.medium),
                  ),
                  validator: (String? val) =>
                      noteTitleFor(val ?? '', bodyController.text) == null
                      ? 'Write a title or some text'
                      : null,
                ),
                AppSpacing.gapMd,
                TextFormField(
                  controller: bodyController,
                  focusNode: bodyFocus,
                  maxLines: 6,
                  textAlignVertical: TextAlignVertical.top,
                  decoration: const InputDecoration(
                    labelText: 'Note content',
                    alignLabelWithHint: true,
                    hintText:
                        'Notes or active recall cards (e.g. Q: ... A: ...)',
                    border: OutlineInputBorder(borderRadius: AppRadius.medium),
                  ),
                ),
                const SizedBox(height: 4),
                Wrap(
                  children: <Widget>[
                    TextButton.icon(
                      onPressed: () {
                        final String text = bodyController.text;
                        final int cursor = bodyController.selection.isValid
                            ? bodyController.selection.start
                            : text.length;
                        final String before = text.substring(0, cursor);
                        final String after = text.substring(cursor);
                        final String prefix =
                            before.isEmpty || before.endsWith('\n') ? '' : '\n';
                        final String inserted = '$before$prefix- [ ] ';
                        bodyController.text = '$inserted$after';
                        bodyController.selection = TextSelection.fromPosition(
                          TextPosition(offset: inserted.length),
                        );
                        bodyFocus.requestFocus();
                      },
                      icon: const Icon(Icons.add_task_rounded, size: 16),
                      label: Text(
                        'Add checklist item',
                        style: Theme.of(ctx).textTheme.labelMedium,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () {
                        final String text = bodyController.text;
                        final String prefix =
                            text.isEmpty || text.endsWith('\n') ? '' : '\n\n';
                        bodyController.text = '$text${prefix}Q: \nA: ';
                        bodyController.selection = TextSelection.fromPosition(
                          TextPosition(offset: bodyController.text.length - 4),
                        );
                        // So the question is typed here, not in whichever
                        // field had the cursor.
                        bodyFocus.requestFocus();
                      },
                      icon: const Icon(Icons.bolt_rounded, size: 16),
                      label: Text(
                        'Add Q&A recall card',
                        style: Theme.of(ctx).textTheme.labelMedium,
                      ),
                    ),
                  ],
                ),
                AppSpacing.gapMd,
                TextFormField(
                  controller: tagsController,
                  decoration: const InputDecoration(
                    labelText: 'Tags (comma separated, e.g. math, lecture)',
                    border: OutlineInputBorder(borderRadius: AppRadius.medium),
                  ),
                ),
                AppSpacing.gapXl,
                SizedBox(
                  height: AppSizes.buttonHeight,
                  child: FilledButton(
                    onPressed: () {
                      if (!formKey.currentState!.validate()) return;
                      final List<String> tags = tagsController.text
                          .split(',')
                          .map((String s) => s.trim())
                          .where((String s) => s.isNotEmpty)
                          .toList();

                      final String title = noteTitleFor(
                        titleController.text,
                        bodyController.text,
                      )!;
                      if (onCreate != null) {
                        onCreate(
                          Note(
                            id: 0,
                            title: title,
                            body: bodyController.text,
                            tags: tags,
                          ),
                        );
                      } else {
                        ref
                            .read(notesControllerProvider.notifier)
                            .updateNote(
                              note.id,
                              title: title,
                              body: bodyController.text,
                              tags: tags,
                            );
                      }
                      Navigator.pop(ctx);
                    },
                    child: Text(onCreate == null ? 'Update Note' : 'Save Note'),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                if (onCreate == null)
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      foregroundColor: ctx.colors.error,
                    ),
                    icon: const Icon(Icons.delete_outline_rounded),
                    label: const Text('Delete note'),
                    onPressed: () async {
                      final bool confirmed = await confirmDestructive(
                        ctx,
                        title: 'Delete note?',
                        message: '"${note.title}" will be removed.',
                      );
                      if (!confirmed) return;
                      await ref
                          .read(notesControllerProvider.notifier)
                          .deleteNote(note.id);
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
                  ),
                AppSpacing.gapSm,
              ],
            ),
          ),
        ),
      );
    },
  );
}
