import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// The one app bar every tab uses: menu button, left-aligned tab name, and
/// at most two actions.
class AppTopBar extends StatelessWidget implements PreferredSizeWidget {
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
  Widget build(BuildContext context) {
    return AppBar(
      centerTitle: false,
      titleSpacing: 0,
      leading: IconButton(
        icon: const Icon(Icons.menu_rounded),
        tooltip: 'Menu',
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
