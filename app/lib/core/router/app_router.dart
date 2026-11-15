import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/auth_controller.dart';
import '../../features/auth/auth_state.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/register_screen.dart';
import '../../features/calendar/calendar_screen.dart';
import '../../features/finance/finance_screen.dart';
import '../../features/notes/notes_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../widgets/scaffold_with_nav_bar.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'root');

class RouterNotifier extends ChangeNotifier {
  RouterNotifier(this._ref) {
    _ref.listen<AuthState>(
      authControllerProvider,
      (_, _) => notifyListeners(),
    );
  }

  final Ref _ref;

  String? redirect(BuildContext context, GoRouterState state) {
    final AuthState authState = _ref.read(authControllerProvider);

    if (authState is AuthUnknown) {
      return null;
    }

    final bool isAuthRoute =
        state.matchedLocation == '/login' || state.matchedLocation == '/register';

    if (authState is Unauthenticated) {
      return isAuthRoute ? null : '/login';
    }

    if (authState is Authenticated) {
      if (isAuthRoute || state.matchedLocation == '/') {
        return '/calendar';
      }
      return null;
    }

    return null;
  }
}

final Provider<RouterNotifier> routerNotifierProvider =
    Provider<RouterNotifier>((ref) => RouterNotifier(ref));

final Provider<GoRouter> routerProvider = Provider<GoRouter>((ref) {
  final RouterNotifier notifier = ref.watch(routerNotifierProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/calendar',
    refreshListenable: notifier,
    redirect: notifier.redirect,
    routes: <RouteBase>[
      GoRoute(
        path: '/login',
        builder: (BuildContext context, GoRouterState state) =>
            const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (BuildContext context, GoRouterState state) =>
            const RegisterScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (
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
                path: '/profile',
                builder: (BuildContext context, GoRouterState state) =>
                    const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
