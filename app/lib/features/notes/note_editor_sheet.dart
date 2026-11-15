import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import 'note.dart';
import 'notes_controller.dart';

/// Opens [note] for editing in a bottom sheet.
Future<void> showNoteEditor(
  BuildContext context,
  WidgetRef ref,
  Note note,
) async {
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
                  'Edit Note',
                  style: ctx.textStyles.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                AppSpacing.gapLg,
                TextFormField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    border: OutlineInputBorder(borderRadius: AppRadius.medium),
                  ),
                  validator: (String? val) => val == null || val.trim().isEmpty
                      ? 'Title required'
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

                      ref
                          .read(notesControllerProvider.notifier)
                          .updateNote(
                            note.id,
                            title: titleController.text.trim(),
                            body: bodyController.text,
                            tags: tags,
                          );
                      Navigator.pop(ctx);
                    },
                    child: const Text('Update Note'),
                  ),
                ),
                AppSpacing.gapLg,
              ],
            ),
          ),
        ),
      );
    },
  );
}
