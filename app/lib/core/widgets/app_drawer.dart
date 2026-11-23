import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../features/calendar/calendar_controller.dart';
import '../../features/calendar/schedule_view.dart';
import '../../features/finance/bills_controller.dart';
import '../../features/finance/finance_controller.dart';
import '../../features/focus/focus_controller.dart';
import '../../features/focus/focus_platform.dart';
import '../../features/phone/phone_controller.dart';
import '../../features/work/payday.dart';
import '../../features/work/work_controller.dart';
import '../../features/notes/notes_controller.dart';
import '../db/backup.dart';
import '../theme/app_spacing.dart';
import '../theme/app_theme.dart';
import 'confirm_dialog.dart';
import 'ponpon.dart';

/// The menu behind the hamburger button: things that are not a tab.
class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  static String _count(int n, String noun) => '$n $noun${n == 1 ? '' : 's'}';

  /// Formats the restore snackbar message, omitting zero counts for optional
  /// modules (`bills`, `shifts`, `alarms`).
  static String formatRestoreSummary({
    required int events,
    required int transactions,
    required int notes,
    int bills = 0,
    int shifts = 0,
    int alarms = 0,
  }) {
    final List<String> parts = <String>[
      _count(events, 'event'),
      _count(transactions, 'transaction'),
      _count(notes, 'note'),
      if (bills > 0) _count(bills, 'bill'),
      if (shifts > 0) _count(shifts, 'shift'),
      if (alarms > 0) _count(alarms, 'alarm'),
    ];
    final String head = parts.sublist(0, parts.length - 1).join(', ');
    return 'Restored $head and ${parts.last}';
  }

  Future<void> _backUp(BuildContext context, WidgetRef ref) async {
    // Everything needed is taken before the drawer closes; after that this
    // widget is gone and `ref` can no longer be used.
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final BackupService backup = ref.read(backupServiceProvider);
    final ProviderContainer container = ProviderScope.containerOf(context);
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
        await backup.markBackedUp(DateTime.now());
        container.invalidate(backupStatusProvider);
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
      final counts = await backup.restoreJsonWithCounts(json);
      container
        ..invalidate(calendarControllerProvider)
        ..invalidate(scheduleViewProvider)
        ..invalidate(financeControllerProvider)
        ..invalidate(billsControllerProvider)
        ..invalidate(notesControllerProvider)
        ..invalidate(workControllerProvider)
        ..invalidate(paydayProvider)
        ..invalidate(phoneControllerProvider)
        ..invalidate(alarmControllerProvider)
        ..invalidate(focusControllerProvider)
        ..invalidate(backupStatusProvider);
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            formatRestoreSummary(
              events: counts.events,
              transactions: counts.transactions,
              notes: counts.notes,
              bills: counts.bills,
              shifts: counts.shifts,
              alarms: counts.alarms,
            ),
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
    final BackupStatus? backupStatus = ref.watch(backupStatusProvider).value;

    Widget sectionLabel(String text) => Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.lg,
        AppSpacing.xl,
        AppSpacing.xs,
      ),
      child: Text(
        text,
        style: textStyles.labelSmall?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
          color: colors.onSurfaceVariant,
        ),
      ),
    );

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          Container(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              AppSpacing.xl,
              AppSpacing.xl,
              AppSpacing.xl,
            ),
            decoration: BoxDecoration(
              color: colors.primaryContainer.withValues(alpha: 0.4),
              border: Border(bottom: BorderSide(color: colors.outlineVariant)),
            ),
            child: SafeArea(
              bottom: false,
              child: Row(
                children: <Widget>[
                  const Ponpon(size: 64),
                  AppSpacing.gapMd,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'StudentOS',
                          style: textStyles.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        AppSpacing.gapXs,
                        Text(
                          'Everything is stored on this device.',
                          style: textStyles.bodySmall?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ],
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
            subtitle: Text(
              'Last backup: ${backupAgeLabel(backupStatus?.last, DateTime.now())}',
            ),
            onTap: () => _backUp(context, ref),
          ),
          ListTile(
            leading: const Icon(Icons.restore_rounded),
            title: const Text('Restore from a file'),
            subtitle: const Text('Replaces what is in the app now'),
            onTap: () => _restore(context, ref),
          ),
          sectionLabel('HOME-SCREEN WIDGETS'),
          for (final (String which, IconData icon, String title, String about)
              in <(String, IconData, String, String)>[
                (
                  'calendar',
                  Icons.calendar_month_outlined,
                  'Today',
                  'Next class, alarm and focus timer',
                ),
                (
                  'finance',
                  Icons.account_balance_wallet_outlined,
                  'Money',
                  'Spent today and left this month',
                ),
              ])
            ListTile(
              leading: Icon(icon),
              title: Text('Add $title widget'),
              subtitle: Text(about),
              onTap: () async {
                final ScaffoldMessengerState messenger = ScaffoldMessenger.of(
                  context,
                );
                Navigator.of(context).pop();
                final bool ok = await ref
                    .read(focusPlatformProvider)
                    .pinWidget(which);
                if (!ok) {
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Your launcher cannot add it from here. Long-press '
                        'the home screen, tap Widgets and find StudentOS.',
                      ),
                    ),
                  );
                }
              },
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
