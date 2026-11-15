import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
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

  await showModalBottomSheet<void>(
    context: context,
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
                  maxLines: 6,
                  decoration: const InputDecoration(
                    labelText: 'Note content',
                    border: OutlineInputBorder(borderRadius: AppRadius.medium),
                  ),
                ),
                AppSpacing.gapMd,
                TextFormField(
                  controller: tagsController,
                  decoration: const InputDecoration(
                    labelText: 'Tags (comma separated)',
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
                AppSpacing.gapSm,
              ],
            ),
          ),
        ),
      );
    },
  );
}
