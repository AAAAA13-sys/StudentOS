import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../features/calendar/calendar_controller.dart';
import '../../features/finance/finance_controller.dart';
import '../../features/notes/notes_controller.dart';
import '../db/backup.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import 'confirm_dialog.dart';

/// The menu behind the hamburger button: things that are not a tab.
class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  static String _count(int n, String noun) => '$n $noun${n == 1 ? '' : 's'}';

  Future<void> _backUp(BuildContext context, WidgetRef ref) async {
    // Everything needed is taken before the drawer closes; after that this
    // widget is gone and `ref` can no longer be used.
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final BackupService backup = ref.read(backupServiceProvider);
    Navigator.pop(context);
    try {
      final String json = await backup.exportJson();
      final String stamp = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final Uri? saved = await FilePicker.saveFile(
        fileName: 'studentos-backup-$stamp.json',
        bytes: utf8.encode(json),
        mimeType: 'application/json',
      );
      if (saved != null) {
        messenger.showSnackBar(const SnackBar(content: Text('Backup saved')));
      }
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Could not save the backup')),
      );
    }
  }

  Future<void> _restore(BuildContext context, WidgetRef ref) async {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final bool confirmed = await confirmDestructive(
      context,
      title: 'Restore a backup?',
      message:
          'Everything in the app now will be replaced by the contents of '
          'the backup file you pick.',
      confirmLabel: 'Choose file',
    );
    if (!confirmed || !context.mounted) return;
    final BackupService backup = ref.read(backupServiceProvider);
    final ProviderContainer container = ProviderScope.containerOf(context);
    Navigator.pop(context);
    try {
      final PlatformFile? file = await FilePicker.pickFile();
      if (file == null) return;
      final String json = utf8.decode(await file.readAsBytes());
      final counts = await backup.restoreJson(json);
      container
        ..invalidate(calendarControllerProvider)
        ..invalidate(financeControllerProvider)
        ..invalidate(notesControllerProvider);
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Restored ${_count(counts.events, 'event')}, '
            '${_count(counts.transactions, 'transaction')} and '
            '${_count(counts.notes, 'note')}',
          ),
        ),
      );
    } on BackupFormatException catch (error) {
      messenger.showSnackBar(SnackBar(content: Text(error.message)));
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Could not read that file')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ColorScheme colors = context.colors;
    final TextTheme textStyles = context.textStyles;

    Widget sectionLabel(String text) => Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
          color: AppColors.slate500,
        ),
      ),
    );

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          Container(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
            decoration: BoxDecoration(
              color: colors.primaryContainer.withValues(alpha: 0.4),
              border: Border(bottom: BorderSide(color: colors.outlineVariant)),
            ),
            child: SafeArea(
              bottom: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'StudentOS',
                    style: textStyles.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Everything is stored on this device.',
                    style: textStyles.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          sectionLabel('YOUR DATA'),
          ListTile(
            leading: const Icon(Icons.save_alt_rounded),
            title: const Text('Back up to a file'),
            subtitle: const Text('Save a copy you can keep elsewhere'),
            onTap: () => _backUp(context, ref),
          ),
          ListTile(
            leading: const Icon(Icons.restore_rounded),
            title: const Text('Restore from a file'),
            subtitle: const Text('Replaces what is in the app now'),
            onTap: () => _restore(context, ref),
          ),
          sectionLabel('ABOUT'),
          const ListTile(
            leading: Icon(Icons.info_outline_rounded),
            title: Text('StudentOS 1.0.0'),
            subtitle: Text('No account, no internet needed'),
          ),
        ],
      ),
    );
  }
}
