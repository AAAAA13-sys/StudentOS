import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/calendar/calendar_screen.dart';
import '../../features/finance/finance_screen.dart';
import '../../features/notes/notes_screen.dart';
import '../../features/focus/clock_screen.dart';
import '../widgets/scaffold_with_nav_bar.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'root',
);

final Provider<GoRouter> routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/calendar',
    routes: <RouteBase>[
      StatefulShellRoute.indexedStack(
        builder:
            (
              BuildContext context,
              GoRouterState state,
              StatefulNavigationShell navigationShell,
            ) {
              return ScaffoldWithNavBar(navigationShell: navigationShell);
            },
        branches: <StatefulShellBranch>[
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: '/calendar',
                builder: (BuildContext context, GoRouterState state) =>
                    const CalendarScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: '/finance',
                builder: (BuildContext context, GoRouterState state) =>
                    const FinanceScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: '/notes',
                builder: (BuildContext context, GoRouterState state) =>
                    const NotesScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: '/clock',
                builder: (BuildContext context, GoRouterState state) =>
                    const ClockScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
