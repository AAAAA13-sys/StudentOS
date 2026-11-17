import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../db/backup.dart';
import '../theme/app_theme.dart';

/// The one app bar every tab uses: menu button, left-aligned tab name, and
/// at most two actions.
class AppTopBar extends ConsumerWidget implements PreferredSizeWidget {
  const AppTopBar({
    required this.title,
    this.actions = const <Widget>[],
    super.key,
  });

  final String title;
  final List<Widget> actions;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final BackupStatus? status = ref.watch(backupStatusProvider).value;
    final bool backupDue =
        status != null &&
        backupNeedsAttention(
          status.last,
          DateTime.now(),
          hasData: status.hasData,
        );
    return AppBar(
      centerTitle: false,
      titleSpacing: 0,
      leading: IconButton(
        icon: Badge(
          smallSize: 8,
          isLabelVisible: backupDue,
          child: const Icon(Icons.menu_rounded),
        ),
        tooltip: backupDue ? 'Menu, a backup is due' : 'Menu',
        // The drawer belongs to the shell's Scaffold, not the tab's own.
        onPressed: () =>
            context.findRootAncestorStateOfType<ScaffoldState>()?.openDrawer(),
      ),
      title: Text(
        title,
        style: context.textStyles.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
      actions: actions,
    );
  }
}
