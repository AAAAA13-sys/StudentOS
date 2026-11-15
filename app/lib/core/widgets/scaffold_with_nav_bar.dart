import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

class ScaffoldWithNavBar extends StatelessWidget {
  const ScaffoldWithNavBar({
    required this.navigationShell,
    super.key,
  });

  final StatefulNavigationShell navigationShell;

  void _goTo(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = context.colors;
    final TextTheme textStyles = context.textStyles;

    return Scaffold(
      drawer: NavigationDrawer(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (int index) {
          Navigator.pop(context);
          _goTo(index);
        },
        children: <Widget>[
          Container(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: colors.primaryContainer.withValues(alpha: 0.4),
              border: Border(
                bottom: BorderSide(color: colors.outlineVariant, width: 1),
              ),
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
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'MODULES',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
                color: AppColors.slate500,
              ),
            ),
          ),
          const NavigationDrawerDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month_rounded),
            label: Text('Calendar'),
          ),
          const NavigationDrawerDestination(
            icon: Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: Icon(Icons.account_balance_wallet_rounded),
            label: Text('Finance Tracker'),
          ),
          const NavigationDrawerDestination(
            icon: Icon(Icons.article_outlined),
            selectedIcon: Icon(Icons.article_rounded),
            label: Text('Lecture Notes'),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Divider(),
          ),
          const ListTile(
            dense: true,
            leading: Icon(Icons.phone_android_rounded, size: 20),
            title: Text('Local only'),
            subtitle: Text('No account, no internet needed'),
          ),
          const ListTile(
            dense: true,
            leading: Icon(Icons.info_outline_rounded, size: 20),
            title: Text('Version'),
            subtitle: Text('StudentOS 1.0.0'),
          ),
        ],
      ),
      body: navigationShell,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: colors.surfaceContainerLowest,
          border: Border(
            top: BorderSide(color: colors.outlineVariant, width: 1.0),
          ),
        ),
        child: NavigationBar(
          selectedIndex: navigationShell.currentIndex,
          onDestinationSelected: _goTo,
          destinations: const <NavigationDestination>[
            NavigationDestination(
              icon: Icon(Icons.calendar_month_outlined),
              selectedIcon: Icon(Icons.calendar_month_rounded),
              label: 'Calendar',
            ),
            NavigationDestination(
              icon: Icon(Icons.account_balance_wallet_outlined),
              selectedIcon: Icon(Icons.account_balance_wallet_rounded),
              label: 'Finance',
            ),
            NavigationDestination(
              icon: Icon(Icons.article_outlined),
              selectedIcon: Icon(Icons.article_rounded),
              label: 'Notes',
            ),
          ],
        ),
      ),
    );
  }
}
